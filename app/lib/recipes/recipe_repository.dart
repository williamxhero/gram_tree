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
  }) async {
    final response = await _recipes.saveRecipeVersion(
      recipeId: recipeId,
      recipeVersionCreate: RecipeVersionCreate(
        baseVersionId: baseVersionId,
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
    this.optional = false,
    this.functional = false,
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
        scalingMode: value.scalingMode,
        optional: value.optional == true,
        functional: value.functional == true,
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
      optional: value['optional'] == true,
      functional: value['functional'] == true,
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

  /// The author's explicit choice; `null` leaves it to the standard
  /// ingredient's library default (resolved by the server on save).
  RecipeIngredientScalingModeEnum? scalingMode;
  bool optional;
  bool functional;
  RecipeReplacementDraft? replacement;

  RecipeIngredient toModel() => RecipeIngredient(
    baseQuantity: baseQuantity,
    baseUnit: _baseUnit(baseUnit),
    displayName: displayName.trim(),
    functional: functional,
    group: _optionalText(group),
    id: id,
    ingredientId: ingredientId,
    optional: optional,
    preparation: _optionalText(preparation),
    quantity: quantity,
    quantitySource: _authorSource(quantity.toString()),
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
    'optional': optional,
    'functional': functional,
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

  RecipeStep toModel() => RecipeStep(
    action: _optionalText(action),
    cookware: _optionalText(cookware),
    dependsOn: [...dependsOn],
    doneness: _optionalText(doneness),
    durationSeconds: durationSeconds,
    durationSource: _authorSource(durationSeconds.toString()),
    heat: _optionalText(heat),
    heatSource: _optionalText(heat) == null ? null : _authorSource(heat),
    id: id,
    ingredientIds: [...ingredientIds],
    instruction: instruction.trim(),
    notes: _optionalText(notes),
    temperatureCelsius: temperatureCelsius == 0 ? null : temperatureCelsius,
    temperatureSource: temperatureCelsius == 0
        ? null
        : _authorSource(temperatureCelsius.toString()),
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
    this.baseMold,
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
  MoldSpec? baseMold;
  List<RecipeIngredientDraft> ingredients;
  List<RecipeStepDraft> steps;
  List<String> imageIds;

  RecipeSnapshot get snapshot => RecipeSnapshot(
    activeTimeSeconds: activeTimeSeconds,
    baseMold: baseMold,
    difficulty: difficulty,
    dishType: dishType,
    formatVersion: RecipeSnapshotFormatVersionEnum.number1,
    ingredients: [for (final item in ingredients) item.toModel()],
    servings: servings,
    steps: [for (final item in steps) item.toModel()],
    tags: [...tags],
    totalTimeSeconds: totalTimeSeconds,
  );

  Map<String, dynamic> toDraft() => {
    'dish_name': dishName,
    'aliases': [...aliases],
    'change_note': changeNote,
    'image_ids': [...imageIds],
    'snapshot': snapshot.toJson(),
  };
}

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
