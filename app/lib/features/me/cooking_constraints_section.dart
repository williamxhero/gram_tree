import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';
import '../../app/theme.dart';
import '../../ui_protocol/source_mark.dart';
import '../../ui_protocol/source_types.dart';
import '../../ui_protocol/components/component_scaffold.dart';
import 'taste_profile_data.dart';

final cookingConstraintsProvider =
    FutureProvider.autoDispose<CookingConstraintsOut>((ref) async {
      final account = ref.watch(authProvider).value?.id;
      if (account == null) throw StateError('做菜约束需要登录');
      return (await ref
              .watch(apiClientProvider)
              .getTasteProfileApi()
              .getCookingConstraints())
          .data!;
    });

const _days = {'weekday': '工作日', 'weekend': '周末'};
const _meals = {'breakfast': '早餐', 'lunch': '午餐', 'dinner': '晚餐'};
const _dishes = {
  'meat': '荤菜',
  'vegetable': '素菜',
  'soup': '汤',
  'staple': '主食',
  'other': '其他',
};

String cookingConstraintsHistoryLabel(Object value) {
  if (value is! Map) return '做菜约束';
  final parts = <String>[];
  final household = value['household_servings'];
  if (household != null) parts.add('$household 人');
  final equipment = value['equipment'];
  if (equipment is List && equipment.isNotEmpty) {
    parts.add('${equipment.length} 件厨具');
  }
  final times = value['meal_times'];
  if (times is List && times.isNotEmpty) parts.add('${times.length} 餐时间');
  final templates = value['meal_templates'];
  if (templates is List && templates.isNotEmpty) {
    parts.add('${templates.length} 餐模板');
  }
  return parts.isEmpty ? '未设置' : parts.join('、');
}

class CookingConstraintsSection extends ConsumerStatefulWidget {
  const CookingConstraintsSection({super.key});

  @override
  ConsumerState<CookingConstraintsSection> createState() =>
      _CookingConstraintsSectionState();
}

