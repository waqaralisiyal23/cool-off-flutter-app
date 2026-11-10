import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wc_dart_framework/wc_dart_framework.dart';

import '../../../../engine/checkin_schedule.dart';
import '../../../../models/data/check_record_data.dart';
import '../../../../models/data/reflection_data.dart';
import '../../../../models/data/user_settings_data.dart';
import '../../../../models/enums/reflection_answer.dart';
import '../../../../services/analytics_service.dart';
import '../../../../services/checkin_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/records_service.dart';
import '../../../../widgets/cubit/cubit.dart';
import 'write_state.dart';

part 'write_bloc.bloc.g.dart';

final _logger = Logger('write_bloc.dart');

/// The Write tab: which next-morning check-ins are due (Extra 2), and their
/// answers, which also tune sensitivity (docs/03-heat-engine.md).
@BlocGen()
class WriteBloc extends BVCubit<WriteState, WriteStateBuilder>
    with _$WriteBlocMixin {
  WriteBloc({
    required Stream<UserSettingsData?> settings,
    required UserSettingsData? initialSettings,
    required Stream<bool> demoCheckinsNow,
    required bool initialDemo,
  }) : _settings = initialSettings,
       _demo = initialDemo,
       super(WriteState()) {
    _listen(settings, demoCheckinsNow);
    _clock = Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(_refresh()),
    );
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(_refresh()));
  }

  factory WriteBloc.of(BuildContext context) =>
      BlocProvider.of<WriteBloc>(context);

  final List<StreamSubscription<Object?>> _subscriptions = [];
  late final Timer _clock;
  late final AppLifecycleListener _lifecycle;

  List<CheckRecordData> _sends = const [];
  List<ReflectionData> _reflections = const [];
  UserSettingsData? _settings;
  bool _demo;

  void _listen(Stream<UserSettingsData?> settings, Stream<bool> demo) {
    _subscriptions
      ..add(
        recordsService.watchHeatedSends().listen((v) {
          _sends = v;
          unawaited(_refresh());
        }, onError: addError),
      )
      ..add(
        recordsService.watchReflections().listen((v) {
          _reflections = v;
          unawaited(_refresh());
        }, onError: addError),
      )
      ..add(
        settings.listen((v) {
          _settings = v;
          unawaited(_refresh());
        }),
      )
      ..add(
        demo.listen((v) {
          _demo = v;
          unawaited(_refresh());
        }),
      );
  }

  /// Bumped by every refresh. A refresh that waited on the database while a
  /// newer one started is stale and must not overwrite it (on launch the
  /// sends can arrive before the answers, which would show answered
  /// check-ins again).
  int _generation = 0;

  Future<void> _refresh() async {
    final generation = ++_generation;
    final settings = _settings;
    if (settings == null || !settings.checkinEnabled) {
      emit(state.rebuild((b) => b.checkins.clear()));
      return;
    }
    final answered = {for (final r in _reflections) r.checkRecordId};
    final now = DateTime.now();
    final due = <PendingCheckin>[];
    for (final send in _sends) {
      if (answered.contains(send.id)) {
        continue;
      }
      final sentAt = send.checkedAt.toLocal();
      final isDue = _demo
          ? now.difference(sentAt) < CheckinSchedule.expiresAfter
          : CheckinSchedule.isDue(sentAt, settings.checkinMinutes, now);
      if (!isDue) {
        continue;
      }
      final messageId = send.messageId;
      final message = messageId == null
          ? null
          : await recordsService.getMessage(messageId);
      if (generation != _generation) {
        return;
      }
      due.add(
        PendingCheckin(
          checkId: send.id,
          sentAt: sentAt,
          recipient: message?.recipientLabel,
          text: settings.keepMessageText ? message?.body : null,
        ),
      );
    }
    if (generation == _generation) {
      emit(state.rebuild((b) => b.checkins.replace(due)));
    }
  }

  /// Saves the answer (which also re-tunes the Heated cutoff) and cancels
  /// the check-in notification if it has not fired yet.
  Future<void> answer(PendingCheckin checkin, ReflectionAnswer answer) async {
    emit(
      state.rebuild(
        (b) => b
          ..checkins.removeWhere((c) => c.checkId == checkin.checkId)
          ..lastAnswerNote = answer == ReflectionAnswer.glad
              ? 'Good call. Noted.'
              : 'Noted. Your answers teach Cool Off when to step in.',
      ),
    );
    try {
      if (await checkinService.answer(checkin.checkId, answer)) {
        unawaited(analyticsService.logCheckinAnswered());
      }
      await notificationService.cancelFor(checkin.checkId);
    } on Object catch (e) {
      _logger.warning('Saving a check-in answer failed: $e');
    }
  }

  void clearNote() => emit(state.rebuild((b) => b.lastAnswerNote = null));

  @override
  Future<void> close() async {
    _clock.cancel();
    _lifecycle.dispose();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
