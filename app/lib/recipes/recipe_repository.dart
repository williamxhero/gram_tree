import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../api/api_client.dart';

/// Thin adapter around the generated client. UI code deals in recipe actions,
/// not Dio paths or generated request plumbing.
class RecipeRepository {
  RecipeRepository(this._api);

  final GramtreeApi _api;

  RecipesApi get _recipes => _api.getRecipesApi();
  RecipeAiApi get _ai => _api.getRecipeAiApi();

  Future<AIStatus> aiStatus() async => (await _ai.recipeAiStatus()).data!;

  Future<RetrievalResult> findForRequest(String text) async =>
      (await _ai.findRecipeForRequest(oneLineInput: OneLineInput(text: text)))
          .data!;

  Future<RecipeDetail> chooseExisting(
    String requestId,
    String recipeId,
  ) async => (await _ai.chooseExistingRecipe(
    requestId: requestId,
    existingChoice: ExistingChoice(recipeId: recipeId),
  )).data!;

  Future<GenerationResult> generate(
    String requestId,
    GenerateInput answers,
  ) async => (await _ai.generateRecipeDraft(
    requestId: requestId,
    generateInput: answers,
  )).data!;

  Future<RecipeDetail> saveGenerated(String requestId, RecipeForm form) async =>
      (await _ai.saveGeneratedRecipe(
        requestId: requestId,
        recipeCreate: RecipeCreate(
          dishName: form.dishName,
          dishAliases: form.aliases,
          snapshot: form.snapshot,
          changeNote: form.changeNote,
          imageIds: form.imageIds,
          aiAssisted: true,
        ),
      )).data!;

  Future<RecipeList> listPage({String? cursor}) async {
    final response = await _recipes.listRecipes(cursor: cursor);
    return response.data ?? RecipeList(items: const []);
  }

  Future<RecipeList> list({String? cursor}) async {
    final items = <RecipeListItem>[];
    var next = cursor;
    do {
      final page = await listPage(cursor: next);
      items.addAll(page.items);
      next = page.nextCursor;
    } while (next != null);
    return RecipeList(items: items);
  }

  Future<RecipeDetail> get(String recipeId) async {
    final response = await _recipes.getRecipe(recipeId: recipeId);
    return response.data!;
  }

  Future<RecipeDetail> getVersion(String recipeId, String versionId) async {
    final response = await _recipes.getRecipeVersion(
      recipeId: recipeId,
      versionId: versionId,
    );
    return response.data!;
  }

  Future<RecipeIngredientComparison> compareIngredients(
    String recipeId,
    String fromVersionId,
    String toVersionId,
  ) async => (await _recipes.compareRecipeIngredients(
    recipeId: recipeId,
    fromVersionId: fromVersionId,
    toVersionId: toVersionId,
  )).data!;

  Future<RecipeFullComparison> compareFull(
    String recipeId,
    String fromVersionId,
    String toVersionId,
  ) async => (await _recipes.compareRecipeFull(
    recipeId: recipeId,
    fromVersionId: fromVersionId,
    toVersionId: toVersionId,
  )).data!;

  Future<RecipeComparisonAssistance> compareAssistance(
    String recipeId,
    String fromVersionId,
    String toVersionId,
  ) async => (await _recipes.compareRecipeAssistance(
    recipeId: recipeId,
    fromVersionId: fromVersionId,
    toVersionId: toVersionId,
  )).data!;

  Future<RecipeComparisonCandidates> comparisonCandidatesPage(
    String recipeId, {
    String? cursor,
  }) async => (await _recipes.listRecipeComparisonCandidates(
    recipeId: recipeId,
    cursor: cursor,
  )).data!;

  /// Fetch a server conversion when the caller needs a shareable/public result.
  /// Recipe details use the same pure kernel locally so this is not required for
  /// the offline serving control.
  Future<RecipeServingConversionOut> convertServings(
    String recipeId,
    int targetServings, {
    String? versionId,
  }) async {
    final response = versionId == null
        ? await _recipes.convertCurrentRecipeServings(
            recipeId: recipeId,
            targetServings: targetServings,
          )
        : await _recipes.convertRecipeVersionServings(
            recipeId: recipeId,
            versionId: versionId,
            targetServings: targetServings,
          );
    return response.data!;
  }

