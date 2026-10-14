"""Authorized exact-source improvement creation, without publishing working copies."""

import hashlib
import json
import math
import uuid
from typing import Any

from redis import Redis
from sqlalchemy import select
from sqlalchemy.orm import Session

from gramtree.accounts.models import User
from gramtree.core.errors import ApiError, NotFound
from gramtree.events.service import append_server_event
from gramtree.recipes import personalization, reproducibility, service
from gramtree.recipes.comparison import ComparisonVersion
from gramtree.recipes.full_comparison import RecipeFullComparison, compare_snapshots
from gramtree.recipes.improvement_models import (
    ImprovementCuration,
    ImprovementDraft,
    ImprovementReceipt,
    RecipeImprovementFact,
)
from gramtree.recipes.improvement_schemas import (
    ImprovementDraftOut,
    ImprovementPreviewInput,
    ImprovementPreviewOut,
    ImprovementSaveInput,
    ImprovementSaveOut,
    ImprovementTasteProposal,
    RecordVersionSaveInput,
)
from gramtree.recipes.models import Dish, Recipe, RecipeVersion
from gramtree.recipes.schemas import RecipeSnapshot
from gramtree.records.models import CookingRecord
from gramtree.runtime_config import service as config
from gramtree.settings import Settings
from gramtree.taste_profiles import service as taste
from gramtree.taste_profiles.models import TasteProfile
from gramtree.taste_profiles.schemas import FlavorKey


def _source(session: Session, owner: User, recipe_id: uuid.UUID, version_id: uuid.UUID):
    from gramtree.recipes.publication import readable_version

    recipe, version = readable_version(session, owner, recipe_id, version_id)
    if recipe.owner_id == owner.id:
        raise ApiError(422, "self_improvement", "自己的菜谱请存为新一版，不生成改良分支")
    return recipe, version


def _working_source(
    session: Session,
    owner: User,
    recipe_id: uuid.UUID,
    version_id: uuid.UUID,
    record_id: uuid.UUID | None = None,
):
    """Resume an owned exact draft/record, never grant a new public read."""
    if record_id is not None:
        recipe = session.get(Recipe, recipe_id)
        version = session.get(RecipeVersion, version_id)
        if recipe is None or version is None or version.recipe_id != recipe_id:
            raise NotFound()
        _record(session, owner, recipe, version, record_id)
        if recipe.owner_id == owner.id:
            raise ApiError(422, "self_improvement", "自己的菜谱请存为新一版，不生成改良分支")
        return recipe, version
    draft = session.scalar(
        select(ImprovementDraft)
        .where(
            ImprovementDraft.owner_id == owner.id,
            ImprovementDraft.source_recipe_id == recipe_id,
            ImprovementDraft.source_version_id == version_id,
        )
        .order_by(ImprovementDraft.created_at)
        .limit(1)
    )
    if draft is None:
        return _source(session, owner, recipe_id, version_id)
    recipe = session.get(Recipe, recipe_id)
    version = session.get(RecipeVersion, version_id)
    if recipe is None or version is None or version.recipe_id != recipe_id:
        raise NotFound()
    return recipe, version


def draft_out(row: ImprovementDraft) -> ImprovementDraftOut:
    return ImprovementDraftOut.model_validate(row, from_attributes=True)


def owned_draft(session: Session, owner: User, draft_id: uuid.UUID) -> ImprovementDraft:
    row = session.scalar(
        select(ImprovementDraft).where(
            ImprovementDraft.id == draft_id,
            ImprovementDraft.owner_id == owner.id,
        )
    )
    if row is None:
        raise NotFound()
    # The authorized working copy belongs to its creator, even after withdrawal.
    return row


def create_draft(session: Session, owner: User, recipe_id: uuid.UUID, version_id: uuid.UUID):
    recipe, version = _source(session, owner, recipe_id, version_id)
    dish = session.get(Dish, recipe.dish_id)
    if dish is None:
        raise NotFound()
    row = ImprovementDraft(
        owner_id=owner.id,
        source_recipe_id=recipe.id,
        source_version_id=version.id,
        snapshot=version.snapshot,
        dish_name=dish.name,
        ai_assisted=version.ai_assisted,
    )
    session.add(row)
    session.commit()
    return draft_out(row)


