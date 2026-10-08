import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';
import '../../auth/session.dart';
import '../../storage/device_id.dart';
import '../../util/ids.dart';

/// Memory-only revocation generation: no sensitive data/consent is stored locally.
/// Changing it cancels all old provider generations, including late history reads.
class SensitiveMemory extends Notifier<({int epoch, bool suppressed})> {
  @override
  ({int epoch, bool suppressed}) build() {
    ref.watch(authProvider.select((value) => value.value?.id));
    return (epoch: 0, suppressed: false);
  }

  void suppress() => state = (epoch: state.epoch + 1, suppressed: true);
  void reload() => state = (epoch: state.epoch + 1, suppressed: false);
}

final sensitiveMemoryProvider =
    NotifierProvider<SensitiveMemory, ({int epoch, bool suppressed})>(
      SensitiveMemory.new,
    );

Map<String, dynamic> sensitiveAccountHeaders(SessionStore store) {
  final session = store.current;
  if (session == null) throw StateError('请先登录');
  // Pin requests to the originating account even when Dio dispatch is queued.
  return {'Authorization': 'Bearer ${session.accessToken}'};
}

Future<void> uploadSensitiveConsent(
  WidgetRef ref,
  bool agree,
  String version,
) async {
  final headers = sensitiveAccountHeaders(ref.read(sessionStoreProvider));
  await ref
      .read(apiClientProvider)
      .getAccountApi()
      .uploadConsents(
        headers: headers,
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
  return (await ref
          .watch(apiClientProvider)
          .getAllergiesApi()
          .getAllergies(
            headers: sensitiveAccountHeaders(ref.read(sessionStoreProvider)),
          ))
      .data!;
});
final allergyChangesProvider =
    FutureProvider.autoDispose<List<TasteProfileChangeOut>>((ref) async {
      final authorized =
          (await ref.watch(allergiesProvider.future))?.consentId != null;
      if (!authorized || !ref.mounted) return [];
      final api = ref.watch(apiClientProvider).getAllergiesApi();
      final headers = sensitiveAccountHeaders(ref.read(sessionStoreProvider));
      final items = <TasteProfileChangeOut>[];
      String? cursor;
      do {
        final page = (await api.listAllergyChanges(
          cursor: cursor,
          headers: headers,
        )).data!;
        items.addAll(page.items);
        cursor = page.nextCursor;
      } while (cursor != null);
      return items;
    });
