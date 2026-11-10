import 'dart:async';
import 'dart:ui';

import '../engine/checkin_schedule.dart';
import '../models/check_outcome.dart';
import '../models/data/user_settings_data.dart';
import '../models/enums/check_action.dart';
import '../models/enums/heat_level.dart';
import 'analytics_service.dart';
import 'notification_service.dart';
import 'records_service.dart';
import 'share_service.dart';

/// What the user does with a check's result: send, hold, cool down, edit or
/// delete (docs/02-features.md). Used by the result and cool-down screens,
/// so the privacy rules live in one place:
///
/// * text is saved only for a held message, or when "Keep message text" is
///   on;
/// * a send while Heated gets a next-morning check-in, if enabled;
/// * analytics say only that something happened.
class _OutcomeService {
  /// Opens the share sheet. False when the user dismissed it, and nothing
  /// stays recorded then.
  ///
  /// The send is recorded *before* the sheet opens: on Android the sheet's
  /// result only reaches the app when the user comes back to it, and someone
  /// who shares to WhatsApp and stays there (or whose Cool Off is closed in
  /// the background meanwhile) must still have the send and its check-in.
  /// A dismissed sheet undoes it.
  Future<bool> send(
    CheckOutcome outcome, {
    required UserSettingsData settings,
    Rect? origin,
    bool checkinSoon = false,
  }) async {
    final heated = outcome.result.level == HeatLevel.heated;
    final messageId = await recordsService.recordSent(
      body: outcome.text,
      recipientLabel: outcome.recipient,
      checkId: outcome.checkId,
      keepText: settings.keepMessageText,
    );
    await recordsService.setCheckAction(
      outcome.checkId,
      heated ? CheckAction.sentAnyway : CheckAction.sent,
      messageId: messageId,
    );
    if (heated && settings.checkinEnabled) {
      await notificationService.scheduleCheckin(
        checkId: outcome.checkId,
        // QA demo mode: a minute from now, to test and film the
        // notification's 👍/👎 buttons without waiting for the morning.
        fireAt: checkinSoon
            ? DateTime.now().add(const Duration(minutes: 1))
            : CheckinSchedule.dueAt(DateTime.now(), settings.checkinMinutes),
      );
    }

    final bool shared;
    try {
      shared = await shareService.shareText(outcome.text, origin: origin);
    } on Object {
      await _undoSend(outcome.checkId, messageId);
      rethrow;
    }
    if (!shared) {
      await _undoSend(outcome.checkId, messageId);
      return false;
    }
    unawaited(analyticsService.logMessageShared());
    return true;
  }

  Future<void> _undoSend(String checkId, String messageId) async {
    await notificationService.cancelFor(checkId);
    await recordsService.undoSent(checkId: checkId, messageId: messageId);
  }

  /// Holds the message for [UserSettingsData.holdMinutes]; returns when it is
  /// ready.
  Future<DateTime> hold(
    CheckOutcome outcome, {
    required UserSettingsData settings,
  }) async {
    final until = DateTime.now().add(Duration(minutes: settings.holdMinutes));
    final messageId = await recordsService.holdMessage(
      body: outcome.text,
      recipientLabel: outcome.recipient,
      holdUntil: until,
      checkId: outcome.checkId,
    );
    await recordsService.setCheckAction(
      outcome.checkId,
      CheckAction.held,
      messageId: messageId,
    );
    await notificationService.scheduleHoldEnded(
      messageId: messageId,
      fireAt: until,
    );
    unawaited(analyticsService.logMessageHeld());
    return until;
  }

  Future<void> startCooldown(CheckOutcome outcome) async {
    await recordsService.setCheckAction(
      outcome.checkId,
      CheckAction.cooledDown,
    );
    unawaited(analyticsService.logCooldownStarted());
  }

  Future<void> edit(CheckOutcome outcome) =>
      recordsService.setCheckAction(outcome.checkId, CheckAction.edited);

  Future<void> discard(CheckOutcome outcome) =>
      recordsService.setCheckAction(outcome.checkId, CheckAction.discarded);
}

final outcomeService = _OutcomeService();
