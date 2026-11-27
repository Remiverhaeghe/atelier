import 'package:atelier/ui/house_3d.dart';
import 'package:atelier/ui/motion.dart';
import 'package:atelier/ui/room_3d_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('animations réduites : durée nulle, sinon la durée demandée', (pTester) async {
    late Duration vNormal;
    late Duration vReduced;
    await pTester.pumpWidget(
      Column(
        children: [
          Builder(
            builder: (pContext) {
              vNormal = motionDuration(pContext, 300);

              return const SizedBox();
            },
          ),
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (pContext) {
                vReduced = motionDuration(pContext, 300);

                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );

    expect(vNormal, const Duration(milliseconds: 300));
    expect(vReduced, Duration.zero);
  });

  testWidgets('la 3D est sobre au départ, Détails ajoute meubles et structures', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(Room3dCard(room: rectangleRoom())));
    await pTester.pumpAndSettle();

    expect(pTester.widget<House3d>(find.byType(House3d)).simple, isTrue);

    await pTester.tap(find.text('Détails'));
    await pTester.pumpAndSettle();
    expect(pTester.widget<House3d>(find.byType(House3d)).simple, isFalse);

    await pTester.tap(find.text('Simple'));
    await pTester.pumpAndSettle();
    expect(pTester.widget<House3d>(find.byType(House3d)).simple, isTrue);
  });

  testWidgets('la maison se pose d\'un quart de tour, ou tout de suite si réduit', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(House3d(rooms: [rectangleRoom()])));
    await pTester.pump(const Duration(milliseconds: 100));
    expect(pTester.hasRunningAnimations, isTrue);
    await pTester.pumpAndSettle();
    expect(pTester.hasRunningAnimations, isFalse);

    await pTester.pumpWidget(const SizedBox());
    await pTester.pumpWidget(
      localized(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: House3d(rooms: [rectangleRoom()]),
        ),
      ),
    );
    await pTester.pump();
    expect(pTester.hasRunningAnimations, isFalse);
  });
}
