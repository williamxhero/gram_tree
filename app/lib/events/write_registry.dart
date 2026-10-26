import '../recipes/offline_recipe_repository.dart'
    show recipeVersionWriteRegistration;
import '../recipes/personal_measure_write.dart'
    show personalMeasureWriteRegistration;

const recordImprovementWriteType = 'record_improvement.save';

/// Business modules register once and use the existing event queue/uploader.
/// Resource IDs in payloads are not delivery IDs in dependencies.
enum WriteConflictRule { appendOnly, fieldLastWriteWithHistory, preserveBoth }

class WriteRegistration {
  const WriteRegistration({
    required this.type,
    required this.conflictRule,
    required this.validate,
    required this.applyResult,
  });

  final String type;
  final WriteConflictRule conflictRule;
  final void Function(Map<String, dynamic> payload) validate;

  /// Pure local result application, persisted atomically with confirmation.
  /// Must retain business content; must not perform network I/O or delete it.
  final Map<String, dynamic>? Function(
    Map<String, dynamic>? businessRecord,
    Map<String, dynamic> result,
  )
  applyResult;
}

class WriteRegistry {
  WriteRegistry() {
    register(recipeVersionWriteRegistration);
    register(personalMeasureWriteRegistration);
    register(
      WriteRegistration(
        type: 'cooking_record.create',
        conflictRule: WriteConflictRule.appendOnly,
        validate: (payload) {
          final record = payload['record'];
          if (record is! Map ||
              record['client_id'] is! String ||
              record['source'] is! String) {
            throw ArgumentError('Invalid cooking record');
          }
        },
        applyResult: (record, result) => record,
      ),
    );
    register(
      WriteRegistration(
        type: recordImprovementWriteType,
        conflictRule: WriteConflictRule.preserveBoth,
        validate: (payload) {
          const required = ['recipe_id', 'source_version_id'];
          if (required.any((key) => payload[key] is! String) ||
              (payload['record_id'] is! String &&
                  payload['record_write_id'] is! String) ||
              payload['change_note'] is! String ||
              (payload['microadjust_choice'] != null &&
                  payload['microadjust_choice'] != 'branch' &&
                  payload['microadjust_choice'] != 'taste') ||
              (payload['expected_profile_version'] != null &&
                  payload['expected_profile_version'] is! int)) {
            throw ArgumentError('Invalid record improvement');
          }
        },
        applyResult: (record, result) {
          if (record == null ||
              result['resource_type'] != 'record.improvement') {
            throw StateError(
              'Record improvement confirmation has no retained intent',
            );
          }
          final values = result['values'] as Map?;
          if (values?['response'] is! Map && values?['preview'] is! Map) {
            throw StateError('Record improvement confirmation has no result');
          }
          return {
            ...record,
            if (values?['response'] is Map)
              'response': Map<String, dynamic>.from(values!['response'] as Map),
            if (values?['preview'] is Map)
              'preview': Map<String, dynamic>.from(values!['preview'] as Map),
          };
        },
      ),
    );
    register(
      WriteRegistration(
        type: 'experience.event',
        conflictRule: WriteConflictRule.appendOnly,
        validate: (payload) {
          if (payload['event_type'] is! String ||
              payload['type_version'] is! int ||
              payload['device_id'] is! String ||
              payload['app_version'] is! String) {
            throw ArgumentError('Invalid experience event');
          }
        },
        applyResult: (record, result) => record,
      ),
    );
  }

  final Map<String, WriteRegistration> _types = {};

  void register(WriteRegistration registration) {
    if (_types.containsKey(registration.type)) {
      throw StateError('Write type already registered: ${registration.type}');
    }
    _types[registration.type] = registration;
  }

  WriteRegistration require(String type) {
    final registration = _types[type];
    if (registration == null) throw ArgumentError('Unknown write type: $type');
    return registration;
  }
}
