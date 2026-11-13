// 0.20.0: cumpleaños con ruedas (Katawi, clientas). Día y mes siempre; el año es opcional («Sin año»), porque muchas
// personas no quieren decir su edad.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'month_year_picker.dart';
import 'strings.dart';
import 'wheel_rows.dart';

/// Un cumpleaños: día y mes, y el año solo si se sabe.
@immutable
class KaeliBirthday {
  const KaeliBirthday({required this.month, required this.day, this.year})
    : assert(month >= 1 && month <= 12),
      assert(day >= 1 && day <= 31);

  /// 1 = enero … 12 = diciembre.
  final int month;

  /// 1…31 (29 de febrero solo sin año o con año bisiesto).
  final int day;

  /// null = «Sin año».
  final int? year;

  /// Días que tiene [month] en [year] (sin año cuenta como bisiesto: 29 de febrero se puede).
  static int daysIn(int month, int? year) => DateTime(year ?? 2000, month + 1, 0).day;

  @override
  bool operator ==(Object other) =>
      other is KaeliBirthday && other.month == month && other.day == day && other.year == year;

  @override
  int get hashCode => Object.hash(month, day, year);

  @override
  String toString() => 'KaeliBirthday(month: $month, day: $day, year: $year)';
}

/// Cumpleaños con ruedas, con el MISMO estilo que la hora ([showKaeliTimePicker]): ventana con título «Cumpleaños»,
/// ruedas de día, mes (en el idioma de la app) y año, y botones de texto «Cancelar» y «Listo». Sale encima de todo
/// (también de la barra de pestañas).
///
/// - El año es opcional: la primera opción de su rueda es «Sin año»; después, de [today] hacia atrás hasta
///   [firstYear].
/// - Sin [initial], se abre en el día y el mes de hoy ([today], o `DateTime.now()`) y «Sin año».
/// - El día se ajusta al mes: 29 de febrero se puede sin año o con año bisiesto; con un año no bisiesto baja a 28.
///
/// Devuelve el cumpleaños elegido, o null si se cerró.
///
/// ```dart
/// final b = await showKaeliBirthdayPicker(context, initial: client.birthday);
/// if (b != null) save(month: b.month, day: b.day, year: b.year);
/// ```
Future<KaeliBirthday?> showKaeliBirthdayPicker(
  BuildContext context, {
  KaeliBirthday? initial,
  DateTime? today,
  String? title,
  KaeliUiStrings? strings,
  int firstYear = 1920,
}) => showDialog<KaeliBirthday>(
  context: context,
  useRootNavigator: true,
  builder: (context) {
    final texts = KaeliUiTexts.of(context, strings);
    return AlertDialog(
      title: Text(title ?? texts.birthdayTitle),
      contentPadding: const EdgeInsetsDirectional.fromSTEB(24, 12, 16, 8),
      content: SizedBox(
        width: 340,
        child: KaeliBirthdayPicker(
          initial: initial,
          today: today,
          firstYear: firstYear,
          strings: strings,
          showTitle: false,
          onCancel: () => Navigator.of(context).pop(),
          onConfirm: (b) => Navigator.of(context).pop(b),
        ),
      ),
    );
  },
);

/// Contenido de [showKaeliBirthdayPicker]: título (opcional), ruedas de día, mes y año, y «Cancelar» / «Listo».
class KaeliBirthdayPicker extends StatefulWidget {
  const KaeliBirthdayPicker({
    super.key,
    required this.onCancel,
    required this.onConfirm,
    this.initial,
    this.today,
    this.title,
    this.strings,
    this.firstYear = 1920,
    this.monthNames,
    this.showTitle = true,
  });

  final KaeliBirthday? initial;
  final DateTime? today;
  final String? title;
  final KaeliUiStrings? strings;
  final int firstYear;

  /// Nombres de los meses (enero…diciembre); por defecto, los del idioma de la app.
  final List<String>? monthNames;
  final VoidCallback onCancel;
  final ValueChanged<KaeliBirthday> onConfirm;

  /// El título arriba (false si ya lo pone el diálogo que lo contiene).
  final bool showTitle;

  /// Llaves para las pruebas. En la rueda de años, la fila 0 es «Sin año» y la fila i es el año `today.year - i + 1`.
  static const dayWheelKey = Key('kaeli-birthday-day-wheel');
  static const monthWheelKey = Key('kaeli-birthday-month-wheel');
  static const yearWheelKey = Key('kaeli-birthday-year-wheel');
  static const cancelKey = Key('kaeli-birthday-cancel');
  static const doneKey = Key('kaeli-birthday-done');