  Future<RecipeBatchAdviceOut> batchAdvice(
    String recipeId,
    String versionId,
    int targetServings,
  ) async => (await _recipes.requestRecipeBatchAdvice(
    recipeId: recipeId,
    versionId: versionId,
    batchAdviceInput: BatchAdviceInput(targetServings: targetServings),
  )).data!;

  Future<RecipeMoldConversionOut> convertMold(
    String recipeId,
    MoldSpec targetMold, {
    String? versionId,
  }) async {
    final request = RecipeMoldConversionRequest(targetMold: targetMold);
    final response = versionId == null
        ? await _recipes.convertCurrentRecipeMold(
            recipeId: recipeId,
            recipeMoldConversionRequest: request,
          )
        : await _recipes.convertRecipeVersionMold(
            recipeId: recipeId,
            versionId: versionId,
            recipeMoldConversionRequest: request,
          );
    return response.data!;
  }

  /// Fetch the server-owned display contract for a recipe version.
  /// Detail pages may use their matching local kernel while offline; this
  /// method is the shareable HTTP seam with immutable source provenance.
  Future<RecipeIngredientDisplayOut> displayIngredients(
    String recipeId, {
    required String mode,
    String? measureId,
    int? targetServings,
    MoldSpec? targetMold,
    String? versionId,
  }) async {
    final targetMoldJson = targetMold == null
        ? null
        : jsonEncode(targetMold.toJson());
    final response = versionId == null
        ? await _recipes.displayCurrentRecipeIngredients(
            recipeId: recipeId,
            mode: mode,
            measureId: measureId,
            targetServings: targetServings,
            targetMold: targetMoldJson,
          )
        : await _recipes.displayRecipeVersionIngredients(
            recipeId: recipeId,
            versionId: versionId,
            mode: mode,
            measureId: measureId,
            targetServings: targetServings,
            targetMold: targetMoldJson,
          );
    return response.data!;
  }

  /// Check the current mutable snapshot without creating a version.
  ///
  /// The server owns all rule thresholds; the client only presents the
  /// returned result. This is deliberately a separate call from save so an
  /// author can correct a finding before committing a new immutable version.
  Future<RecipeSafetyResult> checkSafety(
    RecipeForm form, {
    String? recipeId,
    String? baseVersionId,
  }) async {
    final response = await _recipes.checkRecipeSafety(
      recipeSafetyCheckRequest: RecipeSafetyCheckRequest(
        recipeId: recipeId,
        baseVersionId: baseVersionId,
        dishName: form.dishName,
        dishAliases: [...form.aliases],
        changeNote: form.changeNote,
        description: form.description,
        snapshot: form.snapshot,
      ),
    );
    return response.data!.result;
  }

  Future<RecipeReproducibilityResult> checkReproducibility(
    RecipeForm form,
  ) async {
    final response = await _recipes.checkRecipeReproducibility(
      recipeReproducibilityCheckRequest: RecipeReproducibilityCheckRequest(
        snapshot: form.snapshot,
      ),
    );
    return response.data!.result;
  }

  Future<RecipeQuantificationOut> quantify(
    String recipeId,
    String baseVersionId,
  ) async => (await _recipes.quantifyRecipe(
    recipeId: recipeId,
    quantificationInput: QuantificationInput(baseVersionId: baseVersionId),
  )).data!;

  Future<RecipeDetail> decideQuantification(
    String recipeId,
    String proposalId, {
    List<QuantificationDecision> decisions = const [],
    bool acceptAll = false,
  }) async => (await _recipes.decideRecipeQuantification(
    recipeId: recipeId,
    proposalId: proposalId,
    quantificationDecisionsInput: QuantificationDecisionsInput(
      decisions: decisions,
      acceptAll: acceptAll,
    ),
  )).data!;

  Future<RecipeDetail> create(RecipeForm form) async {
    final response = await _recipes.createRecipe(
      recipeCreate: RecipeCreate(
        dish: DishInput(name: form.dishName, aliases: form.aliases),
        dishName: form.dishName,
        dishAliases: form.aliases,
        snapshot: form.snapshot,
        changeNote: form.changeNote,
        imageIds: form.imageIds,
      ),
    );
    return response.data!;
  }

