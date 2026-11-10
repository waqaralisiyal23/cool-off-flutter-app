import 'package:built_value/built_value.dart';

part 'settings_page_state.g.dart';

abstract class SettingsPageState
    implements Built<SettingsPageState, SettingsPageStateBuilder> {
  factory SettingsPageState([void Function(SettingsPageStateBuilder) updates]) =
      _$SettingsPageState;

  SettingsPageState._();

  @BuiltValueHook(initializeBuilder: true)
  static void _initialize(SettingsPageStateBuilder b) => b
    ..version = ''
    ..isDeleting = false;

  String get version;

  bool get isDeleting;

  String? get error;
}
