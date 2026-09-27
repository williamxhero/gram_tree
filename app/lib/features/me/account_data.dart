import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';

/// 已绑定的登录方式。
final identitiesProvider = FutureProvider.autoDispose<List<IdentityOut>>((
  ref,
) async {
  // 换账号或退出后重新拉取
  ref.watch(authProvider.select((a) => a.value?.id));
  final resp = await ref
      .watch(apiClientProvider)
      .getAccountApi()
      .listIdentities();
  return resp.data!;
});

/// 昵称长度上限，和服务端配置项 account.nickname_max_length 的默认值一致；
/// 超过时以服务端的提示为准。
const nicknameMaxLength = 20;
