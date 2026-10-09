import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';
import '../../auth/session.dart';
import 'allergies_data.dart';

typedef FamilyMemoryState = ({
  int epoch,
  Set<String> deleted,
  Set<String> pending,
});

/// ID-only tombstones prevent pre-deletion replies from restoring private values.
/// Pending IDs survive page recreation, but never account/consent generations.
/// A separate generation also clears open editors without hiding owner allergies.
class FamilyMemory extends Notifier<FamilyMemoryState> {
  int _generation = 0;
  @override
  FamilyMemoryState build() {
    ref.watch(sensitiveMemoryProvider);
    return (epoch: ++_generation, deleted: <String>{}, pending: <String>{});
  }

  void evict(String id) => state = (
    epoch: ++_generation,
    deleted: {...state.deleted, id},
    pending: {...state.pending, id},
  );

  void confirmDeletion(String id) => state = (
    epoch: state.epoch,
    deleted: state.deleted,
    pending: {...state.pending}..remove(id),
  );

  void discardSnapshot() => state = (
    epoch: ++_generation,
    deleted: state.deleted,
    pending: state.pending,
  );
}

final familyMemoryProvider = NotifierProvider<FamilyMemory, FamilyMemoryState>(
  FamilyMemory.new,
);

final familyMembersProvider = FutureProvider.autoDispose<FamilyMembersOut?>((
  ref,
) async {
  final account = ref.watch(authProvider).value?.id;
  final sensitive = ref.watch(sensitiveMemoryProvider);
  final memory = ref.watch(familyMemoryProvider);
  if (account == null || sensitive.suppressed) return null;
  final store = ref.read(sessionStoreProvider);
  final api = ref.watch(apiClientProvider).getFamilyMembersApi();
  final headers = sensitiveAccountHeaders(store);
  final extra = sensitiveAccountExtra(store);
  FamilyMembersOut? result;
  final members = <FamilyMemberOut>[];
  String? cursor;
  do {
    final page = (await api.listFamilyMembers(
      cursor: cursor,
      headers: headers,
      extra: extra,
    )).data!;
    if (!ref.mounted) {
      members.clear();
      return null;
    }
    if (result != null &&
        (page.consentId != result.consentId ||
            page.authorizationVersion != result.authorizationVersion ||
            page.profileVersion != result.profileVersion ||
            page.consentVersion != result.consentVersion)) {
      members.clear();
      throw StateError('family_snapshot_changed');
    }
    result ??= page;
    members.addAll(
      page.items.where((item) => !memory.deleted.contains(item.id)),
    );
    cursor = page.nextCursor;
  } while (cursor != null);
  return result.copyWith(items: members);
});

final familyMemberProvider = FutureProvider.autoDispose
    .family<FamilyMemberOut?, String>((ref, id) async {
      final account = ref.watch(authProvider).value?.id;
      final sensitive = ref.watch(sensitiveMemoryProvider);
      final memory = ref.watch(familyMemoryProvider);
      if (account == null ||
          sensitive.suppressed ||
          memory.deleted.contains(id)) {
        return null;
      }
      final store = ref.read(sessionStoreProvider);
      final result = await ref
          .watch(apiClientProvider)
          .getFamilyMembersApi()
          .getFamilyMember(
            memberId: id,
            headers: sensitiveAccountHeaders(store),
            extra: sensitiveAccountExtra(store),
          );
      return ref.mounted ? result.data : null;
    });

final familyChangesProvider =
    FutureProvider.autoDispose<List<TasteProfileChangeOut>>((ref) async {
      final account = ref.watch(authProvider).value?.id;
      final sensitive = ref.watch(sensitiveMemoryProvider);
      final memory = ref.watch(familyMemoryProvider);
      if (account == null || sensitive.suppressed) return [];
      final api = ref.watch(apiClientProvider).getFamilyMembersApi();
      final store = ref.read(sessionStoreProvider);
      final headers = sensitiveAccountHeaders(store);
      final extra = sensitiveAccountExtra(store);
      final snapshot = await ref.watch(familyMembersProvider.future);
      if (snapshot == null || snapshot.consentId == null || !ref.mounted) {
        return [];
      }
      final items = <TasteProfileChangeOut>[];
      String? cursor;
      do {
        final page = (await api.listFamilyMemberChanges(
          cursor: cursor,
          headers: headers,
          extra: extra,
        )).data!;
        if (!ref.mounted) {
          items.clear();
          return [];
        }
        items.addAll(
          page.items.where(
            (row) =>
                !memory.deleted.any((id) => row.field == 'family_members.$id'),
          ),
        );
        cursor = page.nextCursor;
      } while (cursor != null);
      // History pages have no authorization/snapshot metadata. Revalidate before
      // exposing accumulated decrypted rows, including remote deletion races.
      final verification = (await api.listFamilyMembers(
        limit: 1,
        headers: headers,
        extra: extra,
      )).data!;
      if (!ref.mounted) {
        items.clear();
        return [];
      }
      if (verification.consentId != snapshot.consentId ||
          verification.authorizationVersion != snapshot.authorizationVersion ||
          verification.profileVersion != snapshot.profileVersion ||
          verification.consentVersion != snapshot.consentVersion) {
        items.clear();
        ref.read(familyMemoryProvider.notifier).discardSnapshot();
        return [];
      }
      return items;
    });
