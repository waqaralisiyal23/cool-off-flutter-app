import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

part 'write_state.g.dart';

/// A heated send waiting for its next-morning answer (Extra 2).
class PendingCheckin {
  const PendingCheckin({
    required this.checkId,
    required this.sentAt,
    required this.recipient,
    required this.text,
  });

  final String checkId;

  /// Local time.
  final DateTime sentAt;
  final String? recipient;

  /// Only when "Keep message text" is on.
  final String? text;
}

abstract class WriteState implements Built<WriteState, WriteStateBuilder> {
  factory WriteState([void Function(WriteStateBuilder) updates]) = _$WriteState;

  WriteState._();

  BuiltList<PendingCheckin> get checkins;

  /// Set briefly after an answer, for the thank-you line.
  String? get lastAnswerNote;
}
