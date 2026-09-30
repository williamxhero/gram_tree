# gramtree_api.api.ConfigApi

## Load the API package
```dart
import 'package:gramtree_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**clientConfig**](ConfigApi.md#clientconfig) | **GET** /v1/client-config | App 用的能力开关和参数


# **clientConfig**
> ClientConfig clientConfig()

App 用的能力开关和参数

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getConfigApi();

try {
    final response = api.clientConfig();
    print(response);
} catch on DioException (e) {
    print('Exception when calling ConfigApi->clientConfig: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ClientConfig**](ClientConfig.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

