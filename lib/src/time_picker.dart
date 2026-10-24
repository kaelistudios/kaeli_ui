import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'strings.dart';

/// Hora con ruedas (Sesly #61), igual que el selector de mes y año: hoja desde abajo con ✕ y ✓. Respeta el reloj
/// del teléfono (12 o 24 horas). [minuteInterval]: de cuántos en cuántos minutos (5 por defecto). Devuelve la hora
/// elegida, o null si se cerró.
///
/// ```dart
/// final t = await showKaeliTimePicker(context, initial: const TimeOfDay(hour: 8, minute: 0), title: 'Desde');
/// ```
Future<TimeOfDay?> showKaeliTimePicker(
  BuildContext context, {
  required TimeOfDay initial,
  String? title,
  int minuteInterval = 5,
  KaeliUiStrings? strings,
}) => showModalBottomSheet<TimeOfDay>(
  context: context,
  useSafeArea: true,
  builder: (context) => KaeliTimePicker(
    initial: initial,
    title: title,
    minuteInterval: minuteInterval,
    strings: strings,
    onCancel: () => Navigator.of(context).pop(),
    onConfirm: (t) => Navigator.of(context).pop(t),
  ),
);

/// Contenido de [showKaeliTimePicker].
class KaeliTimePicker extends StatefulWidget {
  const KaeliTimePicker({
    super.key,
    required this.initial,
    required this.onCancel,
    required this.onConfirm,
    this.title,
    this.minuteInterval = 5,
    this.strings,
  });

  final TimeOfDay initial;
  final String? title;
  final int minuteInterval;
  final KaeliUiStrings? strings;
  final VoidCallback onCancel;
  final ValueChanged<TimeOfDay> onConfirm;

  @override
  State<KaeliTimePicker> createState() => _KaeliTimePickerState();
}

class _KaeliTimePickerState extends State<KaeliTimePicker> {
  // La rueda solo acepta minutos múltiplos del intervalo.
  late TimeOfDay _value = TimeOfDay(
    hour: widget.initial.hour,
    minute: widget.initial.minute - widget.initial.minute % widget.minuteInterval,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final texts = KaeliUiTexts.of(context, widget.strings);
    final scaler = MediaQuery.textScalerOf(context);
    return SafeArea(
      top: false,
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
            height: scaler.scale(216).clamp(216, 320),
            child: CupertinoTheme(
              data: CupertinoThemeData(
                brightness: theme.brightness,
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: theme.textTheme.titleLarge?.copyWith(color: colors.onSurface),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
                minuteInterval: widget.minuteInterval,
                initialDateTime: DateTime(2000, 1, 1, _value.hour, _value.minute),
                onDateTimeChanged: (d) => _value = TimeOfDay(hour: d.hour, minute: d.minute),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
