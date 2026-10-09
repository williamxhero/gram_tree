import '../recipes/offline_recipe_repository.dart'
    show recipeVersionWriteRegistration;
import '../recipes/personal_measure_write.dart'
    show personalMeasureWriteRegistration;

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
