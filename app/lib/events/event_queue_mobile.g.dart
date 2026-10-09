// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_queue_mobile.dart';

// ignore_for_file: type=lint
class $QueuedEventsTable extends QueuedEvents
    with TableInfo<$QueuedEventsTable, QueuedEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QueuedEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeVersionMeta = const VerificationMeta(
    'typeVersion',
  );
  @override
  late final GeneratedColumn<int> typeVersion = GeneratedColumn<int>(
    'type_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceTimeMeta = const VerificationMeta(
    'deviceTime',
  );
  @override
  late final GeneratedColumn<DateTime> deviceTime = GeneratedColumn<DateTime>(
    'device_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appVersionMeta = const VerificationMeta(
    'appVersion',
  );
  @override
  late final GeneratedColumn<String> appVersion = GeneratedColumn<String>(
    'app_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correlationJsonMeta = const VerificationMeta(
    'correlationJson',
  );
  @override
  late final GeneratedColumn<String> correlationJson = GeneratedColumn<String>(
    'correlation_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentJsonMeta = const VerificationMeta(
    'contentJson',
  );
  @override
  late final GeneratedColumn<String> contentJson = GeneratedColumn<String>(
    'content_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _envelopeJsonMeta = const VerificationMeta(
    'envelopeJson',
  );
  @override
  late final GeneratedColumn<String> envelopeJson = GeneratedColumn<String>(
    'envelope_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enqueueSequenceMeta = const VerificationMeta(
    'enqueueSequence',
  );
  @override
  late final GeneratedColumn<int> enqueueSequence = GeneratedColumn<int>(
    'enqueue_sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deliveryStateMeta = const VerificationMeta(
    'deliveryState',
  );
  @override
  late final GeneratedColumn<String> deliveryState = GeneratedColumn<String>(
    'delivery_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('quarantined'),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _reasonCodeMeta = const VerificationMeta(
    'reasonCode',
  );
  @override
  late final GeneratedColumn<String> reasonCode = GeneratedColumn<String>(
    'reason_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _resultJsonMeta = const VerificationMeta(
    'resultJson',
  );
  @override
  late final GeneratedColumn<String> resultJson = GeneratedColumn<String>(
    'result_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _businessJsonMeta = const VerificationMeta(
    'businessJson',
  );
  @override
  late final GeneratedColumn<String> businessJson = GeneratedColumn<String>(
    'business_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confirmedAtMeta = const VerificationMeta(
    'confirmedAt',
  );
  @override
  late final GeneratedColumn<DateTime> confirmedAt = GeneratedColumn<DateTime>(
    'confirmed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eventType,
    typeVersion,
    deviceId,
    deviceTime,
    appVersion,
    correlationJson,
    contentJson,
    ownerId,
    envelopeJson,
    enqueueSequence,
    deliveryState,
    attempts,
    reasonCode,
    nextAttemptAt,
    resultJson,
    businessJson,
    confirmedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'queued_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<QueuedEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('type_version')) {
      context.handle(
        _typeVersionMeta,
        typeVersion.isAcceptableOrUnknown(
          data['type_version']!,
          _typeVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_typeVersionMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('device_time')) {
      context.handle(
        _deviceTimeMeta,
        deviceTime.isAcceptableOrUnknown(data['device_time']!, _deviceTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceTimeMeta);
    }
    if (data.containsKey('app_version')) {
      context.handle(
        _appVersionMeta,
        appVersion.isAcceptableOrUnknown(data['app_version']!, _appVersionMeta),
      );
    } else if (isInserting) {
      context.missing(_appVersionMeta);
    }
    if (data.containsKey('correlation_json')) {
      context.handle(
        _correlationJsonMeta,
        correlationJson.isAcceptableOrUnknown(
          data['correlation_json']!,
          _correlationJsonMeta,
        ),
      );
    }
    if (data.containsKey('content_json')) {
      context.handle(
        _contentJsonMeta,
        contentJson.isAcceptableOrUnknown(
          data['content_json']!,
          _contentJsonMeta,
        ),
      );
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    }
    if (data.containsKey('envelope_json')) {
      context.handle(
        _envelopeJsonMeta,
        envelopeJson.isAcceptableOrUnknown(
          data['envelope_json']!,
          _envelopeJsonMeta,
        ),
      );
    }
    if (data.containsKey('enqueue_sequence')) {
      context.handle(
        _enqueueSequenceMeta,
        enqueueSequence.isAcceptableOrUnknown(
          data['enqueue_sequence']!,
          _enqueueSequenceMeta,
        ),
      );
    }
    if (data.containsKey('delivery_state')) {
      context.handle(
        _deliveryStateMeta,
        deliveryState.isAcceptableOrUnknown(
          data['delivery_state']!,
          _deliveryStateMeta,
        ),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('reason_code')) {
      context.handle(
        _reasonCodeMeta,
        reasonCode.isAcceptableOrUnknown(data['reason_code']!, _reasonCodeMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('result_json')) {
      context.handle(
        _resultJsonMeta,
        resultJson.isAcceptableOrUnknown(data['result_json']!, _resultJsonMeta),
      );
    }
    if (data.containsKey('business_json')) {
      context.handle(
        _businessJsonMeta,
        businessJson.isAcceptableOrUnknown(
          data['business_json']!,
          _businessJsonMeta,
        ),
      );
    }
    if (data.containsKey('confirmed_at')) {
      context.handle(
        _confirmedAtMeta,
        confirmedAt.isAcceptableOrUnknown(
          data['confirmed_at']!,
          _confirmedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QueuedEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueuedEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      typeVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type_version'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      deviceTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}device_time'],
      )!,
      appVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_version'],
      )!,
      correlationJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}correlation_json'],
      ),
      contentJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_json'],
      ),
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      ),
      envelopeJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}envelope_json'],
      ),
      enqueueSequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}enqueue_sequence'],
      )!,
      deliveryState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delivery_state'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      reasonCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason_code'],
      ),
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      resultJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_json'],
      ),
      businessJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_json'],
      ),
      confirmedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}confirmed_at'],
      ),
    );
  }

  @override
  $QueuedEventsTable createAlias(String alias) {
    return $QueuedEventsTable(attachedDatabase, alias);
  }
}

