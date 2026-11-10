import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wc_dart_framework/wc_dart_framework.dart';

import '../../../../models/data/message_data.dart';
import '../../../../services/analytics_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/records_service.dart';
import '../../../../services/share_service.dart';
import '../../../../widgets/cubit/cubit.dart';
import 'held_state.dart';

part 'held_bloc.bloc.g.dart';

final _logger = Logger('held_bloc.dart');

/// Held messages (docs/02-features.md §7). Provided with the tabs, so the
/// tab bar can show how many are waiting.
@BlocGen()
class HeldBloc extends BVCubit<HeldState, HeldStateBuilder>
    with _$HeldBlocMixin {
  HeldBloc() : super(HeldState());

  factory HeldBloc.of(BuildContext context) =>
      BlocProvider.of<HeldBloc>(context);

  StreamSubscription<List<MessageData>>? _subscription;

  void start() {
    unawaited(_subscription?.cancel());
    _subscription = recordsService.watchHeld().listen(
      (messages) =>
          emit(state.rebuild((b) => b.messages = ListBuilder(messages))),
      onError: (Object e, StackTrace stackTrace) {
        addError(e, stackTrace);
        emit(state.rebuild((b) => b.error = "Couldn't load held messages."));
      },
    );
  }

  /// Opens the share sheet; when used, the message counts as sent.
  Future<void> send(
    MessageData message, {
    required bool keepText,
    Rect? origin,
  }) => _guard(() async {
    final sent = await shareService.shareText(
      message.body ?? '',
      origin: origin,
    );
    if (!sent) {
      return;
    }
    await recordsService.markHeldSent(message.id, keepText: keepText);
    await notificationService.cancelFor(message.id);
    unawaited(analyticsService.logMessageShared());
  });

  Future<void> delete(MessageData message, {required bool keepText}) =>
      _guard(() async {
        await recordsService.discardHeld(message.id, keepText: keepText);
        await notificationService.cancelFor(message.id);
      });

  /// Moves the message back into the draft: the held copy is dropped.
  Future<void> takeForEditing(MessageData message, {required bool keepText}) =>
      delete(message, keepText: keepText);

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (e) {
      _logger.warning('Held message action failed: $e');
      emit(
        state.rebuild((b) => b.error = "That didn't work. Please try again."),
      );
      emit(state.rebuild((b) => b.error = null));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
