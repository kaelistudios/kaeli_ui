import 'package:flutter/material.dart';

/// Lo común de las ventanas con ruedas (mes y año, hora): título opcional, las ruedas y los botones de texto.
///
/// 0.16.0 (lo de 0.9.1, que no había pasado a 0.13): las ruedas muestran 5 filas si caben; si no (letra grande en
/// pantalla pequeña), las que quepan, nunca menos de 3, y si ni así cabe, la ventana se desplaza. Nunca se sale por
/// abajo.
class KaeliWheelRows extends StatelessWidget {
  const KaeliWheelRows({super.key, required this.itemExtent, required this.wheels, required this.actions, this.title});

  /// Alto de una fila de las ruedas.
  final double itemExtent;

  /// Las ruedas (una fila con una o varias).
  final Widget wheels;
  final List<Widget> actions;
  final Widget? title;

  /// Cuántas filas de ruedas caben en [height] con [reserved] ocupado por el título y los botones (de 3 a 5).
  static int rowsFor(double height, double reserved, double itemExtent) =>
      height.isFinite ? ((height - reserved) / itemExtent).floor().clamp(3, 5) : 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final titleStyle = theme.dialogTheme.titleTextStyle ?? theme.textTheme.titleLarge;
    final buttonStyle = theme.textTheme.labelLarge;
    // Lo que ocupan el título (hasta 2 líneas) y la fila de botones, para saber cuántas filas de ruedas caben.
    final titleHeight = title == null
        ? 0.0
        : scaler.scale((titleStyle?.fontSize ?? 22) * (titleStyle?.height ?? 1.3)) * 2 + 12;
    final buttonsHeight = 8 + scaler.scale((buttonStyle?.fontSize ?? 14) * 1.5).clamp(40.0, double.infinity) + 8;
    return LayoutBuilder(
      builder: (context, constraints) {
        final rows = rowsFor(constraints.maxHeight, titleHeight + buttonsHeight, itemExtent);
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title case final title?) Padding(padding: const EdgeInsetsDirectional.only(bottom: 12), child: title),
              SizedBox(height: itemExtent * rows, child: wheels),
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 8),
                child: OverflowBar(alignment: MainAxisAlignment.end, spacing: 8, children: actions),
              ),
            ],
          ),
        );
      },
    );
  }
}
