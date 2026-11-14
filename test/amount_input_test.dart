import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaeli_ui/kaeli_ui.dart';

/// Escribe [typed] letra por letra al final, como en el teclado.
TextEditingValue typeAll(KaeliAmountFormatter f, String typed) {
  var value = TextEditingValue.empty;
  for (final c in typed.split('')) {
    final text = value.text + c;
    value = f.formatEditUpdate(
      value,
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );
  }
  return value;
}

void main() {
  final crc = KaeliAmountFormatter(groupSeparator: ' ', decimalSeparator: ',');
  final usd = KaeliAmountFormatter(groupSeparator: ',', decimalSeparator: '.');
  final jpy = KaeliAmountFormatter(groupSeparator: ',', decimalSeparator: '.', decimals: 0);

  test('agrupa los miles mientras se escribe, con el cursor al final', () {
    final v = typeAll(crc, '120000');
    expect(v.text, '120 000');
    expect(v.selection.extentOffset, v.text.length);
    expect(typeAll(usd, '1234567').text, '1,234,567');
    expect(typeAll(usd, '123').text, '123');
  });

  test('decimales: punto o coma según el idioma, y no más de los de la moneda', () {
    expect(typeAll(crc, '1500,5').text, '1 500,5');
    expect(typeAll(crc, '1500.55').text, '1 500,55');
    expect(typeAll(crc, '12,345').text, '12,34');
    expect(typeAll(usd, '1500.25').text, '1,500.25');
    // El separador de miles tecleado al final es la tecla decimal de otro teclado: cuenta como decimal.
    expect(typeAll(usd, '1,5').text, '1.5');
    final es = KaeliAmountFormatter(groupSeparator: '.', decimalSeparator: ',');
    expect(typeAll(es, '12.5').text, '12,5');
    expect(typeAll(es, '120000').text, '120.000');
    // Pegado, el separador de miles se ignora y se vuelve a poner donde va.
    final pasted = es.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '1.500', selection: TextSelection.collapsed(offset: 5)),
    );
    expect(pasted.text, '1.500');
    expect(usd.format('1,5000'), '15,000');
    expect(typeAll(jpy, '1500.5').text, '15,005');
    expect(typeAll(crc, ',5').text, '0,5');
    expect(typeAll(crc, '007').text, '7');
  });

  test('escribir en medio no hace saltar el cursor', () {
    // «12|000» → se escribe 5 → «125|000».
    const old = TextEditingValue(text: '12 000', selection: TextSelection.collapsed(offset: 2));
    final v = crc.formatEditUpdate(
      old,
      const TextEditingValue(text: '125 000', selection: TextSelection.collapsed(offset: 3)),
    );
    expect(v.text, '125 000');
    expect(v.selection.extentOffset, 3);
    // «1 2|00» → se escribe 3 → «12 3|00».
    final w = crc.formatEditUpdate(
      const TextEditingValue(text: '1 200', selection: TextSelection.collapsed(offset: 3)),
      const TextEditingValue(text: '1 2300', selection: TextSelection.collapsed(offset: 4)),
    );
    expect(w.text, '12 300');
    expect(w.selection.extentOffset, 4);
  });

  test('borrar el separador de miles borra la cifra de antes', () {
    final v = crc.formatEditUpdate(
      const TextEditingValue(text: '120 000', selection: TextSelection.collapsed(offset: 4)),
      const TextEditingValue(text: '120000', selection: TextSelection.collapsed(offset: 3)),
    );
    expect(v.text, '12 000');
    expect(v.selection.extentOffset, 2);
  });

  test('borrar todo deja el campo vacío; negativo solo si se permite', () {
    final v = crc.formatEditUpdate(
      const TextEditingValue(text: '5', selection: TextSelection.collapsed(offset: 1)),
      const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0)),
    );
    expect(v.text, '');
    expect(typeAll(crc, '-50').text, '50');
    final neg = KaeliAmountFormatter(groupSeparator: ',', decimalSeparator: '.', allowNegative: true);
    expect(typeAll(neg, '-5000').text, '-5,000');
  });

  test('forLocale toma los separadores de intl y format sirve para el valor inicial', () {
    final pt = KaeliAmountFormatter.forLocale('pt_BR');
    expect(pt.format('1234567,89'), '1.234.567,89');
    final en = KaeliAmountFormatter.forLocale('en_US');
    expect(en.format('12000.5'), '12,000.5');
    final es = KaeliAmountFormatter.forLocale('es_CR');
    expect(es.format('120000'), '120${es.groupSeparator}000');
  });
}
