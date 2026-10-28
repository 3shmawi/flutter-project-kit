import 'package:__PROJECT_NAME__/features/settings/domain/entities/app_settings.dart';

/// Contract for storing [AppSettings]. The domain and presentation layers
/// depend on this interface, never on the data implementation.
abstract interface class SettingsRepository {
  AppSettings load();

  Future<void> save(AppSettings settings);
}
