import '../features/me/taste_profile_page.dart';
import '../features/recipes/recipe_pages.dart';
import '../features/tab_paths.dart';

/// "打开页面"意图（`open_page`）能打开的页面：`params.page` 的取值 -> go_router 的
/// 路径。只有登记在这里的名字能被打开，其余一律拒绝——包括任意网址、没打算给
/// App 内跳转用的字符串（SPEC-009.1 #81）。
///
/// 这是"App 已登记的页面"这件事唯一的来源，`intent_registry.dart` 的 `open_page`
/// 意图校验参数格式、`composition_provider.dart` 判定"非法动作"、真正执行跳转的
/// 处理器都读这张表，不各写一份。
///
/// 新增一个可以被 `open_page` 打开的页面：在这里加一项，value 通常就是
/// `TabPaths` 里的某个值；这张票只登记"今天"页用到的 `create`。
const Map<String, String> registeredPages = {
  'create': TabPaths.create,
  'my_recipes': RecipeListPage.path,
  'taste_profile': TasteProfilePage.path,
};