class QueuedEventRow extends DataClass implements Insertable<QueuedEventRow> {
  final String id;
  final String eventType;
  final int typeVersion;
  final String deviceId;
  final DateTime deviceTime;
  final String appVersion;
  final String? correlationJson;
  final String? contentJson;
  final String? ownerId;
  final String? envelopeJson;
  final int enqueueSequence;
  final String deliveryState;
  final int attempts;
  final String? reasonCode;
  final DateTime? nextAttemptAt;
  final String? resultJson;
  final String? businessJson;
  final DateTime? confirmedAt;
  const QueuedEventRow({
    required this.id,
    required this.eventType,
    required this.typeVersion,
    required this.deviceId,
    required this.deviceTime,
    required this.appVersion,
    this.correlationJson,
    this.contentJson,
    this.ownerId,
    this.envelopeJson,
    required this.enqueueSequence,
    required this.deliveryState,
    required this.attempts,
    this.reasonCode,
    this.nextAttemptAt,
    this.resultJson,
    this.businessJson,
    this.confirmedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['event_type'] = Variable<String>(eventType);
    map['type_version'] = Variable<int>(typeVersion);
    map['device_id'] = Variable<String>(deviceId);
    map['device_time'] = Variable<DateTime>(deviceTime);
    map['app_version'] = Variable<String>(appVersion);
    if (!nullToAbsent || correlationJson != null) {
      map['correlation_json'] = Variable<String>(correlationJson);
    }
    if (!nullToAbsent || contentJson != null) {
      map['content_json'] = Variable<String>(contentJson);
    }
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<String>(ownerId);
    }
    if (!nullToAbsent || envelopeJson != null) {
      map['envelope_json'] = Variable<String>(envelopeJson);
    }
    map['enqueue_sequence'] = Variable<int>(enqueueSequence);
    map['delivery_state'] = Variable<String>(deliveryState);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || reasonCode != null) {
      map['reason_code'] = Variable<String>(reasonCode);
    }
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    if (!nullToAbsent || resultJson != null) {
      map['result_json'] = Variable<String>(resultJson);
    }
    if (!nullToAbsent || businessJson != null) {
      map['business_json'] = Variable<String>(businessJson);
    }
    if (!nullToAbsent || confirmedAt != null) {
      map['confirmed_at'] = Variable<DateTime>(confirmedAt);
    }
    return map;
  }

  QueuedEventsCompanion toCompanion(bool nullToAbsent) {
    return QueuedEventsCompanion(
      id: Value(id),
      eventType: Value(eventType),
      typeVersion: Value(typeVersion),
      deviceId: Value(deviceId),
      deviceTime: Value(deviceTime),
      appVersion: Value(appVersion),
      correlationJson: correlationJson == null && nullToAbsent
          ? const Value.absent()
          : Value(correlationJson),
      contentJson: contentJson == null && nullToAbsent
          ? const Value.absent()
          : Value(contentJson),
      ownerId: ownerId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerId),
      envelopeJson: envelopeJson == null && nullToAbsent
          ? const Value.absent()
          : Value(envelopeJson),
      enqueueSequence: Value(enqueueSequence),
      deliveryState: Value(deliveryState),
      attempts: Value(attempts),
      reasonCode: reasonCode == null && nullToAbsent
          ? const Value.absent()
          : Value(reasonCode),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      resultJson: resultJson == null && nullToAbsent
          ? const Value.absent()
          : Value(resultJson),
      businessJson: businessJson == null && nullToAbsent
          ? const Value.absent()
          : Value(businessJson),
      confirmedAt: confirmedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedAt),
    );
  }

  factory QueuedEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueuedEventRow(
      id: serializer.fromJson<String>(json['id']),
      eventType: serializer.fromJson<String>(json['eventType']),
      typeVersion: serializer.fromJson<int>(json['typeVersion']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deviceTime: serializer.fromJson<DateTime>(json['deviceTime']),
      appVersion: serializer.fromJson<String>(json['appVersion']),
      correlationJson: serializer.fromJson<String?>(json['correlationJson']),
      contentJson: serializer.fromJson<String?>(json['contentJson']),
      ownerId: serializer.fromJson<String?>(json['ownerId']),
      envelopeJson: serializer.fromJson<String?>(json['envelopeJson']),
      enqueueSequence: serializer.fromJson<int>(json['enqueueSequence']),
      deliveryState: serializer.fromJson<String>(json['deliveryState']),
      attempts: serializer.fromJson<int>(json['attempts']),
      reasonCode: serializer.fromJson<String?>(json['reasonCode']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      resultJson: serializer.fromJson<String?>(json['resultJson']),
      businessJson: serializer.fromJson<String?>(json['businessJson']),
      confirmedAt: serializer.fromJson<DateTime?>(json['confirmedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'eventType': serializer.toJson<String>(eventType),
      'typeVersion': serializer.toJson<int>(typeVersion),
      'deviceId': serializer.toJson<String>(deviceId),
      'deviceTime': serializer.toJson<DateTime>(deviceTime),
      'appVersion': serializer.toJson<String>(appVersion),
      'correlationJson': serializer.toJson<String?>(correlationJson),
      'contentJson': serializer.toJson<String?>(contentJson),
      'ownerId': serializer.toJson<String?>(ownerId),
      'envelopeJson': serializer.toJson<String?>(envelopeJson),
      'enqueueSequence': serializer.toJson<int>(enqueueSequence),
      'deliveryState': serializer.toJson<String>(deliveryState),
      'attempts': serializer.toJson<int>(attempts),
      'reasonCode': serializer.toJson<String?>(reasonCode),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'resultJson': serializer.toJson<String?>(resultJson),
      'businessJson': serializer.toJson<String?>(businessJson),
      'confirmedAt': serializer.toJson<DateTime?>(confirmedAt),
    };
  }

  QueuedEventRow copyWith({
    String? id,
    String? eventType,
    int? typeVersion,
    String? deviceId,
    DateTime? deviceTime,
    String? appVersion,
    Value<String?> correlationJson = const Value.absent(),
    Value<String?> contentJson = const Value.absent(),
    Value<String?> ownerId = const Value.absent(),
    Value<String?> envelopeJson = const Value.absent(),
    int? enqueueSequence,
    String? deliveryState,
    int? attempts,
    Value<String?> reasonCode = const Value.absent(),
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    Value<String?> resultJson = const Value.absent(),
    Value<String?> businessJson = const Value.absent(),
    Value<DateTime?> confirmedAt = const Value.absent(),
  }) => QueuedEventRow(
    id: id ?? this.id,
    eventType: eventType ?? this.eventType,
    typeVersion: typeVersion ?? this.typeVersion,
    deviceId: deviceId ?? this.deviceId,
    deviceTime: deviceTime ?? this.deviceTime,
    appVersion: appVersion ?? this.appVersion,
    correlationJson: correlationJson.present
        ? correlationJson.value
        : this.correlationJson,
    contentJson: contentJson.present ? contentJson.value : this.contentJson,
    ownerId: ownerId.present ? ownerId.value : this.ownerId,
    envelopeJson: envelopeJson.present ? envelopeJson.value : this.envelopeJson,
    enqueueSequence: enqueueSequence ?? this.enqueueSequence,
    deliveryState: deliveryState ?? this.deliveryState,
    attempts: attempts ?? this.attempts,
    reasonCode: reasonCode.present ? reasonCode.value : this.reasonCode,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    resultJson: resultJson.present ? resultJson.value : this.resultJson,
    businessJson: businessJson.present ? businessJson.value : this.businessJson,
    confirmedAt: confirmedAt.present ? confirmedAt.value : this.confirmedAt,
  );
  QueuedEventRow copyWithCompanion(QueuedEventsCompanion data) {
    return QueuedEventRow(
      id: data.id.present ? data.id.value : this.id,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      typeVersion: data.typeVersion.present
          ? data.typeVersion.value
          : this.typeVersion,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deviceTime: data.deviceTime.present
          ? data.deviceTime.value
          : this.deviceTime,
      appVersion: data.appVersion.present
          ? data.appVersion.value
          : this.appVersion,
      correlationJson: data.correlationJson.present
          ? data.correlationJson.value
          : this.correlationJson,
      contentJson: data.contentJson.present
          ? data.contentJson.value
          : this.contentJson,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      envelopeJson: data.envelopeJson.present
          ? data.envelopeJson.value
          : this.envelopeJson,
      enqueueSequence: data.enqueueSequence.present
          ? data.enqueueSequence.value
          : this.enqueueSequence,
      deliveryState: data.deliveryState.present
          ? data.deliveryState.value
          : this.deliveryState,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      reasonCode: data.reasonCode.present
          ? data.reasonCode.value
          : this.reasonCode,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      resultJson: data.resultJson.present
          ? data.resultJson.value
          : this.resultJson,
      businessJson: data.businessJson.present
          ? data.businessJson.value
          : this.businessJson,
      confirmedAt: data.confirmedAt.present
          ? data.confirmedAt.value
          : this.confirmedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueuedEventRow(')
          ..write('id: $id, ')
          ..write('eventType: $eventType, ')
          ..write('typeVersion: $typeVersion, ')
          ..write('deviceId: $deviceId, ')
          ..write('deviceTime: $deviceTime, ')
          ..write('appVersion: $appVersion, ')
          ..write('correlationJson: $correlationJson, ')
          ..write('contentJson: $contentJson, ')
          ..write('ownerId: $ownerId, ')
          ..write('envelopeJson: $envelopeJson, ')
          ..write('enqueueSequence: $enqueueSequence, ')
          ..write('deliveryState: $deliveryState, ')
          ..write('attempts: $attempts, ')
          ..write('reasonCode: $reasonCode, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('resultJson: $resultJson, ')
          ..write('businessJson: $businessJson, ')
          ..write('confirmedAt: $confirmedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    eventType,
    typeVersion,
    deviceId,
    deviceTime,
    appVersion,
    correlationJson,
    contentJson,
    ownerId,
    envelopeJson,
    enqueueSequence,
    deliveryState,
    attempts,
    reasonCode,
    nextAttemptAt,
    resultJson,
    businessJson,
    confirmedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueuedEventRow &&
          other.id == this.id &&
          other.eventType == this.eventType &&
          other.typeVersion == this.typeVersion &&
          other.deviceId == this.deviceId &&
          other.deviceTime == this.deviceTime &&
          other.appVersion == this.appVersion &&
          other.correlationJson == this.correlationJson &&
          other.contentJson == this.contentJson &&
          other.ownerId == this.ownerId &&
          other.envelopeJson == this.envelopeJson &&
          other.enqueueSequence == this.enqueueSequence &&
          other.deliveryState == this.deliveryState &&
          other.attempts == this.attempts &&
          other.reasonCode == this.reasonCode &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.resultJson == this.resultJson &&
          other.businessJson == this.businessJson &&
          other.confirmedAt == this.confirmedAt);
}

class QueuedEventsCompanion extends UpdateCompanion<QueuedEventRow> {
  final Value<String> id;
  final Value<String> eventType;
  final Value<int> typeVersion;
  final Value<String> deviceId;
  final Value<DateTime> deviceTime;
  final Value<String> appVersion;
  final Value<String?> correlationJson;
  final Value<String?> contentJson;
  final Value<String?> ownerId;
  final Value<String?> envelopeJson;
  final Value<int> enqueueSequence;
  final Value<String> deliveryState;
  final Value<int> attempts;
  final Value<String?> reasonCode;
  final Value<DateTime?> nextAttemptAt;
  final Value<String?> resultJson;
  final Value<String?> businessJson;
  final Value<DateTime?> confirmedAt;
  final Value<int> rowid;
  const QueuedEventsCompanion({
    this.id = const Value.absent(),
    this.eventType = const Value.absent(),
    this.typeVersion = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deviceTime = const Value.absent(),
    this.appVersion = const Value.absent(),
    this.correlationJson = const Value.absent(),
    this.contentJson = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.envelopeJson = const Value.absent(),
    this.enqueueSequence = const Value.absent(),
    this.deliveryState = const Value.absent(),
    this.attempts = const Value.absent(),
    this.reasonCode = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.resultJson = const Value.absent(),
    this.businessJson = const Value.absent(),
    this.confirmedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QueuedEventsCompanion.insert({
    required String id,
    required String eventType,
    required int typeVersion,
    required String deviceId,
    required DateTime deviceTime,
    required String appVersion,
    this.correlationJson = const Value.absent(),
    this.contentJson = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.envelopeJson = const Value.absent(),
    this.enqueueSequence = const Value.absent(),
    this.deliveryState = const Value.absent(),
    this.attempts = const Value.absent(),
    this.reasonCode = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.resultJson = const Value.absent(),
    this.businessJson = const Value.absent(),
    this.confirmedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       eventType = Value(eventType),
       typeVersion = Value(typeVersion),
       deviceId = Value(deviceId),
       deviceTime = Value(deviceTime),
       appVersion = Value(appVersion);
  static Insertable<QueuedEventRow> custom({
    Expression<String>? id,
    Expression<String>? eventType,
    Expression<int>? typeVersion,
    Expression<String>? deviceId,
    Expression<DateTime>? deviceTime,
    Expression<String>? appVersion,
    Expression<String>? correlationJson,
    Expression<String>? contentJson,
    Expression<String>? ownerId,
    Expression<String>? envelopeJson,
    Expression<int>? enqueueSequence,
    Expression<String>? deliveryState,
    Expression<int>? attempts,
    Expression<String>? reasonCode,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? resultJson,
    Expression<String>? businessJson,
    Expression<DateTime>? confirmedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventType != null) 'event_type': eventType,
      if (typeVersion != null) 'type_version': typeVersion,
      if (deviceId != null) 'device_id': deviceId,
      if (deviceTime != null) 'device_time': deviceTime,
      if (appVersion != null) 'app_version': appVersion,
      if (correlationJson != null) 'correlation_json': correlationJson,
      if (contentJson != null) 'content_json': contentJson,
      if (ownerId != null) 'owner_id': ownerId,
      if (envelopeJson != null) 'envelope_json': envelopeJson,
      if (enqueueSequence != null) 'enqueue_sequence': enqueueSequence,
      if (deliveryState != null) 'delivery_state': deliveryState,
      if (attempts != null) 'attempts': attempts,
      if (reasonCode != null) 'reason_code': reasonCode,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (resultJson != null) 'result_json': resultJson,
      if (businessJson != null) 'business_json': businessJson,
      if (confirmedAt != null) 'confirmed_at': confirmedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QueuedEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? eventType,
    Value<int>? typeVersion,
    Value<String>? deviceId,
    Value<DateTime>? deviceTime,
    Value<String>? appVersion,
    Value<String?>? correlationJson,
    Value<String?>? contentJson,
    Value<String?>? ownerId,
    Value<String?>? envelopeJson,
    Value<int>? enqueueSequence,
    Value<String>? deliveryState,
    Value<int>? attempts,
    Value<String?>? reasonCode,
    Value<DateTime?>? nextAttemptAt,
    Value<String?>? resultJson,
    Value<String?>? businessJson,
    Value<DateTime?>? confirmedAt,
    Value<int>? rowid,
  }) {
    return QueuedEventsCompanion(
      id: id ?? this.id,
      eventType: eventType ?? this.eventType,
      typeVersion: typeVersion ?? this.typeVersion,
      deviceId: deviceId ?? this.deviceId,
      deviceTime: deviceTime ?? this.deviceTime,
      appVersion: appVersion ?? this.appVersion,
      correlationJson: correlationJson ?? this.correlationJson,
      contentJson: contentJson ?? this.contentJson,
      ownerId: ownerId ?? this.ownerId,
      envelopeJson: envelopeJson ?? this.envelopeJson,
      enqueueSequence: enqueueSequence ?? this.enqueueSequence,
      deliveryState: deliveryState ?? this.deliveryState,
      attempts: attempts ?? this.attempts,
      reasonCode: reasonCode ?? this.reasonCode,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      resultJson: resultJson ?? this.resultJson,
      businessJson: businessJson ?? this.businessJson,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (typeVersion.present) {
      map['type_version'] = Variable<int>(typeVersion.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deviceTime.present) {
      map['device_time'] = Variable<DateTime>(deviceTime.value);
    }
    if (appVersion.present) {
      map['app_version'] = Variable<String>(appVersion.value);
    }
    if (correlationJson.present) {
      map['correlation_json'] = Variable<String>(correlationJson.value);
    }
    if (contentJson.present) {
      map['content_json'] = Variable<String>(contentJson.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (envelopeJson.present) {
      map['envelope_json'] = Variable<String>(envelopeJson.value);
    }
    if (enqueueSequence.present) {
      map['enqueue_sequence'] = Variable<int>(enqueueSequence.value);
    }
    if (deliveryState.present) {
      map['delivery_state'] = Variable<String>(deliveryState.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (reasonCode.present) {
      map['reason_code'] = Variable<String>(reasonCode.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (resultJson.present) {
      map['result_json'] = Variable<String>(resultJson.value);
    }
    if (businessJson.present) {
      map['business_json'] = Variable<String>(businessJson.value);
    }
    if (confirmedAt.present) {
      map['confirmed_at'] = Variable<DateTime>(confirmedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QueuedEventsCompanion(')
          ..write('id: $id, ')
          ..write('eventType: $eventType, ')
          ..write('typeVersion: $typeVersion, ')
          ..write('deviceId: $deviceId, ')
          ..write('deviceTime: $deviceTime, ')
          ..write('appVersion: $appVersion, ')
          ..write('correlationJson: $correlationJson, ')
          ..write('contentJson: $contentJson, ')
          ..write('ownerId: $ownerId, ')
          ..write('envelopeJson: $envelopeJson, ')
          ..write('enqueueSequence: $enqueueSequence, ')
          ..write('deliveryState: $deliveryState, ')
          ..write('attempts: $attempts, ')
          ..write('reasonCode: $reasonCode, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('resultJson: $resultJson, ')
          ..write('businessJson: $businessJson, ')
          ..write('confirmedAt: $confirmedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RejectedEventsTable extends RejectedEvents
    with TableInfo<$RejectedEventsTable, RejectedEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RejectedEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeVersionMeta = const VerificationMeta(
    'typeVersion',
  );
  @override
  late final GeneratedColumn<int> typeVersion = GeneratedColumn<int>(
    'type_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonCodeMeta = const VerificationMeta(
    'reasonCode',
  );
  @override
  late final GeneratedColumn<String> reasonCode = GeneratedColumn<String>(
    'reason_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rejectedAtMeta = const VerificationMeta(
    'rejectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> rejectedAt = GeneratedColumn<DateTime>(
    'rejected_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eventType,
    typeVersion,
    reasonCode,
    rejectedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rejected_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<RejectedEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('type_version')) {
      context.handle(
        _typeVersionMeta,
        typeVersion.isAcceptableOrUnknown(
          data['type_version']!,
          _typeVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_typeVersionMeta);
    }
    if (data.containsKey('reason_code')) {
      context.handle(
        _reasonCodeMeta,
        reasonCode.isAcceptableOrUnknown(data['reason_code']!, _reasonCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonCodeMeta);
    }
    if (data.containsKey('rejected_at')) {
      context.handle(
        _rejectedAtMeta,
        rejectedAt.isAcceptableOrUnknown(data['rejected_at']!, _rejectedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_rejectedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RejectedEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RejectedEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      typeVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type_version'],
      )!,
      reasonCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason_code'],
      )!,
      rejectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}rejected_at'],
      )!,
    );
  }

  @override
  $RejectedEventsTable createAlias(String alias) {
    return $RejectedEventsTable(attachedDatabase, alias);
  }
}

class RejectedEventRow extends DataClass
    implements Insertable<RejectedEventRow> {
  final String id;
  final String eventType;
  final int typeVersion;
  final String reasonCode;
  final DateTime rejectedAt;
  const RejectedEventRow({
    required this.id,
    required this.eventType,
    required this.typeVersion,
    required this.reasonCode,
    required this.rejectedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['event_type'] = Variable<String>(eventType);
    map['type_version'] = Variable<int>(typeVersion);
    map['reason_code'] = Variable<String>(reasonCode);
    map['rejected_at'] = Variable<DateTime>(rejectedAt);
    return map;
  }

  RejectedEventsCompanion toCompanion(bool nullToAbsent) {
    return RejectedEventsCompanion(
      id: Value(id),
      eventType: Value(eventType),
      typeVersion: Value(typeVersion),
      reasonCode: Value(reasonCode),
      rejectedAt: Value(rejectedAt),
    );
  }

  factory RejectedEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RejectedEventRow(
      id: serializer.fromJson<String>(json['id']),
      eventType: serializer.fromJson<String>(json['eventType']),
      typeVersion: serializer.fromJson<int>(json['typeVersion']),
      reasonCode: serializer.fromJson<String>(json['reasonCode']),
      rejectedAt: serializer.fromJson<DateTime>(json['rejectedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'eventType': serializer.toJson<String>(eventType),
      'typeVersion': serializer.toJson<int>(typeVersion),
      'reasonCode': serializer.toJson<String>(reasonCode),
      'rejectedAt': serializer.toJson<DateTime>(rejectedAt),
    };
  }

  RejectedEventRow copyWith({
    String? id,
    String? eventType,
    int? typeVersion,
    String? reasonCode,
    DateTime? rejectedAt,
  }) => RejectedEventRow(
    id: id ?? this.id,
    eventType: eventType ?? this.eventType,
    typeVersion: typeVersion ?? this.typeVersion,
    reasonCode: reasonCode ?? this.reasonCode,
    rejectedAt: rejectedAt ?? this.rejectedAt,
  );
  RejectedEventRow copyWithCompanion(RejectedEventsCompanion data) {
    return RejectedEventRow(
      id: data.id.present ? data.id.value : this.id,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      typeVersion: data.typeVersion.present
          ? data.typeVersion.value
          : this.typeVersion,
      reasonCode: data.reasonCode.present
          ? data.reasonCode.value
          : this.reasonCode,
      rejectedAt: data.rejectedAt.present
          ? data.rejectedAt.value
          : this.rejectedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RejectedEventRow(')
          ..write('id: $id, ')
          ..write('eventType: $eventType, ')
          ..write('typeVersion: $typeVersion, ')
          ..write('reasonCode: $reasonCode, ')
          ..write('rejectedAt: $rejectedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, eventType, typeVersion, reasonCode, rejectedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RejectedEventRow &&
          other.id == this.id &&
          other.eventType == this.eventType &&
          other.typeVersion == this.typeVersion &&
          other.reasonCode == this.reasonCode &&
          other.rejectedAt == this.rejectedAt);
}

class RejectedEventsCompanion extends UpdateCompanion<RejectedEventRow> {
  final Value<String> id;
  final Value<String> eventType;
  final Value<int> typeVersion;
  final Value<String> reasonCode;
  final Value<DateTime> rejectedAt;
  final Value<int> rowid;
  const RejectedEventsCompanion({
    this.id = const Value.absent(),
    this.eventType = const Value.absent(),
    this.typeVersion = const Value.absent(),
    this.reasonCode = const Value.absent(),
    this.rejectedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RejectedEventsCompanion.insert({
    required String id,
    required String eventType,
    required int typeVersion,
    required String reasonCode,
    required DateTime rejectedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       eventType = Value(eventType),
       typeVersion = Value(typeVersion),
       reasonCode = Value(reasonCode),
       rejectedAt = Value(rejectedAt);
  static Insertable<RejectedEventRow> custom({
    Expression<String>? id,
    Expression<String>? eventType,
    Expression<int>? typeVersion,
    Expression<String>? reasonCode,
    Expression<DateTime>? rejectedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventType != null) 'event_type': eventType,
      if (typeVersion != null) 'type_version': typeVersion,
      if (reasonCode != null) 'reason_code': reasonCode,
      if (rejectedAt != null) 'rejected_at': rejectedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RejectedEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? eventType,
    Value<int>? typeVersion,
    Value<String>? reasonCode,
    Value<DateTime>? rejectedAt,
    Value<int>? rowid,
  }) {
    return RejectedEventsCompanion(
      id: id ?? this.id,
      eventType: eventType ?? this.eventType,
      typeVersion: typeVersion ?? this.typeVersion,
      reasonCode: reasonCode ?? this.reasonCode,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (typeVersion.present) {
      map['type_version'] = Variable<int>(typeVersion.value);
    }
    if (reasonCode.present) {
      map['reason_code'] = Variable<String>(reasonCode.value);
    }
    if (rejectedAt.present) {
      map['rejected_at'] = Variable<DateTime>(rejectedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RejectedEventsCompanion(')
          ..write('id: $id, ')
          ..write('eventType: $eventType, ')
          ..write('typeVersion: $typeVersion, ')
          ..write('reasonCode: $reasonCode, ')
          ..write('rejectedAt: $rejectedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueCountersTable extends SyncQueueCounters
    with TableInfo<$SyncQueueCountersTable, SyncQueueCounter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueCountersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextSequenceMeta = const VerificationMeta(
    'nextSequence',
  );
  @override
  late final GeneratedColumn<int> nextSequence = GeneratedColumn<int>(
    'next_sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, nextSequence];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_counters';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueCounter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('next_sequence')) {
      context.handle(
        _nextSequenceMeta,
        nextSequence.isAcceptableOrUnknown(
          data['next_sequence']!,
          _nextSequenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextSequenceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueCounter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueCounter(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nextSequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_sequence'],
      )!,
    );
  }

  @override
  $SyncQueueCountersTable createAlias(String alias) {
    return $SyncQueueCountersTable(attachedDatabase, alias);
  }
}

class SyncQueueCounter extends DataClass
    implements Insertable<SyncQueueCounter> {
  final int id;
  final int nextSequence;
  const SyncQueueCounter({required this.id, required this.nextSequence});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['next_sequence'] = Variable<int>(nextSequence);
    return map;
  }

  SyncQueueCountersCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCountersCompanion(
      id: Value(id),
      nextSequence: Value(nextSequence),
    );
  }

  factory SyncQueueCounter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueCounter(
      id: serializer.fromJson<int>(json['id']),
      nextSequence: serializer.fromJson<int>(json['nextSequence']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nextSequence': serializer.toJson<int>(nextSequence),
    };
  }

  SyncQueueCounter copyWith({int? id, int? nextSequence}) => SyncQueueCounter(
    id: id ?? this.id,
    nextSequence: nextSequence ?? this.nextSequence,
  );
  SyncQueueCounter copyWithCompanion(SyncQueueCountersCompanion data) {
    return SyncQueueCounter(
      id: data.id.present ? data.id.value : this.id,
      nextSequence: data.nextSequence.present
          ? data.nextSequence.value
          : this.nextSequence,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCounter(')
          ..write('id: $id, ')
          ..write('nextSequence: $nextSequence')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nextSequence);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueCounter &&
          other.id == this.id &&
          other.nextSequence == this.nextSequence);
}

class SyncQueueCountersCompanion extends UpdateCompanion<SyncQueueCounter> {
  final Value<int> id;
  final Value<int> nextSequence;
  const SyncQueueCountersCompanion({
    this.id = const Value.absent(),
    this.nextSequence = const Value.absent(),
  });
  SyncQueueCountersCompanion.insert({
    this.id = const Value.absent(),
    required int nextSequence,
  }) : nextSequence = Value(nextSequence);
  static Insertable<SyncQueueCounter> custom({
    Expression<int>? id,
    Expression<int>? nextSequence,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nextSequence != null) 'next_sequence': nextSequence,
    });
  }

  SyncQueueCountersCompanion copyWith({
    Value<int>? id,
    Value<int>? nextSequence,
  }) {
    return SyncQueueCountersCompanion(
      id: id ?? this.id,
      nextSequence: nextSequence ?? this.nextSequence,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nextSequence.present) {
      map['next_sequence'] = Variable<int>(nextSequence.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCountersCompanion(')
          ..write('id: $id, ')
          ..write('nextSequence: $nextSequence')
          ..write(')'))
        .toString();
  }
}

abstract class _$EventQueueDatabase extends GeneratedDatabase {
  _$EventQueueDatabase(QueryExecutor e) : super(e);
  $EventQueueDatabaseManager get managers => $EventQueueDatabaseManager(this);
  late final $QueuedEventsTable queuedEvents = $QueuedEventsTable(this);
  late final $RejectedEventsTable rejectedEvents = $RejectedEventsTable(this);
  late final $SyncQueueCountersTable syncQueueCounters =
      $SyncQueueCountersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    queuedEvents,
    rejectedEvents,
    syncQueueCounters,
  ];
}

typedef $$QueuedEventsTableCreateCompanionBuilder =
    QueuedEventsCompanion Function({
      required String id,
      required String eventType,
      required int typeVersion,
      required String deviceId,
      required DateTime deviceTime,
      required String appVersion,
      Value<String?> correlationJson,
      Value<String?> contentJson,
      Value<String?> ownerId,
      Value<String?> envelopeJson,
      Value<int> enqueueSequence,
      Value<String> deliveryState,
      Value<int> attempts,
      Value<String?> reasonCode,
      Value<DateTime?> nextAttemptAt,
      Value<String?> resultJson,
      Value<String?> businessJson,
      Value<DateTime?> confirmedAt,
      Value<int> rowid,
    });
typedef $$QueuedEventsTableUpdateCompanionBuilder =
    QueuedEventsCompanion Function({
      Value<String> id,
      Value<String> eventType,
      Value<int> typeVersion,
      Value<String> deviceId,
      Value<DateTime> deviceTime,
      Value<String> appVersion,
      Value<String?> correlationJson,
      Value<String?> contentJson,
      Value<String?> ownerId,
      Value<String?> envelopeJson,
      Value<int> enqueueSequence,
      Value<String> deliveryState,
      Value<int> attempts,
      Value<String?> reasonCode,
      Value<DateTime?> nextAttemptAt,
      Value<String?> resultJson,
      Value<String?> businessJson,
      Value<DateTime?> confirmedAt,
      Value<int> rowid,
    });

class $$QueuedEventsTableFilterComposer
    extends Composer<_$EventQueueDatabase, $QueuedEventsTable> {
  $$QueuedEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get typeVersion => $composableBuilder(
    column: $table.typeVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deviceTime => $composableBuilder(
    column: $table.deviceTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correlationJson => $composableBuilder(
    column: $table.correlationJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentJson => $composableBuilder(
    column: $table.contentJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get envelopeJson => $composableBuilder(
    column: $table.envelopeJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get enqueueSequence => $composableBuilder(
    column: $table.enqueueSequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryState => $composableBuilder(
    column: $table.deliveryState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reasonCode => $composableBuilder(
    column: $table.reasonCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessJson => $composableBuilder(
    column: $table.businessJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QueuedEventsTableOrderingComposer
    extends Composer<_$EventQueueDatabase, $QueuedEventsTable> {
  $$QueuedEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get typeVersion => $composableBuilder(
    column: $table.typeVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deviceTime => $composableBuilder(
    column: $table.deviceTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correlationJson => $composableBuilder(
    column: $table.correlationJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentJson => $composableBuilder(
    column: $table.contentJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get envelopeJson => $composableBuilder(
    column: $table.envelopeJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get enqueueSequence => $composableBuilder(
    column: $table.enqueueSequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryState => $composableBuilder(
    column: $table.deliveryState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasonCode => $composableBuilder(
    column: $table.reasonCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessJson => $composableBuilder(
    column: $table.businessJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QueuedEventsTableAnnotationComposer
    extends Composer<_$EventQueueDatabase, $QueuedEventsTable> {
  $$QueuedEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<int> get typeVersion => $composableBuilder(
    column: $table.typeVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get deviceTime => $composableBuilder(
    column: $table.deviceTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get correlationJson => $composableBuilder(
    column: $table.correlationJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentJson => $composableBuilder(
    column: $table.contentJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get envelopeJson => $composableBuilder(
    column: $table.envelopeJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get enqueueSequence => $composableBuilder(
    column: $table.enqueueSequence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deliveryState => $composableBuilder(
    column: $table.deliveryState,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get reasonCode => $composableBuilder(
    column: $table.reasonCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resultJson => $composableBuilder(
    column: $table.resultJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessJson => $composableBuilder(
    column: $table.businessJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => column,
  );
}

class $$QueuedEventsTableTableManager
    extends
        RootTableManager<
          _$EventQueueDatabase,
          $QueuedEventsTable,
          QueuedEventRow,
          $$QueuedEventsTableFilterComposer,
          $$QueuedEventsTableOrderingComposer,
          $$QueuedEventsTableAnnotationComposer,
          $$QueuedEventsTableCreateCompanionBuilder,
          $$QueuedEventsTableUpdateCompanionBuilder,
          (
            QueuedEventRow,
            BaseReferences<
              _$EventQueueDatabase,
              $QueuedEventsTable,
              QueuedEventRow
            >,
          ),
          QueuedEventRow,
          PrefetchHooks Function()
        > {
  $$QueuedEventsTableTableManager(
    _$EventQueueDatabase db,
    $QueuedEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QueuedEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QueuedEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QueuedEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<int> typeVersion = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<DateTime> deviceTime = const Value.absent(),
                Value<String> appVersion = const Value.absent(),
                Value<String?> correlationJson = const Value.absent(),
                Value<String?> contentJson = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<String?> envelopeJson = const Value.absent(),
                Value<int> enqueueSequence = const Value.absent(),
                Value<String> deliveryState = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> reasonCode = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> resultJson = const Value.absent(),
                Value<String?> businessJson = const Value.absent(),
                Value<DateTime?> confirmedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QueuedEventsCompanion(
                id: id,
                eventType: eventType,
                typeVersion: typeVersion,
                deviceId: deviceId,
                deviceTime: deviceTime,
                appVersion: appVersion,
                correlationJson: correlationJson,
                contentJson: contentJson,
                ownerId: ownerId,
                envelopeJson: envelopeJson,
                enqueueSequence: enqueueSequence,
                deliveryState: deliveryState,
                attempts: attempts,
                reasonCode: reasonCode,
                nextAttemptAt: nextAttemptAt,
                resultJson: resultJson,
                businessJson: businessJson,
                confirmedAt: confirmedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String eventType,
                required int typeVersion,
                required String deviceId,
                required DateTime deviceTime,
                required String appVersion,
                Value<String?> correlationJson = const Value.absent(),
                Value<String?> contentJson = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<String?> envelopeJson = const Value.absent(),
                Value<int> enqueueSequence = const Value.absent(),
                Value<String> deliveryState = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> reasonCode = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> resultJson = const Value.absent(),
                Value<String?> businessJson = const Value.absent(),
                Value<DateTime?> confirmedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QueuedEventsCompanion.insert(
                id: id,
                eventType: eventType,
                typeVersion: typeVersion,
                deviceId: deviceId,
                deviceTime: deviceTime,
                appVersion: appVersion,
                correlationJson: correlationJson,
                contentJson: contentJson,
                ownerId: ownerId,
                envelopeJson: envelopeJson,
                enqueueSequence: enqueueSequence,
                deliveryState: deliveryState,
                attempts: attempts,
                reasonCode: reasonCode,
                nextAttemptAt: nextAttemptAt,
                resultJson: resultJson,
                businessJson: businessJson,
                confirmedAt: confirmedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QueuedEventsTable, QueuedEventRow>(table),
                  BaseReferences<
                    _$EventQueueDatabase,
                    $QueuedEventsTable,
                    QueuedEventRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QueuedEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$EventQueueDatabase,
      $QueuedEventsTable,
      QueuedEventRow,
      $$QueuedEventsTableFilterComposer,
      $$QueuedEventsTableOrderingComposer,
      $$QueuedEventsTableAnnotationComposer,
      $$QueuedEventsTableCreateCompanionBuilder,
      $$QueuedEventsTableUpdateCompanionBuilder,
      (
        QueuedEventRow,
        BaseReferences<
          _$EventQueueDatabase,
          $QueuedEventsTable,
          QueuedEventRow
        >,
      ),
      QueuedEventRow,
      PrefetchHooks Function()
    >;
typedef $$RejectedEventsTableCreateCompanionBuilder =
    RejectedEventsCompanion Function({
      required String id,
      required String eventType,
      required int typeVersion,
      required String reasonCode,
      required DateTime rejectedAt,
      Value<int> rowid,
    });
typedef $$RejectedEventsTableUpdateCompanionBuilder =
    RejectedEventsCompanion Function({
      Value<String> id,
      Value<String> eventType,
      Value<int> typeVersion,
      Value<String> reasonCode,
      Value<DateTime> rejectedAt,
      Value<int> rowid,
    });

class $$RejectedEventsTableFilterComposer
    extends Composer<_$EventQueueDatabase, $RejectedEventsTable> {
  $$RejectedEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get typeVersion => $composableBuilder(
    column: $table.typeVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reasonCode => $composableBuilder(
    column: $table.reasonCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get rejectedAt => $composableBuilder(
    column: $table.rejectedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RejectedEventsTableOrderingComposer
    extends Composer<_$EventQueueDatabase, $RejectedEventsTable> {
  $$RejectedEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get typeVersion => $composableBuilder(
    column: $table.typeVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasonCode => $composableBuilder(
    column: $table.reasonCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get rejectedAt => $composableBuilder(
    column: $table.rejectedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RejectedEventsTableAnnotationComposer
    extends Composer<_$EventQueueDatabase, $RejectedEventsTable> {
  $$RejectedEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<int> get typeVersion => $composableBuilder(
    column: $table.typeVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reasonCode => $composableBuilder(
    column: $table.reasonCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get rejectedAt => $composableBuilder(
    column: $table.rejectedAt,
    builder: (column) => column,
  );
}

class $$RejectedEventsTableTableManager
    extends
        RootTableManager<
          _$EventQueueDatabase,
          $RejectedEventsTable,
          RejectedEventRow,
          $$RejectedEventsTableFilterComposer,
          $$RejectedEventsTableOrderingComposer,
          $$RejectedEventsTableAnnotationComposer,
          $$RejectedEventsTableCreateCompanionBuilder,
          $$RejectedEventsTableUpdateCompanionBuilder,
          (
            RejectedEventRow,
            BaseReferences<
              _$EventQueueDatabase,
              $RejectedEventsTable,
              RejectedEventRow
            >,
          ),
          RejectedEventRow,
          PrefetchHooks Function()
        > {
  $$RejectedEventsTableTableManager(
    _$EventQueueDatabase db,
    $RejectedEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RejectedEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RejectedEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RejectedEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<int> typeVersion = const Value.absent(),
                Value<String> reasonCode = const Value.absent(),
                Value<DateTime> rejectedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RejectedEventsCompanion(
                id: id,
                eventType: eventType,
                typeVersion: typeVersion,
                reasonCode: reasonCode,
                rejectedAt: rejectedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String eventType,
                required int typeVersion,
                required String reasonCode,
                required DateTime rejectedAt,
                Value<int> rowid = const Value.absent(),
              }) => RejectedEventsCompanion.insert(
                id: id,
                eventType: eventType,
                typeVersion: typeVersion,
                reasonCode: reasonCode,
                rejectedAt: rejectedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RejectedEventsTable, RejectedEventRow>(table),
                  BaseReferences<
                    _$EventQueueDatabase,
                    $RejectedEventsTable,
                    RejectedEventRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RejectedEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$EventQueueDatabase,
      $RejectedEventsTable,
      RejectedEventRow,
      $$RejectedEventsTableFilterComposer,
      $$RejectedEventsTableOrderingComposer,
      $$RejectedEventsTableAnnotationComposer,
      $$RejectedEventsTableCreateCompanionBuilder,
      $$RejectedEventsTableUpdateCompanionBuilder,
      (
        RejectedEventRow,
        BaseReferences<
          _$EventQueueDatabase,
          $RejectedEventsTable,
          RejectedEventRow
        >,
      ),
      RejectedEventRow,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueCountersTableCreateCompanionBuilder =
    SyncQueueCountersCompanion Function({
      Value<int> id,
      required int nextSequence,
    });
typedef $$SyncQueueCountersTableUpdateCompanionBuilder =
    SyncQueueCountersCompanion Function({
      Value<int> id,
      Value<int> nextSequence,
    });

class $$SyncQueueCountersTableFilterComposer
    extends Composer<_$EventQueueDatabase, $SyncQueueCountersTable> {
  $$SyncQueueCountersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextSequence => $composableBuilder(
    column: $table.nextSequence,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueCountersTableOrderingComposer
    extends Composer<_$EventQueueDatabase, $SyncQueueCountersTable> {
  $$SyncQueueCountersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextSequence => $composableBuilder(
    column: $table.nextSequence,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueCountersTableAnnotationComposer
    extends Composer<_$EventQueueDatabase, $SyncQueueCountersTable> {
  $$SyncQueueCountersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get nextSequence => $composableBuilder(
    column: $table.nextSequence,
    builder: (column) => column,
  );
}

class $$SyncQueueCountersTableTableManager
    extends
        RootTableManager<
          _$EventQueueDatabase,
          $SyncQueueCountersTable,
          SyncQueueCounter,
          $$SyncQueueCountersTableFilterComposer,
          $$SyncQueueCountersTableOrderingComposer,
          $$SyncQueueCountersTableAnnotationComposer,
          $$SyncQueueCountersTableCreateCompanionBuilder,
          $$SyncQueueCountersTableUpdateCompanionBuilder,
          (
            SyncQueueCounter,
            BaseReferences<
              _$EventQueueDatabase,
              $SyncQueueCountersTable,
              SyncQueueCounter
            >,
          ),
          SyncQueueCounter,
          PrefetchHooks Function()
        > {
  $$SyncQueueCountersTableTableManager(
    _$EventQueueDatabase db,
    $SyncQueueCountersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueCountersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueCountersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueCountersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> nextSequence = const Value.absent(),
          }) => SyncQueueCountersCompanion(id: id, nextSequence: nextSequence),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int nextSequence,
              }) => SyncQueueCountersCompanion.insert(
                id: id,
                nextSequence: nextSequence,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncQueueCountersTable, SyncQueueCounter>(table),
                  BaseReferences<
                    _$EventQueueDatabase,
                    $SyncQueueCountersTable,
                    SyncQueueCounter
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueCountersTableProcessedTableManager =
    ProcessedTableManager<
      _$EventQueueDatabase,
      $SyncQueueCountersTable,
      SyncQueueCounter,
      $$SyncQueueCountersTableFilterComposer,
      $$SyncQueueCountersTableOrderingComposer,
      $$SyncQueueCountersTableAnnotationComposer,
      $$SyncQueueCountersTableCreateCompanionBuilder,
      $$SyncQueueCountersTableUpdateCompanionBuilder,
      (
        SyncQueueCounter,
        BaseReferences<
          _$EventQueueDatabase,
          $SyncQueueCountersTable,
          SyncQueueCounter
        >,
      ),
      SyncQueueCounter,
      PrefetchHooks Function()
    >;

class $EventQueueDatabaseManager {
  final _$EventQueueDatabase _db;
  $EventQueueDatabaseManager(this._db);
  $$QueuedEventsTableTableManager get queuedEvents =>
      $$QueuedEventsTableTableManager(_db, _db.queuedEvents);
  $$RejectedEventsTableTableManager get rejectedEvents =>
      $$RejectedEventsTableTableManager(_db, _db.rejectedEvents);
  $$SyncQueueCountersTableTableManager get syncQueueCounters =>
      $$SyncQueueCountersTableTableManager(_db, _db.syncQueueCounters);
}
