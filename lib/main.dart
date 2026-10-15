import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/api/cuan_api.dart';
import 'core/notifications/notification_service.dart';
import 'core/theme/ledger_theme.dart';

/// Thin entry point — initializes services, then runs [CuanApp].
/// All DI lives in app.dart; all state lives in blocs/cubits.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await api.init();
  // Push notifications — no-ops gracefully when Firebase isn't configured yet.
  await notifications.init();
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: LedgerTheme.bg,
    ),
  );
  runApp(const CuanApp());
}
