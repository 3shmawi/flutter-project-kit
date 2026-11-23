import 'package:flutter/material.dart';
import 'package:__PROJECT_NAME__/core/adaptive/adaptive.dart';
import 'package:__PROJECT_NAME__/core/auth/auth_redirect.dart';
import 'package:__PROJECT_NAME__/core/theme/app_dimens.dart';
import 'package:__PROJECT_NAME__/core/theme/app_text_styles.dart';
import 'package:__PROJECT_NAME__/core/ui/app_ui.dart';
import 'package:__PROJECT_NAME__/l10n/l10n.dart';

enum SignInMode { signIn, signUp }

/// Email + password form, with Apple / Google buttons when they're
/// offered. Pure UI: the form's text and field errors live here, every
/// action goes out through a callback; [SignInPage] does the work.
class SignInView extends StatefulWidget {
  const SignInView({
    required this.onSubmit,
    required this.onForgotPassword,
    this.onApple,
    this.onGoogle,
    this.busy = false,
    this.error,
    this.notice,
    super.key,
  });

  final void Function(SignInMode mode, String email, String password)
  onSubmit;
  final ValueChanged<String> onForgotPassword;

  /// Each social button is hidden while its callback is null.
  final VoidCallback? onApple;
  final VoidCallback? onGoogle;

  /// An action is running: buttons are disabled and a spinner shows.
  final bool busy;

  /// A failure message, or an information (e.g. "check your email").
  final String? error;
  final String? notice;

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  SignInMode _mode = SignInMode.signIn;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _validEmail() {
    final ok = AuthInput.isEmail(_email.text);
    setState(() => _emailError = ok ? null : context.l10n.authEmailInvalid);
    return ok;
  }

  void _submit() {
    final l10n = context.l10n;
    final emailOk = _validEmail();
    final passwordOk = AuthInput.isPassword(_password.text);
    setState(
      () => _passwordError = passwordOk
          ? null
          : l10n.authPasswordTooShort(AuthInput.passwordMinLength),
    );
    if (emailOk && passwordOk) {
      widget.onSubmit(_mode, _email.text.trim(), _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final signUp = _mode == SignInMode.signUp;
    final enabled = !widget.busy;
    return AppScaffold(
      title: signUp ? l10n.authSignUpTitle : l10n.authSignInTitle,
      body: ListView(
        padding: EdgeInsets.all(AppDimens.lg),
        children: [
          TextField(
            key: const Key('sign_in_email'),
            controller: _email,
            enabled: enabled,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            maxLength: AuthInput.emailMaxLength,
            decoration: InputDecoration(
              labelText: l10n.authEmail,
              errorText: _emailError,
              counterText: '',
            ),
          ),
          SizedBox(height: AppDimens.md),
          TextField(
            key: const Key('sign_in_password'),
            controller: _password,
            enabled: enabled,
            obscureText: true,
            autofillHints: [
              if (signUp) AutofillHints.newPassword else AutofillHints.password,
            ],
            maxLength: AuthInput.passwordMaxLength,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: l10n.authPassword,
              errorText: _passwordError,
              counterText: '',
            ),
          ),
          if (widget.error case final error? when error.isNotEmpty) ...[
            SizedBox(height: AppDimens.md),
            Text(
              error,
              key: const Key('sign_in_error'),
              style: AppTextStyles.body.copyWith(color: scheme.error),
            ),
          ],
          if (widget.notice case final notice?) ...[
            SizedBox(height: AppDimens.md),
            Text(notice, key: const Key('sign_in_notice')),
          ],
          SizedBox(height: AppDimens.lg),
          AdaptiveButton(
            key: const Key('sign_in_submit'),
            onPressed: enabled ? _submit : null,
            child: widget.busy
                ? SizedBox.square(
                    dimension: AppDimens.iconMd,
                    child: const CircularProgressIndicator.adaptive(),
                  )
                : Text(signUp ? l10n.authSignUpButton : l10n.authSignInButton),
          ),
          if (!signUp)
            TextButton(
              key: const Key('sign_in_forgot'),
              onPressed: enabled
                  ? () {
                      if (_validEmail()) {
                        widget.onForgotPassword(_email.text.trim());
                      }
                    }
                  : null,
              child: Text(l10n.authForgotPassword),
            ),
          TextButton(
            key: const Key('sign_in_switch_mode'),
            onPressed: enabled
                ? () => setState(
                    () => _mode = signUp ? SignInMode.signIn : SignInMode.signUp,
                  )
                : null,
            child: Text(
              signUp ? l10n.authSwitchToSignIn : l10n.authSwitchToSignUp,
            ),
          ),
          if (widget.onApple != null || widget.onGoogle != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimens.md),
              child: Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppDimens.sm),
                    child: Text(l10n.authOr),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
            ),
            if (widget.onApple case final onApple?)
              OutlinedButton.icon(
                key: const Key('sign_in_apple'),
                onPressed: enabled ? onApple : null,
                icon: const Icon(AdaptiveIcons.apple),
                label: Text(l10n.authContinueWithApple),
              ),
            if (widget.onGoogle case final onGoogle?) ...[
              SizedBox(height: AppDimens.sm),
              OutlinedButton(
                key: const Key('sign_in_google'),
                onPressed: enabled ? onGoogle : null,
                child: Text(l10n.authContinueWithGoogle),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
