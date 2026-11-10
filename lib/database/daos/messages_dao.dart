import 'package:drift/drift.dart';

import '../../models/data/message_data.dart';
import '../../models/enums/message_status.dart';
import '../app_database.dart';
import '../tables/messages.dart';

part 'messages_dao.g.dart';

/// Held and sent messages. Every method that ends a hold takes
/// `keepText`: unless it is on, the text is cleared from the row
/// (docs/11-data-and-sync.md).
@DriftAccessor(tables: [Messages])
class MessagesDao extends DatabaseAccessor<AppDatabase>
    with _$MessagesDaoMixin {
  MessagesDao(super.attachedDatabase);

  Future<String> addHeld({
    required String body,
    required String? recipientLabel,
    required DateTime holdUntil,
    required String? firstCheckId,
  }) => attachedDatabase.insertSyncable(
    messages,
    MessagesCompanion(
      body: Value(body),
      recipientLabel: Value(recipientLabel),
      status: const Value(MessageStatus.held),
      holdUntil: Value(holdUntil),
      firstCheckId: Value(firstCheckId),
    ),
  );

  /// A message sent straight from a result. [body] only when the user keeps
  /// message text.
  Future<String> addSent({
    required String? body,
    required String? recipientLabel,
    required DateTime sentAt,
    required String? firstCheckId,
  }) => attachedDatabase.insertSyncable(
    messages,
    MessagesCompanion(
      body: Value(body),
      recipientLabel: Value(recipientLabel),
      status: const Value(MessageStatus.sent),
      sentAt: Value(sentAt),
      firstCheckId: Value(firstCheckId),
    ),
  );

  Future<MessageData?> getById(String id) =>
      (select(messages)
            ..where((t) => t.id.equals(id) & attachedDatabase.isActive(t)))
          .getSingleOrNull();

  /// Held messages, the one that is ready first at the top.
  Stream<List<MessageData>> watchHeld() =>
      (select(messages)
            ..where(
              (t) =>
                  attachedDatabase.isActive(t) &
                  t.status.equalsValue(MessageStatus.held),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.holdUntil)]))
          .watch();

  Future<bool> updateHeld(
    String id, {
    required String body,
    required String? recipientLabel,
  }) => attachedDatabase.updateSyncable(
    messages,
    id,
    MessagesCompanion(body: Value(body), recipientLabel: Value(recipientLabel)),
  );

  Future<bool> markSent(
    String id, {
    required DateTime sentAt,
    required bool keepText,
  }) => attachedDatabase.updateSyncable(
    messages,
    id,
    MessagesCompanion(
      status: const Value(MessageStatus.sent),
      sentAt: Value(sentAt),
      body: keepText ? const Value.absent() : const Value(null),
    ),
  );

  Future<bool> markDiscarded(String id, {required bool keepText}) =>
      attachedDatabase.updateSyncable(
        messages,
        id,
        MessagesCompanion(
          status: const Value(MessageStatus.discarded),
          body: keepText ? const Value.absent() : const Value(null),
        ),
      );

  /// "Keep message text" turned off: drop the text of every message that is
  /// no longer held.
  Future<void> clearFinishedBodies() async {
    final finished =
        await (select(messages)..where(
              (t) =>
                  attachedDatabase.isActive(t) &
                  t.body.isNotNull() &
                  t.status.equalsValue(MessageStatus.held).not(),
            ))
            .get();
    for (final message in finished) {
      await attachedDatabase.updateSyncable(
        messages,
        message.id,
        const MessagesCompanion(body: Value(null)),
      );
    }
  }
}
