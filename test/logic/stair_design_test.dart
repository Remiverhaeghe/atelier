import 'package:atelier/logic/stair_design.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('escalier de 2,80 m : marches, limons et trémie', () {
    final vDesign = designStair(2800);

    expect(vDesign.plan.risers, 16);
    expect(vDesign.treads, 15);
    expect(vDesign.treadDepthMm, 310);
    expect(vDesign.stringerMm, 5248);
    // 4 marches passent sous 1,90 m de plancher, les 11 suivantes sous la trémie
    expect(vDesign.tremieMm, 11 * 280);
    expect(vDesign.headroomOk, isTrue);
  });

  test('trémie trop courte, et petite hauteur sans trémie à ouvrir en grand', () {
    expect(designStair(2800, pTremieMm: 2500).headroomOk, isFalse);
    expect(designStair(2800, pTremieMm: 3100).headroomOk, isTrue);
    expect(designStair(1000).tremieMm, designStair(1000).treads * designStair(1000).plan.goingMm);
  });
}
