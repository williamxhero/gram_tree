import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';
import '../../auth/session.dart';
import '../../storage/device_id.dart';
import '../../util/ids.dart';

/// Memory-only generation: no decrypted values or consent receipts persist here.
/// Never reuse a generation, even when switching A -> B -> A.
class SensitiveMemory extends Notifier<({int epoch, bool suppressed})> {
  int _generation = 0;
  @override
  ({int epoch, bool suppressed}) build() {
    ref.watch(authProvider.select((value) => value.value?.id));
    return (epoch: ++_generation, suppressed: false);
  }

  void suppress() => state = (epoch: ++_generation, suppressed: true);
  void reload() => state = (epoch: ++_generation, suppressed: false);
}

final sensitiveMemoryProvider =
    NotifierProvider<SensitiveMemory, ({int epoch, bool suppressed})>(
      SensitiveMemory.new,
    );

Map<String, dynamic> sensitiveAccountHeaders(SessionStore store) {
  final session = store.current;
  if (session == null) throw StateError('account_unavailable');
  return {'Authorization': 'Bearer ${session.accessToken}'};
}

Map<String, dynamic> sensitiveAccountExtra(SessionStore store) {
  final session = store.current;
  if (session == null) throw StateError('account_unavailable');
  // Local request metadata, never transmitted or persisted. Auth retries must
  // not replace the originating account with whichever account is current.
  return {
    'sensitive_account_id': session.user.id,
    'sensitive_session': session,
  };
}

Future<void> uploadSensitiveConsent(
  WidgetRef ref,
  bool agree,
  String version,
) async {
  final store = ref.read(sessionStoreProvider);
  await ref
      .read(apiClientProvider)
      .getAccountApi()
      .uploadConsents(
        headers: sensitiveAccountHeaders(store),
        extra: sensitiveAccountExtra(store),
        consentUpload: ConsentUpload(
          records: [
            ConsentRecordInput(
              id: newUuidV4(),
              kind: ConsentRecordInputKindEnum.sensitivePersonalInfo,
              version: version,
              action: agree
                  ? ConsentRecordInputActionEnum.agree
                  : ConsentRecordInputActionEnum.withdraw,
              occurredAt: DateTime.now().toUtc(),
              deviceId: ref.read(deviceIdProvider),
            ),
          ],
        ),
      );
}

final allergiesProvider = FutureProvider.autoDispose<AllergiesOut?>((
  ref,
) async {
  final account = ref.watch(authProvider).value?.id;
  final memory = ref.watch(sensitiveMemoryProvider);
  if (account == null || memory.suppressed) return null;
  final store = ref.read(sessionStoreProvider);
  final result = await ref
      .watch(apiClientProvider)
      .getAllergiesApi()
      .getAllergies(
        headers: sensitiveAccountHeaders(store),
        extra: sensitiveAccountExtra(store),
      );
  return ref.mounted ? result.data! : null;
});
final allergyChangesProvider =
    FutureProvider.autoDispose<List<TasteProfileChangeOut>>((ref) async {
      final account = ref.watch(authProvider).value?.id;
      final memory = ref.watch(sensitiveMemoryProvider);
      if (account == null || memory.suppressed) return [];
      final api = ref.watch(apiClientProvider).getAllergiesApi();
      final store = ref.read(sessionStoreProvider);
      final headers = sensitiveAccountHeaders(store);
      final extra = sensitiveAccountExtra(store);
      final authorized =
          (await ref.watch(allergiesProvider.future))?.consentId != null;
      if (!authorized || !ref.mounted) return [];
      final items = <TasteProfileChangeOut>[];
      String? cursor;
      do {
        final page = (await api.listAllergyChanges(
          cursor: cursor,
          headers: headers,
          extra: extra,
        )).data!;
        if (!ref.mounted) {
          items.clear();
          return [];
        }
        items.addAll(page.items);
        cursor = page.nextCursor;
      } while (cursor != null);
      return items;
    });
