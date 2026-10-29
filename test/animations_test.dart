import 'package:clinica_plus/providers/app_startup_notifier.dart';
import 'package:clinica_plus/widgets/animations/fade_slide_in.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

double _opacityOf(WidgetTester tester) => tester
    .widget<FadeTransition>(find.byType(FadeTransition).first)
    .opacity
    .value;

Widget _wrap(Widget child, {bool disableAnimations = false}) => MediaQuery(
  data: MediaQueryData(disableAnimations: disableAnimations),
  child: Directionality(textDirection: TextDirection.ltr, child: child),
);

void main() {
  group('FadeSlideIn', () {
    testWidgets('empieza invisible y termina completamente visible', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(_wrap(const FadeSlideIn(child: Text('Hola'))));
      // Assert inicial
      expect(_opacityOf(tester), 0);
      // Act
      await tester.pumpAndSettle();
      // Assert final
      expect(_opacityOf(tester), 1);
    });

    testWidgets('respeta el retardo antes de animar', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const FadeSlideIn(
            delay: Duration(milliseconds: 300),
            child: Text('Hola'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(_opacityOf(tester), 0);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(_opacityOf(tester), 1);
    });

    testWidgets('con "reducir movimiento" se muestra de inmediato', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const FadeSlideIn(delay: Duration(seconds: 5), child: Text('Hola')),
          disableAnimations: true,
        ),
      );
      expect(_opacityOf(tester), 1);
    });

    test('staggerDelay limita listas largas', () {
      expect(FadeSlideIn.staggerDelay(2), const Duration(milliseconds: 120));
      expect(FadeSlideIn.staggerDelay(50), const Duration(milliseconds: 480));
    });
  });

  group('AppStartupNotifier', () {
    test('notifica una sola vez al completar la intro', () {
      final notifier = AppStartupNotifier();
      var notifications = 0;
      notifier.addListener(() => notifications++);

      notifier
        ..completeIntro()
        ..completeIntro();

      expect(notifier.introCompleted, isTrue);
      expect(notifications, 1);
    });
  });
}
