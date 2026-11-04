import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:whisper_flutter_new/whisper_flutter_new.dart';
import 'coach.dart';
import 'pitch.dart';

/// The instructor's MOUTH. Android system text-to-speech (no model download):
/// the coach talks Swahili, the target words are spoken in es / ja / zh / ru.
class Voice {
  final FlutterTts tts = FlutterTts();

  /// Swahili voice found on this phone (sw-TZ / sw-KE / sw), or null -> the coach stays text-only
  /// (a wrong-language voice would teach wrong pronunciation, so we prefer silence).
  String? coachLocale;

  Future<void> init() async {
    await tts.awaitSpeakCompletion(true);
    await tts.setVolume(1.0);
    await recheckCoach();
  }

  /// (Re)detects an installed Swahili voice. Call again when the app returns from the voice installer.
  Future<bool> recheckCoach() async {
    coachLocale = null;
    for (final l in ['sw-TZ', 'sw-KE', 'sw']) {
      if (await available(l)) { coachLocale = l; break; }
    }
    return coachLocale != null;
  }

  /// Opens Android's own voice-data installer: the supported way to add a system voice (a silent install is not allowed).
  Future<void> openVoiceInstaller() async {
    try { await AndroidIntent(action: 'android.speech.tts.engine.INSTALL_TTS_DATA').launch(); } catch (_) {}
  }

  Future<void> say(String text, String locale, {double rate = 0.45, double pitch = 1.0}) async {
    try {
      await tts.stop();
      await tts.setLanguage(locale);
      await tts.setSpeechRate(rate);
      await tts.setPitch(pitch);
      await tts.speak(text);
    } catch (_) {}
  }

  /// Disappointed = lower + slower, proud = higher + brighter, strict = lowest + firm.
  Future<void> coach(Reaction r) async {
    final loc = coachLocale;
    if (loc == null) return;
    final p = switch (r.mood) {
      Mood.proud => [1.3, 0.52],
      Mood.happy => [1.15, 0.5],
      Mood.meh => [0.95, 0.42],
      Mood.sad => [0.72, 0.36],
      Mood.strict => [0.62, 0.38],
      Mood.think => [1.0, 0.45],
    };
    await say(r.line, loc, pitch: p[0], rate: p[1]);
  }

  Future<void> stop() async {
    try { await tts.stop(); } catch (_) {}
  }

  Future<bool> available(String locale) async {
    try {
      final a = await tts.isLanguageAvailable(locale);
      return a == true || a == 1;
    } catch (_) {
      return false;
    }
  }
}

/// The instructor's EARS: microphone + on-device Whisper (whisper.cpp ggml from Hugging Face
/// ggerganov/whisper.cpp). 'tiny' (~39M params) is the lightest multilingual model there is.
class Ear {
  final AudioRecorder _rec = AudioRecorder();
  Whisper? _w;
  String _modelName = '';

  Future<bool> hasPermission() => _rec.hasPermission();

  Future<String> start() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/say_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _rec.start(RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1), path: path);
    return path;
  }

  Future<String?> stop() => _rec.stop();

  /// Silence guard: Whisper hallucinates text on silence, so check there is real sound first.
  Future<bool> hasSignal(String path) async => (await Wav.read(path)).rms > 0.008;

  /// First call downloads the model (tiny = ~75 MB) from Hugging Face, then everything runs offline.
  Future<String> transcribe(String path, String lang, String model) async {
    if (_w == null || _modelName != model) {
      _modelName = model;
      _w = Whisper(
        model: model == 'base' ? WhisperModel.base : WhisperModel.tiny,
        downloadHost: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main',
      );
    }
    final dynamic r = await _w!.transcribe(
      transcribeRequest: TranscribeRequest(audio: path, language: lang, isNoTimestamps: true, splitOnWord: false),
    );
    final String text = r is String ? r : ((r.text ?? '') as String);
    return text.replaceAll(RegExp(r'\[[^\]]*\]|\([^)]*\)'), '').trim();
  }

  void dispose() { _rec.dispose(); }
}
