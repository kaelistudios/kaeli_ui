import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaeli_ui/kaeli_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Teléfono falso: anota lo que la app pidió.
class _FakeActions extends KaeliPlatformActions {
  final shared = <String>[];
  final origins = <Rect?>[];
  final opened = <String>[];
  var reviews = 0;
  var shareWorks = true;

  @override
  Future<bool> share(String text, {String? subject, Rect? origin}) async {
    shared.add(text);
    origins.add(origin);
    return shareWorks;
  }

  @override
  Future<void> openStoreListing(String appStoreId) async => opened.add(appStoreId);

  @override
  Future<bool> requestReview() async {
    reviews++;
    return true;
  }
}

const _app = KaeliAppInfo(appStoreId: '6819557562', downloadUrl: 'https://wibblo.kaeliapps.com/');

void main() {
  late _FakeActions phone;
  final real = KaeliPlatformActions.instance;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    phone = _FakeActions();
    KaeliPlatformActions.instance = phone;
  });
  tearDown(() => KaeliPlatformActions.instance = real);

  testWidgets('Compartir abre la hoja con el texto y el enlace, junto al botón', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () async =>
                    result = await kaeliShareApp(context, text: 'Prueba Wibblo: ${_app.downloadUrl}'),
                child: const Text('Compartir Wibblo'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Compartir Wibblo'));
    await tester.pump();
    expect(phone.shared, ['Prueba Wibblo: https://wibblo.kaeliapps.com/']);
    expect(
      phone.origins.single,
      tester.getRect(find.byType(TextButton)),
      reason: 'el iPad ubica la hoja junto al botón',
    );
    expect(result, isTrue);
  });

  testWidgets('Compartir devuelve false si no se pudo abrir', (tester) async {
    phone.shareWorks = false;
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await kaeliShareApp(context, text: 'x'),
            child: const Text('Compartir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Compartir'));
    await tester.pump();
    expect(result, isFalse);
  });

  test('Calificar abre la ficha de la tienda, nunca la ventana nativa', () async {
    await kaeliOpenStoreToRate(_app);
    expect(phone.opened, ['6819557562']);
    expect(phone.reviews, 0);
  });

  test('la ventana nativa se pide una sola vez, al llegar al logro N', () async {
    expect(await KaeliReviewPrompt.milestone(after: 3), isFalse);
    expect(await KaeliReviewPrompt.milestone(after: 3), isFalse);
    expect(phone.reviews, 0);
    expect(await KaeliReviewPrompt.milestone(after: 3), isTrue);
    expect(phone.reviews, 1);
    for (var i = 0; i < 5; i++) {
      expect(await KaeliReviewPrompt.milestone(after: 3), isFalse);
    }
    expect(phone.reviews, 1, reason: 'nunca se insiste');
    expect(await KaeliReviewPrompt.asked(), isTrue);
  });

  test('after: 1 (por defecto) la pide en el primer logro', () async {
    expect(await KaeliReviewPrompt.milestone(), isTrue);
    expect(await KaeliReviewPrompt.milestone(), isFalse);
    expect(phone.reviews, 1);
  });

  test('con las claves que ya usa una app sigue su cuenta y no la vuelve a pedir', () async {
    // Wibblo ya contó 2 fichas exportadas: la 3.ª la pide.
    SharedPreferences.setMockInitialValues({'review.exportCount': 2});
    expect(
      await KaeliReviewPrompt.milestone(after: 3, countKey: 'review.exportCount', askedKey: 'review.asked'),
      isTrue,
    );
    expect(phone.reviews, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('review.asked'), isTrue);

    // AlojaConmigo ya la pidió: no sale otra vez.
    SharedPreferences.setMockInitialValues({'review.asked': true});
    expect(await KaeliReviewPrompt.milestone(key: 'review'), isFalse);
    expect(phone.reviews, 1);
  });
}
