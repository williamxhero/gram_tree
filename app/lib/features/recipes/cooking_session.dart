import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../app/theme.dart';
import '../../events/event_recorder.dart';
import '../../platform/device_capabilities.dart';
import '../../platform/permissions.dart';
import '../../recipes/recipe_snapshot.dart';
import '../../recipes/recipe_snapshot_provider.dart';
import '../../storage/local_store.dart';
import '../../util/ids.dart';
import 'cooking_voice.dart';
import 'press_hold_voice_question.dart';

const _cookingStoreKey = 'cooking_sessions:v1';

class CookingTimerState {
  CookingTimerState({
    required this.id,
    required this.stepId,
    required this.startedAt,
    required this.durationSeconds,
    this.pausedSeconds = 0,
    this.pausedAt,
    this.dueReportedAt,
    this.status = 'running',
  });

  final String id;
  final String stepId;
  final DateTime startedAt;
  final int durationSeconds;
  final int pausedSeconds;
  final DateTime? pausedAt;

  /// Persisted idempotency marker for the local timer-due event. Keeping this
  /// in the session (rather than only in widget memory) prevents a process
  /// restart/resume from recording the same due timer repeatedly.
  final DateTime? dueReportedAt;
  final String status;

  bool isDueAt(DateTime now) => status == 'running' && remainingAt(now) == 0;

  bool get hasReportedDue => dueReportedAt != null;

  int remainingAt(DateTime now) {
    final paused = pausedAt == null
        ? pausedSeconds
        : pausedSeconds + now.difference(pausedAt!).inSeconds;
    final elapsed = now.difference(startedAt).inSeconds - paused;
    return (durationSeconds - elapsed).clamp(0, durationSeconds);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'step_id': stepId,
    'started_at': startedAt.toUtc().toIso8601String(),
    'duration_seconds': durationSeconds,
    'paused_seconds': pausedSeconds,
    'paused_at': pausedAt?.toUtc().toIso8601String(),
    'due_reported_at': dueReportedAt?.toUtc().toIso8601String(),
    'status': status,
  };

  static CookingTimerState? fromJson(Object? raw) {
    try {
      final map = Map<String, dynamic>.from(raw as Map);
      return CookingTimerState(
        id: map['id'] as String,
        stepId: map['step_id'] as String,
        startedAt: DateTime.parse(map['started_at'] as String),
        durationSeconds: map['duration_seconds'] as int,
        pausedSeconds: map['paused_seconds'] as int? ?? 0,
        pausedAt: map['paused_at'] == null
            ? null
            : DateTime.parse(map['paused_at'] as String),
        dueReportedAt: map['due_reported_at'] == null
            ? null
            : DateTime.parse(map['due_reported_at'] as String),
        status: map['status'] as String? ?? 'running',
      );
    } catch (_) {
      return null;
    }
  }
}

class CookingSession {
  CookingSession({
    required this.id,
    required this.snapshot,
    required this.startedAt,
    this.stepIndex = -1,
    this.status = 'active',
    this.reached = const [],
    this.completed = const [],
    this.skipped = const [],
    this.timers = const [],
    this.adjustments = const [],
    this.questions = const [],
    this.finishedAt,
  });

  final String id;
  final FrozenRecipeSnapshot snapshot;
  final DateTime startedAt;
  final int stepIndex;
  final String status;
  final List<String> reached;
  final List<String> completed;
  final List<String> skipped;
  final List<CookingTimerState> timers;
  final List<Map<String, dynamic>> adjustments;
  final List<Map<String, dynamic>> questions;
  final DateTime? finishedAt;

  List<RecipeStep> get steps =>
      snapshot.detail.version.snapshot.steps ?? const [];
  bool get isComplete => status == 'completed';

  bool dependenciesReady(RecipeStep step) =>
      (step.dependsOn ?? const <String>[]).every(
        (id) => completed.contains(id) || skipped.contains(id),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'snapshot': snapshot.toJson(),
    'started_at': startedAt.toUtc().toIso8601String(),
    'step_index': stepIndex,
    'status': status,
    'reached': reached,
    'completed': completed,
    'skipped': skipped,
    'timers': [for (final timer in timers) timer.toJson()],
    'adjustments': adjustments,
    'questions': questions,
    'finished_at': finishedAt?.toUtc().toIso8601String(),
  };

