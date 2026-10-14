import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';
import '../../events/event_uploader.dart';
import '../../ui_protocol/components/component_scaffold.dart';
import '../../ui_protocol/intent_dispatcher.dart';
import '../../ui_protocol/recipe_operations.dart';
import '../../util/ids.dart';
import 'comparison_cards.dart';

String publicationLabel(String state) => switch (state) {
  'published' => '已公开',
  'pending_verification' => '已公开 · 待验证',
  'withdrawn' => '已下架',
  _ => '草稿 · 仅自己可见',
};

class PublicationStateLabel extends StatelessWidget {
  const PublicationStateLabel({super.key, required this.state});
  final String state;
  @override
  Widget build(BuildContext context) => Text(publicationLabel(state));
}

/// No client eligibility calculation: every missing condition comes from the
/// exact saved version on the server, including the cumulative cooked baseline.
class PublicationPanelCard extends ConsumerStatefulWidget {
  const PublicationPanelCard({
    super.key,
    required this.detail,
    required this.onChanged,
    required this.onCook,
  });
  final RecipeDetail detail;
  final VoidCallback onChanged;
  final VoidCallback onCook;
  @override
  ConsumerState<PublicationPanelCard> createState() =>
      _PublicationPanelCardState();
}

class _PublicationPanelCardState extends ConsumerState<PublicationPanelCard> {
  PublicationPanel? _panel;
  String? _error;
  bool _busy = false;
  final _compositionId = newUuidV4();
  late final String? _owner;
  bool get _sameOwner => ref.read(authProvider).value?.id == _owner;

  @override
  void initState() {
    super.initState();
    _owner = ref.read(authProvider).value?.id;
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final response = await ref
          .read(apiClientProvider)
          .getRecipesApi()
          .getRecipePublication(
            recipeId: widget.detail.id,
            versionId: widget.detail.version.id,
          );
      if (mounted && _sameOwner) {
        setState(() {
          _panel = response.data;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted && _sameOwner) setState(() => _error = '公开状态暂时无法读取，请联网重试。');
    }
  }

  Future<void> _risk() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('公开高风险菜谱前请确认'),
        content: const Text(
          '这道菜包含高风险食材或做法。请核对食品安全提示；公开后会接受更严格的审核。确认不代表安全风险已消除。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('暂不确认'),
          ),
          FilledButton(
            key: const ValueKey('publication-confirm-risk'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('我已了解风险'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || !_sameOwner) return;
    await _mutate(() async {
      await ref
          .read(apiClientProvider)
          .getRecipesApi()
          .confirmRecipePublicationRisk(
            recipeId: widget.detail.id,
            versionId: widget.detail.version.id,
          );
    });
  }

  Future<void> _mutate(Future<void> Function() action) async {
    if (_busy || !_sameOwner) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted && _sameOwner) {
        await _load();
        widget.onChanged();
      }
    } catch (_) {
      if (mounted && _sameOwner) setState(() => _error = '操作未确认，请联网重试。');
    } finally {
      if (mounted && _sameOwner) setState(() => _busy = false);
    }
  }

