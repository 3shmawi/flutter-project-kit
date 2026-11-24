import 'package:__PROJECT_NAME__/core/network/app_failure.dart';

/// No backend SDK, so no backend errors to map (REST API errors are mapped
/// in `core/api/api_errors.dart`).
AppFailure? backendFailure(Object error) => null;

/// No backend SDK, so no backend outages (see `isOutage`).
bool backendOutage(Object error) => false;