  CookingSession copyWith({
    int? stepIndex,
    String? status,
    List<String>? reached,
    List<String>? completed,
    List<String>? skipped,
    List<CookingTimerState>? timers,
    List<Map<String, dynamic>>? adjustments,
    List<Map<String, dynamic>>? questions,
    DateTime? finishedAt,
  }) => CookingSession(
    id: id,
    snapshot: snapshot,
    startedAt: startedAt,
    stepIndex: stepIndex ?? this.stepIndex,
    status: status ?? this.status,
    reached: reached ?? this.reached,
    completed: completed ?? this.completed,
    skipped: skipped ?? this.skipped,
    timers: timers ?? this.timers,
    adjustments: adjustments ?? this.adjustments,
    questions: questions ?? this.questions,
    finishedAt: finishedAt ?? this.finishedAt,
  );

  static CookingSession? fromJson(Object? raw) {
    try {
      final map = Map<String, dynamic>.from(raw as Map);
      final snapshot = FrozenRecipeSnapshot.fromJson(map['snapshot']);
      if (snapshot == null) return null;
      return CookingSession(
        id: map['id'] as String,
        snapshot: snapshot,
        startedAt: DateTime.parse(map['started_at'] as String),
        stepIndex: map['step_index'] as int? ?? -1,
        status: map['status'] as String? ?? 'active',
        reached: [
          for (final item in (map['reached'] as List? ?? [])) item as String,
        ],
        completed: [
          for (final item in (map['completed'] as List? ?? [])) item as String,
        ],
        skipped: [
          for (final item in (map['skipped'] as List? ?? [])) item as String,
        ],
        timers: [
          for (final item in (map['timers'] as List? ?? []))
            CookingTimerState.fromJson(item),
        ].nonNulls.toList(),
        adjustments: [
          for (final item in (map['adjustments'] as List? ?? []))
            Map<String, dynamic>.from(item as Map),
        ],
        questions: [
          for (final item in (map['questions'] as List? ?? []))
            Map<String, dynamic>.from(item as Map),
        ],
        finishedAt: map['finished_at'] == null
            ? null
            : DateTime.parse(map['finished_at'] as String),
      );
    } catch (_) {
      return null;
    }
  }
}

class CookingSessionStore {
  CookingSessionStore(this.store, {required this.accountId});
  final LocalStore store;
  final String accountId;