  /// Save a new immutable version from [baseVersionId].
  Future<RecipeDetail> saveVersion(
    String recipeId,
    RecipeForm form, {
    String? baseVersionId,
    String? expectedCurrentVersionId,
  }) async {
    final response = await _recipes.saveRecipeVersion(
      recipeId: recipeId,
      recipeVersionCreate: RecipeVersionCreate(
        baseVersionId: baseVersionId,
        expectedCurrentVersionId: expectedCurrentVersionId,
        aiAssisted: form.aiAssisted,
        snapshot: form.snapshot,
        changeNote: form.changeNote,
        imageIds: form.imageIds,
      ),
    );
    return response.data!;
  }

  Future<RecipeVersionHistory> historyPage(
    String recipeId, {
    String? cursor,
  }) async {
    final response = await _recipes.listRecipeVersions(
      recipeId: recipeId,
      cursor: cursor,
    );
    return response.data ?? RecipeVersionHistory(items: const []);
  }

  Future<RecipeVersionHistory> history(String recipeId) async {
    final items = <RecipeVersionSummary>[];
    String? cursor;
    do {
      final page = await historyPage(recipeId, cursor: cursor);
      items.addAll(page.items);
      cursor = page.nextCursor;
    } while (cursor != null);
    return RecipeVersionHistory(items: items);
  }

  Future<void> delete(String recipeId) async {
    await _recipes.deleteRecipe(recipeId: recipeId);
  }

  Future<RecipeImageOut> uploadImage(
    String recipeId, {
    required String base64,
    required String contentType,
    String? filename,
  }) async {
    final response = await _recipes.uploadRecipeImage(
      recipeId: recipeId,
      recipeImageUpload: RecipeImageUpload(
        contentBase64: base64,
        contentType: contentType,
        filename: filename,
      ),
    );
    return response.data!;
  }
}

final recipeRepositoryProvider = Provider<RecipeRepository>(
  (ref) => RecipeRepository(ref.watch(apiClientProvider)),
);

/// A mutable, serializable ingredient row used by the editor. It intentionally
/// keeps both the author-entered quantity and the server-facing base quantity;
/// the client never derives conversions from units.
class RecipeIngredientDraft {
  RecipeIngredientDraft({
    required this.id,
    this.ingredientId,
    this.displayName = '',
    this.quantity = 0,
    this.unit = 'g',
    this.baseQuantity = 0,
    this.baseUnit = 'g',
    this.preparation = '',
    this.group = '',
    this.scalingMode,
    this.quantitySource,
    this.measureInputToken,
    this.preparationSource,
    this.optional = false,
    this.functional = false,
    this.flavorContribution,
    this.flavorSource,
    this.functionalSource,
    this.replacement,
  });

  factory RecipeIngredientDraft.fromModel(RecipeIngredient value) =>
      RecipeIngredientDraft(
        id: value.id,
        ingredientId: value.ingredientId?.isEmpty == true
            ? null
            : value.ingredientId,
        displayName: value.displayName,
        quantity: value.quantity.toDouble(),
        unit: value.unit,
        baseQuantity: value.baseQuantity?.toDouble() ?? 0,
        baseUnit: value.baseUnit?.value ?? 'g',
        preparation: value.preparation ?? '',
        group: value.group ?? '',
        scalingMode:
            value.scalingMode ?? RecipeIngredientScalingModeEnum.proportional,
        quantitySource: value.quantitySource,
        measureInputToken: value.measureInputToken,
        preparationSource: value.preparationSource,
        optional: value.optional == true,
        functional: value.functional == true,
        flavorContribution: value.flavorContribution,
        flavorSource: value.flavorSource,
        functionalSource: value.functionalSource,
        replacement: value.replacement is String
            ? RecipeReplacementDraft(
                ingredientId: null,
                displayName: value.replacement as String,
              )
            : value.replacement is Map
            ? RecipeReplacementDraft.fromJson(
                Map<String, dynamic>.from(value.replacement as Map),
              )
            : null,
      );

