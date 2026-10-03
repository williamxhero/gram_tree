import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../api/api_client.dart';
import '../auth/auth_controller.dart';
import '../storage/local_store.dart';

/// Current-account read-through cache. Writes always go to the API first;
/// offline reads cannot replace server-owned recipe or measure data.
class PersonalMeasureRepository {
  PersonalMeasureRepository({
    required this.api,
    required this.store,
    required this.accountId,
  });

  final PersonalMeasuresApi api;
  final LocalStore store;
  final String accountId;
  bool offline = false;

  String get _key => 'personal_measures:v1:$accountId';

  List<PersonalMeasureOut> cached() {
    try {
      final encoded = store.getString(_key);
      if (encoded == null) return [];
      final value = jsonDecode(encoded);
      if (value is! Map || value['account_id'] != accountId) return [];
      final items = value['items'];
      if (items is! List) return [];
      return items
          .map(
            (item) => PersonalMeasureOut.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return [];
    }
  }

  Future<void> _cache(List<PersonalMeasureOut> values) => store.setString(
    _key,
    jsonEncode({
      'account_id': accountId,
      'items': [for (final value in values) value.toJson()],
    }),
  );

  Future<List<PersonalMeasureOut>> list() async {
    try {
      final values = <PersonalMeasureOut>[];
      String? cursor;
      do {
        final response = await api.listPersonalMeasures(cursor: cursor);
        final page = response.data ?? PagePersonalMeasureOut(items: const []);
        values.addAll(page.items);
        cursor = page.nextCursor;
      } while (cursor != null);
      await _cache(values);
      offline = false;
      return values;
    } catch (error) {
      if (ApiFailure.from(error).code != 'network') rethrow;
      offline = true;
      return cached();
    }
  }

  Future<PersonalMeasureOut> create(PersonalMeasureInput input) async {
    final response = await api.createPersonalMeasure(
      personalMeasureInput: input,
    );
    final value = response.data!;
    await _cache([...cached(), value]);
    offline = false;
    return value;
  }

  Future<PersonalMeasureOut> update(
    String id,
    PersonalMeasureUpdate input,
  ) async {
    final response = await api.updatePersonalMeasure(
      measureId: id,
      personalMeasureUpdate: input,
    );
    final value = response.data!;
    await _cache([
      for (final item in cached())
        if (item.id == id) value else item,
    ]);
    offline = false;
    return value;
  }

  Future<void> delete(String id) async {
    await api.deletePersonalMeasure(measureId: id);
    await _cache([
      for (final item in cached())
        if (item.id != id) item,
    ]);
    offline = false;
  }
}

final personalMeasureRepositoryProvider = Provider<PersonalMeasureRepository>((
  ref,
) {
  final accountId = ref.watch(authProvider).value?.id;
  if (accountId == null) throw StateError('个人量具需要登录');
  return PersonalMeasureRepository(
    api: ref.watch(apiClientProvider).getPersonalMeasuresApi(),
    store: ref.watch(localStoreProvider),
    accountId: accountId,
  );
});

final personalMeasuresProvider =
    FutureProvider.autoDispose<List<PersonalMeasureOut>>(
      (ref) => ref.watch(personalMeasureRepositoryProvider).list(),
    );
