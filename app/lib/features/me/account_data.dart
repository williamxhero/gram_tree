import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';
import '../../auth/session.dart';

/// 已绑定的登录方式。
final identitiesProvider = FutureProvider.autoDispose<List<IdentityOut>>((
  ref,
) async {
  // 换账号后重新拉取；退出后不再请求
  final auth = ref.watch(authProvider);
  final session = ref.read(sessionStoreProvider);
  final identity = session.identity;
  if (auth.value == null || identity == null) return const [];
  final resp = await ref
      .watch(apiClientProvider)
      .getAccountApi()
      .listIdentities(
        extra: {
          'auth_owner_id': identity.ownerId,
          'auth_identity_epoch': identity.epoch,
        },
      );
  if (!session.matches(identity)) return const [];
  return resp.data!;
});

/// Loaded only after reauthentication; absence/error must block confirmation.
final deletionPreviewProvider = FutureProvider.autoDispose<DeletionPreview>((
  ref,
) async {
  ref.watch(authProvider);
  final session = ref.read(sessionStoreProvider);
  final identity = session.identity;
  if (identity == null) throw StateError('Login required');
  final result = await ref
      .read(apiClientProvider)
      .getAccountApi()
      .getDeletionPreview(
        extra: {
          'auth_owner_id': identity.ownerId,
          'auth_identity_epoch': identity.epoch,
        },
      );
  if (!session.matches(identity)) throw StateError('Account changed');
  return result.data!;
});

/// 昵称长度上限，和服务端配置项 account.nickname_max_length 的默认值一致；
/// 超过时以服务端的提示为准。
const nicknameMaxLength = 20;
