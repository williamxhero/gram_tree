//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:dio/dio.dart';
import 'package:gramtree_api/src/auth/api_key_auth.dart';
import 'package:gramtree_api/src/auth/basic_auth.dart';
import 'package:gramtree_api/src/auth/bearer_auth.dart';
import 'package:gramtree_api/src/auth/oauth.dart';
import 'package:gramtree_api/src/api/account_api.dart';
import 'package:gramtree_api/src/api/allergies_api.dart';
import 'package:gramtree_api/src/api/analytics_api.dart';
import 'package:gramtree_api/src/api/auth_api.dart';
import 'package:gramtree_api/src/api/config_api.dart';
import 'package:gramtree_api/src/api/events_api.dart';
import 'package:gramtree_api/src/api/health_api.dart';
import 'package:gramtree_api/src/api/ingredients_api.dart';
import 'package:gramtree_api/src/api/personal_measures_api.dart';
import 'package:gramtree_api/src/api/recipe_ai_api.dart';
import 'package:gramtree_api/src/api/recipes_api.dart';
import 'package:gramtree_api/src/api/taste_profile_api.dart';
import 'package:gramtree_api/src/api/ui_protocol_api.dart';

class GramtreeApi {
  static const String basePath = r'http://localhost';

  final Dio dio;
  GramtreeApi({
    Dio? dio,
    String? basePathOverride,
    List<Interceptor>? interceptors,
  }) : this.dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: basePathOverride ?? basePath,
               connectTimeout: const Duration(milliseconds: 5000),
               receiveTimeout: const Duration(milliseconds: 3000),
             ),
           ) {
    if (interceptors == null) {
      this.dio.interceptors.addAll([
        OAuthInterceptor(),
        BasicAuthInterceptor(),
        BearerAuthInterceptor(),
        ApiKeyAuthInterceptor(),
      ]);
    } else {
      this.dio.interceptors.addAll(interceptors);
    }
  }

  void setOAuthToken(String name, String token) {
    if (this.dio.interceptors.any((i) => i is OAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is OAuthInterceptor)
                  as OAuthInterceptor)
              .tokens[name] =
          token;
    }
  }

  void setBearerAuth(String name, String token) {
    if (this.dio.interceptors.any((i) => i is BearerAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BearerAuthInterceptor)
                  as BearerAuthInterceptor)
              .tokens[name] =
          token;
    }
  }

  void setBasicAuth(String name, String username, String password) {
    if (this.dio.interceptors.any((i) => i is BasicAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BasicAuthInterceptor)
              as BasicAuthInterceptor)
          .authInfo[name] = BasicAuthInfo(
        username,
        password,
      );
    }
  }

  void setApiKey(String name, String apiKey) {
    if (this.dio.interceptors.any((i) => i is ApiKeyAuthInterceptor)) {
      (this.dio.interceptors.firstWhere(
                    (element) => element is ApiKeyAuthInterceptor,
                  )
                  as ApiKeyAuthInterceptor)
              .apiKeys[name] =
          apiKey;
    }
  }

  /// Get AccountApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AccountApi getAccountApi() {
    return AccountApi(dio);
  }

  /// Get AllergiesApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AllergiesApi getAllergiesApi() {
    return AllergiesApi(dio);
  }

  /// Get AnalyticsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AnalyticsApi getAnalyticsApi() {
    return AnalyticsApi(dio);
  }

  /// Get AuthApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AuthApi getAuthApi() {
    return AuthApi(dio);
  }

  /// Get ConfigApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ConfigApi getConfigApi() {
    return ConfigApi(dio);
  }

  /// Get EventsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  EventsApi getEventsApi() {
    return EventsApi(dio);
  }

  /// Get HealthApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  HealthApi getHealthApi() {
    return HealthApi(dio);
  }

  /// Get IngredientsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  IngredientsApi getIngredientsApi() {
    return IngredientsApi(dio);
  }

  /// Get PersonalMeasuresApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  PersonalMeasuresApi getPersonalMeasuresApi() {
    return PersonalMeasuresApi(dio);
  }

  /// Get RecipeAiApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  RecipeAiApi getRecipeAiApi() {
    return RecipeAiApi(dio);
  }

  /// Get RecipesApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  RecipesApi getRecipesApi() {
    return RecipesApi(dio);
  }

  /// Get TasteProfileApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  TasteProfileApi getTasteProfileApi() {
    return TasteProfileApi(dio);
  }

  /// Get UiProtocolApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  UiProtocolApi getUiProtocolApi() {
    return UiProtocolApi(dio);
  }
}
