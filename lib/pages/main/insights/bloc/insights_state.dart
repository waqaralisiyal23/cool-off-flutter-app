import 'package:built_value/built_value.dart';

import '../../../../stats/insights.dart';

part 'insights_state.g.dart';

abstract class InsightsState
    implements Built<InsightsState, InsightsStateBuilder> {
  factory InsightsState([void Function(InsightsStateBuilder) updates]) =
      _$InsightsState;

  InsightsState._();

  /// Null while loading.
  Insights? get insights;
}
