# gramtree_api.model.ComponentDescriptor

## Load the model package
```dart
import 'package:gramtree_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**type** | **String** | 组件类型名，必须是 App 声明支持的组件 | 
**id** | **String** | 这份描述里的组件实例 ID | 
**detail** | **String** |  | 
**data** | [**BuiltMap&lt;String, JsonObject&gt;**](JsonObject.md) | 组件数据，形状由该 type 的组件 Schema 定义 | 
**actions** | [**BuiltList&lt;ActionDescriptor&gt;**](ActionDescriptor.md) |  | [optional] 
**reason** | [**ComponentReason**](ComponentReason.md) |  | 
**required_** | **bool** | 是否是必显组件 | [optional] [default to false]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