  factory RecipeIngredientDraft.fromJson(Map<String, dynamic> value) {
    final replacement = value['replacement'];
    return RecipeIngredientDraft(
      id: _string(value['id']) ?? 'ingredient-${_nextId()}',
      ingredientId: _nonEmpty(value['ingredient_id']),
      displayName: _string(value['display_name']) ?? '',
      quantity: _number(value['quantity']),
      unit: _string(value['unit']) ?? 'g',
      baseQuantity: _number(value['base_quantity']),
      baseUnit: _string(value['base_unit']) ?? 'g',
      preparation: _string(value['preparation']) ?? '',
      group: _string(value['group']) ?? '',
      scalingMode: _scalingMode(value['scaling_mode']),
      quantitySource: _valueSource(value['quantity_source']),
      measureInputToken: _nonEmpty(value['measure_input_token']),
      preparationSource: _valueSource(value['preparation_source']),
      optional: value['optional'] == true,
      functional: value['functional'] == true,
      flavorContribution: value['flavor_contribution'] is Map
          ? RecipeFlavorContribution.fromJson(
              Map<String, dynamic>.from(value['flavor_contribution'] as Map),
            )
          : null,
      flavorSource: _valueSource(value['flavor_source']),
      functionalSource: _valueSource(value['functional_source']),
      replacement: replacement is String
          ? RecipeReplacementDraft(ingredientId: null, displayName: replacement)
          : replacement is Map
          ? RecipeReplacementDraft.fromJson(
              Map<String, dynamic>.from(replacement),
            )
          : null,
    );
  }

  String id;
  String? ingredientId;
  String displayName;
  double quantity;
  String unit;
  double baseQuantity;
  String baseUnit;
  String preparation;
  String group;

  /// New editor rows may leave this null for server-side default resolution;
  /// loaded legacy snapshots materialize proportional before editing so their
  /// historical behavior cannot drift with later library updates.
  RecipeIngredientScalingModeEnum? scalingMode;
  ValueSource? quantitySource;
  String? measureInputToken;
  ValueSource? preparationSource;
  bool optional;
  bool functional;
  RecipeFlavorContribution? flavorContribution;
  ValueSource? flavorSource;
  ValueSource? functionalSource;
  RecipeReplacementDraft? replacement;

  void adoptIngredientDefaults(IngredientDetail ingredient) {
    final flavor = ingredient.attributes.flavor;
    flavorContribution = flavor == null
        ? null
        : RecipeFlavorContribution.fromJson(flavor.value.toJson());
    flavorSource = flavor == null
        ? null
        : _librarySource(flavor.estimate, ingredient.version, flavor.source_);
    final functionalDefault = ingredient.attributes.functional;
    functional = functionalDefault?.value ?? false;
    functionalSource = functionalDefault == null
        ? null
        : _librarySource(
            functionalDefault.estimate,
            ingredient.version,
            functionalDefault.source_,
          );
  }

  void setFlavor(String axis, int? strength) {
    final values = flavorContribution?.toJson() ?? <String, dynamic>{};
    values[axis] = strength;
    flavorContribution = values.values.every((value) => value == null)
        ? null
        : RecipeFlavorContribution.fromJson(values);
    flavorSource = flavorContribution == null
        ? null
        : ValueSource(
            source_: ValueSourceSource_Enum.authorFilled,
            basis: '作者按这道菜的实际作用填写；未填写不代表零贡献',
          );
  }

  RecipeIngredient toModel({bool writable = true}) => RecipeIngredient(
    baseQuantity: baseQuantity,
    baseUnit: _baseUnit(baseUnit),
    displayName: displayName.trim(),
    functional: functional,
    // dart-dio omits null properties. Send an empty, unknown profile so clearing
    // a contribution is explicit and cannot re-adopt a mutable library default.
    flavorContribution: flavorContribution ?? RecipeFlavorContribution(),
    flavorSource: flavorSource,
    functionalSource: functionalSource,
    group: _optionalText(group),
    id: id,
    ingredientId: ingredientId,
    optional: optional,
    preparation: _optionalText(preparation),
    quantity: quantity,
    quantitySource: writable
        ? _writableSource(quantitySource ?? _authorSource(quantity.toString()))
        : quantitySource,
    measureInputToken: measureInputToken,
    preparationSource: writable
        ? _writableSource(preparationSource)
        : preparationSource,
    replacement: replacement?.toModel(),
    scalingMode: scalingMode,
    unit: unit.trim().isEmpty ? 'g' : unit.trim(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'ingredient_id': ingredientId,
    'display_name': displayName,
    'quantity': quantity,
    'unit': unit,
    'base_quantity': baseQuantity,
    'base_unit': baseUnit,
    'preparation': preparation,
    'group': group,
    'scaling_mode': scalingMode?.value,
    'quantity_source': quantitySource?.toJson(),
    'measure_input_token': measureInputToken,
    'preparation_source': preparationSource?.toJson(),
    'optional': optional,
    'functional': functional,
    'flavor_contribution': flavorContribution?.toJson(),
    'flavor_source': flavorSource?.toJson(),
    'functional_source': functionalSource?.toJson(),
    'replacement': replacement?.toJson(),
  };
}

class RecipeReplacementDraft {
  RecipeReplacementDraft({
    required this.ingredientId,
    required this.displayName,
    this.ratio = 1,
    this.note = '',
  });

