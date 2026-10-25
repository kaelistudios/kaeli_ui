// Mes y año con ruedas, igual en iPhone y Android. Nació de una prueba en iPhone (23 oct 2026): para cambiar de mes
// en un calendario había que tocar la flecha muchas veces.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart' show dateTimeSymbolMap;
import 'package:intl/date_symbols.dart';
import 'package:intl/intl.dart' show Intl;

import 'strings.dart';

/// Abre una hoja desde abajo con dos ruedas, meses y años (como el selector de hora del iPhone), con ✕ y ✓.
/// Devuelve el primer día del mes elegido, o null si se cerró con ✕ o deslizando.
///
/// ```dart
/// final month = await showKaeliMonthYearPicker(context, initial: visibleMonth);
/// if (month != null) setState(() => visibleMonth = month);
/// ```
///
/// - [first] y [last]: rango de meses que se puede elegir (por defecto, de 5 años atrás a 10 años adelante del
///   actual, y siempre incluye [initial]).
/// - [title]: texto arriba, entre ✕ y ✓ (opcional).
/// - Los meses salen en el idioma de la app (`Localizations.localeOf`); [monthNames] los cambia.
/// - Colores y letras del tema de la app (`ColorScheme`, `TextTheme`).
Future<DateTime?> showKaeliMonthYearPicker(
  BuildContext context, {
  required DateTime initial,
  DateTime? first,
  DateTime? last,
  String? title,
  List<String>? monthNames,
  KaeliUiStrings? strings,
}) => showModalBottomSheet<DateTime>(
  context: context,
  // 0.13.1: encima de todo (también de la barra de pestañas de la app).
  useRootNavigator: true,
  useSafeArea: true,
  showDragHandle: false,
  // 0.13.0: hoja corta, del alto justo (título, ruedas y botones).
  builder: (context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(24, 20, 16, 8),
    child: KaeliMonthYearPicker(
      initial: initial,
      first: first,
      last: last,
      title: title,
      monthNames: monthNames,
      strings: strings,
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: (month) => Navigator.of(context).pop(month),
    ),
  ),
);

class KaeliMonthYearPicker extends StatefulWidget {
  const KaeliMonthYearPicker({
    super.key,
    required this.initial,
    this.first,
    this.last,
    this.title,
    this.monthNames,
    this.strings,
    required this.onCancel,
    required this.onConfirm,
    this.showTitle = true,
  });

  /// 0.13.0: el título «Elige mes y año» arriba (false si ya lo pone el diálogo que lo contiene).
  final bool showTitle;

  final DateTime initial;
  final DateTime? first;
  final DateTime? last;
  final String? title;
  final List<String>? monthNames;
  final KaeliUiStrings? strings;
  final VoidCallback onCancel;
  final ValueChanged<DateTime> onConfirm;

  /// Llaves de las ruedas (pruebas).
  static const monthWheelKey = Key('kaeli-month-wheel');
  static const yearWheelKey = Key('kaeli-year-wheel');
  static const cancelKey = Key('kaeli-month-year-cancel');
  static const doneKey = Key('kaeli-month-year-done');

  /// Rango por defecto: de 5 años atrás a 10 adelante de [now], estirado para incluir [initial].
  static (DateTime, DateTime) defaultRange(DateTime initial, DateTime now, {DateTime? first, DateTime? last}) {
    var from = first ?? DateTime(now.year - 5);
    var to = last ?? DateTime(now.year + 10, 12);
    if (initial.isBefore(from)) from = DateTime(initial.year, initial.month);
    if (initial.isAfter(to)) to = DateTime(initial.year, initial.month);
    return (DateTime(from.year, from.month), DateTime(to.year, to.month));
  }

  /// Nombres de los meses (enero…diciembre) en [locale], con mayúscula inicial; inglés si no hay datos del idioma.
  static List<String> monthNamesFor(Locale locale) {
    final symbols = dateTimeSymbolMap();
    DateSymbols? found;
    for (final tag in [Intl.canonicalizedLocale(locale.toString()), locale.languageCode, 'en']) {
      final s = symbols[tag];
      if (s is DateSymbols) {
        found = s;
        break;
      }
    }
    return [for (final m in found!.STANDALONEMONTHS) m.isEmpty ? m : m[0].toUpperCase() + m.substring(1)];
  }

