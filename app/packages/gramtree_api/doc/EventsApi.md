# gramtree_api.api.EventsApi

## Load the API package
```dart
import 'package:gramtree_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**uploadEvents**](EventsApi.md#uploadevents) | **POST** /v1/events/upload | 批量上传经验层事件（需要登录，按登记表校验，按事件 ID 去重，只追加存储）


# **uploadEvents**
> EventUploadResponse uploadEvents(eventUploadRequest)

批量上传经验层事件（需要登录，按登记表校验，按事件 ID 去重，只追加存储）

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getEventsApi();
final EventUploadRequest eventUploadRequest = ; // EventUploadRequest | 

try {
    final response = api.uploadEvents(eventUploadRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling EventsApi->uploadEvents: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **eventUploadRequest** | [**EventUploadRequest**](EventUploadRequest.md)|  | 

### Return type

[**EventUploadResponse**](EventUploadResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

