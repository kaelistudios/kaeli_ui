import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Da formato a un monto mientras se escribe: «120000» se ve «120 000» (o «120,000», «120.000») con los separadores
/// del idioma y país, sin que el cursor salte y sin tocar los decimales («1500,5» → «1 500,5»).
///
/// - Acepta el decimal con punto o con coma (lo que traiga el teclado). El separador de miles del idioma, tecleado al
///   final, también cuenta como decimal (los miles los pone el formato): en `es` «12.5» y «12,5» son 12,5. Pegado o en
///   medio del número, se toma como separador de miles y se ignora («1.500» pegado en `es` es 1500).
/// - Corta los decimales a [decimals] (0 para monedas sin decimales: no deja escribir el separador).
/// - Al borrar un separador de miles, borra la cifra de antes (si no, parecería que la tecla no hace nada).
/// - El texto que deja se puede leer igual que antes: solo agrega el separador de miles del idioma.
///
/// Para poner un valor inicial con el mismo formato, usa [format].
class KaeliAmountFormatter extends TextInputFormatter {
  KaeliAmountFormatter({
    required this.groupSeparator,
    required this.decimalSeparator,
    this.decimals = 2,
    this.allowNegative = false,
  }) : assert(groupSeparator != decimalSeparator);

  /// Con los separadores de [locale] según `intl` («es_CR», «pt_BR», «en_US», «fr»…).
  factory KaeliAmountFormatter.forLocale(String locale, {int decimals = 2, bool allowNegative = false}) {
    final symbols = NumberFormat.decimalPattern(locale).symbols;
    return KaeliAmountFormatter(
      groupSeparator: symbols.GROUP_SEP,
      decimalSeparator: symbols.DECIMAL_SEP,
      decimals: decimals,
      allowNegative: allowNegative,
    );
  }

  final String groupSeparator;
  final String decimalSeparator;
  final int decimals;
  final bool allowNegative;

  static final _digit = RegExp(r'[0-9]');

  /// [text] con el formato de este campo («120000» → «120 000»).
  String format(String text) => _build(text, text.length).text;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    var cursor = newValue.selection.isValid ? newValue.selection.extentOffset : text.length;
    // Se borró solo un separador de miles: se borra también la cifra de antes.
    if (text.length == oldValue.text.length - 1 &&
        cursor > 0 &&
        oldValue.selection.isCollapsed &&
        oldValue.selection.extentOffset == cursor + 1 &&
        oldValue.text[cursor] == groupSeparator) {
      text = text.substring(0, cursor - 1) + text.substring(cursor);
      cursor -= 1;
    }
    // Se tecleó el separador de miles al final (la tecla decimal de un teclado de otro país, como «.» en español):
    // como los miles los pone el formato, se toma como el decimal.
    if (decimals > 0 &&
        text.length == oldValue.text.length + 1 &&
        cursor == text.length &&
        text.endsWith(groupSeparator) &&
        !oldValue.text.contains(decimalSeparator)) {
      text = text.substring(0, text.length - 1) + decimalSeparator;
    }
    final built = _build(text, cursor);
    return TextEditingValue(
      text: built.text,
      selection: TextSelection.collapsed(offset: built.cursor),
    );
  }

  ({String text, int cursor}) _build(String input, int cursor) {
    // Cifras, el signo y el decimal que se quedan, con su posición en el texto escrito.
    final kept = <({String char, int at})>[];
    var hasDecimal = false;
    var fraction = 0;
    for (var i = 0; i < input.length; i++) {
      final c = input[i];
      if (_digit.hasMatch(c)) {
        if (hasDecimal) {
          if (fraction >= decimals) continue;
          fraction++;
        }
        kept.add((char: c, at: i));
      } else if (c == '-' && allowNegative && kept.isEmpty) {
        kept.add((char: '-', at: i));
      } else if ((c == '.' || c == ',' || c == decimalSeparator) && c != groupSeparator) {
        if (hasDecimal || decimals == 0) continue;
        hasDecimal = true;
        kept.add((char: decimalSeparator, at: i));
      }
    }
    // Sin ceros de más adelante («007» → «7»; «0,5» se queda).
    final start = kept.isNotEmpty && kept.first.char == '-' ? 1 : 0;
    while (start < kept.length - 1 && kept[start].char == '0' && _digit.hasMatch(kept[start + 1].char)) {
      kept.removeAt(start);
    }
    // Un decimal al inicio lleva su cero («,5» → «0,5»).
    if (start < kept.length && kept[start].char == decimalSeparator) {
      kept.insert(start, (char: '0', at: kept[start].at));
    }
    final before = kept.where((k) => k.at < cursor).length;
    final decimalAt = kept.indexWhere((k) => k.char == decimalSeparator);
    final intEnd = decimalAt < 0 ? kept.length : decimalAt;
    final intDigits = intEnd - start;
    final out = StringBuffer();
    var newCursor = -1;
    for (var i = 0; i < kept.length; i++) {
      if (i == before) newCursor = out.length;
      if (i > start && i < intEnd && (intDigits - (i - start)) % 3 == 0) out.write(groupSeparator);
      out.write(kept[i].char);
    }
    if (newCursor < 0) newCursor = out.length;
    return (text: out.toString(), cursor: newCursor);
  }
}
