import 'package:flutter/material.dart';

import '../ui_protocol/registered_pages.dart';

import 'reachability.dart';

/// Contract only for future businesses: registering a capability never creates
/// an import/discovery/publishing/planning page or synthetic cached content.
enum OnlineFeature {
  aiGenerate,
  aiModify,
  importRecipe,
  discovery,
  serverSearch,
  recommendationRecalculate,
  planningRecalculate,
  publicPublish,
  serverConversion,
}

/// One policy for rendered entries, intents (including one-line input), deep
/// links and the last request boundary. Local search/edit/save/conversions and
/// read-only caches deliberately have no feature in this registry.
abstract final class OnlineFeatures {
  /// Future generated-client calls declare this in their `extra` map rather
  /// than adding a separate network gate. Value must be an [OnlineFeature].
  static const requestFeatureKey = 'gramtree.online_feature';

  static const operations = <String, OnlineFeature>{
    'ai_generate': OnlineFeature.aiGenerate,
    'ai_modify': OnlineFeature.aiModify,
    'import_recipe': OnlineFeature.importRecipe,
    'discover': OnlineFeature.discovery,
    'server_search': OnlineFeature.serverSearch,
    'recalculate_recommendations': OnlineFeature.recommendationRecalculate,
    'recalculate_plan': OnlineFeature.planningRecalculate,
    'publish_recipe': OnlineFeature.publicPublish,
    'server_conversion': OnlineFeature.serverConversion,
  };

  static OnlineFeature? forPage(String path) =>
      path == '/recipes/one-line' ? OnlineFeature.aiGenerate : null;

  static OnlineFeature? forIntent(String intent, Map<String, dynamic> params) {
    if (intent == 'open_page') {
      return forPage(registeredPages[params['page']] ?? '');
    }
    if (intent == 'call_operation') return operations[params['operation']];
    if (intent == 'skip_this_time') return OnlineFeature.serverConversion;
    return operations[intent];
  }

  static OnlineFeature? forRequest(String method, String path) {
    // Saving an already generated draft is manual persistence, not AI work.
    if (path.startsWith('/v1/ai/recipes/') && !path.endsWith('/save')) {
      return path.endsWith('/modify')
          ? OnlineFeature.aiModify
          : OnlineFeature.aiGenerate;
    }
    if (path.startsWith('/v1/recipes/') &&
        (path.endsWith('/servings') ||
            path.endsWith('/mold') ||
            path.endsWith('/display'))) {
      return OnlineFeature.serverConversion;
    }
    if (path == '/v1/ui/compositions/skip-adjustment') {
      return OnlineFeature.serverConversion;
    }
    return null;
  }
}

class OnlineFeatureUnavailable implements Exception {
  const OnlineFeatureUnavailable(this.status);
  final ApiReachability status;
  @override
  String toString() => status.message;
}

/// Carries the same policy into protocol component builders without changing
/// their wire schema or disabling a whole card's local actions.
class OnlineActionAvailability extends InheritedWidget {
  const OnlineActionAvailability({
    super.key,
    required this.status,
    required super.child,
  });
  final ApiReachability status;
  static bool allows(
    BuildContext context,
    String intent,
    Map<String, dynamic> params,
  ) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<OnlineActionAvailability>();
    return OnlineFeatures.forIntent(intent, params) == null ||
        (scope?.status.canRequest ?? true);
  }

  @override
  bool updateShouldNotify(OnlineActionAvailability oldWidget) =>
      oldWidget.status != status;
}
