import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'registered_pages.dart';

/// App 内置意图登记表（SPEC-009.1 #81）：组件上的每个动作只能是这里登记过的意图，
/// 按钮、菜单、以后的一句话输入都落到同一批意图，都走同一个处理器
/// （见 `intent_dispatcher.dart` 的 `IntentDispatcher`）。
///
/// 和 #77/#80 留下的 `intentDefaultLabel` 是什么关系：这个文件原本只有一个给按钮配
/// 文案的小函数（现在的 [intentDefaultLabel]），这张票把它扩展成完整的登记表——
/// 名字、默认文案、参数格式校验、处理器都在同一个 [IntentSpec] 里；不再有第二套
/// 意图相关的映射表。
///
/// 每个意图登记：
/// * [IntentSpec.defaultLabel]：协议没有显式给按钮文案时用的通用文案（和之前
///   `intentDefaultLabel` 的行为完全一样）。
/// * [IntentSpec.validateParams]：判断动作的 `params` 是否符合这个意图的参数格式，
///   composition_provider.dart 用它判定"非法动作"（未登记意图名本身、参数格式错、
///   打开页面时的任意网址都在这一层被拒绝）。
/// * [IntentSpec.handler]：真正触发这个意图要做的事；为 `null` 表示这个意图目前
///   只登记了名字和参数格式，处理器留给以后的子 SPEC 补（`skip_this_time`/
///   `dont_do_again` 留给 #82；`call_operation` 范围见下面它自己的注释）。
typedef IntentParamsValidator = bool Function(Map<String, dynamic> params);

/// 触发一个意图时真正要做的事。[context] 给需要跳转的意图（比如 `open_page`）用；
/// [ref] 给以后可能要读 Provider、调用接口的意图（比如 `call_operation` 真正实现
/// 时）用。可以同步返回（`void`），[IntentDispatcher.dispatch] 一律 `await` 一次。
typedef IntentHandler = FutureOr<void> Function(
  BuildContext context,
  Ref ref,
  Map<String, dynamic> params,
);

class IntentSpec {
  const IntentSpec({
    required this.name,
    required this.defaultLabel,
    required this.validateParams,
    this.handler,
  });

  final String name;
  final String defaultLabel;
  final IntentParamsValidator validateParams;
  final IntentHandler? handler;
}

/// App 内置意图登记表。
class IntentRegistry {
  IntentRegistry(Iterable<IntentSpec> specs)
    : _byName = {for (final s in specs) s.name: s};

  final Map<String, IntentSpec> _byName;

  bool isRegistered(String name) => _byName.containsKey(name);

  IntentSpec? operator [](String name) => _byName[name];

  /// 一个动作（意图名 + 参数）合不合法：意图必须已登记，且参数通过该意图登记的格式
  /// 校验。协议信封 Schema（SPEC-009.1 #79）只保证 `intent`/`params` 这两个字段
  /// 本身的结构（字符串、对象）合法；"这个意图名是不是在登记表里、参数格式对不对"
  /// 是这一层（#81）加的语义校验，`composition_provider.dart` 的 `fetchComposition`
  /// 拿它判定 `illegal_action`。
  bool isValidAction(String intent, Map<String, dynamic> params) {
    final spec = _byName[intent];
    return spec != null && spec.validateParams(params);
  }
}

bool _requireNonEmptyString(Map<String, dynamic> params, String key) {
  final value = params[key];
  return value is String && value.isNotEmpty;
}

/// `open_page`：`params.page` 必须是 [registeredPages] 里登记过的页面名——这一条
/// 校验同时挡住"未登记的页面名"和"任意网址跳转"（一个 URL 字符串不会出现在这张
/// 白名单里，天然被拒绝，不需要额外判断"像不像网址"）。
bool _validateOpenPage(Map<String, dynamic> params) {
  final page = params['page'];
  return page is String && registeredPages.containsKey(page);
}

Future<void> _handleOpenPage(
  BuildContext context,
  Ref ref,
  Map<String, dynamic> params,
) async {
  final path = registeredPages[params['page']];
  // 正常链路里参数已经在渲染前校验过，这里理应总能找到；找不到就安静地什么都不做
  // （不崩溃），呼应 IntentDispatcher.dispatch 顶部注释里说的兜底口子。
  if (path == null) return;
  context.go(path);
}

