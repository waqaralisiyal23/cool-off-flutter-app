/// Lazy holder for global blocs, provided at the root in `main.dart`.
///
/// Planned (docs/05-architecture.md): `AppPreferencesBloc` (hydrated: device
/// id, onboarding, analytics and crash-report toggles), `SettingsBloc` and
/// `BaselineBloc`. Add each as a lazily created getter:
///
/// ```dart
/// AppPreferencesBloc? _appPreferencesBloc;
/// AppPreferencesBloc get appPreferencesBloc =>
///     _appPreferencesBloc ??= AppPreferencesBloc();
/// ```
class _SingletonBloc {}

final singletonBloc = _SingletonBloc();
