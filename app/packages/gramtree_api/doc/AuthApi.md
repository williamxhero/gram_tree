# gramtree_api.api.AuthApi

## Load the API package
```dart
import 'package:gramtree_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**appleLogin**](AuthApi.md#applelogin) | **POST** /v1/auth/apple/login | 通过 Apple 登录（首次登录自动创建账号）
[**emailLogin**](AuthApi.md#emaillogin) | **POST** /v1/auth/email/login | 用邮箱验证码登录（首次登录自动创建账号）
[**logout**](AuthApi.md#logout) | **POST** /v1/auth/logout | 退出当前设备的登录
[**reauthApple**](AuthApi.md#reauthapple) | **POST** /v1/auth/reauth/apple | 通过 Apple 重新验证身份
[**reauthEmail**](AuthApi.md#reauthemail) | **POST** /v1/auth/reauth/email | 用邮箱验证码重新验证身份（注销账号等敏感操作前）
[**refreshTokens**](AuthApi.md#refreshtokens) | **POST** /v1/auth/refresh | 用刷新令牌续期
[**sendEmailCode**](AuthApi.md#sendemailcode) | **POST** /v1/auth/email/code | 发送邮箱验证码


# **appleLogin**
> TokenPair appleLogin(appleLoginRequest)

通过 Apple 登录（首次登录自动创建账号）

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getAuthApi();
final AppleLoginRequest appleLoginRequest = ; // AppleLoginRequest | 

try {
    final response = api.appleLogin(appleLoginRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthApi->appleLogin: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **appleLoginRequest** | [**AppleLoginRequest**](AppleLoginRequest.md)|  | 

### Return type

[**TokenPair**](TokenPair.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **emailLogin**
> TokenPair emailLogin(emailLoginRequest)

用邮箱验证码登录（首次登录自动创建账号）

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getAuthApi();
final EmailLoginRequest emailLoginRequest = ; // EmailLoginRequest | 

try {
    final response = api.emailLogin(emailLoginRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthApi->emailLogin: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **emailLoginRequest** | [**EmailLoginRequest**](EmailLoginRequest.md)|  | 

### Return type

[**TokenPair**](TokenPair.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **logout**
> logout()

退出当前设备的登录

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getAuthApi();

try {
    api.logout();
} catch on DioException (e) {
    print('Exception when calling AuthApi->logout: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **reauthApple**
> reauthApple(appleReauthRequest)

通过 Apple 重新验证身份

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getAuthApi();
final AppleReauthRequest appleReauthRequest = ; // AppleReauthRequest | 

try {
    api.reauthApple(appleReauthRequest);
} catch on DioException (e) {
    print('Exception when calling AuthApi->reauthApple: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **appleReauthRequest** | [**AppleReauthRequest**](AppleReauthRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **reauthEmail**
> reauthEmail(emailReauthRequest)

用邮箱验证码重新验证身份（注销账号等敏感操作前）

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getAuthApi();
final EmailReauthRequest emailReauthRequest = ; // EmailReauthRequest | 

try {
    api.reauthEmail(emailReauthRequest);
} catch on DioException (e) {
    print('Exception when calling AuthApi->reauthEmail: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **emailReauthRequest** | [**EmailReauthRequest**](EmailReauthRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **refreshTokens**
> TokenPair refreshTokens(refreshRequest)

用刷新令牌续期

每次续期都换发新的刷新令牌。旧的刷新令牌再被使用时，这台设备的登录全部失效。

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getAuthApi();
final RefreshRequest refreshRequest = ; // RefreshRequest | 

try {
    final response = api.refreshTokens(refreshRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthApi->refreshTokens: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **refreshRequest** | [**RefreshRequest**](RefreshRequest.md)|  | 

### Return type

[**TokenPair**](TokenPair.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **sendEmailCode**
> EmailCodeSent sendEmailCode(emailCodeRequest)

发送邮箱验证码

purpose=login 不需要登录；bind（绑定新邮箱）和 reauth（重新验证身份）需要登录。

### Example
```dart
import 'package:gramtree_api/api.dart';

final api = GramtreeApi().getAuthApi();
final EmailCodeRequest emailCodeRequest = ; // EmailCodeRequest | 

try {
    final response = api.sendEmailCode(emailCodeRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthApi->sendEmailCode: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **emailCodeRequest** | [**EmailCodeRequest**](EmailCodeRequest.md)|  | 

### Return type

[**EmailCodeSent**](EmailCodeSent.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

