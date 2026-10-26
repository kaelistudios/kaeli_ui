import 'package:flutter/material.dart';

/// Cómo se muestra [KaeliChoice]. Los dos estilos aprobados para Kaeli (Sesly #51), además del segmentado:
/// - [cards]: tarjetas con ícono, para cosas con identidad propia (especialidades, tipos de cita, lugares, consultorios).
/// - [list]: lista agrupada con círculo, para valores simples (horas, minutos, estados, filtros, idioma, tema).
/// - [segmented]: 2 o 3 opciones cortas.
/// - [auto]: segmentado si son 2 o 3 cortas; si no, [list].
enum KaeliChoiceLayout { auto, segmented, list, cards }

/// Una opción de [KaeliChoice] o [KaeliMultiChoice].
@immutable
class KaeliOption<T> {
  const KaeliOption(this.value, this.label, {this.icon, this.subtitle, this.detail, this.key});

  final T value;
  final String label;

  /// Clave de la opción (0.11.0): va en la fila, la tarjeta o el segmento, para encontrarla en las pruebas de la app.
  final Key? key;

  /// Ícono a la izquierda (lista y tarjetas).
  final IconData? icon;

  /// Segunda línea (si alguna opción la tiene, no se usa el segmentado).
  final String? subtitle;

  /// Segunda línea con formato propio (p. ej. un precio en otro color); reemplaza a [subtitle].
  final Widget? detail;

  bool get _hasSecondLine => subtitle != null || detail != null;
}

/// «Otra» / «Otro» al final, para cuando el valor puede ser libre. Al elegirla se muestra [field] (el campo para
/// escribirlo) dentro del mismo grupo. Quien la usa guarda si está elegida y el valor escrito.
@immutable
class KaeliChoiceOther {
  const KaeliChoiceOther({required this.label, required this.selected, required this.onSelected, required this.field});

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Widget field;
}

