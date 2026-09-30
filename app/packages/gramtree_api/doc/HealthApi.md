# gramtree_api.api.HealthApi

## Load the API package
```dart
import 'package:gramtree_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**health**](HealthApi.md#health) | **GET** /v1/health | 健康检查：服务、数据库、Redis 是否可用


# **health**
> HealthResponse health()

健康检查：服务、数据库、Redis 是否可用

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getHealthApi();

try {
    final response = api.health();
    print(response);
} catch on DioException (e) {
    print('Exception when calling HealthApi->health: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**HealthResponse**](HealthResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