def _record(
    session: Session, owner: User, recipe: Recipe, version: RecipeVersion, record_id: uuid.UUID
) -> tuple[CookingRecord, RecipeSnapshot]:
    row = session.scalar(
        select(CookingRecord)
        .where(
            CookingRecord.id == record_id,
            CookingRecord.owner_id == owner.id,
        )
        .with_for_update()
    )
    if row is None:
        raise NotFound()
    if (
        row.recipe_id != recipe.id
        or row.recipe_version_id != version.id
        or row.source != "cooking_session"
        or row.verification != "cooking_mode"
        or not row.counts_as_cooked
        or row.source_context.get("server_completed") is not True
        or row.source_context.get("derivation_available") is not True
        or not row.source_context.get("executed_snapshot")
    ):
        raise ApiError(422, "invalid_derivation_record", "只能保存本人已完成做菜模式的实际做法")
    return row, RecipeSnapshot.model_validate(row.source_context["executed_snapshot"])


def _edit(
    session: Session,
    settings: Settings,
    owner: User,
    recipe: Recipe,
    version: RecipeVersion,
    body: ImprovementPreviewInput,
    *,
    final: bool = False,
):
    baseline = RecipeSnapshot.model_validate(version.snapshot)
    record = None
    modification = None
    operations = None
    if body.from_cooking_record_id:
        record, candidate = _record(session, owner, recipe, version, body.from_cooking_record_id)
        if body.snapshot is not None and body.snapshot.model_dump(
            mode="json"
        ) != candidate.model_dump(mode="json"):
            raise ApiError(422, "derivation_snapshot_mismatch", "保存的配方必须与这次实际做法一致")
    elif body.modification_request_id:
        from gramtree.ai import modifications

        modification = modifications._owned(session, owner, body.modification_request_id)
        if modification.saved_version_id or modification.confirmation:
            raise ApiError(409, "modification_already_saved", "这批修改已经保存")
        draft_id = modification.request.get("improvement_draft_id")
        if not draft_id:
            raise ApiError(422, "wrong_modification_target", "这批修改不属于改良工作副本")
        draft = owned_draft(session, owner, uuid.UUID(draft_id))
        if (draft.source_recipe_id, draft.source_version_id) != (recipe.id, version.id):
            raise ApiError(422, "wrong_modification_target", "这批修改不属于此来源版本")
        modifications._fresh(session, owner, modification)
        if modification.error or modification.revision != body.modification_revision:
            raise ApiError(409, "stale_modification_decisions", "请核对最新修改预览")
        candidate, _, decisions, operations = modifications._state(session, modification)
        if final and any(d.decision == "pending" for d in decisions):
            raise ApiError(409, "modification_decisions_required", "请逐条确认或拒绝修改建议")
        if final:
            from gramtree.ai import explanations

            explanations.validate_modification_fingerprint(
                owner.id,
                modification.id,
                modification.revision,
                operations,
                body.explanation_fingerprint,
            )
    else:
        candidate = body.snapshot or baseline.model_copy(deep=True)
    snapshot = service._prepare_version_snapshot(
        session,
        candidate,
        baseline,
        owner.id,
        settings=settings,
        trusted_sources=modification is not None or record is not None,
    )
    # Provenance normalization must not change the executed recipe's actual fields.
    dish = session.get(Dish, recipe.dish_id)
    if dish is None:
        raise NotFound()
    service._safety_for_save(session, snapshot, dish.name, [body.change_note])
    ops = operations if operations is not None else service._operations(baseline, snapshot)
    if record:
        ops = [{**op, "intent": "临场调整"} for op in ops]
    return snapshot, ops, record, modification


def _comparison(
    session: Session, recipe: Recipe, version: RecipeVersion, snapshot: RecipeSnapshot, owner: User
) -> RecipeFullComparison:
    dish = session.get(Dish, recipe.dish_id)
    author = session.get(User, recipe.owner_id)
    if dish is None or author is None:
        raise NotFound()
    original = RecipeSnapshot.model_validate(version.snapshot)
    metadata = ComparisonVersion(
        recipe_id=recipe.id,
        version_id=version.id,
        version_number=version.version_number,
        author=author.nickname,
        dish_name=dish.name,
        servings=original.servings,
    )
    # The unsaved endpoint metadata is display-only, not a persisted version ID.
    target = metadata.model_copy(update={"author": owner.nickname, "servings": snapshot.servings})
    return compare_snapshots(session, original, snapshot, metadata, target, stable=True)


