import 'package:__PROJECT_NAME__/core/auth/auth.dart';
import 'package:__PROJECT_NAME__/core/network/app_failure.dart';
import 'package:__PROJECT_NAME__/core/network/result.dart';

/// An [AuthService] for tests: signs in anyone with [validPassword],
/// records calls, and returns [nextFailure] once when set.
class FakeAuthService implements AuthService {
  FakeAuthService({
    this.validPassword = 'correct-horse',
    this.canUseApple = false,
    this.canUseGoogle = false,
  });

  final String validPassword;

  @override
  final bool canUseApple;

  @override
  final bool canUseGoogle;

  AppFailure? nextFailure;
  final calls = <String>[];

  Future<Result<T>> _result<T>(String call, T value) async {
    calls.add(call);
    final failure = nextFailure;
    nextFailure = null;
    return failure == null ? Success(value) : Failed(failure);
  }

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<Result<void>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (password != validPassword) {
      nextFailure ??= const AuthFailure(AuthFailureReason.invalidCredentials);
    }
    final result = await _result<void>('signInWithEmail', null);
    if (result is Success<void>) {
      Auth.user.value = AppUser(id: 'user-1', email: email);
    }
    return result;
  }

  @override
  Future<Result<SignUpOutcome>> signUpWithEmail({
    required String email,
    required String password,
  }) => _result('signUpWithEmail', SignUpOutcome.confirmEmail);

  @override
  Future<Result<void>> sendPasswordReset(String email) =>
      _result('sendPasswordReset', null);

  @override
  Future<Result<void>> updatePassword(String password) =>
      _result('updatePassword', null);

  @override
  Future<Result<void>> signInWithApple() => _result('signInWithApple', null);

  @override
  Future<Result<void>> signInWithGoogle() => _result('signInWithGoogle', null);

  @override
  Future<Result<void>> signOut() async {
    final result = await _result<void>('signOut', null);
    if (result is Success<void>) Auth.user.value = null;
    return result;
  }

  @override
  Future<Result<void>> deleteAccount() async {
    final result = await _result<void>('deleteAccount', null);
    if (result is Success<void>) Auth.user.value = null;
    return result;
  }
}
