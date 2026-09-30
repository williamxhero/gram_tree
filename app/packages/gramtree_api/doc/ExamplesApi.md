# gramtree_api.api.ExamplesApi

## Load the API package
```dart
import 'package:gramtree_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**boom**](ExamplesApi.md#boom) | **GET** /v1/examples/boom | 故意抛出未处理异常，用来测试统一错误格式
[**getSample**](ExamplesApi.md#getsample) | **GET** /v1/examples/samples/{sample_id} | 读取一条示例
[**listHeartbeats**](ExamplesApi.md#listheartbeats) | **GET** /v1/examples/heartbeats | 示例后台任务写下的记录（最近 20 条）
[**listSamples**](ExamplesApi.md#listsamples) | **GET** /v1/examples/samples | 示例列表（游标分页，新的在前）
[**putSample**](ExamplesApi.md#putsample) | **PUT** /v1/examples/samples | 创建示例（同一个 ID 重复提交返回已有记录）
[**triggerHeartbeat**](ExamplesApi.md#triggerheartbeat) | **POST** /v1/examples/heartbeats | 触发示例后台任务


# **boom**
> JsonObject boom()

故意抛出未处理异常，用来测试统一错误格式

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getExamplesApi();

try {
    final response = api.boom();
    print(response);
} catch on DioException (e) {
    print('Exception when calling ExamplesApi->boom: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getSample**
> SampleOut getSample(sampleId)

读取一条示例

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getExamplesApi();
final String sampleId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.getSample(sampleId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ExamplesApi->getSample: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **sampleId** | **String**|  | 

### Return type

[**SampleOut**](SampleOut.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listHeartbeats**
> BuiltList<HeartbeatOut> listHeartbeats()

示例后台任务写下的记录（最近 20 条）

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getExamplesApi();

try {
    final response = api.listHeartbeats();
    print(response);
} catch on DioException (e) {
    print('Exception when calling ExamplesApi->listHeartbeats: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**BuiltList&lt;HeartbeatOut&gt;**](HeartbeatOut.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listSamples**
> PageSampleOut listSamples(cursor, limit)

示例列表（游标分页，新的在前）

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getExamplesApi();
final String cursor = cursor_example; // String | 上一页返回的 next_cursor
final int limit = 56; // int | 每页条数，上限见配置项 api.page_size_max

try {
    final response = api.listSamples(cursor, limit);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ExamplesApi->listSamples: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **cursor** | **String**| 上一页返回的 next_cursor | [optional] 
 **limit** | **int**| 每页条数，上限见配置项 api.page_size_max | [optional] [default to 20]

### Return type

[**PageSampleOut**](PageSampleOut.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **putSample**
> SampleOut putSample(sampleCreate)

创建示例（同一个 ID 重复提交返回已有记录）

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getExamplesApi();
final SampleCreate sampleCreate = ; // SampleCreate | 

try {
    final response = api.putSample(sampleCreate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ExamplesApi->putSample: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **sampleCreate** | [**SampleCreate**](SampleCreate.md)|  | 

### Return type

[**SampleOut**](SampleOut.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **triggerHeartbeat**
> TaskAccepted triggerHeartbeat()

触发示例后台任务

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getExamplesApi();

try {
    final response = api.triggerHeartbeat();
    print(response);
} catch on DioException (e) {
    print('Exception when calling ExamplesApi->triggerHeartbeat: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**TaskAccepted**](TaskAccepted.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