/// `start_cooking`：参数格式要求 `recipe_version_id`（要开始做的菜谱版本 ID）。
/// 做菜模式页面还没有实现（留给后续子 SPEC），处理器目前只完成
/// "意图已登记、参数已校验、来源组合 ID 已经记下"这几步——这几步由
/// `IntentDispatcher.dispatch` 统一做，不需要这个处理器自己重复；做菜模式页面上线
/// 后回来把真正的跳转接进这个处理器。
bool _validateStartCooking(Map<String, dynamic> params) =>
    _requireNonEmptyString(params, 'recipe_version_id');

void _handleStartCooking(
  BuildContext context,
  Ref ref,
  Map<String, dynamic> params,
) {}

/// `open_record_card`：参数格式要求 `cooking_record_id`（要打开的做菜记录 ID）。
/// 记录卡页面还没有实现，处理器和 `start_cooking` 一样先是占位——理由同上。
bool _validateOpenRecordCard(Map<String, dynamic> params) =>
    _requireNonEmptyString(params, 'cooking_record_id');

void _handleOpenRecordCard(
  BuildContext context,
  Ref ref,
  Map<String, dynamic> params,
) {}

/// `call_operation`：调用已登记的接口操作。范围边界（#81 明确写在票里）：这张票只
/// 登记"这是一个合法的意图名"和参数格式（`operation` 是哪个已登记的接口操作的
/// 名字），不实现一个通用的"按名字调用任意接口"机制——目前没有任何接口操作登记
/// 在这里可以调用，`handler` 留空；等真的有业务场景要用这个意图时，再在这里给
/// 具体的 `operation` 取值接处理逻辑。
bool _validateCallOperation(Map<String, dynamic> params) =>
    _requireNonEmptyString(params, 'operation');

/// 下面四个意图（存进口味、应用改动、这次不用、以后别这样）这张票只登记名字，参数
/// 格式留给真正实现处理器的子 SPEC（`skip_this_time`/`dont_do_again` 是 #82）按业务
/// 需要再收紧——`ui.source_feedback` 事件（#78 登记的类型）已经定了
/// `skip_this_time`/`dont_do_again` 大致要带的信息（`component_id`、来源标记、
/// 这次不用/以后别这样），但动作参数的确切形状由实现处理器时决定，这里先只要求
/// `params` 是一个对象（协议信封 Schema 已经保证这一点），不做进一步约束。
bool _acceptAnyParams(Map<String, dynamic> params) => true;

/// SPEC-009.1 #81 登记的意图表：#77/#80 用到的 `open_page`/`start_cooking`/
/// `open_record_card` 沿用之前的默认文案，新增 `call_operation` 和四个先只登记
/// 名字的意图。
final defaultIntentRegistry = IntentRegistry(const [
  IntentSpec(
    name: 'open_page',
    defaultLabel: '去看看',
    validateParams: _validateOpenPage,
    handler: _handleOpenPage,
  ),
  IntentSpec(
    name: 'start_cooking',
    defaultLabel: '开始做',
    validateParams: _validateStartCooking,
    handler: _handleStartCooking,
  ),
  IntentSpec(
    name: 'open_record_card',
    defaultLabel: '打开记录卡',
    validateParams: _validateOpenRecordCard,
    handler: _handleOpenRecordCard,
  ),
  IntentSpec(
    name: 'call_operation',
    defaultLabel: '去操作',
    validateParams: _validateCallOperation,
  ),
  IntentSpec(
    name: 'save_to_taste',
    defaultLabel: '存进口味',
    validateParams: _acceptAnyParams,
  ),
  IntentSpec(
    name: 'apply_change',
    defaultLabel: '应用改动',
    validateParams: _acceptAnyParams,
  ),
  IntentSpec(
    name: 'skip_this_time',
    defaultLabel: '这次不用',
    validateParams: _acceptAnyParams,
  ),
  IntentSpec(
    name: 'dont_do_again',
    defaultLabel: '以后别这样',
    validateParams: _acceptAnyParams,
  ),
]);

final intentRegistryProvider = Provider<IntentRegistry>(
  (ref) => defaultIntentRegistry,
);

/// 按意图给一个通用的按钮文案。协议只下发意图名和参数，不下发按钮文字——同一个
/// 意图不管出现在哪个组合里，文案都一样，这是固定骨架的一部分（组件自己的数据里
/// 显式给了文案时优先用那个，见 `components/component_scaffold.dart` 的
/// `labelForAction`）。未登记的意图名退回一个通用文案，不崩溃——这种情况理论上不会
/// 在合法渲染出来的组合里出现（`composition_provider.dart` 已经把未登记意图挡在
/// `illegal_action` 兜底之外），这里只是最后一道保险。
String intentDefaultLabel(String intent) =>
    defaultIntentRegistry[intent]?.defaultLabel ?? '去操作';