  Map<String, dynamic> _load() {
    try {
      final decoded = jsonDecode(store.getString(_cookingStoreKey) ?? '{}');
      if (decoded is Map && decoded['accounts'] is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return {'format_version': 1, 'accounts': <String, dynamic>{}};
  }

  Map<String, dynamic> _account(Map<String, dynamic> root) {
    final accounts = root['accounts'] as Map;
    final current = accounts[accountId];
    if (current is Map && current['sessions'] is Map) {
      return current.cast<String, dynamic>();
    }
    final next = <String, dynamic>{'sessions': <String, dynamic>{}};
    accounts[accountId] = next;
    return next;
  }

  Future<void> _save(Map<String, dynamic> root) =>
      store.setString(_cookingStoreKey, jsonEncode(root));

  Future<CookingSession> start(FrozenRecipeSnapshot snapshot) async {
    final root = _load();
    final account = _account(root);
    final sessions = account['sessions'] as Map;
    final existing = [
      for (final raw in sessions.values)
        if (CookingSession.fromJson(raw) case final item?)
          if (item.snapshot.versionId == snapshot.versionId && !item.isComplete)
            item,
    ].firstOrNull;
    if (existing != null) return existing;
    final session = CookingSession(
      id: newUuidV4(),
      snapshot: snapshot,
      startedAt: DateTime.now().toUtc(),
    );
    sessions[session.id] = session.toJson();
    await _save(root);
    return session;
  }

  Future<CookingSession?> read(String id) async {
    final root = _load();
    return CookingSession.fromJson((_account(root)['sessions'] as Map)[id]);
  }

  Future<void> write(CookingSession session) async {
    final root = _load();
    _account(root)['sessions'][session.id] = session.toJson();
    await _save(root);
  }
}

final cookingSessionStoreProvider = Provider<CookingSessionStore?>((ref) {
  final accountId = ref.watch(recipeSnapshotStoreProvider)?.accountId;
  if (accountId == null) return null;
  return CookingSessionStore(
    ref.watch(localStoreProvider),
    accountId: accountId,
  );
});

class CookingPage extends ConsumerStatefulWidget {
  const CookingPage({super.key, required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<CookingPage> createState() => _CookingPageState();
}

class _CookingPageState extends ConsumerState<CookingPage>
    with WidgetsBindingObserver {
  CookingSession? _session;
  Timer? _ticker;
  bool _reportingDueTimers = false;
  final _voiceCommands = CookingVoiceController();
  VoiceQuestionLifecycle? _voiceQuestion;
  PressAndHoldVoiceQuestion? _voiceRecorder;
  OfflineCookingVoiceListener? _voiceListener;
  bool _voiceUnavailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      final session = _session;
      if (session == null) return;
      unawaited(_reportDueTimers());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _voiceQuestion?.cancel();
    unawaited(_voiceRecorder?.dispose());
    unawaited(_voiceListener?.dispose());
    WidgetsBinding.instance.removeObserver(this);
    unawaited(ref.read(deviceCapabilitiesProvider).setKeepScreenOn(false));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final session = _session;
    if (session == null) return;
    unawaited(
      ref
          .read(deviceCapabilitiesProvider)
          .setKeepScreenOn(
            !session.isComplete && state != AppLifecycleState.detached,
          ),
    );
    if (state == AppLifecycleState.resumed) {
      unawaited(_reportDueTimers());
    }
  }

  Future<void> _reportDueTimers() async {
    // The ticker and the resumed lifecycle callback can arrive in the same
    // frame.  Serialize this read/mark/write sequence so both callbacks
    // cannot emit the same timer_due event before either one updates the
    // persisted idempotency marker.
    if (_reportingDueTimers) return;
    _reportingDueTimers = true;
    try {
      await _reportDueTimersOnce();
    } finally {
      _reportingDueTimers = false;
    }
  }

  Future<void> _reportDueTimersOnce() async {
    final session = _session;
    if (session == null) return;
    final now = DateTime.now().toUtc();
    final due = session.timers
        .where((timer) => timer.isDueAt(now) && !timer.hasReportedDue)
        .toList();
    if (due.isEmpty) return;
    final dueIds = {for (final timer in due) timer.id};
    await _save(
      session.copyWith(
        timers: [
          for (final timer in session.timers)
            dueIds.contains(timer.id)
                ? timer.copyWithStatus('running', dueReportedAt: now)
                : timer,
        ],
      ),
      event: 'timer_due',
    );
  }

  Future<void> _load() async {
    final session = await ref
        .read(cookingSessionStoreProvider)
        ?.read(widget.sessionId);
    if (mounted) setState(() => _session = session);
    if (session != null) {
      unawaited(
        ref
            .read(deviceCapabilitiesProvider)
            .setKeepScreenOn(!session.isComplete),
      );
      final now = DateTime.now().toUtc();
      for (final timer in session.timers.where(
        (item) => item.status == 'running',
      )) {
        await _scheduleTimerReminder(timer, now);
      }
    }
  }

  Future<void> _scheduleTimerReminder(
    CookingTimerState timer,
    DateTime now,
  ) async {
    final remaining = timer.remainingAt(now);
    if (remaining <= 0 || timer.hasReportedDue) return;
    await ref
        .read(deviceCapabilitiesProvider)
        .scheduleTimerReminder(
          id: timer.id,
          dueAt: now.add(Duration(seconds: remaining)),
          title: '做菜计时结束',
          body: '步骤计时已结束，可以回来继续做菜。',
        );
  }

  Future<void> _save(CookingSession session, {String? event}) async {
    await ref.read(cookingSessionStoreProvider)?.write(session);
    if (event != null) {
      await ref
          .read(eventRecorderProvider)
          .record(
            eventType: 'cooking.session',
            typeVersion: 1,
            correlation: EventCorrelationIds(
              recipeVersionId: session.snapshot.versionId,
            ),
            content: {
              'session_id': session.id,
              'event': event,
              'step_index': session.stepIndex,
              'trigger': event == 'timer_due' ? 'local_clock' : 'user_action',
              'source': 'cooking_session',
            },
          );
    }
    if (mounted) setState(() => _session = session);
  }

  Future<void> _move(int delta) async {
    final session = _session;
    if (session == null || session.steps.isEmpty || session.isComplete) return;
    final next = (session.stepIndex + delta).clamp(
      -1,
      session.steps.length - 1,
    );
    if (next == session.stepIndex) return;
    if (delta > 0 &&
        next >= 0 &&
        !session.dependenciesReady(session.steps[next])) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('请先完成前置步骤，再继续。')));
      }
      return;
    }
    final reached = [...session.reached];
    final completed = [...session.completed];
    if (delta > 0 && session.stepIndex >= 0) {
      final previous = session.steps[session.stepIndex].id;
      if (!completed.contains(previous)) completed.add(previous);
    }
    if (next >= 0 && !reached.contains(session.steps[next].id)) {
      reached.add(session.steps[next].id);
    }
    await _save(
      session.copyWith(stepIndex: next, reached: reached, completed: completed),
      event: delta > 0 ? 'step_forward' : 'step_back',
    );
  }

  Future<void> _toggleTimer(RecipeStep step) async {
    final session = _session;
    final seconds = step.durationSeconds ?? 0;
    if (session == null || seconds <= 0) return;
    await ref
        .read(permissionServiceProvider)
        .request(AppPermission.notifications);
    final existing = session.timers
        .where((timer) => timer.stepId == step.id && timer.status == 'running')
        .firstOrNull;
    if (existing != null) {
      final paused = existing.copyWithStatus(
        'paused',
        pausedAt: DateTime.now().toUtc(),
      );
      await _save(
        session.copyWith(
          timers: [
            for (final timer in session.timers)
              timer.id == paused.id ? paused : timer,
          ],
        ),
        event: 'timer_pause',
      );
      await ref.read(deviceCapabilitiesProvider).cancelTimerReminder(paused.id);
      return;
    }
    final paused = session.timers
        .where((timer) => timer.stepId == step.id && timer.status == 'paused')
        .firstOrNull;
    if (paused != null) {
      final resumed = CookingTimerState(
        id: paused.id,
        stepId: paused.stepId,
        startedAt: paused.startedAt,
        durationSeconds: paused.durationSeconds,
        pausedSeconds:
            paused.pausedSeconds +
            DateTime.now().toUtc().difference(paused.pausedAt!).inSeconds,
        dueReportedAt: paused.dueReportedAt,
        status: 'running',
      );
      await _save(
        session.copyWith(
          timers: [
            for (final timer in session.timers)
              timer.id == resumed.id ? resumed : timer,
          ],
        ),
        event: 'timer_resume',
      );
      await ref
          .read(deviceCapabilitiesProvider)
          .scheduleTimerReminder(
            id: resumed.id,
            dueAt: DateTime.now().toUtc().add(
              Duration(seconds: resumed.remainingAt(DateTime.now().toUtc())),
            ),
            title: '做菜计时结束',
            body: '步骤计时已结束，可以回来继续做菜。',
          );
      return;
    }
    final timer = CookingTimerState(
      id: newUuidV4(),
      stepId: step.id,
      startedAt: DateTime.now().toUtc(),
      durationSeconds: seconds,
    );
    await _save(
      session.copyWith(timers: [...session.timers, timer]),
      event: 'timer_start',
    );
    await ref
        .read(deviceCapabilitiesProvider)
        .scheduleTimerReminder(
          id: timer.id,
          dueAt: timer.startedAt.add(Duration(seconds: timer.durationSeconds)),
          title: '做菜计时结束',
          body: '步骤计时已结束，可以回来继续做菜。',
        );
  }

  Future<void> _complete() async {
    final session = _session;
    if (session == null || session.steps.isEmpty) return;
    final completed = [...session.completed];
    final currentIndex = session.stepIndex;
    if (currentIndex >= 0 && currentIndex < session.steps.length) {
      final current = session.steps[currentIndex].id;
      if (!completed.contains(current)) completed.add(current);
    }
    final unfinished = session.steps
        .where(
          (step) =>
              !completed.contains(step.id) &&
              !session.skipped.contains(step.id),
        )
        .toList();
    if (unfinished.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('还有 ${unfinished.length} 个步骤未完成，请逐步执行或跳过。')),
        );
      }
      return;
    }
    // A completed session must not leave native alarms behind. Keep the timer
    // records (they are part of the execution evidence), but mark them
    // cancelled so a late alarm cannot claim that this finished session still
    // needs attention.
    final finished = session.copyWith(
      status: 'completed',
      completed: completed,
      timers: [
        for (final timer in session.timers)
          timer.status == 'running' || timer.status == 'paused'
              ? timer.copyWithStatus('cancelled')
              : timer,
      ],
      finishedAt: DateTime.now().toUtc(),
    );
    await _save(finished, event: 'completed');
    for (final timer in session.timers) {
      if (timer.status == 'running' || timer.status == 'paused') {
        await ref
            .read(deviceCapabilitiesProvider)
            .cancelTimerReminder(timer.id);
      }
    }
  }

  Future<void> _skipCurrent() async {
    final session = _session;
    if (session == null || session.stepIndex < 0) return;
    final stepId = session.steps[session.stepIndex].id;
    if (session.skipped.contains(stepId)) return;
    await _save(
      session.copyWith(skipped: [...session.skipped, stepId]),
      event: 'step_skip',
    );
  }

  /// Run a validated transcript from the active offline command recognizer.
  Future<void> runVoiceCommand(String transcript) async {
    final command = _voiceCommands.accept(transcript, DateTime.now());
    if (_voiceRecorder != null) return;
    final session = _session;
    if (command == null || session == null || session.isComplete) return;
    switch (command) {
      case CookingVoiceCommand.next:
        await _move(1);
      case CookingVoiceCommand.previous:
        await _move(-1);
      case CookingVoiceCommand.repeat:
        if (mounted) setState(() {});
      case CookingVoiceCommand.startTimer:
        final index = session.stepIndex;
        if (index < 0 || index >= session.steps.length) return;
        final step = session.steps[index];
        final existing = session.timers
            .where(
              (timer) => timer.stepId == step.id && timer.status == 'running',
            )
            .firstOrNull;
        if (existing == null && (step.durationSeconds ?? 0) > 0) {
          await _toggleTimer(step);
        }
      case CookingVoiceCommand.pauseTimer:
        final index = session.stepIndex;
        if (index < 0 || index >= session.steps.length) return;
        final step = session.steps[index];
        final running = session.timers.any(
          (timer) => timer.stepId == step.id && timer.status == 'running',
        );
        if (running) await _toggleTimer(step);
    }
    await _save(session.copyWith(), event: 'voice_command_${command.name}');
  }

  Future<void> _recordQuestion() async {
    final session = _session;
    if (session == null || session.stepIndex < 0) return;
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('记录问题'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.isEmpty) return;
    await _save(
      session.copyWith(
        questions: [
          ...session.questions,
          {'step_id': session.steps[session.stepIndex].id, 'text': text},
        ],
      ),
      event: 'question_recorded',
    );
  }

  Future<void> _recordAdjustment() async {
    final session = _session;
    if (session == null || session.stepIndex < 0) return;
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('记录临时调整'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '例如：少放一点盐'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.isEmpty) return;
    await _save(
      session.copyWith(
        adjustments: [
          ...session.adjustments,
          {
            'step_id': session.steps[session.stepIndex].id,
            'text': text,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          },
        ],
      ),
      event: 'adjustment_recorded',
    );
  }

  Future<void> _startVoiceQuestion() async {
    await _stopVoiceCommands();
    final state = await ref
        .read(permissionServiceProvider)
        .request(AppPermission.microphone);
    if (!mounted || state != PermissionState.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('未获得麦克风权限，语音提问已取消。')));
      }
      return;
    }
    final session = _session;
    if (session == null || session.stepIndex < 0) return;
    final recognizer = SherpaOfflineChineseRecognizer();
    final modelState = await recognizer.initialize(
      const OfflineChineseModel(
        modelPath: 'assets/models/zh/encoder.onnx',
        decoderPath: 'assets/models/zh/decoder.onnx',
        joinerPath: 'assets/models/zh/joiner.onnx',
        tokensPath: 'assets/models/zh/tokens.txt',
        language: 'zh-CN',
      ),
    );
    if (modelState is! OfflineModelReady) {
      recognizer.dispose();
      if (mounted) {
        setState(() => _voiceUnavailable = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((modelState as OfflineModelUnavailable).reason),
          ),
        );
      }
      return;
    }
    final recorder = PressAndHoldVoiceQuestion(recognizer);
    try {
      await recorder.pressDown(
        sessionId: session.id,
        versionId: session.snapshot.versionId,
        stepId: session.steps[session.stepIndex].id,
      );
    } catch (error) {
      await recorder.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('无法开始录音：$error')));
      }
      return;
    }
    _voiceRecorder = recorder;
    _voiceQuestion = recorder.lifecycle;
    if (mounted) setState(() {});
  }

  Future<void> _finishVoiceQuestion() async {
    final recorder = _voiceRecorder;
    final session = _session;
    if (recorder == null || session == null) return;
    final lifecycle = recorder.lifecycle;
    final saved = await recorder.release();
    if (!saved || !mounted || lifecycle == null) {
      if (mounted) {
        final reason = lifecycle?.error ?? '语音提问已取消';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(reason)));
      }
      return;
    }
    await _save(
      session.copyWith(
        questions: [
          ...session.questions,
          {
            'session_id': lifecycle.sessionId,
            'version_id': lifecycle.versionId,
            'step_id': lifecycle.stepId,
            'text': lifecycle.text,
            'status': '已记下，暂时不能即时回答',
            'created_at': DateTime.now().toUtc().toIso8601String(),
          },
        ],
      ),
      event: 'question_recorded',
    );
    await recorder.dispose();
    _voiceRecorder = null;
    _voiceQuestion = null;
    if (mounted) setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已记下，暂时不能即时回答。')));
    }
  }

  Future<void> _cancelVoiceQuestion() async {
    final recorder = _voiceRecorder;
    if (recorder == null) return;
    await recorder.cancel();
    await recorder.dispose();
    _voiceRecorder = null;
    _voiceQuestion = null;
    if (mounted) setState(() {});
  }

  Future<void> _toggleVoiceCommands() async {
    final listener = _voiceListener;
    if (listener != null) {
      await listener.dispose();
      if (mounted) setState(() => _voiceListener = null);
      return;
    }
    final permission = await ref
        .read(permissionServiceProvider)
        .request(AppPermission.microphone);
    if (!mounted || permission != PermissionState.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('未获得麦克风权限，语音翻页未开启。')));
      }
      return;
    }
    final recognizer = SherpaOfflineChineseRecognizer();
    final state = await recognizer.initialize(
      const OfflineChineseModel(
        modelPath: 'assets/models/zh/encoder.onnx',
        decoderPath: 'assets/models/zh/decoder.onnx',
        joinerPath: 'assets/models/zh/joiner.onnx',
        tokensPath: 'assets/models/zh/tokens.txt',
        language: 'zh-CN',
      ),
    );
    if (state is! OfflineModelReady) {
      recognizer.dispose();
      if (mounted) {
        setState(() => _voiceUnavailable = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((state as OfflineModelUnavailable).reason)),
        );
      }
      return;
    }
    final next = OfflineCookingVoiceListener(
      recognizer: recognizer,
      onTranscript: runVoiceCommand,
    );
    try {
      await next.start();
      if (mounted) setState(() => _voiceListener = next);
    } catch (error) {
      await next.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('无法开始语音翻页：$error')));
      }
    }
  }

  Future<void> _stopVoiceCommands() async {
    final listener = _voiceListener;
    if (listener == null) return;
    await listener.dispose();
    _voiceListener = null;
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final steps = session.steps;
    if (session.isComplete) {
      return Scaffold(
        appBar: AppBar(title: const Text('做菜完成')),
        body: Center(
          child: Text(
            '已完成 ${session.snapshot.detail.dish.name}',
            key: const ValueKey('cooking-complete'),
          ),
        ),
      );
    }
    final index = session.stepIndex;
    final current = index >= 0 && index < steps.length ? steps[index] : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(session.snapshot.detail.dish.name),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            tooltip: '暂离',
          ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) =>
            _move((details.primaryVelocity ?? 0) < 0 ? 1 : -1),
        onTap: () => _move(1),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (index < 0) ...[
              Text('先准备食材', style: Theme.of(context).textTheme.headlineMedium),
              for (final ingredient
                  in session.snapshot.detail.version.snapshot.ingredients ??
                      const [])
                ListTile(
                  title: Text(ingredient.displayName),
                  trailing: Text('${ingredient.quantity} ${ingredient.unit}'),
                ),
              FilledButton.icon(
                onPressed: () => _move(1),
                icon: const Icon(Icons.play_arrow),
                label: const Text('开始第一步'),
              ),
            ] else if (current != null) ...[
              Text(
                '步骤 ${index + 1} / ${steps.length}',
                style: GramTreeColors.of(context)
                    .numberStyle(Theme.of(context).textTheme.titleMedium!),
              ),
              const SizedBox(height: 16),
              Text(
                current.action ?? current.instruction,
                key: const ValueKey('cooking-action'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                current.instruction,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (current.heat != null) Text('火候：${current.heat}'),
              if (current.temperatureCelsius != null)
                Text('温度：${current.temperatureCelsius}°C'),
              if (current.cookware != null) Text('厨具：${current.cookware}'),
              if (current.doneness != null) Text('成熟判断：${current.doneness}'),
              if (current.why != null)
                ExpansionTile(
                  title: const Text('为什么'),
                  children: [Text(current.why!)],
                ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _toggleTimer(current),
                    icon: const Icon(Icons.timer_outlined),
                    label: Text(
                      current.durationSeconds == 0
                          ? '无计时'
                          : '计时 ${current.durationSeconds} 秒',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _skipCurrent,
                    icon: const Icon(Icons.skip_next),
                    label: const Text('跳过'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _voiceUnavailable ? null : _toggleVoiceCommands,
                    icon: Icon(
                      _voiceListener?.isRunning == true
                          ? Icons.mic
                          : Icons.mic_none,
                    ),
                    label: Text(
                      _voiceUnavailable
                          ? '语音不可用'
                          : _voiceListener?.isRunning == true
                          ? '关闭语音翻页'
                          : '开启语音翻页',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _recordQuestion,
                    icon: const Icon(Icons.help_outline),
                    label: const Text('记录问题'),
                  ),
                  GestureDetector(
                    onLongPressStart: (_) => _startVoiceQuestion(),
                    onLongPressEnd: (_) => _finishVoiceQuestion(),
                    onLongPressCancel: _cancelVoiceQuestion,
                    child: OutlinedButton.icon(
                      onPressed: null,
                      icon: Icon(
                        _voiceQuestion?.state == VoiceQuestionState.recording
                            ? Icons.mic
                            : Icons.mic_none,
                      ),
                      label: Text(
                        _voiceUnavailable
                            ? '语音不可用'
                            : _voiceQuestion?.state ==
                                  VoiceQuestionState.recording
                            ? '松开结束录音'
                            : '按住语音提问',
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _recordAdjustment,
                    icon: const Icon(Icons.edit_note),
                    label: const Text('记录临时调整'),
                  ),
                  OutlinedButton.icon(
                    onPressed: index == 0 ? null : () => _move(-1),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('上一步'),
                  ),
                  FilledButton.icon(
                    onPressed: index == steps.length - 1
                        ? _complete
                        : () => _move(1),
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(index == steps.length - 1 ? '完成' : '下一步'),
                  ),
                ],
              ),
              for (final timer in session.timers.where(
                (item) => item.status != 'cancelled',
              ))
                ListTile(
                  key: ValueKey('cooking-timer-${timer.id}'),
                  title: Text('步骤计时'),
                  trailing: Text(timer.remainingAt(DateTime.now()).toString()),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

extension on CookingTimerState {
  CookingTimerState copyWithStatus(
    String status, {
    DateTime? pausedAt,
    DateTime? dueReportedAt,
  }) => CookingTimerState(
    id: id,
    stepId: stepId,
    startedAt: startedAt,
    durationSeconds: durationSeconds,
    pausedSeconds: pausedSeconds,
    pausedAt: pausedAt,
    dueReportedAt: dueReportedAt ?? this.dueReportedAt,
    status: status,
  );
}
