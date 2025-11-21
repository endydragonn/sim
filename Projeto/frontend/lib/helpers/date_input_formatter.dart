import 'package:flutter/services.dart';

/// Formata a entrada como DD/MM/AAAA enquanto o usuário digita.
/// Aceita apenas dígitos e insere '/' após o dia e mês.
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Mantém apenas dígitos
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 8) digits = digits.substring(0, 8);

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if (i == 1 || i == 3) buffer.write('/');
    }

    final String formatted = buffer.toString();

    // Posiciona o cursor no final do texto formatado
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
