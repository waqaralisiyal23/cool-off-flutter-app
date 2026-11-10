import 'package:drift/drift.dart';

import '../../models/data/reflection_data.dart';
import '../../models/enums/reflection_answer.dart';
import '../converters/enum_converter.dart';
import '../converters/utc_date_time_converter.dart';
import 'sync_columns.dart';

/// Next-morning answers ("Glad you sent it?") for heated sends.
@UseRowClass(ReflectionData, constructor: 'fromRow')
class Reflections extends Table with SyncColumns {
  TextColumn get checkRecordId => text()();

  TextColumn get answer => text().map(
    const EnumConverter<ReflectionAnswer>(ReflectionAnswer.glad),
  )();

  DateTimeColumn get answeredAt =>
      dateTime().map(const UtcDateTimeConverter())();
}