def taste_proposal(
    session: Session, owner: User, baseline: RecipeSnapshot, snapshot: RecipeSnapshot
) -> ImprovementTasteProposal:
    """Invert identifiable single-axis weights, then verify with the actual compiler.

    Ambiguous mixed-axis edits cannot be inferred reliably; never silently discard
    other edits or guess coefficients. The existing compiler is the final authority.
    """

    def shape(value):
        data = value.model_dump(mode="json")
        for item in data["ingredients"]:
            for field in ("quantity", "base_quantity", "quantity_source", "measure_input_token"):
                item.pop(field, None)
        return data

    if shape(baseline) != shape(snapshot):
        return ImprovementTasteProposal(
            convertible=False,
            reason="只有可换算的用量改动才能存进口味；文字、步骤或单位变化请保存分支",
        )
    scale = taste.scale_for(session)
    profile = session.scalar(select(TasteProfile).where(TasteProfile.owner_id == owner.id))
    state = profile.flavors if profile else taste.defaults(scale)
    flavors = {key: float(value["coefficient"]) for key, value in state.items()}
    values: dict[str, float] = {}
    changed = False
    for before, after in zip(baseline.ingredients, snapshot.ingredients, strict=True):
        if before.quantity == after.quantity:
            continue
        changed = True
        axes = [
            (key, getattr(before.flavor_contribution, key))
            for key in personalization.FLAVOR_KEYS
            if before.flavor_contribution and getattr(before.flavor_contribution, key)
        ]
        if before.functional or before.group == "主料" or before.quantity <= 0 or len(axes) != 1:
            return ImprovementTasteProposal(
                convertible=False,
                reason="这项用量受功能性保护、缺少味型贡献或涉及多个味型，不能唯一换算进口味档案",
            )
        key, weight = axes[0]
        coefficient = 1 + (after.quantity / before.quantity - 1) * 3 / weight
        if not scale.minimum <= coefficient <= scale.maximum:
            return ImprovementTasteProposal(
                convertible=False, reason="换算后的口味系数超出档案允许范围"
            )
        if key in values and not math.isclose(values[key], coefficient, abs_tol=1e-8):
            return ImprovementTasteProposal(
                convertible=False, reason="同一味型的用量变化不一致，不能用一个口味系数完整表达"
            )
        values[key] = coefficient
    if not changed:
        return ImprovementTasteProposal(convertible=False, reason="没有可转换的用量变化")
    projected, _, _ = personalization.compile_rules(
        baseline,
        personalization.PersonalizationInput(
            flavors={**flavors, **values},
            profile_version=profile.version if profile else 1,
            adjustment_limit=float(config.get(session, "recipe.personalization_adjustment_limit")),
        ),
    )
    if any(
        not math.isclose(a.quantity, b.quantity, abs_tol=1e-8)
        for a, b in zip(projected.ingredients, snapshot.ingredients, strict=True)
    ):
        return ImprovementTasteProposal(
            convertible=False, reason="现有口味换算不能完整复现这些用量；请保存分支"
        )
    return ImprovementTasteProposal(
        convertible=True, coefficients=values, profile_version=profile.version if profile else 1
    )


def preview(
    session: Session,
    settings: Settings,
    owner: User,
    recipe_id: uuid.UUID,
    body: ImprovementPreviewInput,
) -> ImprovementPreviewOut:
    recipe, version = _working_source(
        session, owner, recipe_id, body.source_version_id, body.from_cooking_record_id
    )
    snapshot, _, _, _ = _edit(session, settings, owner, recipe, version, body)
    comparison = _comparison(session, recipe, version, snapshot, owner)
    proposal = taste_proposal(
        session, owner, RecipeSnapshot.model_validate(version.snapshot), snapshot
    )
    return ImprovementPreviewOut(
        snapshot=snapshot,
        comparison=comparison,
        microadjust_prompt="这个改动更像个人口味"
        if comparison.conclusion == "minor_only"
        else None,
        taste_proposal=proposal,
    )


def creation_event(
    session: Session,
    owner_id: uuid.UUID,
    event_type: str,
    content: dict[str, Any],
    correlation: dict[str, Any],
) -> None:
    append_server_event(session, owner_id, event_type, content, correlation)


def _source_path(session: Session, recipe: Recipe, version: RecipeVersion):
    fact = session.get(RecipeImprovementFact, recipe.id)
    path = list(fact.source_path) if fact else []
    author = session.get(User, recipe.owner_id)
    dish = session.get(Dish, recipe.dish_id)
    if author is None or dish is None:
        raise NotFound()
    path.append(
        {
            "recipe_id": str(recipe.id),
            "version_id": str(version.id),
            "version_number": version.version_number,
            "author_id": str(author.id),
            "author": author.nickname,
            "title": dish.name,
        }
    )
    if len({node["recipe_id"] for node in path}) != len(path):
        raise ApiError(409, "invalid_source_chain", "来源链出现循环")
    return (fact.root_recipe_id if fact else recipe.id), path