class _CookingConstraintsSectionState
    extends ConsumerState<CookingConstraintsSection> {
  bool _busy = false;

  Future<void> _save(CookingConstraints values) async {
    final account = ref.read(authProvider).value?.id;
    if (_busy || account == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(apiClientProvider)
          .getTasteProfileApi()
          .replaceCookingConstraints(cookingConstraints: values);
      if (!mounted || ref.read(authProvider).value?.id != account) return;
      ref.invalidate(cookingConstraintsProvider);
      ref.invalidate(tasteProfileProvider);
      ref.invalidate(tasteProfileChangesProvider);
    } catch (error) {
      if (mounted && ref.read(authProvider).value?.id == account) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ApiFailure.from(error).message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit(CookingConstraintsOut current) async {
    final account = ref.read(authProvider).value?.id;
    final values = await showDialog<CookingConstraints>(
      context: context,
      builder: (_) => _ConstraintsDialog(current: current),
    );
    if (values != null &&
        mounted &&
        ref.read(authProvider).value?.id == account) {
      await _save(values);
    }
  }

  Future<void> _clear() async {
    final account = ref.read(authProvider).value?.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除做菜约束？'),
        content: const Text('人数、厨具、时间和餐型恢复为空。菜谱原始版本不会改变。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const ValueKey('cooking-constraints-clear-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清除'),
          ),
        ],
      ),
    );
    if (confirmed == true &&
        mounted &&
        ref.read(authProvider).value?.id == account) {
      await _save(CookingConstraints());
    }
  }

  @override
  Widget build(BuildContext context) => ref
      .watch(cookingConstraintsProvider)
      .when(
        loading: () => const LinearProgressIndicator(),
        error: (error, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('做菜约束暂时无法读取'),
            TextButton(
              onPressed: () => ref.invalidate(cookingConstraintsProvider),
              child: const Text('重试'),
            ),
          ],
        ),
        data: (current) {
          final values = current.constraints;
          final names = {
            for (final item in current.equipmentVocabulary) item.id: item.label,
          };
          return ComponentCard(
            key: const ValueKey('cooking-constraints'),
            detail: ComponentDescriptorDetailEnum.standard,
            conclusion: Text(
              values.householdServings == null
                  ? '人数未设置，菜谱沿用作者份数'
                  : '家庭默认：${values.householdServings} 人',
            ),
            conclusionSemanticsText: '做菜约束',
            standardExtra: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('做菜约束 · 仅作为家庭默认，不修改作者菜谱'),
                const SourceMark(
                  key: ValueKey('cooking-constraints-why'),
                  sourceType: sourceTypeAuthorFilled,
                  componentId: 'cooking-constraints',
                  value: '家庭做菜约束',
                  basisText: '来自你手动填写；未设置的项目为空。人数只用于新一次查看的默认份数，本次手动选择优先，作者配方和原始版本不变。厨具、时间与餐型仅保存，不在这里推荐或改写菜谱。',
                  required: false,
                  neutral: true,
                  feedbackEnabled: false,
                  showWhenAuthorFilled: true,
                  labelOverride: '你手动设置',
                  onAction: null,
                ),
                Text(
                  values.equipment?.isNotEmpty == true
                      ? '厨具：${values.equipment!.map((id) => names[id] ?? id).join('、')}'
                      : '厨具未设置',
                ),
                if (values.mealTimes?.isEmpty != false) const Text('各餐可用时间未设置'),
                for (final slot in values.mealTimes ?? <CookingMealTime>[])
                  Text(
                    '${_days[slot.dayType.value]}${_meals[slot.meal.value]}：${slot.minutes} 分钟',
                  ),
                if (values.mealTemplates?.isEmpty != false) const Text('餐型未设置'),
                for (final slot
                    in values.mealTemplates ?? <CookingMealTemplate>[])
                  Text(
                    '${_days[slot.dayType.value]}${_meals[slot.meal.value]}：${slot.dishCount} 道（${slot.composition.map((type) => _dishes[type.value]).join('、')}）',
                  ),
                Wrap(
                  spacing: 12,
                  children: [
                    OutlinedButton(
                      key: const ValueKey('cooking-constraints-edit'),
                      onPressed: _busy ? null : () => _edit(current),
                      child: const Text('设置做菜约束'),
                    ),
                    TextButton(
                      key: const ValueKey('cooking-constraints-clear'),
                      onPressed: _busy ? null : _clear,
                      child: const Text('清除做菜约束'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
}

class _ConstraintsDialog extends StatefulWidget {
  const _ConstraintsDialog({required this.current});
  final CookingConstraintsOut current;

  @override
  State<_ConstraintsDialog> createState() => _ConstraintsDialogState();
}

class _ConstraintsDialogState extends State<_ConstraintsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _household;
  final _times = <String, TextEditingController>{};
  final _templates = <String, TextEditingController>{};
  final _equipment = <String>{};

  @override
  void initState() {
    super.initState();
    final values = widget.current.constraints;
    _household = TextEditingController(
      text: values.householdServings?.toString() ?? '',
    );
    _equipment.addAll(values.equipment ?? []);
    for (final day in _days.keys) {
      for (final meal in _meals.keys) {
        final key = '$day-$meal';
        _times[key] = TextEditingController();
        _templates[key] = TextEditingController();
      }
    }
    for (final slot in values.mealTimes ?? <CookingMealTime>[]) {
      _times['${slot.dayType.value}-${slot.meal.value}']!.text = slot.minutes
          .toString();
    }
    for (final slot in values.mealTemplates ?? <CookingMealTemplate>[]) {
      _templates['${slot.dayType.value}-${slot.meal.value}']!.text = slot
          .composition
          .map((type) => _dishes[type.value])
          .join(',');
    }
  }

  @override
  void dispose() {
    _household.dispose();
    for (final controller in [..._times.values, ..._templates.values]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _integer(String? text, int minimum, int maximum) {
    if (text == null || text.trim().isEmpty) return null;
    final value = int.tryParse(text.trim());
    return value == null || value < minimum || value > maximum
        ? '请输入 $minimum～$maximum 的整数；留空清除'
        : null;
  }

  List<String> _composition(String text) => text
      .split(RegExp('[,，、]'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final times = <CookingMealTime>[];
    final templates = <CookingMealTemplate>[];
    for (final day in _days.keys) {
      for (final meal in _meals.keys) {
        final key = '$day-$meal';
        final minutes = int.tryParse(_times[key]!.text.trim());
        if (minutes != null) {
          times.add(
            CookingMealTime.fromJson({
              'day_type': day,
              'meal': meal,
              'minutes': minutes,
            }),
          );
        }
        final composition = _composition(_templates[key]!.text);
        if (composition.isNotEmpty) {
          templates.add(
            CookingMealTemplate.fromJson({
              'day_type': day,
              'meal': meal,
              'dish_count': composition.length,
              'composition': composition
                  .map(
                    (label) => _dishes.entries
                        .singleWhere((item) => item.value == label)
                        .key,
                  )
                  .toList(),
            }),
          );
        }
      }
    }
    Navigator.pop(
      context,
      CookingConstraints(
        householdServings: int.tryParse(_household.text.trim()),
        equipment: _equipment.toList()..sort(),
        mealTimes: times,
        mealTemplates: templates,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('做菜约束'),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const ValueKey('household-servings'),
                controller: _household,
                style: GramTreeColors.of(context)
                    .numberStyle(Theme.of(context).textTheme.bodyLarge!),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '家庭人数（留空沿用作者份数）'),
                validator: (text) => _integer(
                  text,
                  widget.current.servingsMin,
                  widget.current.servingsMax,
                ),
              ),
              const SizedBox(height: 12),
              const Text('家里有哪些厨具'),
              for (final item in widget.current.equipmentVocabulary)
                CheckboxListTile(
                  key: ValueKey('equipment-${item.id}'),
                  title: Text(item.label),
                  value: _equipment.contains(item.id),
                  onChanged: (checked) => setState(() {
                    if (checked == true) {
                      _equipment.add(item.id);
                    } else {
                      _equipment.remove(item.id);
                    }
                  }),
                ),
              const Text('每餐时间与餐型（留空清除）'),
              const Text('菜型用逗号分隔：荤菜、素菜、汤、主食、其他。每项代表一道，可重复。'),
              for (final day in _days.entries)
                for (final meal in _meals.entries) ...[
                  const SizedBox(height: 12),
                  Text('${day.value}${meal.value}'),
                  TextFormField(
                    key: ValueKey('meal-minutes-${day.key}-${meal.key}'),
                    controller: _times['${day.key}-${meal.key}'],
                    style: GramTreeColors.of(context)
                        .numberStyle(Theme.of(context).textTheme.bodyLarge!),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '可用分钟'),
                    validator: (text) => _integer(text, 1, 1440),
                  ),
                  TextFormField(
                    key: ValueKey('meal-template-${day.key}-${meal.key}'),
                    controller: _templates['${day.key}-${meal.key}'],
                    decoration: const InputDecoration(
                      labelText: '菜型组合，例如 荤菜,素菜,汤',
                    ),
                    validator: (text) {
                      final values = _composition(text ?? '');
                      return values.length > 20 ||
                              values.any(
                                (label) => !_dishes.containsValue(label),
                              )
                          ? '请用上述菜型组合，最多 20 道'
                          : null;
                    },
                  ),
                ],
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        key: const ValueKey('cooking-constraints-save'),
        onPressed: _submit,
        child: const Text('保存'),
      ),
    ],
  );
}
