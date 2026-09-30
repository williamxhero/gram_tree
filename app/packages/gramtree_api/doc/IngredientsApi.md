# gramtree_api.api.IngredientsApi

## Load the API package
```dart
import 'package:gramtree_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getIngredient**](IngredientsApi.md#getingredient) | **GET** /v1/ingredients/{ingredient_id} | Get Ingredient
[**normalizeIngredients**](IngredientsApi.md#normalizeingredients) | **POST** /v1/ingredients/normalize | Normalize Ingredients
[**searchIngredients**](IngredientsApi.md#searchingredients) | **POST** /v1/ingredients/search | Search Ingredients


# **getIngredient**
> IngredientDetail getIngredient(ingredientId)

Get Ingredient

读取一种食材的完整数据。如果这个 ID 已经合并到另一个,自动返回合并后的食材。  没经人工校对的属性带 `estimate: true`，计算和显示时按估算处理。

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getIngredientsApi();
final String ingredientId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.getIngredient(ingredientId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling IngredientsApi->getIngredient: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **ingredientId** | **String**|  | 

### Return type

[**IngredientDetail**](IngredientDetail.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **normalizeIngredients**
> NormalizeResponse normalizeIngredients(normalizeRequest)

Normalize Ingredients

把一批食材名称归一到标准 ID（只用规则匹配），结果按输入顺序返回。

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getIngredientsApi();
final NormalizeRequest normalizeRequest = ; // NormalizeRequest | 

try {
    final response = api.normalizeIngredients(normalizeRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling IngredientsApi->normalizeIngredients: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **normalizeRequest** | [**NormalizeRequest**](NormalizeRequest.md)|  | 

### Return type

[**NormalizeResponse**](NormalizeResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **searchIngredients**
> SearchResult searchIngredients(searchQuery)

Search Ingredients

搜索食材。支持标准名、别名、拼音首字母、完整拼音前缀匹配。最多返回 20 个结果。

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getIngredientsApi();
final SearchQuery searchQuery = ; // SearchQuery | 

try {
    final response = api.searchIngredients(searchQuery);
    print(response);
} catch on DioException (e) {
    print('Exception when calling IngredientsApi->searchIngredients: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **searchQuery** | [**SearchQuery**](SearchQuery.md)|  | 

### Return type

[**SearchResult**](SearchResult.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

