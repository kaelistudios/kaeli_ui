import 'package:flutter/foundation.dart';

part 'phone_countries.g.dart';

/// Un país para [KaeliPhoneField]: código telefónico y largo válido del número nacional. La lista completa es
/// [kaeliPhoneCountries] (generada por `tool/gen_phone_countries.mjs`; mismas reglas que AlojaConmigo).
@immutable
class KaeliPhoneCountry {
  const KaeliPhoneCountry(
    this.iso,
    this.dial,
    this.min,
    this.max, {
    required this.names,
    this.trunkZero = false,
    this.prefixes = const [],
  });

  /// ISO 3166-1 alfa-2 («CR»).
  final String iso;

  /// Código telefónico sin «+» («506»).
  final String dial;

  /// Cifras del número nacional, sin el 0 inicial de larga distancia.
  final int min;
  final int max;

  /// Nombre en es, en, fr y pt (en ese orden).
  final List<String> names;

  /// Se quita un 0 inicial al escribirlo («06 12…» en Francia).
  final bool trunkZero;

  /// Si comparte el código con otros países (+1, +7): cómo empieza su número nacional (código de área).
  final List<String> prefixes;

  /// Nombre en [languageCode] (inglés si no está).
  String name(String? languageCode) =>
      names[switch (languageCode) {
        'es' => 0,
        'fr' => 2,
        'pt' => 3,
        _ => 1,
      }];

  /// Bandera con los símbolos regionales («CR» → 🇨🇷).
  String get flag => String.fromCharCodes(iso.codeUnits.map((c) => 0x1F1E6 + c - 0x41));

  @override
  String toString() => '$iso +$dial';
}

/// El país con ese código ISO («cr» o «CR»); null si no está.
KaeliPhoneCountry? kaeliPhoneCountryOf(String? iso) {
  final code = (iso ?? '').toUpperCase();
  for (final c in kaeliPhoneCountries) {
    if (c.iso == code) return c;
  }
  return null;
}

/// Cifras de un número escrito en formato internacional («+…» o «00…»); null si no lo es.
String? _internationalDigits(String phone) {
  final raw = phone.trim();
  if (!raw.startsWith('+') && !raw.startsWith('00')) return null;
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  return raw.startsWith('00') ? digits.substring(2) : digits;
}

/// País de un número internacional por su código («+50660895761» → Costa Rica). En +1 y +7 decide el código de área
/// (+1 809… → República Dominicana; el resto del +1 es EE. UU.; +7 7… → Kazajistán). null si no se sabe.
KaeliPhoneCountry? kaeliCountryFromPhone(String? phone) {
  final digits = _internationalDigits(phone ?? '');
  if (digits == null || digits.isEmpty) return null;
  for (final len in [3, 2, 1]) {
    if (digits.length < len) continue;
    final dial = digits.substring(0, len);
    final same = kaeliPhoneCountries.where((c) => c.dial == dial).toList();
    if (same.isEmpty) continue;
    if (same.length == 1) return same.single;
    final national = digits.substring(len);
    for (final c in same) {
      if (c.prefixes.any(national.startsWith)) return c;
    }
    // El país «principal» del código: el que no tiene prefijos (EE. UU. en +1, Rusia en +7).
    return same.firstWhere((c) => c.prefixes.isEmpty, orElse: () => same.first);
  }
  return null;
}

/// Solo las cifras del número nacional que escribió la persona, sin el 0 de larga distancia si el país lo usa.
String kaeliNationalDigits(String typed, KaeliPhoneCountry country) {
  var national = typed.replaceAll(RegExp(r'\D'), '');
  if (country.trunkZero && national.startsWith('0')) national = national.substring(1);
  return national;
}

/// ¿El número nacional tiene el largo válido para ese país?
bool kaeliValidNational(String typed, KaeliPhoneCountry country) {
  final n = kaeliNationalDigits(typed, country).length;
  return n >= country.min && n <= country.max;
}

