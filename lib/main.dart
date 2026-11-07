import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:wc_dart_framework/wc_dart_framework.dart';

import 'core/app_theme.dart';
import 'core/config.dart';
import 'router/app_router_delegate.dart';
import 'utils/firebase_utils.dart';
import 'utils/local_utils.dart';
import 'widgets/env_mode_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalUtils.init();

  LoggingUtils.initialize();
  await dotenv.load(fileName: 'config/${config.environment}.config');

  // ─── Firebase (Core, Crashlytics, Analytics) ───────────────────────────
  await FirebaseUtils.init();

  // ─── HydratedBloc ──────────────────────────────────────────────────────
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory(LocalUtils.appDirectory.path),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appRouterDelegate = AppRouterDelegate();

  @override
  Widget build(BuildContext context) {
    // Global blocs (singletonBloc) get a MultiBlocProvider around this once
    // the first one exists (docs/05-architecture.md).
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      // `.router` rather than a `Router` as `home`, which put a navigator of
      // MaterialApp's own above the router's. Dialogs open on the topmost
      // navigator, and closing one there told Android that the app had
      // nothing to pop — so with a screen open, the next system back
      // closed the app. With the router's navigator on top, the dialogs
      // open on it, and it answers for the screens beneath.
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: config.appName,
        themeMode: ThemeMode.light,
        theme: AppTheme.getLightTheme(),
        routerDelegate: _appRouterDelegate,
        backButtonDispatcher: RootBackButtonDispatcher(),
        builder: (_, child) => EnvModeBanner(child: child!),
      ),
    );
  }
}
