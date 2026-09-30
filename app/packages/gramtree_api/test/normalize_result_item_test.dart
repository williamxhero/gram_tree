import 'package:test/test.dart';
import 'package:gramtree_api/gramtree_api.dart';

// tests for NormalizeResultItem
void main() {
  final instance = NormalizeResultItemBuilder();
  // TODO add properties to the builder and call build()

  group(NormalizeResultItem, () {
    // 原样返回输入的名称
    // String name
    test('to test the property `name`', () async {
      // TODO
    });

    // exact 标准名精确匹配；alias 别名匹配（含已合并食材的旧名）；fuzzy 去掉修饰词或按拼音后唯一命中；ambiguous 歧义名，见 candidates；unrecorded 未收录
    // String confidence
    test('to test the property `confidence`', () async {
      // TODO
    });

    // String ingredientId
    test('to test the property `ingredientId`', () async {
      // TODO
    });

    // String standardName
    test('to test the property `standardName`', () async {
      // TODO
    });

    // 只有 ambiguous 时非空
    // BuiltList<NormalizeCandidate> candidates
    test('to test the property `candidates`', () async {
      // TODO
    });

  });
}
