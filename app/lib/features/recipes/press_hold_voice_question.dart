import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import 'cooking_voice.dart';

/// Captures only while the user holds the question button. PCM stays in
/// memory and is discarded after transcription or cancellation.
class PressAndHoldVoiceQuestion {
  PressAndHoldVoiceQuestion(this.recognizer);

  final SherpaOfflineChineseRecognizer recognizer;
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _subscription;
  final _chunks = <Uint8List>[];
  VoiceQuestionLifecycle? _lifecycle;

  VoiceQuestionLifecycle? get lifecycle => _lifecycle;

  Future<void> pressDown({
    required String sessionId,
    required String versionId,
    required String stepId,
  }) async {
    if (_lifecycle?.state == VoiceQuestionState.recording) {
      return;
    }
    _lifecycle = VoiceQuestionLifecycle(
      sessionId: sessionId,
      versionId: versionId,
      stepId: stepId,
    )..pressDown();
    _chunks.clear();
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );
    _subscription = stream.listen(_chunks.add);
  }

  Future<bool> release() async {
    final item = _lifecycle;
    if (item == null || item.state != VoiceQuestionState.recording) {
      return false;
    }
    await _recorder.stop();
    await _subscription?.cancel();
    _subscription = null;
    final pcm = _decodePcm16(_chunks);
    _chunks.clear();
    return item.release(transcribe: () => recognizer.transcribeSamples(pcm));
  }

  Future<void> cancel() async {
    _lifecycle?.cancel();
    await _recorder.cancel();
    await _subscription?.cancel();
    _subscription = null;
    _chunks.clear();
  }

  Future<void> dispose() async {
    await cancel();
    await _recorder.dispose();
    recognizer.dispose();
  }

  Float32List _decodePcm16(List<Uint8List> chunks) {
    final bytes = chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
    final result = Float32List(bytes ~/ 2);
    var index = 0;
    for (final chunk in chunks) {
      for (var offset = 0; offset + 1 < chunk.length; offset += 2) {
        final value = chunk[offset] | (chunk[offset + 1] << 8);
        final signed = value >= 0x8000 ? value - 0x10000 : value;
        result[index++] = signed / 32768.0;
      }
    }
    return result;
  }
}
