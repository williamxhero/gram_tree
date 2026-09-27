import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../api/api_client.dart';

/// 服务端下发的能力开关（服务端配置项 feature.*）。
///
/// 关闭的能力在 App 里不出现入口，避免“能点但点了必然失败”的按钮（SPEC-009）。
/// 底部五个入口固定，不受开关控制。
enum Feature {
  evolutionTree('evolution_tree'),
  cookingQa('cooking_qa'),
  receiptScan('receipt_scan');

  const Feature(this.key);

  /// 服务端返回的 key（去掉了 feature. 前缀）。
  final String key;
}

/// 启动时从服务端拉取 App 配置。拉取失败时按“全部关闭”处理。
final clientConfigProvider = FutureProvider<ClientConfig>((ref) async {
  final response = await ref
      .watch(apiClientProvider)
      .getConfigApi()
      .clientConfig();
  return response.data!;
});

/// 某个能力当前是否开启。配置还没拉到或拉取失败时一律视为关闭。
final featureEnabledProvider = Provider.family<bool, Feature>((ref, feature) {
  final config = ref.watch(clientConfigProvider).value;
  return config?.features[feature.key] ?? false;
});

/// 只在 [feature] 开启时显示 [child]。
class FeatureGate extends ConsumerWidget {
  const FeatureGate({super.key, required this.feature, required this.child});

  final Feature feature;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(featureEnabledProvider(feature))
      ? child
      : const SizedBox.shrink();
}
