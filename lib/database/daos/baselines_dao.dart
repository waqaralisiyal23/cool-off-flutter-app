import 'package:drift/drift.dart';

import '../../models/data/baseline_data.dart';
import '../app_database.dart';
import '../tables/baselines.dart';

part 'baselines_dao.g.dart';

@DriftAccessor(tables: [Baselines])
class BaselinesDao extends DatabaseAccessor<AppDatabase>
    with _$BaselinesDaoMixin {
  BaselinesDao(super.attachedDatabase);

  SimpleSelectStatement<$BaselinesTable, BaselineData> _current() =>
      select(baselines)
        ..where((_) => attachedDatabase.isActive(baselines))
        ..orderBy([(t) => OrderingTerm.desc(t.measuredAt)])
        ..limit(1);

  /// The current baseline: the latest one taken. Null before the first.
  Stream<BaselineData?> watchCurrent() => _current().watchSingleOrNull();

  Future<BaselineData?> getCurrent() => _current().getSingleOrNull();

  Future<String> add({
    required DateTime measuredAt,
    required double pulseBpm,
    required double angerLevel,
    required int sampleCount,
  }) => attachedDatabase.insertSyncable(
    baselines,
    BaselinesCompanion.insert(
      id: '',
      createdAt: measuredAt,
      updatedAt: measuredAt,
      originDeviceId: '',
      measuredAt: measuredAt,
      pulseBpm: pulseBpm,
      angerLevel: angerLevel,
      sampleCount: sampleCount,
    ),
  );
}
