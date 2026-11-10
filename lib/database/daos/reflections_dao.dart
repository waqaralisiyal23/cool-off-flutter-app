import 'package:drift/drift.dart';

import '../../models/data/reflection_data.dart';
import '../../models/enums/reflection_answer.dart';
import '../app_database.dart';
import '../tables/reflections.dart';

part 'reflections_dao.g.dart';

@DriftAccessor(tables: [Reflections])
class ReflectionsDao extends DatabaseAccessor<AppDatabase>
    with _$ReflectionsDaoMixin {
  ReflectionsDao(super.attachedDatabase);

  Future<String> add({
    required String checkRecordId,
    required ReflectionAnswer answer,
    required DateTime answeredAt,
  }) => attachedDatabase.insertSyncable(
    reflections,
    ReflectionsCompanion(
      checkRecordId: Value(checkRecordId),
      answer: Value(answer),
      answeredAt: Value(answeredAt),
    ),
  );

  /// Every answer, newest first.
  Stream<List<ReflectionData>> watchAll() =>
      (select(reflections)
            ..where((t) => attachedDatabase.isActive(t))
            ..orderBy([(t) => OrderingTerm.desc(t.answeredAt)]))
          .watch();

  Future<List<ReflectionData>> getAll() =>
      (select(reflections)
            ..where((t) => attachedDatabase.isActive(t))
            ..orderBy([(t) => OrderingTerm.desc(t.answeredAt)]))
          .get();
}
