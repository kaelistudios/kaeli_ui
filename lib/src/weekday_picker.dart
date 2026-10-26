import 'package:flutter/material.dart';

/// Días de la semana en una fila (Sesly #86): 7 círculos iguales (L M M J V S D), el marcado relleno del color
/// principal, sin ✓ y sin cambiar de tamaño. Debajo, atajos con borde (#83): «Lunes a viernes» y «Todos».
///
/// ```dart
/// KaeliWeekdayPicker(
///   value: days,                       // {1, 2, 3} (1 = lunes … 7 = domingo)
///   onChanged: (d) => setState(() => days = d),
///   initials: (d) => formats.weekdayInitial(...), // «L», «M», …
///   names: (d) => formats.weekdayName(d),         // para lectores de pantalla
///   weekdaysLabel: l10n.mondayToFriday,
///   allLabel: l10n.all,
/// )
/// ```
///
/// - [disabled]: días que no se pueden elegir (p. ej. el día que se copia).
/// - Cada círculo mide al menos 44 px de zona táctil y se encoge con la pantalla, nunca con el texto: la letra
///   escala con el sistema hasta donde cabe.
class KaeliWeekdayPicker extends StatelessWidget {
  const KaeliWeekdayPicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.initials,
    required this.names,
    this.weekdaysLabel,
    this.allLabel,
    this.disabled = const {},
  });

  final Set<int> value;
  final ValueChanged<Set<int>> onChanged;
  final String Function(int weekday) initials;
  final String Function(int weekday) names;
  final String? weekdaysLabel;
  final String? allLabel;
  final Set<int> disabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final days = [for (var d = 1; d <= 7; d++) d];
    final enabled = [
      for (final d in days)
        if (!disabled.contains(d)) d,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            // 0.16.0: en un espacio angosto (un diálogo en un teléfono pequeño) los círculos se achican hasta 28 y
            // los espacios hasta 2, para que el domingo no se salga del borde.
            final gap = c.maxWidth < 7 * 36 + 6 * 6 ? 2.0 : 6.0;
            final side = ((c.maxWidth - gap * 6) / 7).clamp(28.0, 52.0);
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final d in days)
                  _Day(
                    side: side,
                    label: initials(d),
                    name: names(d),
                    selected: value.contains(d),
                    enabled: !disabled.contains(d),
                    scheme: scheme,
                    style: text.titleSmall,
                    onTap: () => onChanged(value.contains(d) ? ({...value}..remove(d)) : {...value, d}),
                  ),
              ],
            );
          },
        ),
        if (weekdaysLabel != null || allLabel != null) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (weekdaysLabel != null)
                OutlinedButton(
                  style: _shortcut,
                  onPressed: () => onChanged({
                    for (final d in enabled)
                      if (d <= 5) d,
                  }),
                  child: Text(weekdaysLabel!),
                ),
              if (allLabel != null)
                OutlinedButton(style: _shortcut, onPressed: () => onChanged({...enabled}), child: Text(allLabel!)),
            ],
          ),
        ],
      ],
    );
  }

  static final _shortcut = OutlinedButton.styleFrom(
    visualDensity: VisualDensity.compact,
    minimumSize: const Size(44, 36),
    tapTargetSize: MaterialTapTargetSize.padded,
  );
}

class _Day extends StatelessWidget {
  const _Day({
    required this.side,
    required this.label,
    required this.name,
    required this.selected,
    required this.enabled,
    required this.scheme,
    required this.style,
    required this.onTap,
  });

  final double side;
  final String label;
  final String name;
  final bool selected;
  final bool enabled;
  final ColorScheme scheme;
  final TextStyle? style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? scheme.primary : Colors.transparent;
    final fg = !enabled
        ? scheme.onSurface.withValues(alpha: 0.38)
        : selected
        ? scheme.onPrimary
        : scheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: name,
      excludeSemantics: true,
      // 0.16.0: el ancho es el del círculo (los 7 caben siempre en la fila; antes cada uno pedía 44 y en un diálogo
      // angosto el domingo se salía del borde). El alto sigue siendo de al menos 44 para tocarlo fácil.
      child: SizedBox(
        width: side,
        height: 44 > side ? 44 : side,
        child: Center(
          child: Material(
            color: bg,
            shape: CircleBorder(side: selected ? BorderSide.none : BorderSide(color: scheme.outline)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: enabled ? onTap : null,
              child: SizedBox.square(
                dimension: side,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label, style: style?.copyWith(color: fg)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
