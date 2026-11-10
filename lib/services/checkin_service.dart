import '../engine/auto_tune.dart';
import '../models/enums/reflection_answer.dart';
import 'records_service.dart';
import 'settings_service.dart';

/// The next-morning check-in answer (Extra 2, docs/03-heat-engine.md):
/// saved once, then the Heated cutoff is re-tuned from every answer.
///
/// Uses only the database, so it runs the same from the Write tab's card,
/// from a notification button while the app is open, and from a
/// notification button in a background isolate while the app is closed.
class _CheckinService {
  /// Saves [answer] for the heated send [checkId]. False when it was already
  /// answered (the card and the notification can both be used).
  Future<bool> answer(String checkId, ReflectionAnswer answer) async {
    final earlier = await recordsService.getReflections();
    if (earlier.any((r) => r.checkRecordId == checkId)) {
      return false;
    }
    await recordsService.saveReflection(checkRecordId: checkId, answer: answer);
    // Newest first, as AutoTune expects.
    final answers = [answer, ...earlier.map((r) => r.answer)];
    final offset = AutoTune.offsetFor(answers);
    final settings = await settingsService.ensure();
    if (settings.autoTuneOffset != offset) {
      await settingsService.update(autoTuneOffset: offset);
    }
    return true;
  }
}

final checkinService = _CheckinService();