/// Número completo en formato internacional E.164 («8889 5761» + Costa Rica → «+50688895761»). Si ya trae el código
/// («+52…», «0052…»), se respeta. null si está vacío o el largo no es válido.
String? kaeliToE164(String? typed, KaeliPhoneCountry country) {
  final text = (typed ?? '').trim();
  if (text.isEmpty) return null;
  final intl = _internationalDigits(text);
  if (intl != null) {
    final c = kaeliCountryFromPhone('+$intl');
    if (c == null) return null;
    return kaeliValidNational(intl.substring(c.dial.length), c) ? '+$intl' : null;
  }
  if (!kaeliValidNational(text, country)) return null;
  return '+${country.dial}${kaeliNationalDigits(text, country)}';
}

/// Un número guardado («+50660895761») → su país y el número nacional con espacios («6089 5761»), para editarlo. Si no
/// se reconoce, el país es null y el número va tal cual.
({KaeliPhoneCountry? country, String national}) kaeliSplitPhone(String? phone) {
  final c = kaeliCountryFromPhone(phone);
  if (c == null) return (country: null, national: (phone ?? '').trim());
  final national = _internationalDigits(phone!)!.substring(c.dial.length);
  return (country: c, national: kaeliFormatNational(national, c));
}

String _group(String digits, List<int> sizes) {
  final out = <String>[];
  var i = 0;
  for (final n in sizes) {
    if (i >= digits.length) break;
    final end = i + n > digits.length ? digits.length : i + n;
    out.add(digits.substring(i, end));
    i = end;
  }
  if (i < digits.length) out.add(digits.substring(i));
  return out.join(' ');
}

/// Número nacional con espacios, para leerlo («60895761» → «6089 5761»). Mismas reglas que AlojaConmigo.
String kaeliFormatNational(String digits, KaeliPhoneCountry country) {
  final d = digits.replaceAll(RegExp(r'\D'), '');
  final sizes = switch (country.dial) {
    '1' => [3, 3, 4],
    '52' => RegExp(r'^(55|33|81)').hasMatch(d) ? [2, 4, 4] : [3, 3, 4],
    '55' => d.length == 11 ? [2, 5, 4] : [2, 4, 4],
    '33' => [1, 2, 2, 2, 2],
    '56' => [1, 4, 4],
    '44' => [4, 6],
    _ => switch (d.length) {
      7 => [3, 4],
      8 => [4, 4],
      9 => [3, 3, 3],
      10 => [3, 3, 4],
      11 => [3, 4, 4],
      _ => [3, 3, 3, 3, 3],
    },
  };
  return _group(d, sizes);
}

String _fold(String s) {
  const from = 'áàâäãåéèêëíìîïóòôöõúùûüñçÁÀÂÄÃÅÉÈÊËÍÌÎÏÓÒÔÖÕÚÙÛÜÑÇ’';
  const to = 'aaaaaaeeeeiiiiooooouuuuncAAAAAAEEEEIIIIOOOOOUUUUNC\'';
  final out = StringBuffer();
  for (final ch in s.split('')) {
    final i = from.indexOf(ch);
    out.write(i < 0 ? ch : to[i]);
  }
  return out.toString().toLowerCase();
}

/// Países que coinciden con [query]: por nombre en [languageCode] (sin importar acentos ni mayúsculas, también en
/// inglés), por código ISO («CR») o por código telefónico («+506», «506», «50»).
List<KaeliPhoneCountry> kaeliSearchPhoneCountries(
  String query,
  String? languageCode, [
  List<KaeliPhoneCountry> countries = kaeliPhoneCountries,
]) {
  final q = query.trim();
  if (q.isEmpty) return countries;
  final digits = q.replaceAll(RegExp(r'[\s+]'), '');
  if (RegExp(r'^\d+$').hasMatch(digits)) return countries.where((c) => c.dial.startsWith(digits)).toList();
  final f = _fold(q);
  return countries
      .where(
        (c) => _fold(c.name(languageCode)).contains(f) || _fold(c.names[1]).contains(f) || c.iso.toLowerCase() == f,
      )
      .toList();
}

/// Ordena por nombre en [languageCode] (sin importar acentos).
List<KaeliPhoneCountry> kaeliSortPhoneCountries(List<KaeliPhoneCountry> countries, String? languageCode) =>
    [...countries]..sort((a, b) => _fold(a.name(languageCode)).compareTo(_fold(b.name(languageCode))));
