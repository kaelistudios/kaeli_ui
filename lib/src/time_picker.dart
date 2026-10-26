import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'strings.dart';
import 'wheel_rows.dart';

/// Hora con ruedas, con el MISMO estilo que el calendario ([showKaeliDatePicker]) desde 0.16.0 (Blunkoo, prueba de la
/// 1.0.0 (11) en iPhone): ventana con título «Elige la hora», ruedas de hora, minutos y (con el reloj de 12 horas)
/// a. m./p. m. con la letra del diálogo (sin números aplastados) y botones de texto «Cancelar» y «Listo». Sale encima
/// de todo (también de la barra de pestañas). Respeta el reloj del teléfono (12 o 24 horas). [minuteInterval]: de
/// cuántos en cuántos minutos (5 por defecto; 1 para horas exactas como 7:35). Devuelve la hora elegida, o null si se
/// cerró.
///
/// ```dart
/// final t = await showKaeliTimePicker(context, initial: const TimeOfDay(hour: 8, minute: 0));
/// ```
Future<TimeOfDay?> showKaeliTimePicker(
  BuildContext context, {
  required TimeOfDay initial,
  String? title,
  int minuteInterval = 5,
  KaeliUiStrings? strings,
}) => showDialog<TimeOfDay>(
  context: context,
  useRootNavigator: true,
  builder: (context) {
    final texts = KaeliUiTexts.of(context, strings);
    return AlertDialog(
      title: Text(title ?? texts.timeTitle),
      contentPadding: const EdgeInsetsDirectional.fromSTEB(24, 12, 16, 8),
      content: SizedBox(
        width: 340,
        child: KaeliTimePicker(
          initial: initial,
          minuteInterval: minuteInterval,
          strings: strings,
          showTitle: false,
          onCancel: () => Navigator.of(context).pop(),
          onConfirm: (t) => Navigator.of(context).pop(t),
        ),
      ),
    );
  },
);

/// Contenido de [showKaeliTimePicker]: título (opcional), ruedas y «Cancelar» / «Listo».
class KaeliTimePicker extends StatefulWidget {
  const KaeliTimePicker({
    super.key,
    required this.initial,
    required this.onCancel,
    required this.onConfirm,
    this.title,
    this.minuteInterval = 5,
    this.strings,
    this.showTitle = true,
  }) : assert(minuteInterval >= 1 && minuteInterval <= 30 && 60 % minuteInterval == 0);

  final TimeOfDay initial;
  final String? title;
  final int minuteInterval;
  final KaeliUiStrings? strings;
  final VoidCallback onCancel;
  final ValueChanged<TimeOfDay> onConfirm;

  /// El título arriba (false si ya lo pone el diálogo que lo contiene).
  final bool showTitle;

  static const hourWheelKey = Key('kaeli-hour-wheel');
  static const minuteWheelKey = Key('kaeli-minute-wheel');
  static const periodWheelKey = Key('kaeli-period-wheel');
  static const cancelKey = Key('kaeli-time-cancel');
  static const doneKey = Key('kaeli-time-done');

  @override
  State<KaeliTimePicker> createState() => _KaeliTimePickerState();
}

class _KaeliTimePickerState extends State<KaeliTimePicker> {
  // La rueda solo tiene minutos múltiplos del intervalo.
  late int _hour = widget.initial.hour;
  late int _minute = widget.initial.minute - widget.initial.minute % widget.minuteInterval;

  FixedExtentScrollController? _hours;
  late final _minutes = FixedExtentScrollController(initialItem: _minute ~/ widget.minuteInterval);
  late final _periods = FixedExtentScrollController(initialItem: _hour < 12 ? 0 : 1);
  bool? _twentyFour;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final twentyFour = MediaQuery.alwaysUse24HourFormatOf(context);
    if (_twentyFour == twentyFour) return;
    _twentyFour = twentyFour;
    _hours?.dispose();
    _hours = FixedExtentScrollController(initialItem: twentyFour ? _hour : (_hour + 11) % 12);
  }

  @override
  void dispose() {
    _hours?.dispose();
    _minutes.dispose();
    _periods.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final texts = KaeliUiTexts.of(context, widget.strings);
    final material = MaterialLocalizations.of(context);
    final twentyFour = _twentyFour ?? false;
    final scaler = MediaQuery.textScalerOf(context);
    // La misma letra que el calendario y filas que crecen con ella: los números nunca quedan aplastados.
    final style = (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(color: colors.onSurface);
    final itemExtent = scaler.scale((style.fontSize ?? 16) * 2.1);
    final overlay = CupertinoPickerDefaultSelectionOverlay(background: colors.primary.withValues(alpha: 0.12));
    final titleStyle = theme.dialogTheme.titleTextStyle ?? theme.textTheme.titleLarge;
    String two(int n) => n.toString().padLeft(2, '0');

    Widget wheel({
      required Key key,
      required FixedExtentScrollController controller,
      required int count,
      required String Function(int) label,
      required ValueChanged<int> onChanged,
      bool loop = false,
    }) => CupertinoPicker(
      key: key,
      scrollController: controller,
      itemExtent: itemExtent,
      selectionOverlay: overlay,
      backgroundColor: Colors.transparent,
      // Como el mes y el año: rueda casi plana, opciones enteras.
      diameterRatio: 4,
      squeeze: 1,
      looping: loop,
      onSelectedItemChanged: onChanged,
      children: [for (var i = 0; i < count; i++) Center(child: Text(label(i), style: style, maxLines: 1))],
    );

    final minutes = 60 ~/ widget.minuteInterval;
    return KaeliWheelRows(
      itemExtent: itemExtent,
      title: widget.showTitle ? Text(widget.title ?? texts.timeTitle, style: titleStyle) : null,
      wheels: Semantics(
        label: material.formatTimeOfDay(
          TimeOfDay(hour: _hour, minute: _minute),
          alwaysUse24HourFormat: twentyFour,
        ),
        child: Row(
          children: [
            Expanded(
              child: wheel(
                key: KaeliTimePicker.hourWheelKey,
                controller: _hours!,
                count: twentyFour ? 24 : 12,
                loop: true,
                label: (i) => twentyFour ? two(i) : '${i + 1}',
                onChanged: (i) => setState(() {
                  if (twentyFour) {
                    _hour = i % 24;
                  } else {
                    final h12 = i % 12 + 1; // 1…12
                    _hour = h12 % 12 + (_hour >= 12 ? 12 : 0);
                  }
                }),
              ),
            ),
            Expanded(
              child: wheel(
                key: KaeliTimePicker.minuteWheelKey,
                controller: _minutes,
                count: minutes,
                loop: true,
                label: (i) => two(i * widget.minuteInterval),
                onChanged: (i) => setState(() => _minute = (i % minutes) * widget.minuteInterval),
              ),
            ),
            if (!twentyFour)
              Expanded(
                child: wheel(
                  key: KaeliTimePicker.periodWheelKey,
                  controller: _periods,
                  count: 2,
                  label: (i) => i == 0 ? material.anteMeridiemAbbreviation : material.postMeridiemAbbreviation,
                  onChanged: (i) => setState(() => _hour = _hour % 12 + (i == 1 ? 12 : 0)),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(key: KaeliTimePicker.cancelKey, onPressed: widget.onCancel, child: Text(texts.cancel)),
        TextButton(
          key: KaeliTimePicker.doneKey,
          onPressed: () => widget.onConfirm(TimeOfDay(hour: _hour, minute: _minute)),
          child: Text(texts.monthYearDone),
        ),
      ],
    );
  }
}
