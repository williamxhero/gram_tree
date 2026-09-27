import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// App 会用到的系统权限。每个权限的用途说明集中在这里，界面只按这里的文案显示。
///
/// 具体权限在用到它的子 SPEC 里接入（相机、相册：SPEC-002.2；麦克风、通知：SPEC-004.1），
/// 接入时还要在 AndroidManifest.xml、Info.plist 和 ios/Podfile 里打开对应权限。
enum AppPermission {
  camera('相机', '拍照', '用来拍这道菜的成品照，照片只存在你的记录里。'),
  photos('相册', '从相册选图', '用来从相册选一张菜谱截图或成品照。'),
  microphone('麦克风', '语音操作', '做菜时手上不方便，可以用说的来翻页、计时。'),
  notifications('通知', '计时提醒', '计时结束时提醒你，锁屏也能看到。');

  const AppPermission(this.label, this.feature, this.rationale);

  /// 权限名，如“相机”。
  final String label;

  /// 需要它的功能，如“拍照”。
  final String feature;

  /// 一句话用途说明，在调用系统申请之前显示。
  final String rationale;
}

enum PermissionState { granted, denied, permanentlyDenied }

/// 系统权限申请。手机用 permission_handler，网页和测试用替身。
abstract class PermissionService {
  Future<PermissionState> status(AppPermission permission);
  Future<PermissionState> request(AppPermission permission);
  Future<void> openSystemSettings();
}

class HandlerPermissionService implements PermissionService {
  const HandlerPermissionService();

  ph.Permission _of(AppPermission p) => switch (p) {
    AppPermission.camera => ph.Permission.camera,
    AppPermission.photos => ph.Permission.photos,
    AppPermission.microphone => ph.Permission.microphone,
    AppPermission.notifications => ph.Permission.notification,
  };

  PermissionState _map(ph.PermissionStatus s) => switch (s) {
    ph.PermissionStatus.granted ||
    ph.PermissionStatus.limited ||
    ph.PermissionStatus.provisional => PermissionState.granted,
    ph.PermissionStatus.permanentlyDenied ||
    ph.PermissionStatus.restricted => PermissionState.permanentlyDenied,
    _ => PermissionState.denied,
  };

  @override
  Future<PermissionState> status(AppPermission permission) async =>
      _map(await _of(permission).status);

  @override
  Future<PermissionState> request(AppPermission permission) async =>
      _map(await _of(permission).request());

  @override
  Future<void> openSystemSettings() => ph.openAppSettings();
}

/// 网页版替身：浏览器在真正使用时自己会问，这里一律当作已允许。
class WebPermissionService implements PermissionService {
  const WebPermissionService();

  @override
  Future<PermissionState> status(AppPermission permission) async =>
      PermissionState.granted;

  @override
  Future<PermissionState> request(AppPermission permission) async =>
      PermissionState.granted;

  @override
  Future<void> openSystemSettings() async {}
}

final permissionServiceProvider = Provider<PermissionService>(
  (ref) =>
      kIsWeb ? const WebPermissionService() : const HandlerPermissionService(),
);
