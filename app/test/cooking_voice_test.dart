import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/features/recipes/cooking_voice.dart';

void main() {
  group('offline Chinese cooking commands', () {
    final parser = const CookingVoiceCommandParser();
    test('parses all five commands and ignores unrelated speech', () {
      expect(parser.parse('下一步。'), CookingVoiceCommand.next);
      expect(parser.parse('上 一 步'), CookingVoiceCommand.previous);
      expect(parser.parse('重复'), CookingVoiceCommand.repeat);
      expect(parser.parse('开始计时'), CookingVoiceCommand.startTimer);
      expect(parser.parse('暂停计时'), CookingVoiceCommand.pauseTimer);
      expect(parser.parse('锅里有声音'), isNull);
    });

    test('deduplicates repeated recognition within the safety window', () {
      final dedupe = VoiceCommandDeduplicator();
      final now = DateTime.utc(2026, 10, 12);
      expect(dedupe.accept('下一步', now), isTrue);
      expect(
        dedupe.accept('下一步', now.add(const Duration(milliseconds: 100))),
        isFalse,
      );
      expect(dedupe.accept('下一步', now.add(const Duration(seconds: 1))), isTrue);
    });

    test(
      'model initialization reports missing resources without fake text',
      () async {
        final recognizer = ContractOfflineChineseRecognizer(
          fileExists: (path) async => path.endsWith('encoder.onnx'),
        );
        final state = await recognizer.initialize(
          const OfflineChineseModel(
            modelPath: 'encoder.onnx',
            tokensPath: 'tokens.txt',
            language: 'zh-CN',
          ),
        );
        expect(state, isA<OfflineModelUnavailable>());
        expect(() => recognizer.transcribe(Uint8List(0)), throwsStateError);
      },
    );
  });

  group('press-and-hold question lifecycle', () {
    VoiceQuestionLifecycle lifecycle() => VoiceQuestionLifecycle(
      stepId: 'step-a',
      sessionId: 'session-a',
      versionId: 'version-a',
    );

    test('freezes session/version/step and saves only returned text', () async {
      final item = lifecycle()..pressDown();
      expect(item.state, VoiceQuestionState.recording);
      final saved = await item.release(transcribe: () async => '锅要多热？');
      expect(saved, isTrue);
      expect(item.state, VoiceQuestionState.saved);
      expect(item.text, '锅要多热？');
      expect(item.sessionId, 'session-a');
      expect(item.versionId, 'version-a');
      expect(item.stepId, 'step-a');
    });

    test('empty or failed transcription is never saved', () async {
      final empty = lifecycle()..pressDown();
      expect(await empty.release(transcribe: () async => ''), isFalse);
      expect(empty.state, VoiceQuestionState.failed);
      expect(empty.text, isNull);

      final failed = lifecycle()..pressDown();
      expect(
        await failed.release(
          transcribe: () async => throw StateError('offline'),
        ),
        isFalse,
      );
      expect(failed.state, VoiceQuestionState.failed);
      expect(failed.text, isNull);
    });

    test('cancelled recording cannot later save a result', () async {
      final item = lifecycle()..pressDown();
      item.cancel();
      expect(await item.release(transcribe: () async => '不应保存'), isFalse);
      expect(item.state, VoiceQuestionState.cancelled);
      expect(item.text, isNull);
    });
  });
}
