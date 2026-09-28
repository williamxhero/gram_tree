import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/ui_protocol/embedded_assets.g.dart';
import 'package:gram_tree/ui_protocol/protocol_paths.dart';
import 'package:gram_tree/ui_protocol/protocol_schemas.dart';

/// SPEC-009.1 #77：App 端渲染前的 Schema 校验，和服务端读同一份
/// contracts/ui_protocol/ 契约（server/tests/test_ui_protocol.py 是服务端那一半）。
///
/// 样例用 [embeddedUiProtocolSamples]（内嵌常量）而不是 rootBundle 直接读——实测
/// rootBundle.loadString() 读这份资产在 `flutter test --platform chrome` 下同一个
/// 测试文件里第二次调用会超时不返回，原因见
/// docs/adr/0005-界面描述协议共享契约.md。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProtocolSchemas schemas;

  setUp(() {
    schemas = ProtocolSchemas();
  });

  Map<String, dynamic> loadSample(String category, String name) {
    final text = embeddedUiProtocolSamples[sampleAsset(category, name)];
    if (text == null) {
      fail('样例未内嵌，运行 tool/gen_ui_protocol_schemas.sh 重新生成：$category/$name');
    }
    return jsonDecode(text) as Map<String, dynamic>;
  }

  test('两端共用的合法样例通过协议信封和每个组件的 Schema 校验', () async {
    final sample = loadSample('valid', 'today_default.json');

    final envelopeIssues = await schemas.validatePageDescription('1.0', sample);
    expect(envelopeIssues, isEmpty);

    for (final raw in sample['components'] as List) {
      final component = raw as Map<String, dynamic>;
      final issues = await schemas.validateComponentData(
        '1.0',
        component['type'] as String,
        component['data'] as Map<String, dynamic>,
      );
      expect(issues, isEmpty, reason: component['type'] as String);
    }
  });

  test('信封缺字段时校验不通过', () async {
    final issues = await schemas.validatePageDescription('1.0', {
      'protocol': '1.0',
      'page_type': 'today',
      // 缺 composition_id / generated_at / cache / components
    });
    expect(issues, isNotEmpty);
  });

  test('信封多出 App 不认识的新字段时照常校验通过（小版本兼容，SPEC-009.1 #79）', () async {
    final valid = loadSample('valid', 'today_default.json');
    final withExtra = {...valid, 'protocol': '1.7', 'unexpected_field': 'x'};
    final issues = await schemas.validatePageDescription('1.7', withExtra);
    expect(issues, isEmpty);
  });

  test('大版本相同、小版本更高时照常按同一份 Schema 校验（协议 1.7 -> 目录 1.0）', () async {
    expect(schemas.resolveMajorDir('1.7'), '1.0');
    expect(schemas.resolveMajorDir('1.0'), '1.0');
  });

  test('不认识的大版本没有对应的内嵌 Schema 目录', () async {
    expect(schemas.resolveMajorDir('9.9'), isNull);
    expect(schemas.resolveMajorDir('not-a-version'), isNull);
    final issues = await schemas.validatePageDescription(
      '9.9',
      loadSample('valid', 'today_default.json'),
    );
    expect(issues, isNotEmpty);
  });

  test('hint_bar 缺 conclusion 时校验不通过', () async {
    final issues = await schemas.validateComponentData('1.0', 'hint_bar', {});
    expect(issues, isNotEmpty);
  });

  test('未登记的组件类型没有对应 Schema，视为不合法', () async {
    final issues = await schemas.validateComponentData(
      '1.0',
      'no_such_component',
      {'anything': 1},
    );
    expect(issues, isNotEmpty);
  });
}
