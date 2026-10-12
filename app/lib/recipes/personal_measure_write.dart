import '../events/write_registry.dart';

const personalMeasureWriteType = 'personal_measure.change';

final personalMeasureWriteRegistration = WriteRegistration(
  type: personalMeasureWriteType,
  conflictRule: WriteConflictRule.fieldLastWriteWithHistory,
  validate: (payload) {
    if (payload['resource_id'] is! String ||
        !['create', 'update', 'delete'].contains(payload['action']) ||
        payload['fields'] is! Map ||
        (payload['fields'] as Map).isEmpty) {
      throw ArgumentError('Invalid personal measure write');
    }
    for (final field in (payload['fields'] as Map).values) {
      if (field is! Map ||
          !field.containsKey('value') ||
          field['device_time'] is! String ||
          !DateTime.parse(field['device_time'] as String).isUtc) {
        throw ArgumentError('Measure edits need UTC field timestamps');
      }
    }
  },
  applyResult: (record, result) {
    final values = result['values'];
    if (values is! Map || values['id'] != result['resource_id']) {
      throw StateError('Missing authoritative measure projection');
    }
    return {...?record, 'projection': Map<String, dynamic>.from(values)};
  },
);
