import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 页面类型声明的必显组件类型，镜像服务端 `gramtree.ui_protocol.page_types`
/// （SPEC-009.1 #79）：描述里缺少这里列出的、且标记为 `required: true` 的组件类型时，
/// 整页退回标准布局，原因代码 `missing_required`。
///
/// App 端独立做一次这个检查是双重保险，不是这个机制唯一的把关处——服务端
/// （`gramtree.ui_protocol.validation.classify_invalid_description`）已经会在下发前
/// 拦下缺必显组件的描述、改用兜底描述；这里防的是版本不一致或异常数据绕过服务端那道
/// 检查的情况。
///
/// 新增一个页面类型：在这里加一项和服务端 `page_types.ITEMS` 对应的必显组件类型
/// 集合；没有必显组件要求时给空集合（现在的 "today" 就是这样，#77 阶段还没有任何
/// 必显组件业务需求）。
const Map<String, Set<String>> defaultRequiredComponentTypes = {
  'today': <String>{},
};

/// 测试里可以覆盖这个 provider，临时给某个页面类型注册一个必显组件类型，验证
/// "缺必显组件时整页退回标准布局" 这个机制本身（不需要真的给 "today" 加必显组件）。
final requiredComponentTypesProvider = Provider<Map<String, Set<String>>>(
  (ref) => defaultRequiredComponentTypes,
);
