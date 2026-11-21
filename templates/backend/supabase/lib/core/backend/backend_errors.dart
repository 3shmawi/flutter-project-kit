import 'package:__PROJECT_NAME__/core/network/app_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps Supabase errors to an [AppFailure]; `null` for anything else.
AppFailure? backendFailure(Object error) => switch (error) {
  AuthException() => UnauthorizedFailure(error),
  PostgrestException(code: 'PGRST116') => NotFoundFailure(error),
  PostgrestException(code: '42501') => UnauthorizedFailure(error),
  PostgrestException(code: final String code) when code.startsWith('22') =>
    ValidationFailure(error),
  PostgrestException() => ServerFailure(error),
  _ => null,
};
