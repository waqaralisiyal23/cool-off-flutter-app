import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wc_dart_framework/wc_dart_framework.dart';

import '../widgets/cubit/cubit.dart';
import 'states/draft_state.dart';

part 'draft_bloc.bloc.g.dart';

/// The message being written, shared by the main flow's screens: compose
/// edits it, the check reads it, and a send, hold or delete clears it.
@BlocGen()
class DraftBloc extends BVCubit<DraftState, DraftStateBuilder>
    with _$DraftBlocMixin {
  DraftBloc() : super(DraftState());

  factory DraftBloc.of(BuildContext context) =>
      BlocProvider.of<DraftBloc>(context);

  /// Typing in the field: no reload.
  void setText(String text) => emit(state.rebuild((b) => b.text = text));

  void setRecipient(String recipient) =>
      emit(state.rebuild((b) => b.recipient = recipient));

  /// Replaces the draft from outside the field.
  void load({required String text, String? recipient}) => emit(
    state.rebuild(
      (b) => b
        ..text = text
        ..recipient = recipient ?? ''
        ..revision = state.revision + 1,
    ),
  );

  void clear() => load(text: '');
}
