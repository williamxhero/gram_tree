# gramtree_api.model.EventUploadItem

## Load the model package
```dart
import 'package:gramtree_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** | 客户端生成的事件 ID（UUID v4），全局唯一，按它去重 | 
**eventType** | **String** |  | 
**typeVersion** | **int** | 事件类型的版本号 | 
**deviceId** | **String** |  | 
**deviceTime** | [**DateTime**](DateTime.md) | 设备本地时间，必须带时区 | 
**appVersion** | **String** |  | 
**correlation** | [**EventCorrelationIds**](EventCorrelationIds.md) |  | [optional] 
**content** | [**BuiltMap&lt;String, JsonObject&gt;**](JsonObject.md) | 事件内容。用户 ID 只按登录状态填入，这里出现的任何 user_id 字段都不采信 | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


