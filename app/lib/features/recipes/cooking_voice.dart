import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// Offline model metadata required by the cooking voice features.
class OfflineChineseModel {
  const OfflineChineseModel({
    required this.modelPath,
    required this.tokensPath,
    required this.language,
    this.decoderPath,
    this.joinerPath,
  });

  final String modelPath;
  final String tokensPath;
  final String language;
  final String? decoderPath;
  final String? joinerPath;
}

sealed class OfflineModelState {
  const OfflineModelState();
}

class OfflineModelUninitialized extends OfflineModelState {
  const OfflineModelUninitialized();
}

class OfflineModelReady extends OfflineModelState {
  const OfflineModelReady(this.model);
  final OfflineChineseModel model;
}

class OfflineModelUnavailable extends OfflineModelState {
  const OfflineModelUnavailable(this.reason);
  final String reason;
}

/// The model boundary is deliberately injectable: the app can use a native
/// sherpa-onnx implementation without making Flutter UI depend on that SDK.
abstract interface class OfflineChineseRecognizer {
  OfflineModelState get state;
  Future<OfflineModelState> initialize(OfflineChineseModel model);
  Future<String> transcribe(Uint8List audio);
}

/// Validates the production model contract before native recognition is used.
/// Missing model files are reported as unavailable; no text is fabricated.
class ContractOfflineChineseRecognizer implements OfflineChineseRecognizer {
  ContractOfflineChineseRecognizer({this.fileExists = _defaultFileExists});

  final Future<bool> Function(String path) fileExists;
  OfflineModelState _state = const OfflineModelUninitialized();

  @override
  OfflineModelState get state => _state;

  @override
  Future<OfflineModelState> initialize(OfflineChineseModel model) async {
    if (model.language != 'zh-CN') {
      return _state = const OfflineModelUnavailable('仅支持 zh-CN 离线模型');
    }
    final hasModel = await fileExists(model.modelPath);
    final hasTokens = await fileExists(model.tokensPath);
    if (!hasModel || !hasTokens) {
      return _state = OfflineModelUnavailable(
        '离线中文模型资源缺失：${!hasModel ? model.modelPath : model.tokensPath}',
      );
    }
    return _state = OfflineModelReady(model);
  }

  @override
  Future<String> transcribe(Uint8List audio) async {
    if (_state is! OfflineModelReady) {
      throw StateError('离线中文模型未初始化');
    }
    throw UnsupportedError('需要在原生 sherpa-onnx bridge 中执行转写');
  }

  static Future<bool> _defaultFileExists(String path) async => false;
}

/// Production sherpa-onnx adapter. Model files must be shipped by the app;
/// recognition never downloads a model at runtime.
class SherpaOfflineChineseRecognizer implements OfflineChineseRecognizer {
  sherpa.OfflineRecognizer? _recognizer;
  OfflineModelState _state = const OfflineModelUninitialized();

  @override
  OfflineModelState get state => _state;

  @override
  Future<OfflineModelState> initialize(OfflineChineseModel model) async {
    if (model.language != 'zh-CN') {
      return _state = const OfflineModelUnavailable('仅支持 zh-CN 离线模型');
    }
    try {
      await sherpa.initBindingsAsync();
      _recognizer?.free();
      final config = sherpa.OfflineRecognizerConfig(
        model: sherpa.OfflineModelConfig(
          transducer: sherpa.OfflineTransducerModelConfig(
            encoder: model.modelPath,
            decoder: model.decoderPath ?? model.modelPath,
            joiner: model.joinerPath ?? model.modelPath,
          ),
          tokens: model.tokensPath,
          modelType: 'transducer',
          numThreads: 1,
          debug: false,
        ),
      );
      _recognizer = sherpa.OfflineRecognizer(config);
      return _state = OfflineModelReady(model);
    } catch (error) {
      return _state = OfflineModelUnavailable('离线中文模型初始化失败：$error');
    }
  }

