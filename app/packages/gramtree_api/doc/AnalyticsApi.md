# gramtree_api.api.AnalyticsApi

## Load the API package
```dart
import 'package:gramtree_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**uploadAnalyticsEvents**](AnalyticsApi.md#uploadanalyticsevents) | **POST** /v1/analytics/events | 上传产品埋点（页面访问 / 入口点击 / 加载耗时）


# **uploadAnalyticsEvents**
> uploadAnalyticsEvents(analyticsUploadRequest)

上传产品埋点（页面访问 / 入口点击 / 加载耗时）

同意隐私政策前、或关闭“产品改进统计”开关后，客户端不应调用这个接口。服务端只按登记好的字段接收，多余字段一律拒收；不接受第三方分析服务转发。

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getAnalyticsApi();
final AnalyticsUploadRequest analyticsUploadRequest = ; // AnalyticsUploadRequest | 

try {
    api.uploadAnalyticsEvents(analyticsUploadRequest);
} catch on DioException (e) {
    print('Exception when calling AnalyticsApi->uploadAnalyticsEvents: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **analyticsUploadRequest** | [**AnalyticsUploadRequest**](AnalyticsUploadRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

