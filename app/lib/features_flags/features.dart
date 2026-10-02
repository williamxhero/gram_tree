import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../api/api_client.dart';
import '../privacy/consent.dart';
import '../storage/local_store.dart';

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

const _clientConfigCacheKey = 'client_config:v1';

final clientConfigProvider = FutureProvider<ClientConfig>((ref) async {
  if (!ref.watch(privacyConsentProvider)) {
    return ClientConfig(features: const {}, params: const {});
  }
  final store = ref.watch(localStoreProvider);
  try {
    final response = await ref
        .watch(apiClientProvider)
        .getConfigApi()
        .clientConfig();
    final config = response.data!;
    await store.setString(_clientConfigCacheKey, jsonEncode(config.toJson()));
    return config;
  } catch (_) {
    final cached = store.getString(_clientConfigCacheKey);
    if (cached != null) {
      try {
        return ClientConfig.fromJson(
          Map<String, dynamic>.from(jsonDecode(cached) as Map),
        );
      } catch (_) {
        // Ignore a stale or corrupt cache and use safe defaults below.
      }
    }
    return ClientConfig(features: const {}, params: const {});
  }
});

class RecipeConversionConfig {
  const RecipeConversionConfig({
    required this.minServings,
    required this.maxServings,
    required this.roundDeviationThreshold,
    required this.batchMultiplier,
  });

  final int minServings;
  final int maxServings;
  final double roundDeviationThreshold;
  final double batchMultiplier;
}

final recipeConversionConfigProvider = Provider<RecipeConversionConfig>((ref) {
  final params = ref.watch(clientConfigProvider).value?.params;
  final values = params is Map ? params : const <Object?, Object?>{};
  num number(String key, num fallback) =>
      values[key] is num ? values[key] as num : fallback;
  return RecipeConversionConfig(
    minServings: number('recipe.servings_min', 1).toInt(),
    maxServings: number('recipe.servings_max', 20).toInt(),
    roundDeviationThreshold: number(
      'recipe.scaling_round_deviation_threshold',
      0.20,
    ).toDouble(),
    batchMultiplier: number('recipe.scaling_batch_multiplier', 2.0).toDouble(),
  );
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