def save(
    session: Session,
    redis: Redis,
    settings: Settings,
    owner: User,
    recipe_id: uuid.UUID,
    body: ImprovementSaveInput,
) -> ImprovementSaveOut:
    # Owner lock serializes all retry/profile/branch mutations, including first use.
    taste.lock_owner(session, owner.id)
    fingerprint = hashlib.sha256(
        json.dumps(
            {"recipe_id": str(recipe_id), "body": body.model_dump(mode="json")},
            sort_keys=True,
            ensure_ascii=False,
        ).encode()
    ).hexdigest()
    receipt = session.scalar(
        select(ImprovementReceipt).where(
            ImprovementReceipt.owner_id == owner.id,
            ImprovementReceipt.request_id == body.request_id,
        )
    )
    if receipt:
        if receipt.fingerprint != fingerprint:
            raise ApiError(409, "idempotency_conflict", "这个保存请求已经用于其他内容")
        return ImprovementSaveOut.model_validate(receipt.response)
    recipe, source = _working_source(
        session, owner, recipe_id, body.source_version_id, body.from_cooking_record_id
    )
    snapshot, operations, record, modification = _edit(
        session, settings, owner, recipe, source, body, final=True
    )
    comparison = _comparison(session, recipe, source, snapshot, owner)
    if comparison.conclusion == "no_change":
        raise ApiError(422, "no_improvement_changes", "没有变化，请直接收藏或做原版")
    minor = comparison.conclusion == "minor_only"
    if minor and body.microadjust_choice is None:
        raise ApiError(
            409, "microadjust_choice_required", "这个改动更像个人口味，请选择存进口味或仍然保存"
        )
    if not minor and body.microadjust_choice == "taste":
        raise ApiError(422, "not_microadjustment", "一般或显著改动不能转换为口味档案")
    root, path = _source_path(session, recipe, source)
    fact_payload = {
        "source_recipe_id": str(recipe.id),
        "source_version_id": str(source.id),
        "root_recipe_id": str(root),
        "source_path": path,
        "conclusion": comparison.conclusion,
        "rules_version": comparison.rules_version,
        "basis": comparison.basis,
        "actor_id": str(owner.id),
        "cooking_record_id": str(record.id) if record else None,
    }
    if body.microadjust_choice == "taste":
        proposal = taste_proposal(
            session, owner, RecipeSnapshot.model_validate(source.snapshot), snapshot
        )
        if not proposal.convertible:
            raise ApiError(
                422, "taste_conversion_unavailable", "不能完整存进口味档案", proposal.reason
            )
        if body.expected_profile_version != proposal.profile_version:
            raise ApiError(409, "profile_changed", "请核对当前口味拟变更后再确认")
        scale = taste.scale_for(session)
        profile = taste.locked_profile(session, owner.id, scale)
        from typing import cast

        taste.mutate_profile(
            session,
            profile,
            {cast(FlavorKey, key): value for key, value in proposal.coefficients.items()},
            scale,
        )
        creation_event(
            session,
            owner.id,
            "recipe.improvement_saved_to_taste",
            {
                "source_recipe_id": str(recipe.id),
                "source_version_id": str(source.id),
                "conclusion": comparison.conclusion,
                "rules_version": comparison.rules_version,
                "profile_id": str(profile.id),
                "profile_version": profile.version,
            },
            {"recipe_version_id": str(source.id)},
        )
        result = ImprovementSaveOut(outcome="taste", profile_version=profile.version)
    else:
        branch = Recipe(
            owner_id=owner.id,
            dish_id=recipe.dish_id,
            visibility="private",
            source_version_id=source.id,
            root_recipe_id=root,
        )
        session.add(branch)
        session.flush()
        dish = session.get(Dish, recipe.dish_id)
        assert dish is not None
        safety = service._safety_for_save(session, snapshot, dish.name, [body.change_note])
        version = RecipeVersion(
            recipe_id=branch.id,
            version_number=1,
            snapshot=snapshot.model_dump(mode="json"),
            derived=service._derived(session, snapshot).model_dump(mode="json"),
            reproducibility=reproducibility.check(snapshot).model_dump(mode="json"),
            safety_at_save=safety.model_dump(mode="json"),
            safety_current=safety.model_dump(mode="json"),
            safety_rules_version=safety.rules_version,
            safety_context={"title": dish.name, "descriptions": [body.change_note]},
            edit_operations=operations,
            ai_assisted=source.ai_assisted or modification is not None,
            change_note=body.change_note,
            conclusion=comparison.conclusion,
            rules_version=comparison.rules_version,
        )
        session.add(version)
        session.flush()
        branch.current_version_id = version.id
        creation_comparison = comparison.model_copy(
            update={
                "to_version": comparison.to_version.model_copy(
                    update={
                        "recipe_id": branch.id,
                        "version_id": version.id,
                        "version_number": version.version_number,
                    }
                )
            }
        )
        fact = RecipeImprovementFact(
            recipe_id=branch.id,
            version_id=version.id,
            owner_id=owner.id,
            source_recipe_id=recipe.id,
            source_version_id=source.id,
            root_recipe_id=root,
            source_path=path,
            branch_type="microadjust" if minor else "normal",
            conclusion=comparison.conclusion,
            rules_version=comparison.rules_version,
            comparison=creation_comparison.model_dump(mode="json"),
            cooking_record_id=record.id if record else None,
        )
        session.add(fact)
        session.flush()
        from gramtree.recipes import publication

        if record:
            publication.trusted_record_derivation(session, record, version)
        publication.check_version(session, settings, branch, version)
        service._enqueue_save_event(session, owner, branch, version)
        if modification:
            modification.saved_version_id = version.id
            modification.confirmation = body.model_dump(mode="json")
        creation_event(
            session,
            owner.id,
            "recipe.improvement_created",
            {
                **fact_payload,
                "recipe_id": str(branch.id),
                "version_id": str(version.id),
                "branch_type": fact.branch_type,
                "intent": "临场调整" if record else "改良",
            },
            {
                "recipe_version_id": str(version.id),
                **({"cooking_record_id": str(record.id)} if record else {}),
            },
        )
        result = ImprovementSaveOut(
            outcome="branch", recipe=service._detail(session, settings, branch, version)
        )
    if modification:
        from gramtree.ai import modifications

        modification.confirmation = body.model_dump(mode="json")
        _, _, decisions, _ = modifications._state(session, modification)
        saved_version = (
            session.get(RecipeVersion, modification.saved_version_id)
            if modification.saved_version_id
            else None
        )
        modifications._event(session, redis, owner, modification, "saved", decisions, saved_version)
    session.add(
        ImprovementReceipt(
            owner_id=owner.id,
            request_id=body.request_id,
            fingerprint=fingerprint,
            response=result.model_dump(mode="json"),
        )
    )
    session.commit()
    service._drain_save_events(session, redis, owner)
    return result


