import 'package:flutter/material.dart';

import 'month_year_picker.dart';
import 'strings.dart';

/// Elegir un día (Sesly #22): calendario del mes con ‹ › y, al tocar «octubre 2026 ▾», las ruedas de mes y año de
/// [showKaeliMonthYearPicker]. «Cancelar» y «Aceptar» con el mismo formato (sin MAYÚSCULAS). Igual en iPhone y
/// Android, con los colores del tema y los meses y días en el idioma de la app.
///
/// - [initial]: el día marcado; si es null, se abre en [openAt] (p. ej. unos años atrás para una fecha de nacimiento)
///   o en hoy, sin marcar ninguno.
/// - [first] y [last] limitan los días que se pueden elegir (p. ej. `last: hoy` para no aceptar fechas futuras).
/// - [isUnavailable] (0.15.0): días ocupados (reservas, bloqueos): salen tachados y no se pueden elegir, como en la
///   web de reservas. Los de fuera de [first]–[last] solo salen apagados.
/// - [firstDayOfWeek] (0.14.0): la semana empieza en lunes en todos los idiomas (`DateTime.monday`, por defecto);
///   `DateTime.sunday` la empieza en domingo. Antes seguía al idioma (en inglés de EE. UU., domingo).
/// - [selectedDayColor] y [selectedDayGradient] (0.18.0): el relleno del día elegido (por ejemplo, el degradado del
///   botón principal de un tema). Sin ellos, `colorScheme.primary`, como siempre.
Future<DateTime?> showKaeliDatePicker(
  BuildContext context, {
  DateTime? initial,
  DateTime? openAt,
  required DateTime first,
  required DateTime last,
  String? title,
  KaeliUiStrings? strings,
  int firstDayOfWeek = DateTime.monday,
  bool Function(DateTime day)? isUnavailable,
  Color? selectedDayColor,
  Gradient? selectedDayGradient,
}) => showDialog<DateTime>(
  context: context,
  builder: (context) => KaeliDatePickerDialog(
    initial: initial,
    openAt: openAt,
    first: first,
    last: last,
    title: title,
    strings: strings,
    firstDayOfWeek: firstDayOfWeek,
    isUnavailable: isUnavailable,
    selectedDayColor: selectedDayColor,
    selectedDayGradient: selectedDayGradient,
  ),
);

class KaeliDatePickerDialog extends StatefulWidget {
  const KaeliDatePickerDialog({
    super.key,
    this.initial,
    this.openAt,
    required this.first,
    required this.last,
    this.title,
    this.strings,
    this.firstDayOfWeek = DateTime.monday,
    this.isUnavailable,
    this.selectedDayColor,
    this.selectedDayGradient,
  });

  final DateTime? initial;
  final DateTime? openAt;
  final DateTime first;
  final DateTime last;
  final String? title;
  final KaeliUiStrings? strings;

  /// Primer día de la semana (`DateTime.monday` … `DateTime.sunday`); lunes por defecto.
  final int firstDayOfWeek;

  /// Días ocupados: tachados y sin poder elegirse (0.15.0).
  final bool Function(DateTime day)? isUnavailable;

  /// Relleno del día elegido (0.18.0); sin él, `colorScheme.primary`.
  final Color? selectedDayColor;

  /// Degradado del día elegido (0.18.0); si está, tapa a [selectedDayColor].
  final Gradient? selectedDayGradient;

  /// Llave del botón «mes año ▾» (pruebas).
  static const monthButtonKey = Key('kaeli-date-month');

  @override
  State<KaeliDatePickerDialog> createState() => _KaeliDatePickerDialogState();
}

class _KaeliDatePickerDialogState extends State<KaeliDatePickerDialog> {
  // Un día ocupado nunca queda elegido de entrada (0.15.0): «Aceptar» no lo dejaría pasar sin querer.
  late DateTime? _selected = widget.initial == null || _taken(_day(widget.initial!)) ? null : _day(widget.initial!);
  late DateTime _month = _clampMonth(_monthOf(widget.initial ?? widget.openAt ?? DateTime.now()));

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _monthOf(DateTime d) => DateTime(d.year, d.month);

  DateTime _clampMonth(DateTime m) {
    final lo = _monthOf(widget.first);
    final hi = _monthOf(widget.last);
    return m.isBefore(lo) ? lo : (m.isAfter(hi) ? hi : m);
  }

  bool _inRange(DateTime d) => !d.isBefore(_day(widget.first)) && !d.isAfter(_day(widget.last));

  bool _taken(DateTime d) => widget.isUnavailable?.call(d) ?? false;

