import 'package:atelier/logic/work_templates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('les étapes déjà là ne sont pas doublées', () {
    String vLabel(TemplateStep pStep) => pStep.name;
    final vMissing = missingSteps(WorkTemplate.refreshRoom, {'protect', 'wallPaint'}, vLabel);
    expect(vMissing.map((pStep) => pStep.$1), [
      TemplateStep.fillHoles,
      TemplateStep.sandWalls,
      TemplateStep.undercoat,
      TemplateStep.ceilingPaint,
      TemplateStep.woodworkPaint,
    ]);
    expect(vMissing.first.$2, 2);
  });

  test('chaque modèle a des étapes, chaque étape sert au moins une fois', () {
    final vUsed = {
      for (final vTemplate in WorkTemplate.values) ...vTemplate.steps.map((pStep) => pStep.$1),
    };
    expect(vUsed, TemplateStep.values.toSet());
  });
}
