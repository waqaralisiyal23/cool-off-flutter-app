import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:wc_dart_framework/wc_dart_framework.dart';

import 'bloc/app_preferences_bloc.dart';
import 'bloc/baseline_bloc.dart';
import 'bloc/notification_access_bloc.dart';
import 'bloc/settings_bloc.dart';
import 'bloc/singleton_bloc.dart';
import 'core/app_theme.dart';
import 'core/config.dart';
import 'database/app_database.dart';
import 'models/enums/environment.dart';
import 'router/app_router_delegate.dart';
import 'services/measurement_service.dart';
import 'services/notification_service.dart';
import 'services/share_intent_service.dart';
import 'services/simulated_measurement_source.dart';
import 'utils/firebase_utils.dart';
import 'utils/license_utils.dart';
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
  final preferences = singletonBloc.appPreferencesBloc;
  // The user's analytics and crash-report choices (both on by default).
  await preferences.applyConsent();

  // ─── Simulated camera (QA builds with SIMULATE_MEASUREMENT only) ───────
  if (simulateMeasurement && config.environment == Environment.qa) {
    final simulated = SimulatedMeasurementSource()
      ..heated = preferences.state.simulateHeated;
    preferences.stream.listen((p) => simulated.heated = p.simulateHeated);
    measurementService = simulated;
  }

  // ─── Database ──────────────────────────────────────────────────────────
  // After HydratedBloc: rows are stamped with this install's id.
  appDatabase = AppDatabase.open(deviceId: preferences.state.deviceId);
  await singletonBloc.settingsBloc.start();
  await singletonBloc.baselineBloc.start();

  // ─── Notifications ─────────────────────────────────────────────────────
  // Never asks for permission here: onboarding asks, after explaining.
  await notificationService.init();
  await singletonBloc.notificationAccessBloc.refresh();

  // ─── Text shared into Cool Off (Android) ───────────────────────────────
  await shareIntentService.init();

  LicenseUtils.init();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemUi);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appRouterDelegate = AppRouterDelegate(
    preferences: singletonBloc.appPreferencesBloc,
  );

  @override
  void dispose() {
    _appRouterDelegate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppPreferencesBloc>(
          create: (_) => singletonBloc.appPreferencesBloc,
        ),
        BlocProvider<SettingsBloc>(create: (_) => singletonBloc.settingsBloc),
        BlocProvider<BaselineBloc>(create: (_) => singletonBloc.baselineBloc),
        BlocProvider<NotificationAccessBloc>(
          create: (_) => singletonBloc.notificationAccessBloc,
        ),
      ],
      child: GestureDetector(
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
          themeMode: ThemeMode.dark,
          darkTheme: AppTheme.getDarkTheme(),
          theme: AppTheme.getDarkTheme(),
          routerDelegate: _appRouterDelegate,
          backButtonDispatcher: RootBackButtonDispatcher(),
          // Large system text is honoured up to 2×; beyond that layouts
          // would break rather than get more readable.
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            maxScaleFactor: 2,
            child: EnvModeBanner(child: child!),
          ),
        ),
      ),
    );
  }
}
