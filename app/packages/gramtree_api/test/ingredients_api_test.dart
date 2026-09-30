import 'package:test/test.dart';
import 'package:gramtree_api/gramtree_api.dart';


/// tests for IngredientsApi
void main() {
  final instance = GramtreeApi().getIngredientsApi();

  group(IngredientsApi, () {
    // Get Ingredient
    //
    // 读取一种食材的完整数据。如果这个 ID 已经合并到另一个,自动返回合并后的食材。  没经人工校对的属性带 `estimate: true`，计算和显示时按估算处理。
    //
    //Future<IngredientDetail> getIngredient(String ingredientId) async
    test('test getIngredient', () async {
      // TODO
    });

    // Normalize Ingredients
    //
    // 把一批食材名称归一到标准 ID（只用规则匹配），结果按输入顺序返回。
    //
    //Future<NormalizeResponse> normalizeIngredients(NormalizeRequest normalizeRequest) async
    test('test normalizeIngredients', () async {
      // TODO
    });

    // Search Ingredients
    //
    // 搜索食材。支持标准名、别名、拼音首字母、完整拼音前缀匹配。最多返回 20 个结果。
    //
    //Future<SearchResult> searchIngredients(SearchQuery searchQuery) async
    test('test searchIngredients', () async {
      // TODO
    });

  });
}
