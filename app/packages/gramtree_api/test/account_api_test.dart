import 'package:test/test.dart';
import 'package:gramtree_api/gramtree_api.dart';


/// tests for AccountApi
void main() {
  final instance = GramtreeApi().getAccountApi();

  group(AccountApi, () {
    // 绑定 Apple
    //
    //Future<BuiltList<IdentityOut>> bindApple(BindAppleRequest bindAppleRequest) async
    test('test bindApple', () async {
      // TODO
    });

    // 绑定邮箱
    //
    //Future<BuiltList<IdentityOut>> bindEmail(BindEmailRequest bindEmailRequest) async
    test('test bindEmail', () async {
      // TODO
    });

    // 当前账号
    //
    //Future<UserOut> getMe() async
    test('test getMe', () async {
      // TODO
    });

    // 我的同意记录
    //
    //Future<BuiltList<ConsentRecordOutput>> listConsents() async
    test('test listConsents', () async {
      // TODO
    });

    // 已绑定的登录方式
    //
    //Future<BuiltList<IdentityOut>> listIdentities() async
    test('test listIdentities', () async {
      // TODO
    });

    // 注销账号
    //
    // 要求最近几分钟内重新验证过身份。成功后所有设备立即退出，账号变为注销中，个人数据在期限内由后台删除。
    //
    //Future<DeletionOut> requestDeletion() async
    test('test requestDeletion', () async {
      // TODO
    });

    // 修改昵称或时区
    //
    //Future<UserOut> updateMe(ProfileUpdate profileUpdate) async
    test('test updateMe', () async {
      // TODO
    });

    // 上传同意或撤回记录（登录前存在本机的，登录后补传）
    //
    //Future uploadConsents(ConsentUpload consentUpload) async
    test('test uploadConsents', () async {
      // TODO
    });

  });
}