  Future<void> _lifecycle() async {
    final restore = _panel?.state.value == 'withdrawn';
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(restore ? '重新上架菜谱？' : '下架菜谱？'),
        content: Text(
          restore
              ? '仅恢复符合条件的公开版本，草稿仍仅自己可见。'
              : '别人将无法打开此菜谱；已有改良版来源署名和做菜记录仍保留。公开过的菜谱不能删除。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const ValueKey('publication-confirm-lifecycle'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(restore ? '重新上架' : '下架'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted || !_sameOwner) return;
    await _mutate(() async {
      final api = ref.read(apiClientProvider).getRecipesApi();
      if (restore) {
        await api.restoreRecipe(recipeId: widget.detail.id);
      } else {
        await api.withdrawRecipe(recipeId: widget.detail.id);
      }
    });
  }

  Future<void> _condition(PublicationCondition condition) async {
    switch (condition.action) {
      case 'confirm_risk':
      case 'risk_confirmation':
        await _risk();
      case 'cook':
      case 'start_cooking':
        widget.onCook();
      case 'review':
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('正在等待审核；审核通过后会自动更新公开状态。')),
          );
        }
      case 'verify_identity':
      case 'real_name':
        if (mounted) context.push('/me/identities');
      default:
        if (mounted) {
          context.push(
            '/recipes/${widget.detail.id}/edit?versionId=${widget.detail.version.id}',
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(authProvider).value?.id != _owner) {
      return const SizedBox.shrink();
    }
    final panel = _panel;
    return RecipeOperationScope(
      handlers: {
        'publication_refresh': (_) => _load(),
        'publication_risk': (_) => _risk(),
        'publication_lifecycle': (_) => _lifecycle(),
        'publication_condition': (params) async {
          final condition = panel?.missing
              ?.where((item) => item.code == params['condition'])
              .firstOrNull;
          if (condition != null) await _condition(condition);
        },
      },
      child: Builder(
        builder: (context) {
          Future<void> dispatch(String operation, [String? condition]) => ref
              .read(intentDispatcherProvider)
              .dispatch(
                context,
                compositionId: _compositionId,
                componentId: 'publication-panel',
                action: ActionDescriptor(
                  intent: 'recipe_operation',
                  params: {'operation': operation, 'condition': ?condition},
                ),
              );
          final label = publicationLabel(
            panel?.state.value ?? widget.detail.version.publicationState.value,
          );
          return ComponentCard(
            key: const ValueKey('publication-panel'),
            detail: ComponentDescriptorDetailEnum.standard,
            conclusion: Text(label),
            conclusionSemanticsText: label,
            basisText: panel?.baselineVersionId == null
                ? '公开条件由服务端检查，离线做完后需先同步。'
                : '和最近一次做过验证的版本比较：${comparisonConclusionLabel(panel!.cumulativeConclusion ?? "未判定")}；规则 ${panel.rulesVersion ?? ""}',
            standardExtra: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if ((panel?.state.value ??
                        widget.detail.version.publicationState.value) ==
                    'draft')
                  const Text(
                    '做过后会自动公开；还需满足以下公开条件。',
                    key: ValueKey('draft-auto-public'),
                  ),
                if (panel == null && _error == null)
                  const LinearProgressIndicator(),
                if (_error != null) Text(_error!, semanticsLabel: _error),
                for (final condition
                    in panel?.missing ?? <PublicationCondition>[])
                  TextButton(
                    key: ValueKey('publication-condition-${condition.code}'),
                    onPressed: _busy
                        ? null
                        : () =>
                              dispatch('publication_condition', condition.code),
                    child: Text(
                      '${condition.label}${condition.remainingCount == null ? "" : "（${condition.remainingCount} 处）"}',
                    ),
                  ),
                if (panel?.highRisk == true)
                  const Text('高风险菜谱 · 公开前请核对安全提示，并确认风险。'),
                if (panel?.everPublic == true)
                  OutlinedButton(
                    key: const ValueKey('publication-lifecycle'),
                    onPressed: _busy
                        ? null
                        : () => dispatch('publication_lifecycle'),
                    child: Text(
                      panel?.state.value == 'withdrawn' ? '重新上架' : '下架菜谱',
                    ),
                  ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => dispatch('publication_refresh'),
                  child: const Text('刷新公开状态'),
                ),
                TextField(
                  key: const ValueKey('publication-command'),
                  decoration: const InputDecoration(
                    labelText: '一句话操作',
                    hintText: '刷新公开状态 / 确认公开风险 / 下架菜谱 / 重新上架',
                  ),
                  onSubmitted: (text) {
                    final action = recipeCommand(text);
                    if (!_busy && action != null) {
                      unawaited(
                        ref
                            .read(intentDispatcherProvider)
                            .dispatch(
                              context,
                              compositionId: _compositionId,
                              componentId: 'publication-panel',
                              action: action,
                            ),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Server persists first-license acknowledgement per account. Rendering the
/// notice is not a consent gate and never prevents the automatic publication.
class PublicationNotices extends ConsumerStatefulWidget {
  const PublicationNotices({super.key});
  @override
  ConsumerState<PublicationNotices> createState() => _PublicationNoticesState();
}

class _PublicationNoticesState extends ConsumerState<PublicationNotices> {
  PublicationNotifications? _notices;
  String? _account;
  int _generation = 0;
  Future<void> _load(String account) async {
    final generation = ++_generation;
    try {
      final api = ref.read(apiClientProvider).getRecipesApi();
      final result = (await api.getPublicationNotifications()).data;
      if (!mounted ||
          generation != _generation ||
          ref.read(authProvider).value?.id != account ||
          result == null) {
        return;
      }
      setState(() => _notices = result);
      if ((result.items?.isEmpty ?? true) && result.licenseNotice == null) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted ||
            generation != _generation ||
            ref.read(authProvider).value?.id != account ||
            ModalRoute.of(context)?.isCurrent == false ||
            !TickerMode.valuesOf(context).enabled) {
          return;
        }
        try {
          await api.acknowledgePublicationNotifications(
            publicationNotificationAck: PublicationNotificationAck(
              notificationIds:
                  (result.items ?? const <PublicationNotificationOut>[])
                      .map((item) => item.id)
                      .toList(),
              licenseSeen: result.licenseNotice != null,
            ),
          );
        } catch (_) {
          /* Retain unacknowledged notices for the next open. */
        }
      });
    } catch (_) {
      /* A failed notice read cannot block records or recipes. */
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(authProvider).value?.id;
    ref.listen(confirmedCookingRecordRevisionProvider, (previous, next) {
      final current = ref.read(authProvider).value?.id;
      if (current != null && current == _account && next != previous) {
        unawaited(_load(current));
      }
    });
    if (account != _account) {
      _account = account;
      _notices = null;
      _generation++;
      if (account != null) unawaited(_load(account));
    }
    final notices = _notices;
    if (notices == null ||
        ((notices.items?.isEmpty ?? true) && notices.licenseNotice == null)) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final item
                in notices.items ?? const <PublicationNotificationOut>[])
              Text(
                item.message,
                key: ValueKey('publication-notice-${item.id}'),
              ),
            if (notices.licenseNotice != null)
              Text(
                notices.licenseNotice!,
                key: const ValueKey('publication-license-notice'),
              ),
            TextButton(
              onPressed: () => setState(() => _notices = null),
              child: const Text('知道了'),
            ),
          ],
        ),
      ),
    );
  }
}
