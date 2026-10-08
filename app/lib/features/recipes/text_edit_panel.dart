import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

/// Both owned entry points use the same explicit preview/confirmation surface.
class TextEditPanel extends ConsumerStatefulWidget {
  const TextEditPanel({
    super.key,
    this.recipeId,
    this.baseVersionId,
    this.generationRequestId,
    this.manualEdits = false,
    required this.onSaved,
  });
  final String? recipeId;
  final String? baseVersionId;
  final String? generationRequestId;
  final bool manualEdits;
  final Future<void> Function(RecipeDetail) onSaved;

  @override
  ConsumerState<TextEditPanel> createState() => _TextEditPanelState();
}

class _TextEditPanelState extends ConsumerState<TextEditPanel> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('一句话改文字', style: Theme.of(context).textTheme.titleMedium),
      const Text('只支持改文字；其他修改暂未支持。确认前不会保存。'),
      if (widget.manualEdits)
        const Text('当前有未保存的表单修改，请先手动保存，再请求文字修改。'),
      TextField(
        key: const ValueKey('text-edit-input'),
        controller: _text,
        enabled: !widget.manualEdits,
        maxLength: 1000,
        minLines: 1,
        maxLines: 4,
        decoration: const InputDecoration(labelText: '想改哪段文字？'),
      ),
    ],
  );
}
