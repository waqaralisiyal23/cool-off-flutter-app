import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../widgets/cubit/cubit.dart';

enum MainTab { write, held, insights, settings }

/// The selected bottom tab. Provided above the main navigator, so a flow
/// (holding a message, a notification tap) can switch tabs.
class TabsBloc extends AppCubit<MainTab> {
  TabsBloc() : super(MainTab.write);

  factory TabsBloc.of(BuildContext context) =>
      BlocProvider.of<TabsBloc>(context);

  void select(MainTab tab) => emit(tab);
}
