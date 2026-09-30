# gramtree_api.model.ComposeRequest

## Load the model package
```dart
import 'package:gramtree_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**pageType** | **String** | 要哪个页面类型的组合，例如 today | 
**protocolVersion** | **String** | App 自己实现的协议版本，例如 1.0 | 
**supportedComponents** | **BuiltList&lt;String&gt;** | App 已登记、认识的组件类型清单；服务端只会下发这里面的类型 | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


