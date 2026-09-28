import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 一个来源字段被"这次不用"之后，服务端退回的显示值（SPEC-009.1 #82）——纯内存态，
/// 只影响这次查看：不重新拉取整份组合、不落本机存储，重启 App 或下次重新组合
/// （比如下一次进入"今天"页）就没有了，这正是"只影响这次查看，不写口味档案"的体现。
class SourceOverride {
  const SourceOverride({
    required this.sourceType,
    required this.value,
    this.originalValue,
    required this.basisText,
    this.citation,
  });

  final String sourceType;
  final String value;
  final String? originalValue;
  final String basisText;
  final String? citation;
}

/// 按组件实例 ID 存这次查看期间的来源字段覆盖值。key 是协议里的组件实例 ID
/// （`ComponentDescriptor.id`），同一个组件实例最多一条覆盖——"这次不用"再点一次
/// 只是把覆盖值刷新一遍，不会叠加出"去掉了两条调整"这种状态（因为
/// `service.skip_source_demo_adjustment` 本身就是无状态的"给定当前值算退回结果"，
/// 不是"在已经退回的基础上再退一步"）。
class SourceOverrides extends Notifier<Map<String, SourceOverride>> {
  @override
  Map<String, SourceOverride> build() => const {};

  void set(String componentId, SourceOverride value) =>
      state = {...state, componentId: value};
}

final sourceOverridesProvider =
    NotifierProvider<SourceOverrides, Map<String, SourceOverride>>(
      SourceOverrides.new,
    );
