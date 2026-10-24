import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'strings.dart';

/// Valida el formulario de [form]. Si algo falla, no basta el mensaje rojo debajo del campo (puede quedar fuera de la
/// pantalla o detrás del teclado): desplaza hasta el **primer** campo con error, lo enfoca (si es de texto) y el lector
/// de pantalla lee el error. Devuelve si el formulario es válido.
///
/// ```dart
/// void _save() {
///   if (!kaeliValidateForm(_form)) return;
///   // ... guardar ...
/// }
/// ```
bool kaeliValidateForm(GlobalKey<FormState> form) {
  final state = form.currentState;
  if (state == null) return false;
  if (state.validate()) return true;
  kaeliRevealFirstError(state.context);
  return false;
}

/// Desplaza hasta el primer campo con error dentro de [context] (en el orden de la pantalla), lo enfoca y lee su error.
/// Sirve también para errores que la app marca a mano (llamar después de `setState`).
void kaeliRevealFirstError(BuildContext context) {
  Element? first;
  String? message;
  void visit(Element e) {
    if (first != null) return;
    if (e is StatefulElement && e.state is FormFieldState && (e.state as FormFieldState).hasError) {
      first = e;
      message = (e.state as FormFieldState).errorText;
      return;
    }
    e.visitChildren(visit);
  }

  (context as Element).visitChildren(visit);
  final field = first;
  if (field == null) return;
  // Un poco abajo del borde de arriba: así se ve la etiqueta y el teclado no lo tapa.
  Scrollable.ensureVisible(field, alignment: 0.15, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  FocusNode? focus;
  void findFocus(Element e) {
    if (focus != null) return;
    final w = e.widget;
    if (w is EditableText) {
      focus = w.focusNode;
      return;
    }
    e.visitChildren(findFocus);
  }

  findFocus(field);
  focus?.requestFocus();
  final text = message;
  if (text != null && text.isNotEmpty) {
    final view = View.maybeOf(context);
    if (view != null) {
      SemanticsService.sendAnnouncement(view, text, Directionality.maybeOf(context) ?? TextDirection.ltr);
    }
  }
}

/// Etiqueta de un campo obligatorio: el texto y un asterisco en el color de error del tema, desde el principio (sin
/// esperar a que falle). El lector de pantalla dice «Nombre, obligatorio».
///
/// ```dart
/// TextFormField(decoration: InputDecoration(label: KaeliRequiredLabel(l10n.name)))
/// ```
class KaeliRequiredLabel extends StatelessWidget {
  const KaeliRequiredLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final texts = KaeliUiTexts.of(context);
    return Semantics(
      label: '$text, ${texts.required}',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          text: text,
          children: [
            TextSpan(
              text: ' *',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cuerpo desplazable de un formulario: **todos** los campos existen siempre (a diferencia de `ListView`, que solo
/// construye lo que se ve). Sin esto, `Form.validate()` no revisa los campos de abajo y [kaeliValidateForm] no los
/// encuentra. Para formularios de hasta unas decenas de campos; para listas largas, `ListView`.
class KaeliFormList extends StatelessWidget {
  const KaeliFormList({super.key, required this.children, this.padding});

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: padding,
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
  );
}
