import 'package:built_value/built_value.dart';

import '../../engine/text_heat.dart';

part 'draft_state.g.dart';

/// The message being written. In memory only: message text is saved only
/// when a message is held (docs/11-data-and-sync.md).
abstract class DraftState implements Built<DraftState, DraftStateBuilder> {
  factory DraftState([void Function(DraftStateBuilder) updates]) = _$DraftState;

  DraftState._();

  @BuiltValueHook(initializeBuilder: true)
  static void _initialize(DraftStateBuilder b) => b
    ..text = ''
    ..recipient = ''
    ..revision = 0;

  String get text;

  /// Optional "to whom" label.
  String get recipient;

  /// Bumped when the draft is replaced from outside the text field (cleared
  /// after sending, or filled from a held message), so the field reloads.
  int get revision;

  /// How the text reads, live while typing (on-device heuristics only).
  @memoized
  TextHeatResult get textHeat => TextHeat.analyze(text);

  bool get canCheck => text.trim().isNotEmpty;

  String? get recipientOrNull =>
      recipient.trim().isEmpty ? null : recipient.trim();
}
