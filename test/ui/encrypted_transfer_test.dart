import 'package:atelier/ui/encrypted_transfer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('mot de passe demandé deux fois, assez long et identique', (pTester) async {
    String? vResult;
    await pTester.pumpWidget(
      localized(
        Builder(
          builder: (pContext) => TextButton(
            onPressed: () async => vResult = await askBackupPassword(pContext, pConfirm: true),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    );
    await pTester.tap(find.text('Ouvrir'));
    await pTester.pumpAndSettle();

    await pTester.enterText(find.widgetWithText(TextField, 'Mot de passe'), 'court');
    await pTester.tap(find.text('Valider'));
    await pTester.pump();
    expect(find.text('Au moins 8 caractères'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Mot de passe'), 'assez-long-1');
    await pTester.enterText(find.widgetWithText(TextField, 'Le même, une deuxième fois'), 'autre');
    await pTester.tap(find.text('Valider'));
    await pTester.pump();
    expect(find.text('Les deux mots de passe ne sont pas les mêmes'), findsOneWidget);

    await pTester.enterText(
      find.widgetWithText(TextField, 'Le même, une deuxième fois'),
      'assez-long-1',
    );
    await pTester.tap(find.text('Valider'));
    await pTester.pumpAndSettle();
    expect(vResult, 'assez-long-1');
  });
}
