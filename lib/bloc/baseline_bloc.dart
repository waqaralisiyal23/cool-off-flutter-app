import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/data/baseline_data.dart';
import '../services/records_service.dart';
import '../widgets/cubit/cubit.dart';

/// The current baseline (the user's usual pulse), followed live. Null before
/// the first one.
class BaselineBloc extends AppCubit<BaselineData?> {
  StreamSubscription<BaselineData?>? _subscription;

  BaselineBloc() : super(null);

  factory BaselineBloc.of(BuildContext context) =>
      BlocProvider.of<BaselineBloc>(context);

  Future<void> start() async {
    await _subscription?.cancel();
    _subscription = recordsService.watchBaseline().listen(
      emit,
      onError: addError,
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