def save_record_version(
    session: Session,
    redis: Redis,
    settings: Settings,
    owner: User,
    record_id: uuid.UUID,
    body: RecordVersionSaveInput,
) -> ImprovementSaveOut:
    from gramtree.recipes import publication
    from gramtree.recipes.schemas import RecipeVersionCreate

    taste.lock_owner(session, owner.id)
    fingerprint = hashlib.sha256(
        json.dumps(
            {"record_id": str(record_id), "body": body.model_dump(mode="json")}, sort_keys=True
        ).encode()
    ).hexdigest()
    receipt = session.scalar(
        select(ImprovementReceipt).where(
            ImprovementReceipt.owner_id == owner.id,
            ImprovementReceipt.request_id == body.request_id,
        )
    )
    if receipt:
        if receipt.fingerprint != fingerprint:
            raise ApiError(409, "idempotency_conflict", "这个保存请求已经用于其他内容")
        return ImprovementSaveOut.model_validate(receipt.response)
    record = session.scalar(
        select(CookingRecord).where(
            CookingRecord.id == record_id, CookingRecord.owner_id == owner.id
        )
    )
    if record is None or record.recipe_id is None or record.recipe_version_id is None:
        raise NotFound()
    recipe, source = service._owned_version(
        session, owner, record.recipe_id, record.recipe_version_id
    )
    record, snapshot = _record(session, owner, recipe, source, record.id)
    comparison = _comparison(session, recipe, source, snapshot, owner)
    if comparison.conclusion == "no_change":
        raise ApiError(422, "no_improvement_changes", "没有实际变化，不需要保存新版本")
    operations = [
        {**op, "intent": "临场调整"}
        for op in service._operations(RecipeSnapshot.model_validate(source.snapshot), snapshot)
    ]

    def proof(version):
        publication.trusted_record_derivation(session, record, version)
        publication.check_version(session, settings, recipe, version)
        creation_event(
            session,
            owner.id,
            "recipe.record_version_saved",
            {
                "recipe_id": str(recipe.id),
                "version_id": str(version.id),
                "source_version_id": str(source.id),
                "cooking_record_id": str(record.id),
                "intent": "临场调整",
                "conclusion": comparison.conclusion,
                "rules_version": comparison.rules_version,
            },
            {"recipe_version_id": str(version.id), "cooking_record_id": str(record.id)},
        )

    detail = service.mutate_version(
        session,
        redis,
        settings,
        owner,
        recipe.id,
        RecipeVersionCreate(
            snapshot=snapshot, base_version_id=source.id, change_note=body.change_note
        ),
        trusted_sources=True,
        confirmed_operations=operations,
        before_commit=proof,
    )
    result = ImprovementSaveOut(outcome="branch", recipe=detail)
    session.add(
        ImprovementReceipt(
            owner_id=owner.id,
            request_id=body.request_id,
            fingerprint=fingerprint,
            response=result.model_dump(mode="json"),
        )
    )
    session.commit()
    service._drain_save_events(session, redis, owner)
    return result


