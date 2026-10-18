import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Para el `State` de un formulario: compara lo que hay ahora ([dirtySnapshot]) con lo que había al abrir.
///
/// ```dart
/// class _EditState extends State<Edit> with KaeliDirtyTracker<Edit> {
///   final _name = TextEditingController(text: 'Casa');
///   var _guests = 2;
///
///   @override
///   Object? dirtySnapshot() => (_name.text, _guests);
///
///   @override
///   Widget build(BuildContext context) => KaeliUnsavedChangesGuard(
///     isDirty: () => hasUnsavedChanges,
///     listenable: _name,
///     child: ...,
///   );
/// }
/// ```
///
/// La primera foto se toma la primera vez que se pregunta [hasUnsavedChanges] (al construir la pantalla). Si los
/// valores se cargan después (p. ej. desde el servidor), o después de guardar, llama a [markSaved].
mixin KaeliDirtyTracker<T extends StatefulWidget> on State<T> {
  Object? _baseline;
  var _hasBaseline = false;

  /// Valores actuales del formulario. Listas, conjuntos, mapas y registros se comparan por contenido.
  Object? dirtySnapshot();

  /// ¿Algo cambió desde la última foto?
  bool get hasUnsavedChanges {
    if (!_hasBaseline) markSaved();
    return !kaeliSnapshotEquals(_baseline, dirtySnapshot());
  }

  /// Lo que hay ahora pasa a ser «sin cambios».
  void markSaved() {
    _baseline = dirtySnapshot();
    _hasBaseline = true;
  }
}

/// Compara dos fotos de un formulario por contenido (listas, conjuntos y mapas, también anidados). Los registros
/// (`(a, b)`) ya se comparan por contenido en Dart.
bool kaeliSnapshotEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!kaeliSnapshotEquals(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is Set && b is Set) return setEquals(a, b);
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (!b.containsKey(k) || !kaeliSnapshotEquals(a[k], b[k])) return false;
    }
    return true;
  }
  return a == b;
}