  factory RecipeReplacementDraft.fromJson(Map<String, dynamic> value) =>
      RecipeReplacementDraft(
        ingredientId: _nonEmpty(value['ingredient_id']),
        displayName: _string(value['display_name']) ?? '',
        ratio: _number(value['ratio'], fallback: 1),
        note: _string(value['note']) ?? '',
      );

  String? ingredientId;
  String displayName;
  double ratio;
  String note;

  RecipeReplacement toModel() => RecipeReplacement(
    displayName: displayName.trim(),
    ingredientId: ingredientId,
    note: note.trim(),
    ratio: ratio,
  );

  Map<String, dynamic> toJson() => {
    'ingredient_id': ingredientId,
    'display_name': displayName,
    'ratio': ratio,
    'note': note,
  };
}

class RecipeStepDraft {
  RecipeStepDraft({
    required this.id,
    this.action = '',
    this.instruction = '',
    List<String>? ingredientIds,
    this.durationSeconds = 0,
    this.unattended = false,
    this.heat = '',
    this.temperatureCelsius = 0,
    this.cookware = '',
    this.doneness = '',
    List<String>? dependsOn,
    this.notes = '',
    this.why = '',
    this.instructionSource,
    this.donenessSource,
    this.durationSource,
    this.heatSource,
    this.temperatureSource,
  }) : ingredientIds = [...?ingredientIds],
       dependsOn = [...?dependsOn];

  factory RecipeStepDraft.fromModel(RecipeStep value) => RecipeStepDraft(
    id: value.id,
    action: value.action ?? '',
    instruction: value.instruction,
    ingredientIds: [...?value.ingredientIds],
    durationSeconds: value.durationSeconds ?? 0,
    unattended: value.unattended == true,
    heat: value.heat ?? '',
    temperatureCelsius: value.temperatureCelsius?.toDouble() ?? 0,
    cookware: value.cookware ?? '',
    doneness: value.doneness ?? '',
    dependsOn: [...?value.dependsOn],
    notes: value.notes ?? '',
    why: value.why ?? '',
    instructionSource: value.instructionSource,
    donenessSource: value.donenessSource,
    durationSource: value.durationSource,
    heatSource: value.heatSource,
    temperatureSource: value.temperatureSource,
  );

  factory RecipeStepDraft.fromJson(Map<String, dynamic> value) =>
      RecipeStepDraft(
        id: _string(value['id']) ?? 'step-${_nextId()}',
        action: _string(value['action']) ?? '',
        instruction: _string(value['instruction']) ?? '',
        ingredientIds: _strings(value['ingredient_ids']),
        durationSeconds: _number(value['duration_seconds']).toInt(),
        unattended: value['unattended'] == true,
        heat: _string(value['heat']) ?? '',
        temperatureCelsius: _number(value['temperature_celsius']),
        cookware: _string(value['cookware']) ?? '',
        doneness: _string(value['doneness']) ?? '',
        dependsOn: _strings(value['depends_on']),
        notes: _string(value['notes']) ?? '',
        why: _string(value['why']) ?? '',
        instructionSource: _valueSource(value['instruction_source']),
        donenessSource: _valueSource(value['doneness_source']),
        durationSource: _valueSource(value['duration_source']),
        heatSource: _valueSource(value['heat_source']),
        temperatureSource: _valueSource(value['temperature_source']),
      );

  String id;
  String action;
  String instruction;
  List<String> ingredientIds;
  int durationSeconds;
  bool unattended;
  String heat;
  double temperatureCelsius;
  String cookware;
  String doneness;
  List<String> dependsOn;
  String notes;
  String why;
  ValueSource? instructionSource;
  ValueSource? donenessSource;
  ValueSource? durationSource;
  ValueSource? heatSource;
  ValueSource? temperatureSource;

