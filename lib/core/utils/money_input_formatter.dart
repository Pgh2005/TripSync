import 'package:flutter/services.dart';
import 'money_formatter.dart';

class MoneyInputFormatter extends TextInputFormatter {
  static final _digitRegex = RegExp(r'\d');

  int _countDigits(String text) {
    return _digitRegex.allMatches(text).length;
  }

  int _findCursor(String formatted, int digitsBeforeCursor) {
    int count = 0;

    for (int i = 0; i < formatted.length; i++) {
      if (_digitRegex.hasMatch(formatted[i])) {
        count++;
      }

      if (count == digitsBeforeCursor) {
        return i + 1;
      }
    }

    return formatted.length;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final digitsBeforeCursor = _countDigits(
      newValue.text.substring(0, newValue.selection.end),
    );

    final raw = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (raw.isEmpty) {
      return const TextEditingValue();
    }

    final number = int.parse(raw);
    final formatted = number.toDouble().toMoney();

    final cursor = _findCursor(formatted, digitsBeforeCursor);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}
