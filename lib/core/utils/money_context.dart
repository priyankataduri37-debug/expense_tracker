import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import 'money.dart';

extension MoneyFormatting on BuildContext {
  String money(int minor) =>
      formatMinor(minor, symbol: watch<SettingsProvider>().currencySymbol);
}