# gramtree_api.api.UiProtocolApi

## Load the API package
```dart
import 'package:gramtree_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**compose**](UiProtocolApi.md#compose) | **POST** /v1/ui/compositions | 按 App 声明的协议版本和组件清单，下发一份页面描述（需要登录）
[**skipAdjustment**](UiProtocolApi.md#skipadjustment) | **POST** /v1/ui/compositions/skip-adjustment | \&quot;这次不用\&quot;：返回去掉这条来源调整后的结果，只影响这次查看，不写口味档案（需要登录）


# **compose**
> PageDescription compose(composeRequest)

按 App 声明的协议版本和组件清单，下发一份页面描述（需要登录）

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getUiProtocolApi();
final ComposeRequest composeRequest = ; // ComposeRequest | 

try {
    final response = api.compose(composeRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling UiProtocolApi->compose: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **composeRequest** | [**ComposeRequest**](ComposeRequest.md)|  | 

### Return type

[**PageDescription**](PageDescription.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **skipAdjustment**
> SkipAdjustmentResult skipAdjustment(skipAdjustmentRequest)

\"这次不用\"：返回去掉这条来源调整后的结果，只影响这次查看，不写口味档案（需要登录）

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getUiProtocolApi();
final SkipAdjustmentRequest skipAdjustmentRequest = ; // SkipAdjustmentRequest | 

try {
    final response = api.skipAdjustment(skipAdjustmentRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling UiProtocolApi->skipAdjustment: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **skipAdjustmentRequest** | [**SkipAdjustmentRequest**](SkipAdjustmentRequest.md)|  | 

### Return type

[**SkipAdjustmentResult**](SkipAdjustmentResult.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

