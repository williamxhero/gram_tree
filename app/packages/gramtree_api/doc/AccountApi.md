# gramtree_api.api.AccountApi

## Load the API package
```dart
import 'package:gramtree_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**bindApple**](AccountApi.md#bindapple) | **POST** /v1/me/identities/apple | 绑定 Apple
[**bindEmail**](AccountApi.md#bindemail) | **POST** /v1/me/identities/email | 绑定邮箱
[**getMe**](AccountApi.md#getme) | **GET** /v1/me | 当前账号
[**listConsents**](AccountApi.md#listconsents) | **GET** /v1/me/consents | 我的同意记录
[**listIdentities**](AccountApi.md#listidentities) | **GET** /v1/me/identities | 已绑定的登录方式
[**requestDeletion**](AccountApi.md#requestdeletion) | **POST** /v1/me/deletion | 注销账号
[**updateMe**](AccountApi.md#updateme) | **PATCH** /v1/me | 修改昵称或时区
[**uploadConsents**](AccountApi.md#uploadconsents) | **POST** /v1/me/consents | 上传同意或撤回记录（登录前存在本机的，登录后补传）


# **bindApple**
> BuiltList<IdentityOut> bindApple(bindAppleRequest)

绑定 Apple

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getAccountApi();
final BindAppleRequest bindAppleRequest = ; // BindAppleRequest | 

try {
    final response = api.bindApple(bindAppleRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AccountApi->bindApple: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **bindAppleRequest** | [**BindAppleRequest**](BindAppleRequest.md)|  | 

### Return type

[**BuiltList&lt;IdentityOut&gt;**](IdentityOut.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **bindEmail**
> BuiltList<IdentityOut> bindEmail(bindEmailRequest)

绑定邮箱

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getAccountApi();
final BindEmailRequest bindEmailRequest = ; // BindEmailRequest | 

try {
    final response = api.bindEmail(bindEmailRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AccountApi->bindEmail: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **bindEmailRequest** | [**BindEmailRequest**](BindEmailRequest.md)|  | 

### Return type

[**BuiltList&lt;IdentityOut&gt;**](IdentityOut.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMe**
> UserOut getMe()

当前账号

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getAccountApi();

try {
    final response = api.getMe();
    print(response);
} catch on DioException (e) {
    print('Exception when calling AccountApi->getMe: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**UserOut**](UserOut.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listConsents**
> BuiltList<ConsentRecordOutput> listConsents()

我的同意记录

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getAccountApi();

try {
    final response = api.listConsents();
    print(response);
} catch on DioException (e) {
    print('Exception when calling AccountApi->listConsents: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**BuiltList&lt;ConsentRecordOutput&gt;**](ConsentRecordOutput.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listIdentities**
> BuiltList<IdentityOut> listIdentities()

已绑定的登录方式

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getAccountApi();

try {
    final response = api.listIdentities();
    print(response);
} catch on DioException (e) {
    print('Exception when calling AccountApi->listIdentities: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**BuiltList&lt;IdentityOut&gt;**](IdentityOut.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **requestDeletion**
> DeletionOut requestDeletion()

注销账号

要求最近几分钟内重新验证过身份。成功后所有设备立即退出，账号变为注销中，个人数据在期限内由后台删除。

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getAccountApi();

try {
    final response = api.requestDeletion();
    print(response);
} catch on DioException (e) {
    print('Exception when calling AccountApi->requestDeletion: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**DeletionOut**](DeletionOut.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateMe**
> UserOut updateMe(profileUpdate)

修改昵称或时区

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getAccountApi();
final ProfileUpdate profileUpdate = ; // ProfileUpdate | 

try {
    final response = api.updateMe(profileUpdate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AccountApi->updateMe: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **profileUpdate** | [**ProfileUpdate**](ProfileUpdate.md)|  | 

### Return type

[**UserOut**](UserOut.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **uploadConsents**
> uploadConsents(consentUpload)

上传同意或撤回记录（登录前存在本机的，登录后补传）

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getAccountApi();
final ConsentUpload consentUpload = ; // ConsentUpload | 

try {
    api.uploadConsents(consentUpload);
} catch on DioException (e) {
    print('Exception when calling AccountApi->uploadConsents: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **consentUpload** | [**ConsentUpload**](ConsentUpload.md)|  | 

### Return type

void (empty response body)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

