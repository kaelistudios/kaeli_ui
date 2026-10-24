import 'package:flutter/material.dart';

/// Cómo se muestra [KaeliChoice]: según la regla ([auto]) o siempre de una forma (p. ej. un selector de vista en una
/// barra, que no puede crecer hacia abajo).
enum KaeliChoiceLayout { auto, segmented, list }

/// Una opción de [KaeliChoice].
@immutable
class KaeliOption<T> {
  const KaeliOption(this.value, this.label, {this.icon, this.subtitle});

  final T value;
  final String label;

  /// Ícono a la izquierda (solo en la lista vertical).
  final IconData? icon;

  /// Segunda línea (solo en la lista vertical; si alguna opción la tiene, se usa la lista).
  final String? subtitle;
}

/// Elegir **una** opción, con la regla de Kaeli para todas las apps (Sesly #35):
/// - 2 o 3 opciones cortas → control segmentado de ancho completo.
/// - 4 o más, textos largos, segunda línea o letra muy grande → lista vertical con ícono y círculo de selección.
///
/// Así ninguna pantalla tiene botones sueltos desordenados. Colores y letras del tema (`ColorScheme`, `TextTheme`).
///
/// ```dart
/// KaeliChoice<Status>(
///   label: l10n.status,
///   value: _status,
///   options: [for (final s in Status.values) KaeliOption(s, label(s), icon: icon(s))],
///   onChanged: (s) => setState(() => _status = s),
/// )
/// ```
class KaeliChoice<T> extends StatelessWidget {
  const KaeliChoice({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.label,
    this.shortLabel = 14,
    this.layout = KaeliChoiceLayout.auto,
  });

  /// [KaeliChoiceLayout.auto] sigue la regla; los otros la fijan.
  final KaeliChoiceLayout layout;

  final T value;
  final List<KaeliOption<T>> options;
  final ValueChanged<T>? onChanged;

  /// Título arriba de las opciones (opcional).
  final String? label;

  /// Hasta cuántas letras un texto cuenta como «corto» para el control segmentado.
  final int shortLabel;

  /// ¿Va como control segmentado? (La regla, por si una pantalla la necesita.)
  static bool segmented(List<KaeliOption<Object?>> options, {int shortLabel = 14, double textScale = 1}) =>
      options.length >= 2 &&
      options.length <= 3 &&
      textScale <= 1.5 &&
      options.every((o) => o.subtitle == null && o.label.length <= shortLabel);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final useSegments = switch (layout) {
      KaeliChoiceLayout.auto => segmented(options, shortLabel: shortLabel, textScale: scale),
      KaeliChoiceLayout.segmented => true,
      KaeliChoiceLayout.list => false,
    };
    final body = useSegments ? _segments(context) : _list(context);
    if (label == null) return body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(label!, style: theme.textTheme.labelLarge),
        ),
        body,
      ],
    );
  }

  Widget _segments(BuildContext context) => SizedBox(
    width: double.infinity,
    child: SegmentedButton<T>(
      showSelectedIcon: false,
      segments: [
        for (final o in options)
          ButtonSegment<T>(
            value: o.value,
            label: Text(o.label, textAlign: TextAlign.center, maxLines: 2),
          ),
      ],
      selected: {value},
      onSelectionChanged: onChanged == null ? null : (s) => onChanged!(s.first),
    ),
  );

  Widget _list(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return RadioGroup<T>(
      groupValue: value,
      onChanged: (v) {
        if (v != null) onChanged?.call(v);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            for (final (i, o) in options.indexed) ...[
              if (i > 0) Divider(height: 1, color: colors.outlineVariant),
              RadioListTile<T>(
                value: o.value,
                enabled: onChanged != null,
                controlAffinity: ListTileControlAffinity.trailing,
                secondary: o.icon == null ? null : Icon(o.icon, color: colors.primary),
                title: Text(o.label),
                subtitle: o.subtitle == null ? null : Text(o.subtitle!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