  RecipeStep toModel({bool writable = true}) => RecipeStep(
    action: _optionalText(action),
    cookware: _optionalText(cookware),
    dependsOn: [...dependsOn],
    doneness: _optionalText(doneness),
    durationSeconds: durationSeconds,
    durationSource: writable ? _writableSource(durationSource) : durationSource,
    instructionSource: writable
        ? _writableSource(instructionSource)
        : instructionSource,
    donenessSource: writable ? _writableSource(donenessSource) : donenessSource,
    heat: _optionalText(heat),
    heatSource: writable ? _writableSource(heatSource) : heatSource,
    id: id,
    ingredientIds: [...ingredientIds],
    instruction: instruction.trim(),
    notes: _optionalText(notes),
    temperatureCelsius: temperatureCelsius == 0 ? null : temperatureCelsius,
    temperatureSource: writable
        ? _writableSource(temperatureSource)
        : temperatureSource,
    unattended: unattended,
    why: _optionalText(why),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'action': action,
    'instruction': instruction,
    'ingredient_ids': [...ingredientIds],
    'duration_seconds': durationSeconds,
    'unattended': unattended,
    'heat': heat,
    'temperature_celsius': temperatureCelsius,
    'cookware': cookware,
    'doneness': doneness,
    'depends_on': [...dependsOn],
    'notes': notes,
    'why': why,
    'instruction_source': instructionSource?.toJson(),
    'doneness_source': donenessSource?.toJson(),
    'duration_source': durationSource?.toJson(),
    'heat_source': heatSource?.toJson(),
    'temperature_source': temperatureSource?.toJson(),
  };
}

/// Complete editor state. Every field in the structured snapshot is represented
/// here so a draft is a full snapshot rather than a second, lossy form format.
class RecipeForm {
  RecipeForm({
    required this.dishName,
    this.aliases = const [],
    this.servings = 2,
    this.difficulty = '',
    this.dishType = '',
    this.tags = const [],
    this.totalTimeSeconds = 0,
    this.activeTimeSeconds = 0,
    this.changeNote = '',
    this.description = '',
    this.baseMold,
    this.cuisine,
    this.designRationale,
    this.textSource,
    this.servingsSource,
    this.aiAssisted = false,
    List<RecipeIngredientDraft>? ingredients,
    List<RecipeStepDraft>? steps,
    List<String>? imageIds,
  }) : ingredients = ingredients ?? [RecipeIngredientDraft(id: 'ingredient-1')],
       steps = steps ?? [RecipeStepDraft(id: 'step-1')],
       imageIds = imageIds ?? <String>[];

  factory RecipeForm.fromSnapshot(
    RecipeSnapshot snapshot,
    String name, {
    List<String>? aliases,
    List<String>? imageIds,
  }) => RecipeForm(
    dishName: name,
    aliases: [...?aliases],
    servings: snapshot.servings,
    baseMold: snapshot.baseMold,
    difficulty: snapshot.difficulty ?? '',
    dishType: snapshot.dishType ?? '',
    tags: [...?snapshot.tags],
    totalTimeSeconds: snapshot.totalTimeSeconds ?? 0,
    activeTimeSeconds: snapshot.activeTimeSeconds ?? 0,
    description: snapshot.description ?? '',
    cuisine: snapshot.cuisine,
    designRationale: snapshot.designRationale,
    textSource: snapshot.textSource,
    servingsSource: snapshot.servingsSource,
    ingredients: [
      for (final item in snapshot.ingredients ?? const [])
        RecipeIngredientDraft.fromModel(item),
    ],
    steps: [
      for (final item in snapshot.steps ?? const [])
        RecipeStepDraft.fromModel(item),
    ],
    imageIds: [...?imageIds],
  );

  static bool isDraftPayloadValid(Map<String, dynamic> value) {
    final snapshot = value['snapshot'];
    if (snapshot is! Map) return false;
    try {
      RecipeSnapshot.fromJson(Map<String, dynamic>.from(snapshot));
      return true;
    } catch (_) {
      return false;
    }
  }

