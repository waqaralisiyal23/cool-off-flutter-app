import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/app_preferences_bloc.dart';
import '../../../bloc/settings_bloc.dart';
import '../../../core/app_colors.dart';
import '../../../utils/app_haptics.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/heat_glow_background.dart';
import '../held/bloc/held_bloc.dart';
import '../held/held_body.dart';
import '../insights/bloc/insights_bloc.dart';
import '../insights/insights_body.dart';
import '../settings/bloc/settings_page_bloc.dart';
import '../settings/settings_body.dart';
import '../write/bloc/write_bloc.dart';
import '../write/write_body.dart';
import 'bloc/tabs_bloc.dart';

/// The main app: Write · Held · Insights · Settings. Each tab keeps its
/// state while another is shown.
class TabsPage extends StatelessWidget {
  static const String ROUTE_NAME = '/';

  const TabsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = AppPreferencesBloc.of(context);
    final settings = SettingsBloc.of(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => WriteBloc(
            settings: settings.stream,
            initialSettings: settings.state,
            demoCheckinsNow: preferences.stream
                .map((p) => p.demoCheckinsNow)
                .distinct(),
            initialDemo: preferences.state.demoCheckinsNow,
          ),
        ),
        BlocProvider(create: (_) => HeldBloc()..start()),
        BlocProvider(create: (_) => InsightsBloc()..start()),
        BlocProvider(
          create: (_) =>
              SettingsPageBloc(preferences: preferences, settings: settings)
                ..load(),
        ),
      ],
      child: BlocBuilder<TabsBloc, MainTab>(
        builder: (context, tab) => AppScaffold(
          body: HeatGlowBackground(
            intensity: 0.3,
            child: IndexedStack(
              index: tab.index,
              children: const [
                WriteBody(),
                HeldBody(),
                InsightsBody(),
                SettingsBody(),
              ],
            ),
          ),
          bottomNavigationBar: HeldBlocSelector<int>(
            selector: (s) => s.messages?.length ?? 0,
            builder: (held) => NavigationBar(
              selectedIndex: tab.index,
              onDestinationSelected: (i) {
                AppHaptics.tap();
                TabsBloc.of(context).select(MainTab.values[i]);
              },
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.edit_note_rounded),
                  label: 'Write',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: held > 0,
                    backgroundColor: AppColors.warm,
                    textColor: AppColors.textOnAccent,
                    label: Text('$held'),
                    child: const Icon(Icons.hourglass_top_rounded),
                  ),
                  label: 'Held',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.insights_rounded),
                  label: 'Insights',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.settings_rounded),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
