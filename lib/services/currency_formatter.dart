import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    // Remove qualquer caractere que não seja número
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanText.isEmpty || cleanText == '00') {
      return newValue.copyWith(text: '0,00', selection: const TextSelection.collapsed(offset: 4));
    }

    double value = double.parse(cleanText) / 100;
    
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: '');
    String newText = formatter.format(value).trim();

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  static double parse(String text) {
    if (text.isEmpty) return 0.0;
    // Remove TUDO que não for número
    String clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return 0.0;
    // Divide por 100 para restaurar os centavos
    return double.parse(clean) / 100;
  }
}
