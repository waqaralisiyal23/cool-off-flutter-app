import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:built_value/built_value.dart';
import 'package:wc_dart_framework/wc_dart_framework.dart';

final _logger = Logger('cubit.dart');

abstract class AppCubit<State> extends Cubit<State> {
  AppCubit(super.initialState);

  @override
  void emit(State state) {
    if (isClosed) {
      return;
    }
    super.emit(state);
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    _logger.severe('onError: $error', error, stackTrace);
    super.onError(error, stackTrace);
  }
}

abstract class BVCubit<V extends Built<V, B>, B extends Builder<V, B>>
    extends AppCubit<V> {
  BVCubit(super.initialState);
}
