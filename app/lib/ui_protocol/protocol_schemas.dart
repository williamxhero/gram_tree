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

  /// 把协议版本号（例如 "1.7"）映射到信封 Schema 目录名（例如 "1.0"）：每个大版本
  /// 一个 `<major>.0` 起点目录，小版本增量不新建目录，和服务端
  /// `gramtree.ui_protocol.schema_validation.resolve_schema_major_dir` 保持一致
  /// （SPEC-009.1 #79，见 docs/adr/0005）。格式不对，或者这个大版本压根没有内嵌的
  /// Schema 目录时返回 `null`，调用方按"不认识的大版本"处理。
  String? resolveMajorDir(String protocol) {
    final parts = protocol.split('.');
    if (parts.length != 2) return null;
    if (int.tryParse(parts[0]) == null || int.tryParse(parts[1]) == null) {
      return null;
    }
    final majorDir = '${parts[0]}.0';
    return embeddedUiProtocolSchemas.containsKey(
          pageDescriptionSchemaAsset(majorDir),
        )
        ? majorDir
        : null;
  }

  /// 校验整份页面描述是否符合协议信封 Schema。返回的列表为空表示合法。
  ///
  /// [protocol] 是描述自己带的版本号（例如 "1.7"），不是目录名；这里先按
  /// [resolveMajorDir] 换算成对应大版本起点目录的 Schema 再校验，同一大版本下的
  /// 小版本增量因此照常通过校验（小版本兼容，SPEC-009.1 #79）。
  Future<List<ProtocolValidationIssue>> validatePageDescription(
    String protocol,
    Map<String, dynamic> description,
  ) async {
    final majorDir = resolveMajorDir(protocol);
    if (majorDir == null) {
      return [ProtocolValidationIssue('', '不认识的协议版本 "$protocol"')];
    }
    final schema = _load(pageDescriptionSchemaAsset(majorDir));
    return _toIssues(schema.validate(description).errors);
  }

  /// 校验一个组件的 `data` 是否符合该组件类型登记的 Schema。
  /// 没有登记过这个组件类型（没有对应 Schema）时也算不合法。
  Future<List<ProtocolValidationIssue>> validateComponentData(
    String protocol,
    String componentType,
    Map<String, dynamic> data,
  ) async {
    final majorDir = resolveMajorDir(protocol);
    if (majorDir == null) {
      return [ProtocolValidationIssue('', '不认识的协议版本 "$protocol"')];
    }
    final schema = _requireSchema(
      componentSchemaAsset(majorDir, componentType),
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
