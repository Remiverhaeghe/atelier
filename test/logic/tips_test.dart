import 'package:atelier/logic/tips.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chaque sujet a ses fiches, toutes classées', () {
    expect(tipsAbout(TipTopic.baseboard), [
      Tip.baseboardSealant,
      Tip.baseboardGlue,
      Tip.baseboardNails,
      Tip.crookedWalls,
    ]);
    expect(TipTopic.values.expand(tipsAbout).toSet(), Tip.values.toSet());
    expect(Tip.airConMaintenance.hasWarning, isTrue);
  });

  test('les étapes sont les lignes non vides', () {
    expect(tipSteps('Dépoussiérer\n\n  Masquer  \n'), ['Dépoussiérer', 'Masquer']);
  });
}