/// Elegir **una** opción, con la regla de Kaeli para todas las apps (Sesly #35 y #51). Ver [KaeliChoiceLayout].
///
/// Así ninguna pantalla tiene botones sueltos desordenados. Colores y letras del tema (`ColorScheme`, `TextTheme`).
///
/// ```dart
/// KaeliChoice<int>(
///   label: l10n.notice,
///   value: _other ? null : _hours,
///   options: [for (final h in [6, 12, 24, 48]) KaeliOption(h, l10n.hours(h))],
///   onChanged: (h) => setState(() { _hours = h; _other = false; }),
///   other: KaeliChoiceOther(label: l10n.other, selected: _other, onSelected: () => setState(() => _other = true),
///       field: TextFormField(...)),
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
    this.other,
  });

  final KaeliChoiceLayout layout;

  /// Lo elegido; null si no hay nada elegido (o si está elegida [other]).
  final T? value;
  final List<KaeliOption<T>> options;
  final ValueChanged<T>? onChanged;

  /// Título arriba de las opciones (opcional).
  final String? label;

  /// Hasta cuántas letras un texto cuenta como «corto» para el control segmentado.
  final int shortLabel;

  /// «Otra» al final (con ella nunca se usa el segmentado).
  final KaeliChoiceOther? other;

  /// ¿Va como control segmentado? (La regla, por si una pantalla la necesita.)
  static bool segmented(List<KaeliOption<Object?>> options, {int shortLabel = 14, double textScale = 1}) =>
      options.length >= 2 &&
      options.length <= 3 &&
      textScale <= 1.5 &&
      options.every((o) => !o._hasSecondLine && o.label.length <= shortLabel);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final resolved = switch (layout) {
      KaeliChoiceLayout.auto =>
        other == null && segmented(options, shortLabel: shortLabel, textScale: scale)
            ? KaeliChoiceLayout.segmented
            : KaeliChoiceLayout.list,
      _ => layout,
    };
    final body = switch (resolved) {
      // 0.16.0: nunca se corta una palabra («Cuatrimest/res»): si alguna no cabe en su segmento, va como lista.
      KaeliChoiceLayout.segmented => LayoutBuilder(
        builder: (context, constraints) =>
            wordsFitSegments(context, options, constraints.maxWidth) ? _segments(context) : _list(context),
      ),
      KaeliChoiceLayout.cards => _cards(context),
      _ => _list(context),
    };
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

  /// ¿Cada palabra de cada opción cabe entera en su segmento de [width]? (Con la letra del botón y el tamaño de letra
  /// del teléfono.)
  static bool wordsFitSegments(BuildContext context, List<KaeliOption<Object?>> options, double width) {
    if (!width.isFinite || options.isEmpty) return true;
    final theme = Theme.of(context);
    final style = theme.segmentedButtonTheme.style?.textStyle?.resolve({}) ?? theme.textTheme.labelLarge;
    final scaler = MediaQuery.textScalerOf(context);
    // Cada segmento: su parte del ancho, menos el relleno a los lados y el borde.
    final room = width / options.length - 2 * 12 - 2;
    for (final option in options) {
      for (final word in option.label.split(RegExp(r'\s+'))) {
        final painter = TextPainter(
          text: TextSpan(text: word, style: style),
          textDirection: Directionality.of(context),
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        final fits = painter.width <= room;
        painter.dispose();
        if (!fits) return false;
      }
    }
    return true;
  }

  Widget _segments(BuildContext context) => SizedBox(
    width: double.infinity,
    child: SegmentedButton<T>(
      showSelectedIcon: false,
      emptySelectionAllowed: value == null,
      segments: [
        for (final o in options)
          ButtonSegment<T>(
            value: o.value,
            label: KeyedSubtree(
              key: o.key,
              child: Text(o.label, textAlign: TextAlign.center, maxLines: 2),
            ),
          ),
      ],
      selected: {?value},
      onSelectionChanged: onChanged == null
          ? null
          : (s) {
              if (s.isNotEmpty) onChanged!(s.first);
            },
    ),
  );

  Widget _cards(BuildContext context) {
    final otherSelected = other?.selected ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, o) in options.indexed) ...[
          if (i > 0) const SizedBox(height: 8),
          KaeliChoiceCard(
            key: o.key,
            icon: o.icon,
            label: o.label,
            subtitle: o.subtitle,
            detail: o.detail,
            selected: !otherSelected && o.value == value,
            onTap: onChanged == null ? null : () => onChanged!(o.value),
          ),
        ],
        if (other case final other?) ...[
          if (options.isNotEmpty) const SizedBox(height: 8),
          KaeliChoiceCard(
            icon: Icons.edit_outlined,
            label: other.label,
            selected: other.selected,
            onTap: other.onSelected,
          ),
          if (other.selected) Padding(padding: const EdgeInsets.only(top: 8), child: other.field),
        ],
      ],
    );
  }

  Widget _list(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final otherSelected = other?.selected ?? false;
    return RadioGroup<Object?>(
      groupValue: otherSelected ? _otherKey : value,
      onChanged: (v) {
        if (identical(v, _otherKey)) {
          other?.onSelected();
        } else if (v is T) {
          onChanged?.call(v);
        }
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, o) in options.indexed) ...[
              if (i > 0) Divider(height: 1, color: colors.outlineVariant),
              RadioListTile<Object?>(
                key: o.key,
                value: o.value,
                enabled: onChanged != null,
                controlAffinity: ListTileControlAffinity.trailing,
                secondary: o.icon == null ? null : Icon(o.icon, color: colors.primary),
                title: Text(o.label),
                subtitle: o.detail ?? (o.subtitle == null ? null : Text(o.subtitle!)),
              ),
            ],
            if (other case final other?) ...[
              if (options.isNotEmpty) Divider(height: 1, color: colors.outlineVariant),
              RadioListTile<Object?>(
                value: _otherKey,
                controlAffinity: ListTileControlAffinity.trailing,
                title: Text(other.label),
              ),
              if (other.selected) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: other.field),
            ],
          ],
        ),
      ),
    );
  }
}

