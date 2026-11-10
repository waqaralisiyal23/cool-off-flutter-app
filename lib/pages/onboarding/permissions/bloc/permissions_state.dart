import 'package:built_value/built_value.dart';

part 'permissions_state.g.dart';

abstract class PermissionsState
    implements Built<PermissionsState, PermissionsStateBuilder> {
  factory PermissionsState([void Function(PermissionsStateBuilder) updates]) =
      _$PermissionsState;

  PermissionsState._();

  @BuiltValueHook(initializeBuilder: true)
  static void _initialize(PermissionsStateBuilder b) => b
    ..cameraGranted = false
    ..cameraDenied = false
    ..notificationsGranted = false
    ..notificationsAsked = false;

  bool get cameraGranted;

  /// Asked and refused: only the phone's Settings can change it now.
  bool get cameraDenied;

  bool get notificationsGranted;

  bool get notificationsAsked;
}