def branch_inputs(session: Session, recipe_id: uuid.UUID) -> dict[str, Any]:
    """Internal inputs, not a public qualification/count/ranking endpoint."""
    fact = session.get(RecipeImprovementFact, recipe_id)
    recipe = session.get(Recipe, recipe_id)
    if fact is None or recipe is None:
        raise NotFound()
    curated = session.get(ImprovementCuration, recipe_id)
    from gramtree.recipes import publication

    version = session.get(RecipeVersion, fact.version_id)
    # Preserve record identities/revisions in the source tables; this read is only
    # the future policy input, not SPEC-007.3 aggregation or scoring.
    records = session.scalars(
        select(CookingRecord).where(
            CookingRecord.recipe_version_id == fact.version_id,
            CookingRecord.owner_id != recipe.owner_id,
            CookingRecord.source == "cooking_session",
            CookingRecord.verification == "cooking_mode",
        )
    )
    identities = {row.owner_id for row in records if publication.trusted_record(row)}
    return {
        "recipe_id": str(recipe.id),
        "version_id": str(fact.version_id),
        "source_recipe_id": str(fact.source_recipe_id),
        "source_version_id": str(fact.source_version_id),
        "root_recipe_id": str(fact.root_recipe_id),
        "source_path": fact.source_path,
        "branch_type": fact.branch_type,
        "conclusion": fact.conclusion,
        "rules_version": fact.rules_version,
        "change_significant": fact.conclusion == "significant",
        "creation_comparison": fact.comparison,
        "non_author_cooked_users": len(identities),
        "cooked_user_threshold": int(config.get(session, "recipe.significant_branch_cooked_users")),
        "curated": bool(curated and curated.curated),
        "cooking_record_id": str(fact.cooking_record_id) if fact.cooking_record_id else None,
        "publication_state": publication.state(session, version) if version else None,
        "ever_public": bool(getattr(recipe, "ever_public", False)),
    }


def source_attribution(session: Session, recipe: Recipe) -> dict[str, Any] | None:
    fact = session.get(RecipeImprovementFact, recipe.id)
    if fact is None:
        return None
    chain = []
    for node in fact.source_path:
        current = session.get(Recipe, uuid.UUID(node["recipe_id"]))
        author = session.get(User, uuid.UUID(node["author_id"]))
        chain.append(
            {
                **node,
                "author": node["author"]
                if author and str(author.status) == "active"
                else "已注销用户",
                "withdrawn": current is None or bool(getattr(current, "withdrawn", False)),
            }
        )
    source = chain[-1]
    return {
        "source_recipe_id": str(fact.source_recipe_id),
        "source_version_id": str(fact.source_version_id),
        "root_recipe_id": str(fact.root_recipe_id),
        "branch_type": fact.branch_type,
        "conclusion": fact.conclusion,
        "rules_version": fact.rules_version,
        "chain": chain,
        "label": f"改良自 @{source['author']}《{source['title']}》第 {source['version_number']} 版"
        + ("（已下架）" if source["withdrawn"] else ""),
    }