  factory RecipeForm.fromDraft(Map<String, dynamic> value) {
    if (!isDraftPayloadValid(value)) return RecipeForm(dishName: '');
    final snapshot = value['snapshot'];
    if (snapshot is Map) {
      try {
        return RecipeForm.fromSnapshot(
            RecipeSnapshot.fromJson(Map<String, dynamic>.from(snapshot)),
            _string(value['dish_name']) ?? '',
          )
          ..aliases = _strings(value['aliases'])
          ..changeNote = _string(value['change_note']) ?? ''
          ..aiAssisted = value['ai_assisted'] == true
          ..imageIds = _strings(value['image_ids']);
      } catch (_) {
        // Fall through to the safe empty form below.
      }
    }
    return RecipeForm(dishName: _string(value['dish_name']) ?? '');
  }

  String dishName;
  List<String> aliases;
  int servings;
  String difficulty;
  String dishType;
  List<String> tags;
  int totalTimeSeconds;
  int activeTimeSeconds;
  String changeNote;
  String description;
  MoldSpec? baseMold;
  String? cuisine;
  String? designRationale;
  ValueSource? textSource;
  ValueSource? servingsSource;
  bool aiAssisted;
  List<RecipeIngredientDraft> ingredients;
  List<RecipeStepDraft> steps;
  List<String> imageIds;

  RecipeSnapshot get snapshot => _snapshot(writable: true);

  RecipeSnapshot _snapshot({required bool writable}) => RecipeSnapshot(
    activeTimeSeconds: activeTimeSeconds,
    baseMold: baseMold,
    description: _optionalText(description),
    cuisine: cuisine,
    designRationale: designRationale,
    textSource: writable ? _writableSource(textSource) : textSource,
    servingsSource: writable ? _writableSource(servingsSource) : servingsSource,
    difficulty: difficulty,
    dishType: dishType,
    formatVersion: RecipeSnapshotFormatVersionEnum.number1,
    ingredients: [
      for (final item in ingredients) item.toModel(writable: writable),
    ],
    servings: servings,
    steps: [for (final item in steps) item.toModel(writable: writable)],
    tags: [...tags],
    totalTimeSeconds: totalTimeSeconds,
  );

  Map<String, dynamic> toDraft() => {
    'dish_name': dishName,
    'ai_assisted': aiAssisted,
    'aliases': [...aliases],
    'change_note': changeNote,
    'image_ids': [...imageIds],
    'snapshot': _snapshot(writable: false).toJson(),
  };
}

ValueSource _librarySource(bool estimate, String version, String source) =>
    ValueSource(
      source_: estimate
          ? ValueSourceSource_Enum.aiEstimated
          : ValueSourceSource_Enum.authorFilled,
      basis:
          '采用食材库 $version 默认参考；$source；'
          '${estimate ? 'AI 起草、待核对' : '人工校对'}；不是做菜验证',
    );

// Verification belongs to the server. An unchanged baseline restores its
// source there; sending it back would be an unauthorized client write.
ValueSource? _writableSource(ValueSource? source) =>
    source?.source_ == ValueSourceSource_Enum.verified ? null : source;

ValueSource _authorSource(String original) => ValueSource(
  basis: '',
  confidence: 1,
  original: original,
  source_: ValueSourceSource_Enum.authorFilled,
);

RecipeIngredientBaseUnitEnum _baseUnit(String value) => switch (value) {
  'ml' => RecipeIngredientBaseUnitEnum.ml,
  'count' => RecipeIngredientBaseUnitEnum.count,
  _ => RecipeIngredientBaseUnitEnum.g,
};

RecipeIngredientScalingModeEnum? _scalingMode(Object? value) {
  final raw = value?.toString();
  return RecipeIngredientScalingModeEnum.values
      .where((item) => item.value == raw)
      .firstOrNull;
}

ValueSource? _valueSource(Object? value) {
  if (value is! Map) return null;
  final source = value['source'];
  final raw = source?.toString();
  final sourceType = ValueSourceSource_Enum.values
      .where((item) => item.value == raw)
      .firstOrNull;
  if (sourceType == null) return null;
  return ValueSource.fromJson(Map<String, dynamic>.from(value));
}

String? _optionalText(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String? _string(Object? value) => value is String ? value : null;
String? _nonEmpty(Object? value) {
  final result = _string(value);
  return result == null || result.isEmpty ? null : result;
}

double _number(Object? value, {double fallback = 0}) =>
    value is num ? value.toDouble() : fallback;

List<String> _strings(Object? value) =>
    value is List ? value.whereType<String>().toList() : <String>[];

int _nextId() => DateTime.now().microsecondsSinceEpoch;
