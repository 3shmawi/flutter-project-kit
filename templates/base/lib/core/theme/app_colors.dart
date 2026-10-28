import 'package:flutter/material.dart';

/// Brand and semantic colors. Widgets read colors from
/// `Theme.of(context).colorScheme`; only use these directly for brand
/// moments or semantic states.
abstract final class AppColors {
  static const primary = Color(__PRIMARY_COLOR_DART__);
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFED6C02);
  static const error = Color(0xFFD32F2F);
}