  @override
  State<KaeliMonthYearPicker> createState() => _KaeliMonthYearPickerState();
}

class _KaeliMonthYearPickerState extends State<KaeliMonthYearPicker> {
  late final DateTime _first;
  late final DateTime _last;
  late int _year;
  late int _month;
  late final FixedExtentScrollController _months;
  late final FixedExtentScrollController _years;

  @override
  void initState() {
    super.initState();
    final (first, last) = KaeliMonthYearPicker.defaultRange(
      widget.initial,
      DateTime.now(),
      first: widget.first,
      last: widget.last,
    );
    _first = first;
    _last = last;
    _year = widget.initial.year;
    _month = widget.initial.month;
    _months = FixedExtentScrollController(initialItem: _month - 1);
    _years = FixedExtentScrollController(initialItem: _year - _first.year);
  }

  @override
  void dispose() {
    _months.dispose();
    _years.dispose();
    super.dispose();
  }

  /// El mes elegido, dentro del rango.
  DateTime get _value {
    final picked = DateTime(_year, _month);
    if (picked.isBefore(_first)) return _first;
    if (picked.isAfter(_last)) return _last;
    return picked;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final texts = KaeliUiTexts.of(context, widget.strings);
    final names = widget.monthNames ?? KaeliMonthYearPicker.monthNamesFor(Localizations.localeOf(context));
    final scaler = MediaQuery.textScalerOf(context);
    // 0.13.0: la misma letra que el resto del diálogo (los días), 5 opciones visibles y ruedas del mismo alto.
    final style = (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(color: colors.onSurface);
    final itemExtent = scaler.scale((style.fontSize ?? 16) * 2.1);
    final overlay = CupertinoPickerDefaultSelectionOverlay(background: colors.primary.withValues(alpha: 0.12));
    final titleStyle = theme.dialogTheme.titleTextStyle ?? theme.textTheme.titleLarge;

    Widget wheel({
      required Key key,
      required FixedExtentScrollController controller,
      required int count,
      required String Function(int) label,
      required ValueChanged<int> onChanged,
      required String semantics,
    }) => Semantics(
      label: semantics,
      child: CupertinoPicker.builder(
        key: key,
        scrollController: controller,
        itemExtent: itemExtent,
        selectionOverlay: overlay,
        backgroundColor: Colors.transparent,
        // 0.13.1: rueda casi plana: se ven 5 opciones enteras (con la curva se asomaban 7, cortadas).
        diameterRatio: 4,
        squeeze: 1,
        onSelectedItemChanged: onChanged,
        childCount: count,
        itemBuilder: (context, i) => Center(
          child: Text(label(i), style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showTitle)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 12),
            child: Text(widget.title ?? texts.monthYearTitle, style: titleStyle),
          ),
        SizedBox(
          height: itemExtent * 5,
          child: DefaultTextStyle(
            style: style,
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: wheel(
                    key: KaeliMonthYearPicker.monthWheelKey,
                    controller: _months,
                    count: 12,
                    label: (i) => names[i],
                    onChanged: (i) => _month = i + 1,
                    semantics: names[_month - 1],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: wheel(
                    key: KaeliMonthYearPicker.yearWheelKey,
                    controller: _years,
                    count: _last.year - _first.year + 1,
                    label: (i) => '${_first.year + i}',
                    onChanged: (i) => _year = _first.year + i,
                    semantics: '$_year',
                  ),
                ),
              ],
            ),
          ),
        ),
        // Botones de texto como los de los demás diálogos (0.13.0: antes eran ✕ y ✓).
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 8),
          child: OverflowBar(
            alignment: MainAxisAlignment.end,
            spacing: 8,
            children: [
              TextButton(
                key: KaeliMonthYearPicker.cancelKey,
                onPressed: widget.onCancel,
                child: Text(texts.cancel),
              ),
              TextButton(
                key: KaeliMonthYearPicker.doneKey,
                onPressed: () => widget.onConfirm(_value),
                child: Text(texts.monthYearDone),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