/// Marca interna de «Otra» en el grupo de círculos.
const Object _otherKey = _OtherKey();

class _OtherKey {
  const _OtherKey();
}

/// Elegir **varias** opciones con tarjetas con ícono (p. ej. especialidades). Para filas propias al final (como
/// «＋ Agregar otra») se usa [footer] con [KaeliChoiceCard].
class KaeliMultiChoice<T> extends StatelessWidget {
  const KaeliMultiChoice({
    super.key,
    required this.values,
    required this.options,
    required this.onChanged,
    this.label,
    this.footer = const [],
  });

  final Set<T> values;
  final List<KaeliOption<T>> options;
  final ValueChanged<Set<T>>? onChanged;
  final String? label;

  /// Tarjetas o widgets extra al final, con la misma separación.
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final o in options)
        KaeliChoiceCard(
          key: o.key,
          icon: o.icon,
          label: o.label,
          subtitle: o.subtitle,
          detail: o.detail,
          selected: values.contains(o.value),
          multiple: true,
          onTap: onChanged == null
              ? null
              : () => onChanged!(values.contains(o.value) ? ({...values}..remove(o.value)) : {...values, o.value}),
        ),
      ...footer,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(label!, style: Theme.of(context).textTheme.labelLarge),
          ),
        for (final (i, w) in items.indexed) ...[if (i > 0) const SizedBox(height: 8), w],
      ],
    );
  }
}

/// Una tarjeta de elección (el estilo de «Especialidades»): ícono, texto, segunda línea opcional y el círculo (o el
/// check si se eligen varias). Elegida: fondo `primaryContainer` y borde `primary`. Crece con la letra (hasta 200 %).
class KaeliChoiceCard extends StatelessWidget {
  const KaeliChoiceCard({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.icon,
    this.subtitle,
    this.detail,
    this.trailing,
    this.multiple = false,
    this.showIndicator = true,
  });

  final IconData? icon;
  final String label;
  final String? subtitle;
  final Widget? detail;
  final bool selected;
  final VoidCallback? onTap;

  /// Acción propia a la derecha (p. ej. quitar). Con ella la tarjeta no se lee como un solo botón.
  final Widget? trailing;

  /// Varias a la vez: check en vez de círculo.
  final bool multiple;

  /// Mostrar el círculo o el check (no en filas de acción como «＋ Agregar»).
  final bool showIndicator;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final fg = selected ? colors.onPrimaryContainer : colors.onSurface;
    final radius = BorderRadius.circular(12);
    final indicator = multiple
        ? (selected ? Icons.check_circle : Icons.radio_button_unchecked)
        : (selected ? Icons.radio_button_checked : Icons.radio_button_unchecked);
    final card = Material(
      color: selected ? colors.primaryContainer : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: selected ? colors.primary : colors.outlineVariant, width: selected ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (icon != null) ...[Icon(icon, color: fg), const SizedBox(width: 16)],
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label, style: text.titleSmall?.copyWith(color: fg)),
                        if (detail != null)
                          DefaultTextStyle.merge(
                            style: text.bodySmall?.copyWith(color: fg),
                            child: detail!,
                          )
                        else if (subtitle != null)
                          Text(subtitle!, style: text.bodySmall?.copyWith(color: fg)),
                      ],
                    ),
                  ),
                ),
                if (showIndicator) ...[
                  const SizedBox(width: 8),
                  Icon(indicator, color: selected ? colors.primary : colors.outline),
                ],
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
    if (trailing != null) return card;
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: !multiple && showIndicator ? true : null,
      checked: showIndicator ? selected : null,
      label: [label, ?subtitle].join(', '),
      excludeSemantics: true,
      child: card,
    );
  }
}
