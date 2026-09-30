import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../api/api_client.dart';

/// Thin adapter around the generated client. UI code deals in recipe actions,
/// not Dio paths or generated request plumbing.
class RecipeRepository {
  RecipeRepository(this._api);

  final GramtreeApi _api;

  RecipesApi get _recipes => _api.getRecipesApi();

  Future<RecipeList> list({String? cursor}) async {
    final response = await _recipes.listRecipes(cursor: cursor);
    return response.data ?? RecipeList(items: const []);
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

  Future<RecipeDetail> create(RecipeForm form) async {
    final response = await _recipes.createRecipe(
      recipeCreate: RecipeCreate(
        dish: DishInput(name: form.dishName, aliases: form.aliases),
        dishName: form.dishName,
        dishAliases: form.aliases,
        snapshot: form.snapshot,
        changeNote: form.changeNote,
      ),
    );
    return response.data!;
  }

  Future<RecipeDetail> saveVersion(String recipeId, RecipeForm form) async {
    final response = await _recipes.saveRecipeVersion(
      recipeId: recipeId,
      recipeVersionCreate: RecipeVersionCreate(
        snapshot: form.snapshot,
        changeNote: form.changeNote,
      ),
    );
    return response.data!;
  }

  Future<RecipeVersionHistory> history(String recipeId) async {
    final response = await _recipes.listRecipeVersions(recipeId: recipeId);
    return response.data ?? RecipeVersionHistory(items: const []);
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

/// Editable fields kept intentionally small for the first authoring surface.
/// The wire snapshot still contains the complete structured contract.
class RecipeForm {
  RecipeForm({
    required this.dishName,
    this.aliases = const [],
    this.servings = 2,
    this.difficulty = '',
    this.dishType = '',
    this.changeNote = '',
    this.ingredientName = '',
    this.ingredientQuantity = 0,
    this.ingredientUnit = 'g',
    this.preparation = '',
    this.ingredientGroup = '主料',
    this.stepInstruction = '',
    this.stepDurationSeconds = 0,
    this.stepAction = '炒',
    this.stepWhy = '',
    this.ingredientId,
    this.extraIngredients = const [],
    this.extraSteps = const [],
  });

  String dishName;
  List<String> aliases;
  int servings;
  String difficulty;
  String dishType;
  String changeNote;
  String ingredientName;
  double ingredientQuantity;
  String ingredientUnit;
  String preparation;
  String ingredientGroup;
  String stepInstruction;
  int stepDurationSeconds;
  String stepAction;
  String stepWhy;
  String? ingredientId;
  List<RecipeIngredient> extraIngredients;
  List<RecipeStep> extraSteps;

  RecipeSnapshot get snapshot => RecipeSnapshot(
    formatVersion: RecipeSnapshotFormatVersionEnum.number1,
    servings: servings,
    difficulty: difficulty,
    dishType: dishType,
    ingredients: [
      RecipeIngredient(
        baseQuantity: ingredientUnit == 'g' ? ingredientQuantity : 0,
        baseUnit: ingredientUnit == 'ml'
            ? RecipeIngredientBaseUnitEnum.ml
            : RecipeIngredientBaseUnitEnum.g,
        displayName: ingredientName.isEmpty ? '未收录食材' : ingredientName,
        group: ingredientGroup,
        id: 'ingredient-1',
        ingredientId: ingredientId ?? '',
        preparation: preparation,
        quantity: ingredientQuantity,
        scalingMode: RecipeIngredientScalingModeEnum.proportional,
        unit: ingredientUnit,
      ),
      ...extraIngredients,
    ],
    steps: [
      RecipeStep(
        action: stepAction,
        cookware: '',
        dependsOn: const [],
        doneness: '',
        durationSeconds: stepDurationSeconds,
        heat: '',
        id: 'step-1',
        ingredientIds: const ['ingredient-1'],
        instruction: stepInstruction.isEmpty ? '完成这一步' : stepInstruction,
        notes: '',
        temperatureCelsius: 0,
        unattended: false,
        why: stepWhy,
      ),
      ...extraSteps,
    ],
  );

  Map<String, dynamic> toDraft() => {
    'dish_name': dishName,
    'aliases': aliases,
    'servings': servings,
    'difficulty': difficulty,
    'dish_type': dishType,
    'change_note': changeNote,
    'ingredient_name': ingredientName,
    'ingredient_quantity': ingredientQuantity,
    'ingredient_unit': ingredientUnit,
    'preparation': preparation,
    'ingredient_group': ingredientGroup,
    'ingredient_id': ingredientId,
    'step_instruction': stepInstruction,
    'step_duration_seconds': stepDurationSeconds,
    'step_action': stepAction,
    'step_why': stepWhy,
    'extra_ingredients': extraIngredients.map((item) => item.toJson()).toList(),
    'extra_steps': extraSteps.map((item) => item.toJson()).toList(),
  };

  static RecipeForm fromDraft(Map<String, dynamic> value) => RecipeForm(
    dishName: value['dish_name'] as String? ?? '',
    aliases:
        (value['aliases'] as List?)?.whereType<String>().toList() ?? const [],
    servings: (value['servings'] as num?)?.toInt() ?? 2,
    difficulty: value['difficulty'] as String? ?? '',
    dishType: value['dish_type'] as String? ?? '',
    changeNote: value['change_note'] as String? ?? '',
    ingredientName: value['ingredient_name'] as String? ?? '',
    ingredientQuantity: (value['ingredient_quantity'] as num?)?.toDouble() ?? 0,
    ingredientUnit: value['ingredient_unit'] as String? ?? 'g',
    preparation: value['preparation'] as String? ?? '',
    ingredientGroup: value['ingredient_group'] as String? ?? '主料',
    stepInstruction: value['step_instruction'] as String? ?? '',
    stepDurationSeconds: (value['step_duration_seconds'] as num?)?.toInt() ?? 0,
    stepAction: value['step_action'] as String? ?? '炒',
    stepWhy: value['step_why'] as String? ?? '',
  );
}
