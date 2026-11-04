import 'models.dart';

/// The OPTIONAL live brain: CraneAILabs/swahili-gemma-1b writing a fresh Swahili tip.
/// The app never waits for it and never shows it as a setting: TipService (tips.dart) prefetches in the
/// background and uses the result on the learner's next attempt. If it is missing, slow, or dead, nothing changes.
///
/// Phase 2 implements this against the on-device model running in a SEPARATE Android process (`:brain`), so a
/// native crash there cannot take the app down. Until then the app runs with [NullBrain].
abstract class BrainClient {
  bool get ready;
  Future<String?> tip({required Lang lang, required String target, required String reading, required String heard, required double score, required int tries});
}

class NullBrain implements BrainClient {
  @override
  bool get ready => false;
  @override
  Future<String?> tip({required Lang lang, required String target, required String reading, required String heard, required double score, required int tries}) async => null;
}
