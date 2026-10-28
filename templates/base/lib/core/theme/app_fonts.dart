import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The app's fonts, chosen per app idea and bundled in assets/fonts (no
/// runtime download). Latin text uses [latin]; Arabic characters fall back
/// to [arabic] automatically, so mixed text renders correctly.
abstract final class AppFonts {
  static const latin = '__FONT_LATIN__';
  static const arabic = '__FONT_ARABIC__';

  /// Open Font License texts, shown on the app's licenses page.
  static const _licenseAssets = <String>[__FONT_LICENSE_ASSETS__];

  static void registerLicenses() {
    if (_licenseAssets.isEmpty) return;
    LicenseRegistry.addLicense(() async* {
      for (final asset in _licenseAssets) {
        final text = await rootBundle.loadString(asset);
        yield LicenseEntryWithLineBreaks(const ['fonts'], text);
      }
    });
  }
}
