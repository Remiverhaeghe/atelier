import 'package:atelier/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets("l'application s'ouvre sur la liste des chantiers, vide", (pTester) async {
    await pTester.pumpWidget(const AtelierApp());
    await pTester.pumpAndSettle();

    expect(find.text('Mes chantiers'), findsOneWidget);
    expect(find.textContaining('Aucun chantier'), findsOneWidget);
  });
}