  bool _enabled(DateTime d) => _inRange(d) && !_taken(d);

  /// 0.13.0: las ruedas de mes y año reemplazan los días en la MISMA ventana (antes se abría otra hoja encima).
  var _choosingMonth = false;

  void _pickMonth() => setState(() => _choosingMonth = true);

  @override
  Widget build(BuildContext context) {
    final texts = KaeliUiTexts.of(context, widget.strings);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final locale = Localizations.localeOf(context);
    final material = MaterialLocalizations.of(context);
    final months = KaeliMonthYearPicker.monthNamesFor(locale);
    final canBack = _month.isAfter(_monthOf(widget.first));
    final canNext = _month.isBefore(_monthOf(widget.last));

    // Días de la semana desde [firstDayOfWeek] (lunes por defecto, en todos los idiomas).
    final firstWeekday = widget.firstDayOfWeek % 7; // 0 = domingo
    final narrow = kaeliNarrowWeekdays(material, locale);
    final lead = (DateTime(_month.year, _month.month).weekday % 7 - firstWeekday) % 7;
    final days = DateUtils.getDaysInMonth(_month.year, _month.month);
    final today = _day(DateTime.now());

    Widget cell(int dayNumber) {
      final d = DateTime(_month.year, _month.month, dayNumber);
      final enabled = _enabled(d);
      final taken = _inRange(d) && _taken(d);
      final selected = d == _selected;
      final isToday = d == today;
      return Semantics(
        selected: selected,
        button: true,
        enabled: enabled,
        label: taken ? '${material.formatFullDate(d)} · ${texts.dayUnavailable}' : material.formatFullDate(d),
        excludeSemantics: true,
        child: InkResponse(
          onTap: enabled ? () => setState(() => _selected = d) : null,
          radius: 22,
          child: Container(
            margin: const EdgeInsets.all(2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected && widget.selectedDayGradient == null ? widget.selectedDayColor ?? colors.primary : null,
              gradient: selected ? widget.selectedDayGradient : null,
              border: isToday && !selected ? Border.all(color: colors.primary) : null,
            ),
            child: Text(
              '$dayNumber',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: selected
                    ? colors.onPrimary
                    : enabled
                    ? colors.onSurface
                    : colors.onSurface.withValues(alpha: 0.38),
                decoration: taken ? TextDecoration.lineThrough : null,
                decorationColor: colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      );
    }

    if (_choosingMonth) {
      return AlertDialog(
        title: Text(texts.monthYearTitle),
        contentPadding: const EdgeInsetsDirectional.fromSTEB(24, 12, 16, 8),
        content: SizedBox(
          width: 340,
          child: KaeliMonthYearPicker(
            initial: _month,
            first: widget.first,
            last: widget.last,
            strings: widget.strings,
            showTitle: false,
            onCancel: () => setState(() => _choosingMonth = false),
            onConfirm: (m) => setState(() {
              _month = _clampMonth(m);
              _choosingMonth = false;
            }),
          ),
        ),
      );
    }

    return AlertDialog(
      title: widget.title == null ? null : Text(widget.title!),
      contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: material.previousMonthTooltip,
                    onPressed: canBack ? () => setState(() => _month = DateTime(_month.year, _month.month - 1)) : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: TextButton(
                      key: KaeliDatePickerDialog.monthButtonKey,
                      onPressed: _pickMonth,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              '${months[_month.month - 1]} ${_month.year}',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: material.nextMonthTooltip,
                    onPressed: canNext ? () => setState(() => _month = DateTime(_month.year, _month.month + 1)) : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (var i = 0; i < 7; i++)
                    ExcludeSemantics(
                      child: Center(
                        child: Text(
                          narrow[(firstWeekday + i) % 7],
                          style: theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ),
                    ),
                  for (var i = 0; i < lead; i++) const SizedBox.shrink(),
                  for (var d = 1; d <= days; d++) cell(d),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(texts.cancel)),
        TextButton(
          onPressed: _selected == null ? null : () => Navigator.of(context).pop(_selected),
          child: Text(texts.confirm),
        ),
      ],
    );
  }
}

/// Iniciales de los días (de domingo a sábado) en el idioma; en español, «X» para el miércoles (en «es-US» o
/// «es-419», martes y miércoles salían los dos «M»).
List<String> kaeliNarrowWeekdays(MaterialLocalizations material, Locale locale) {
  final narrow = [...material.narrowWeekdays];
  if (locale.languageCode == 'es') narrow[3] = 'X';
  return narrow;
}