  Future<String> transcribeSamples(Float32List samples) async {
    final recognizer = _recognizer;
    if (recognizer == null || _state is! OfflineModelReady) {
      throw StateError('离线中文模型未初始化');
    }
    final stream = recognizer.createStream();
    try {
      stream.acceptWaveform(samples: samples, sampleRate: 16000);
      recognizer.decode(stream);
      return recognizer.getResult(stream).text.trim();
    } finally {
      stream.free();
    }
  }

  @override
  Future<String> transcribe(Uint8List audio) =>
      throw ArgumentError('请先将 PCM 音频解码为 Float32List');

  void dispose() {
    _recognizer?.free();
    _recognizer = null;
    _state = const OfflineModelUninitialized();
  }
}

enum CookingVoiceCommand { next, previous, repeat, startTimer, pauseTimer }

class CookingVoiceCommandParser {
  const CookingVoiceCommandParser();

  CookingVoiceCommand? parse(String text) {
    final normalized = text.trim().replaceAll(RegExp(r'[，。！？、 ]'), '');
    if (normalized.isEmpty) return null;
    if (_matches(normalized, const ['下一步', '下一页', '继续', '往后'])) {
      return CookingVoiceCommand.next;
    }
    if (_matches(normalized, const ['上一步', '上一页', '返回'])) {
      return CookingVoiceCommand.previous;
    }
    if (_matches(normalized, const ['重复', '再说一遍', '重说'])) {
      return CookingVoiceCommand.repeat;
    }
    if (_matches(normalized, const ['开始计时', '计时开始', '启动计时'])) {
      return CookingVoiceCommand.startTimer;
    }
    if (_matches(normalized, const ['暂停计时', '计时暂停', '暂停'])) {
      return CookingVoiceCommand.pauseTimer;
    }
    return null;
  }

  bool _matches(String text, List<String> candidates) =>
      candidates.any((candidate) => text == candidate);
}

class VoiceCommandDeduplicator {
  VoiceCommandDeduplicator({this.window = const Duration(milliseconds: 900)});

  final Duration window;
  String? _lastText;
  DateTime? _lastAt;

  bool accept(String text, DateTime now) {
    final normalized = text.trim();
    if (normalized.isEmpty) return false;
    if (_lastText == normalized &&
        _lastAt != null &&
        now.difference(_lastAt!) < window) {
      return false;
    }
    _lastText = normalized;
    _lastAt = now;
    return true;
  }
}

class CookingVoiceController {
  CookingVoiceController({
    this.parser = const CookingVoiceCommandParser(),
    VoiceCommandDeduplicator? deduplicator,
  }) : deduplicator = deduplicator ?? VoiceCommandDeduplicator();

  final CookingVoiceCommandParser parser;
  final VoiceCommandDeduplicator deduplicator;

  CookingVoiceCommand? accept(String text, DateTime now) {
    if (!deduplicator.accept(text, now)) return null;
    return parser.parse(text);
  }
}

enum VoiceQuestionState {
  idle,
  recording,
  transcribing,
  saved,
  failed,
  cancelled,
}

class VoiceQuestionLifecycle {
  VoiceQuestionLifecycle({
    required this.stepId,
    required this.sessionId,
    required this.versionId,
  });

  final String stepId;
  final String sessionId;
  final String versionId;
  VoiceQuestionState state = VoiceQuestionState.idle;
  String? text;
  String? error;

  void pressDown() {
    if (state == VoiceQuestionState.idle ||
        state == VoiceQuestionState.failed) {
      state = VoiceQuestionState.recording;
      text = null;
      error = null;
    }
  }

  void cancel() {
    if (state == VoiceQuestionState.recording ||
        state == VoiceQuestionState.transcribing) {
      state = VoiceQuestionState.cancelled;
    }
  }

  Future<bool> release({required Future<String> Function() transcribe}) async {
    if (state != VoiceQuestionState.recording) return false;
    state = VoiceQuestionState.transcribing;
    try {
      final result = (await transcribe()).trim();
      if (state != VoiceQuestionState.transcribing) return false;
      if (result.isEmpty) throw StateError('没有识别到语音');
      text = result;
      state = VoiceQuestionState.saved;
      return true;
    } catch (e) {
      error = e.toString();
      state = VoiceQuestionState.failed;
      return false;
    }
  }
}
