import 'dart:async';

import 'package:flutter/material.dart';
import 'package:__PROJECT_NAME__/core/analytics/analytics.dart';
import 'package:__PROJECT_NAME__/core/auth/auth.dart';
import 'package:__PROJECT_NAME__/core/network/result.dart';
import 'package:__PROJECT_NAME__/core/ui/app_message.dart';
import 'package:__PROJECT_NAME__/core/widgets/state_views.dart';
import 'package:__PROJECT_NAME__/features/auth/presentation/account_view.dart';
import 'package:__PROJECT_NAME__/l10n/l10n.dart';

/// Wires [AccountView] to [Auth]. Signing out or deleting the account
/// makes the router leave this signed-in-only screen by itself.
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _busy = false;
  String? _error;

  Future<void> _run(String event, Future<Result<void>> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final message = appMessenger(context);
    final deletedMessage = context.l10n.accountDeleted;
    final result = await action();
    if (result is Success<void>) {
      unawaited(Analytics.capture(event));
      if (event == 'account_deleted') {
        message(deletedMessage);
      }
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = switch (result) {
        Failed(:final failure) => failure.message(context.l10n),
        Success() => null,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppUser?>(
      valueListenable: Auth.user,
      builder: (context, user, _) => AccountView(
        email: user?.email,
        busy: _busy,
        error: _error,
        onSignOut: () => unawaited(_run('signed_out', Auth.service.signOut)),
        onDelete: () =>
            unawaited(_run('account_deleted', Auth.service.deleteAccount)),
      ),
    );
  }
}
