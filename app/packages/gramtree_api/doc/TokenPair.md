# gramtree_api.model.TokenPair

## Load the model package
```dart
import 'package:gramtree_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**accessToken** | **String** |  | 
**accessExpiresIn** | **int** | 访问令牌多少秒后过期 | 
**refreshToken** | **String** | 续期用；每次续期都会换发新的，旧的立即作废 | 
**user** | [**UserOut**](UserOut.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


