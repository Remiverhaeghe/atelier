import 'package:atelier/l10n/gen/app_localizations_fr.dart';
import 'package:atelier/logic/shelf.dart';
import 'package:atelier/logic/shelf_joinery.dart';
import 'package:atelier/ui/drill_template_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('le gabarit se construit en PDF, tablettes fixes ou réglables', () async {
    const vDesign = ShelfDesign(material: ShelfMaterial.plywood);

    for (final vAdjustable in [false, true]) {
      final vBytes = await buildDrillTemplatePdf(
        AppLocalizationsFr(),
        vDesign,
        adviseJoint(vDesign, pAdjustable: vAdjustable),
      );
      expect(String.fromCharCodes(vBytes.take(5)), '%PDF-');
    }
  });
}
