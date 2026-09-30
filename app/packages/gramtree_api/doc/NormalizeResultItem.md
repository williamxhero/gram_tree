# gramtree_api.model.NormalizeResultItem

## Load the model package
```dart
import 'package:gramtree_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**name** | **String** | 原样返回输入的名称 | 
**confidence** | **String** | exact 标准名精确匹配；alias 别名匹配（含已合并食材的旧名）；fuzzy 去掉修饰词或按拼音后唯一命中；ambiguous 歧义名，见 candidates；unrecorded 未收录 | 
**ingredientId** | **String** |  | 
**standardName** | **String** |  | 
**candidates** | [**BuiltList&lt;NormalizeCandidate&gt;**](NormalizeCandidate.md) | 只有 ambiguous 时非空 | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


