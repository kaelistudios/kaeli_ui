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
  useSafeArea: true,
  showDragHandle: false,
  builder: (context) => KaeliMonthYearPicker(
    initial: initial,
    first: first,
    last: last,
    title: title,
    monthNames: monthNames,
    strings: strings,
    onCancel: () => Navigator.of(context).pop(),
    onConfirm: (month) => Navigator.of(context).pop(month),
  ),
);

/// Contenido de [showKaeliMonthYearPicker], por si se quiere poner en otro lugar.
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
  });

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
    final style = (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(color: colors.onSurface);
    final itemExtent = scaler.scale((style.fontSize ?? 16) * 2.2);
    final overlay = CupertinoPickerDefaultSelectionOverlay(background: colors.primary.withValues(alpha: 0.12));

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
        onSelectedItemChanged: onChanged,
        childCount: count,
        itemBuilder: (context, i) => Center(
          child: Text(label(i), style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );

    // Alto del encabezado (✕, título y ✓) para calcular cuántas filas caben.
    final titleStyle = theme.textTheme.titleMedium;
    final header =
        4 +
        (widget.title == null
            ? 48.0
            : scaler
                  .scale((titleStyle?.fontSize ?? 16) * (titleStyle?.height ?? 1.4) * 2)
                  .clamp(48.0, double.infinity));

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 5 filas si caben; si no (letra grande en pantalla pequeña), las que quepan, nunca menos de 3. Si ni así
          // cabe, la hoja se desplaza.
          final room = constraints.maxHeight - header - 8;
          final rows = room.isFinite ? (room / itemExtent).floor().clamp(3, 5) : 5;
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 4, 0),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.close), tooltip: texts.cancel, onPressed: widget.onCancel),
                      Expanded(
                        child: Text(
                          widget.title ?? '',
                          style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurface),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.check, color: colors.primary),
                        tooltip: texts.confirm,
                        onPressed: () => widget.onConfirm(_value),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: itemExtent * rows,
                  child: DefaultTextStyle(
                    style: style,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
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
                          flex: 2,
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
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}
