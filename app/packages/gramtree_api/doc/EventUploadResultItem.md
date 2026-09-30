# gramtree_api.model.EventUploadResultItem

## Load the model package
```dart
import 'package:gramtree_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**status** | **String** | accepted：已接收入库；duplicate：这个 ID 之前已经收到过，原记录未改动；rejected：没通过登记表校验，未入库，见 reason | 
**reason** | [**RejectionReason**](RejectionReason.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


