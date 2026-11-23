import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:__PROJECT_NAME__/core/adaptive/adaptive.dart';
import 'package:__PROJECT_NAME__/core/auth/auth.dart';
import 'package:__PROJECT_NAME__/core/auth/auth_redirect.dart';
import 'package:__PROJECT_NAME__/core/network/result.dart';
import 'package:__PROJECT_NAME__/core/router/app_routes.dart';
import 'package:__PROJECT_NAME__/core/theme/app_dimens.dart';
import 'package:__PROJECT_NAME__/core/theme/app_text_styles.dart';
import 'package:__PROJECT_NAME__/core/ui/app_message.dart';
import 'package:__PROJECT_NAME__/core/ui/app_ui.dart';
import 'package:__PROJECT_NAME__/core/widgets/state_views.dart';
import 'package:__PROJECT_NAME__/l10n/l10n.dart';

/// Shown after the user opens a password-reset link (Supabase; Firebase
/// sets the password on its own web page).
class NewPasswordPage extends StatefulWidget {
  const NewPasswordPage({super.key});

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!AuthInput.isPassword(_password.text)) {
      setState(
        () => _error = l10n.authPasswordTooShort(AuthInput.passwordMinLength),
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final message = appMessenger(context);
    final result = await Auth.service.updatePassword(_password.text);
    if (!mounted) return;
    switch (result) {
      case Success():
        message(l10n.newPasswordSaved);
        context.go(AppRoutes.home);
      case Failed(:final failure):
        setState(() {
          _busy = false;
          _error = failure.message(l10n);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppScaffold(
      title: l10n.newPasswordTitle,
      body: ListView(
        padding: EdgeInsets.all(AppDimens.lg),
        children: [
          TextField(
            key: const Key('new_password_field'),
            controller: _password,
            enabled: !_busy,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            maxLength: AuthInput.passwordMaxLength,
            onSubmitted: (_) => unawaited(_save()),
            decoration: InputDecoration(
              labelText: l10n.authPassword,
              counterText: '',
            ),
          ),
          if (_error case final error?) ...[
            SizedBox(height: AppDimens.md),
            Text(
              error,
              style: AppTextStyles.body.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          SizedBox(height: AppDimens.lg),
          AdaptiveButton(
            key: const Key('new_password_save'),
            onPressed: _busy ? null : () => unawaited(_save()),
            child: Text(l10n.newPasswordSave),
          ),
        ],
      ),
    );
  }
}
