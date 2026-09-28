import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:json_schema/json_schema.dart';

import 'embedded_assets.g.dart';
import 'protocol_paths.dart';

/// 一条 Schema 校验错误：出错的字段路径（JSON Pointer 风格）和一句说明。
class ProtocolValidationIssue {
  const ProtocolValidationIssue(this.path, this.message);

  final String path;
  final String message;

  @override
  String toString() => '${path.isEmpty ? '# (root)' : path}: $message';
}

/// 校验页面描述和组件数据是否符合 `contracts/ui_protocol/` 里的 JSON Schema
/// （协议信封一次、每个组件的 data 一次）。
///
/// Schema 内容来自编译期生成的 [embeddedUiProtocolSchemas]（见
/// tool/gen_ui_protocol_schemas.sh），不在运行时用 rootBundle 读文件——实测
/// rootBundle.loadString() 在应用生命周期内第二次加载这份资产时会永远卡住不返回
/// （只在 flutter test 里稳定复现），内嵌成常量彻底绕开这个问题，具体见
/// docs/adr/0005-界面描述协议共享契约.md。
class ProtocolSchemas {
  final Map<String, JsonSchema> _cache = {};

  /// 调用前必须先确认 [assetPath] 在 [embeddedUiProtocolSchemas] 里（见
  /// [_requireSchema]），这里不再重复判断缺失的情况。
  JsonSchema _load(String assetPath) => _cache.putIfAbsent(
    assetPath,
    () => JsonSchema.create(jsonDecode(embeddedUiProtocolSchemas[assetPath]!)),
  );

  List<ProtocolValidationIssue> _toIssues(List<ValidationError> errors) =>
      errors
          .map((e) => ProtocolValidationIssue(e.instancePath, e.message))
          .toList();

  /// 校验整份页面描述是否符合协议信封 Schema。返回的列表为空表示合法。
  Future<List<ProtocolValidationIssue>> validatePageDescription(
    String protocolMajor,
    Map<String, dynamic> description,
  ) async {
    final schema = _requireSchema(pageDescriptionSchemaAsset(protocolMajor));
    if (schema == null) {
      return [ProtocolValidationIssue('', '不认识的协议版本 "$protocolMajor"')];
    }
    return _toIssues(schema.validate(description).errors);
  }

  /// 校验一个组件的 `data` 是否符合该组件类型登记的 Schema。
  /// 没有登记过这个组件类型（没有对应 Schema）时也算不合法。
  Future<List<ProtocolValidationIssue>> validateComponentData(
    String protocolMajor,
    String componentType,
    Map<String, dynamic> data,
  ) async {
    final schema = _requireSchema(
      componentSchemaAsset(protocolMajor, componentType),
    );
    if (schema == null) {
      return [
        ProtocolValidationIssue('', '未登记的组件类型 "$componentType"，没有对应的 Schema'),
      ];
    }
    return _toIssues(schema.validate(data).errors);
  }

  JsonSchema? _requireSchema(String assetPath) {
    if (!embeddedUiProtocolSchemas.containsKey(assetPath)) return null;
    return _load(assetPath);
  }
}

final protocolSchemasProvider = Provider<ProtocolSchemas>(
  (ref) => ProtocolSchemas(),
);
