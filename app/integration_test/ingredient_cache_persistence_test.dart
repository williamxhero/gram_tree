import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'ingredient_cache_persistence_check_stub.dart'
    if (dart.library.io) 'ingredient_cache_persistence_check_mobile.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('食材缓存的手机数据库在重开连接后仍可读', (tester) async {
    await checkIngredientCacheSurvivesRestart();
  });
}
