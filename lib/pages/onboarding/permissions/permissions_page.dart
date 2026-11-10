import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../widgets/app_scaffold.dart';
import 'bloc/permissions_bloc.dart';
import 'permissions_body.dart';

class PermissionsPage extends StatelessWidget {
  static const String ROUTE_NAME = 'onboarding/permissions';

  const PermissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PermissionsBloc()..load(),
      child: AppScaffold(appBar: AppBar(), body: const PermissionsBody()),
    );
  }
}
