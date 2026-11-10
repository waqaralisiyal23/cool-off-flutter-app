import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';

import 'data/baseline_data.dart';
import 'data/check_record_data.dart';
import 'data/message_data.dart';
import 'data/reflection_data.dart';
import 'data/user_settings_data.dart';
import 'enums/check_action.dart';
import 'enums/check_kind.dart';
import 'enums/environment.dart';
import 'enums/heat_level.dart';
import 'enums/message_status.dart';
import 'enums/notification_kind.dart';
import 'enums/reflection_answer.dart';
import 'enums/sensitivity.dart';

part 'serializers.g.dart';

@SerializersFor([
  // data
  BaselineData,
  CheckRecordData,
  MessageData,
  ReflectionData,
  UserSettingsData,
  // enums
  CheckAction,
  CheckKind,
  Environment,
  HeatLevel,
  MessageStatus,
  NotificationKind,
  ReflectionAnswer,
  Sensitivity,
])
final Serializers serializers =
    (_$serializers.toBuilder()
          ..addPlugin(StandardJsonPlugin())
          ..add(Iso8601DateTimeSerializer()))
        .build();
