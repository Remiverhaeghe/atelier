import 'package:atelier/logic/worksite.dart';
import 'package:atelier/support/platform_limits.dart';
import 'package:atelier/ui/laser_screen.dart';
import 'package:atelier/ui/reminders_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  setUp(() => aOnWeb = true);
  tearDown(() => aOnWeb = false);

  testWidgets('version web : le télémètre explique pourquoi il ne se relie pas', (pTester) async {
    int? vMeasured = -1;
    await pTester.pumpWidget(
      localized(
        Builder(
          builder: (pContext) => TextButton(
            onPressed: () async => vMeasured = await measureWithLaser(pContext),
            child: const Text('mesurer'),
          ),
        ),
      ),
    );
    await pTester.tap(find.text('mesurer'));
    await pTester.pumpAndSettle();
    expect(find.textContaining('Safari ne donne pas accès au Bluetooth'), findsOneWidget);
    expect(find.byType(LaserScreen), findsNothing);

    await pTester.tap(find.text('Fermer'));
    await pTester.pumpAndSettle();
    expect(vMeasured, isNull);
  });

  testWidgets('version web : les attentes disent qu\'il n\'y aura pas de notification', (
    pTester,
  ) async {
    await pTester.pumpWidget(
      localized(
        RemindersCard(
          worksite: const Worksite(id: 'c', name: 'Chantier fictif'),
          now: DateTime(2026, 11, 20),
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.textContaining('pas de notification'), findsOneWidget);

    aOnWeb = false;
    await pTester.pumpWidget(
      localized(
        RemindersCard(
          key: const ValueKey('android'),
          worksite: const Worksite(id: 'c', name: 'Chantier fictif'),
          now: DateTime(2026, 11, 20),
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.textContaining('pas de notification'), findsNothing);
  });
}
