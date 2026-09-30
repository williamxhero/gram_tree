import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/features/recipes/recipe_photo_panel.dart';
import 'package:gram_tree/l10n/app_localizations.dart';
import 'package:gram_tree/platform/permissions.dart';
import 'package:gram_tree/platform/recipe_photo.dart';
import 'package:gram_tree/platform/recipe_photo_api.dart';
import 'package:gram_tree/privacy/policy.dart';
import 'package:gram_tree/storage/local_store.dart';
import 'package:image/image.dart' as img;

class _FakePermissions implements PermissionService {
  _FakePermissions({this.answer = PermissionState.granted});

  final PermissionState answer;
  final requested = <AppPermission>[];

  @override
  Future<PermissionState> status(AppPermission permission) async =>
      PermissionState.denied;

  @override
  Future<PermissionState> request(AppPermission permission) async {
    requested.add(permission);
    return answer;
  }

  @override
  Future<void> openSystemSettings() async {}
}

Map<String, String> _consentedStore() => {
  'consent_records':
      '[{"id":"00000000-0000-4000-8000-000000000001","kind":"terms","version":"$termsVersion","agree":true,"occurred_at":"2026-09-27T00:00:00.000Z","device_id":"device-test","uploaded":true},{"id":"00000000-0000-4000-8000-000000000002","kind":"privacy","version":"$privacyVersion","agree":true,"occurred_at":"2026-09-27T00:00:00.000Z","device_id":"device-test","uploaded":true}]',
  'device_id': 'device-test',
};

class _FakePicker implements RecipePhotoPicker {
  _FakePicker(this.asset);

  final RecipePhotoAsset? asset;
  int calls = 0;

  @override
  Future<RecipePhotoAsset?> pick(RecipePhotoSource source) async {
    calls++;
    return asset;
  }
}

class _FakeProcessor implements RecipePhotoProcessor {
  _FakeProcessor(this.result);

  final ProcessedRecipePhoto result;
  int calls = 0;

  @override
  ProcessedRecipePhoto process(RecipePhotoAsset asset) {
    calls++;
    return result;
  }
}

class _FakePhotoApi implements RecipePhotoApi {
  _FakePhotoApi({this.error});

  final Object? error;
  int calls = 0;
  ProcessedRecipePhoto? photo;

  @override
  Future<RecipePhotoUploadResult> upload({
    required String? recipeId,
    required ProcessedRecipePhoto photo,
  }) async {
    calls++;
    this.photo = photo;
    if (error != null) throw error!;
    return const RecipePhotoUploadResult(
      id: '0b9c6d4e-8f2a-4c3b-9d1e-2f3a4b5c6d7e',
      versionId: null,
      contentType: 'image/jpeg',
      byteSize: 12,
      width: 10,
      height: 10,
      url: '/private-image',
      expiresInSeconds: 900,
    );
  }
}

Uint8List _jpeg() {
  final image = img.Image(width: 4, height: 4);
  return Uint8List.fromList(img.encodeJpg(image));
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required RecipePhotoPicker picker,
  required RecipePhotoProcessor processor,
  required RecipePhotoApi api,
  _FakePermissions? permissions,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(
          MemoryLocalStore(_consentedStore()),
        ),
        recipePhotoPickerProvider.overrideWithValue(picker),
        recipePhotoProcessorProvider.overrideWithValue(processor),
        recipePhotoApiProvider.overrideWithValue(api),
        if (permissions != null)
          permissionServiceProvider.overrideWithValue(permissions),
      ],
      child: const MaterialApp(
        locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: RecipePhotoPanel(recipeId: 'recipe-id')),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('选择、处理、上传成功会显示完整状态结果', (tester) async {
    final picker = _FakePicker(
      RecipePhotoAsset(
        bytes: _jpeg(),
        filename: 'dish.jpg',
        contentType: 'image/jpeg',
      ),
    );
    final processor = _FakeProcessor(
      ProcessedRecipePhoto(
        bytes: _jpeg(),
        filename: 'recipe-photo.jpg',
        contentType: 'image/jpeg',
      ),
    );
    final api = _FakePhotoApi();
    await _pumpPanel(tester, picker: picker, processor: processor, api: api);

    await tester.tap(find.text('从相册选图'));
    await tester.pumpAndSettle();

    expect(picker.calls, 1);
    expect(processor.calls, 1);
    expect(api.calls, 1);
    expect(find.text('已上传，图片会以短期私有地址读取。'), findsOneWidget);
  });

  testWidgets('上传失败只影响图片功能并显示失败状态', (tester) async {
    final picker = _FakePicker(
      RecipePhotoAsset(
        bytes: _jpeg(),
        filename: 'dish.jpg',
        contentType: 'image/jpeg',
      ),
    );
    final processor = _FakeProcessor(
      ProcessedRecipePhoto(
        bytes: _jpeg(),
        filename: 'recipe-photo.jpg',
        contentType: 'image/jpeg',
      ),
    );
    final api = _FakePhotoApi(error: StateError('network'));
    await _pumpPanel(tester, picker: picker, processor: processor, api: api);

    await tester.tap(find.text('从相册选图'));
    await tester.pumpAndSettle();

    expect(find.text('图片上传失败，请稍后重试。'), findsOneWidget);
    expect(find.text('从相册选图'), findsOneWidget);
  });

  testWidgets('相机权限拒绝显示不可用状态而不调用上传', (tester) async {
    final picker = _FakePicker(null);
    final processor = _FakeProcessor(
      ProcessedRecipePhoto(
        bytes: _jpeg(),
        filename: 'recipe-photo.jpg',
        contentType: 'image/jpeg',
      ),
    );
    final api = _FakePhotoApi();
    final permissions = _FakePermissions(answer: PermissionState.denied);
    await _pumpPanel(
      tester,
      picker: picker,
      processor: processor,
      api: api,
      permissions: permissions,
    );

    await tester.tap(find.text('拍照'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();

    expect(permissions.requested, [AppPermission.camera]);
    expect(api.calls, 0);
    expect(find.text('拍照不可用'), findsOneWidget);
    expect(find.text('从相册选图'), findsOneWidget);
  });
}