  /// Lo mismo que [doneKey].
  static const confirmKey = doneKey;

  @override
  State<KaeliBirthdayPicker> createState() => _KaeliBirthdayPickerState();
}

class _KaeliBirthdayPickerState extends State<KaeliBirthdayPicker> {
  late final int _topYear;
  late final int _bottomYear;
  late int _month;
  late int _day;
  int? _year;
  late final FixedExtentScrollController _days;
  late final FixedExtentScrollController _months;
  late final FixedExtentScrollController _years;

  @override
  void initState() {
    super.initState();
    final today = widget.today ?? DateTime.now();
    final initial = widget.initial ?? KaeliBirthday(month: today.month, day: today.day);
    _topYear = initial.year != null && initial.year! > today.year ? initial.year! : today.year;
    _bottomYear = initial.year != null && initial.year! < widget.firstYear ? initial.year! : widget.firstYear;
    _month = initial.month;
    _year = initial.year;
    _day = initial.day.clamp(1, KaeliBirthday.daysIn(_month, _year));
    _days = FixedExtentScrollController(initialItem: _day - 1);
    _months = FixedExtentScrollController(initialItem: _month - 1);
    _years = FixedExtentScrollController(initialItem: _year == null ? 0 : _topYear - _year! + 1);
  }

  @override
  void dispose() {
    _days.dispose();
    _months.dispose();
    _years.dispose();
    super.dispose();
  }

  /// Si el mes o el año cambian y el día ya no existe (31 de abril, 29 de febrero de 2026), baja al último.
  void _fitDay() {
    final max = KaeliBirthday.daysIn(_month, _year);
    if (_day <= max) return;
    _day = max;
    // Antes de que la rueda de días se achique: así nunca queda fuera de su lista.
    if (_days.hasClients) _days.jumpToItem(max - 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final texts = KaeliUiTexts.of(context, widget.strings);
    final names = widget.monthNames ?? KaeliMonthYearPicker.monthNamesFor(Localizations.localeOf(context));
    final scaler = MediaQuery.textScalerOf(context);
    // La misma letra y el mismo alto de fila que la hora y el mes y año.
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
    }) => CupertinoPicker.builder(
      key: key,
      scrollController: controller,
      itemExtent: itemExtent,
      selectionOverlay: overlay,
      backgroundColor: Colors.transparent,
      diameterRatio: 4,
      squeeze: 1,
      onSelectedItemChanged: onChanged,
      childCount: count,
      itemBuilder: (context, i) => Center(
        child: Text(label(i), style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );

    final semantics = ['$_day', names[_month - 1], if (_year case final year?) '$year'].join(' ');
    return KaeliWheelRows(
      itemExtent: itemExtent,
      title: widget.showTitle ? Text(widget.title ?? texts.birthdayTitle, style: titleStyle) : null,
      wheels: Semantics(
        label: semantics,
        child: DefaultTextStyle(
          style: style,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: wheel(
                  key: KaeliBirthdayPicker.dayWheelKey,
                  controller: _days,
                  count: KaeliBirthday.daysIn(_month, _year),
                  label: (i) => '${i + 1}',
                  onChanged: (i) => setState(() => _day = i + 1),
                ),
              ),
              Expanded(
                flex: 6,
                child: wheel(
                  key: KaeliBirthdayPicker.monthWheelKey,
                  controller: _months,
                  count: 12,
                  label: (i) => names[i],
                  onChanged: (i) {
                    _month = i + 1;
                    _fitDay();
                    setState(() {});
                  },
                ),
              ),
              Expanded(
                flex: 5,
                child: wheel(
                  key: KaeliBirthdayPicker.yearWheelKey,
                  controller: _years,
                  count: _topYear - _bottomYear + 2,
                  label: (i) => i == 0 ? texts.birthdayNoYear : '${_topYear - i + 1}',
                  onChanged: (i) {
                    _year = i == 0 ? null : _topYear - i + 1;
                    _fitDay();
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(key: KaeliBirthdayPicker.cancelKey, onPressed: widget.onCancel, child: Text(texts.cancel)),
        TextButton(
          key: KaeliBirthdayPicker.doneKey,
          onPressed: () => widget.onConfirm(KaeliBirthday(month: _month, day: _day, year: _year)),
          child: Text(texts.monthYearDone),
        ),
      ],
    );
  }
}
