import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../platform/permissions.dart';
import '../../platform/recipe_photo.dart';
import '../../platform/recipe_photo_api.dart';
import '../../widgets/permission_request.dart';

/// The complete photo-selection lifecycle, independent of the recipe editor.
enum RecipePhotoPanelStatus {
  idle,
  picking,
  processing,
  uploading,
  success,
  error,
}

class RecipePhotoPanel extends ConsumerStatefulWidget {
  const RecipePhotoPanel({super.key, this.recipeId, this.onUploaded});

  /// Null means the image is staged and can be attached to a future version.
  final String? recipeId;
  final ValueChanged<RecipePhotoUploadResult>? onUploaded;

  @override
  ConsumerState<RecipePhotoPanel> createState() => _RecipePhotoPanelState();
}

class _RecipePhotoPanelState extends ConsumerState<RecipePhotoPanel> {
  RecipePhotoPanelStatus _status = RecipePhotoPanelStatus.idle;
  AppPermission? _deniedPermission;
  String? _error;
  RecipePhotoUploadResult? _uploaded;
  Uint8List? _preview;

  bool get _busy =>
      _status == RecipePhotoPanelStatus.picking ||
      _status == RecipePhotoPanelStatus.processing ||
      _status == RecipePhotoPanelStatus.uploading;

  Future<bool> _allow(RecipePhotoSource source) async {
    if (kIsWeb) return true;
    // Android 13/API 34's image_picker uses the system Photo Picker. It does
    // not need READ_MEDIA_IMAGES, so do not request a blanket storage/photos
    // permission here. iOS still needs its Photos rationale when selecting.
    if (source == RecipePhotoSource.gallery &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return true;
    }
    final permission = source == RecipePhotoSource.camera
        ? AppPermission.camera
        : AppPermission.photos;
    final state = await requestPermission(context, ref, permission);
    if (state == PermissionState.granted) return true;
    if (!mounted) return false;
    setState(() {
      _deniedPermission = permission;
      _status = RecipePhotoPanelStatus.idle;
    });
    return false;
  }

  Future<void> _choose(RecipePhotoSource source) async {
    if (_busy || !await _allow(source)) return;
    setState(() {
      _status = RecipePhotoPanelStatus.picking;
      _error = null;
      _deniedPermission = null;
    });
    try {
      final picked = await ref.read(recipePhotoPickerProvider).pick(source);
      if (!mounted || picked == null) {
        if (mounted) setState(() => _status = RecipePhotoPanelStatus.idle);
        return;
      }
      setState(() {
        _status = RecipePhotoPanelStatus.processing;
        _preview = picked.bytes;
      });
      final processed = ref.read(recipePhotoProcessorProvider).process(picked);
      if (!mounted) return;
      setState(() => _status = RecipePhotoPanelStatus.uploading);
      final result = await ref
          .read(recipePhotoApiProvider)
          .upload(recipeId: widget.recipeId, photo: processed);
      if (!mounted) return;
      setState(() {
        _status = RecipePhotoPanelStatus.success;
        _uploaded = result;
        _error = null;
      });
      widget.onUploaded?.call(result);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = RecipePhotoPanelStatus.error;
        _error = _message(error);
      });
    }
  }

  String _message(Object error) {
    if (error is RecipePhotoProcessingException) return error.message;
    return '图片上传失败，请稍后重试。';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('成品图', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              widget.recipeId == null
                  ? '先选图，保存菜谱时会把它放进第 1 版。'
                  : '照片会生成新的菜谱版本，不会改动旧版本。',
              style: theme.textTheme.bodyMedium,
            ),
            if (_preview != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _preview!,
                  height: 180,
                  fit: BoxFit.cover,
                  semanticLabel: '已选择的成品图',
                ),
              ),
            ],
            if (_busy) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _status == RecipePhotoPanelStatus.uploading ? null : 1,
              ),
              const SizedBox(height: 6),
              Text(_statusLabel, style: theme.textTheme.bodySmall),
            ],
            if (_status == RecipePhotoPanelStatus.success &&
                _uploaded != null) ...[
              const SizedBox(height: 8),
              Text(
                '已上传，图片会以短期私有地址读取。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .extension<GramTreeColors>()
                      ?.verified,
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            if (_deniedPermission != null) ...[
              const SizedBox(height: 12),
              PermissionDeniedNotice(permission: _deniedPermission!),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _choose(RecipePhotoSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('拍照'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _choose(RecipePhotoSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('从相册选图'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String get _statusLabel => switch (_status) {
    RecipePhotoPanelStatus.picking => '正在打开照片选择器…',
    RecipePhotoPanelStatus.processing => '正在压缩并清除照片元数据…',
    RecipePhotoPanelStatus.uploading => '正在安全上传…',
    _ => '',
  };
}
