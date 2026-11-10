import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds the bundled fonts' licences to the app's licence page (Settings →
/// About → Licences), as the SIL Open Font License asks.
class LicenseUtils {
  LicenseUtils._();

  static void init() {
    LicenseRegistry.addLicense(() async* {
      for (final (family, file) in [
        ('Manrope', 'assets/fonts/OFL-Manrope.txt'),
        ('Space Grotesk', 'assets/fonts/OFL-SpaceGrotesk.txt'),
      ]) {
        yield LicenseEntryWithLineBreaks([
          family,
        ], await rootBundle.loadString(file));
      }
    });
  }
}
