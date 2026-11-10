import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/draft_bloc.dart';
import '../../models/check_outcome.dart';
import '../../models/enums/notification_kind.dart';
import '../../services/notification_service.dart';
import '../../services/share_intent_service.dart';
import '../../widgets/navigator/navigator.dart';
import '../calibration/calibration_page.dart';
import 'check/check_page.dart';
import 'cooldown/cooldown_page.dart';
import 'result/result_page.dart';
import 'tabs/bloc/tabs_bloc.dart';
import 'tabs/tabs_page.dart';

/// Global route observer for [RouteAware] subscriptions.
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

/// The main flow: the tabs, and the check → result → cool-down screens on
/// top of them. The draft and the selected tab are shared by all of them.
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _draft = DraftBloc();
  final _tabs = TabsBloc();
  final _navigator = MainNavigator();
  StreamSubscription<NotificationTap>? _taps;
  StreamSubscription<String>? _shared;

  @override
  void initState() {
    super.initState();
    _taps = notificationService.taps.listen(_open);
    final launch = notificationService.takeLaunchTap();
    if (launch != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _open(launch));
    }
    _shared = shareIntentService.texts.listen(_receiveShared);
    final pending = shareIntentService.takePending();
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _receiveShared(pending),
      );
    }
  }

  /// Text shared into Cool Off: it becomes the draft, ready to check. A
  /// half-written draft is replaced, and the snackbar says so.
  void _receiveShared(String text) {
    final replaced = _draft.state.text.trim().isNotEmpty;
    _draft.load(text: text.trim());
    _navigator.navigatorKey.currentState?.popUntil((route) => route.isFirst);
    _tabs.select(MainTab.write);
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            replaced
                ? 'Shared text replaced your draft. Check it before sending.'
                : 'Shared text is ready. Check it before sending.',
          ),
        ),
      );
  }

  /// A notification tap: hold ended → Held, check-in → Write (its card).
  void _open(NotificationTap tap) {
    _navigator.navigatorKey.currentState?.popUntil((route) => route.isFirst);
    _tabs.select(
      tap.kind == NotificationKind.holdEnded ? MainTab.held : MainTab.write,
    );
  }

  @override
  void dispose() {
    unawaited(_taps?.cancel());
    unawaited(_shared?.cancel());
    unawaited(_draft.close());
    unawaited(_tabs.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _draft),
        BlocProvider.value(value: _tabs),
      ],
      child: AppNavigator(
        initialRoute: TabsPage.ROUTE_NAME,
        createNavigatorProvider: (_) => _navigator,
        getPage: _getPage,
        observers: [routeObserver],
      ),
    );
  }

  Widget? _getPage(BuildContext _, RouteSettings settings) {
    switch (settings.name) {
      case TabsPage.ROUTE_NAME:
        return const TabsPage();
      case CheckPage.ROUTE_NAME:
        return const CheckPage();
      case ResultPage.ROUTE_NAME:
        return ResultPage(outcome: settings.arguments! as CheckOutcome);
      case CooldownPage.ROUTE_NAME:
        return CooldownPage(outcome: settings.arguments! as CheckOutcome);
      case CalibrationPage.ROUTE_NAME:
        return const CalibrationPage();
      default:
        return null;
    }
  }
}

class MainNavigator extends NavigatorProvider {
  MainNavigator() : super(navigatorKey: GlobalKey<NavigatorState>());

  static NavigatorState of(BuildContext context) =>
      NavigatorProvider.of<MainNavigator>(context);
}
