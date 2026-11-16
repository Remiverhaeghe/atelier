import 'package:atelier/logic/baseboard.dart';
import 'package:atelier/logic/guidance.dart';
import 'package:atelier/logic/parquet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parquet flottant : sous-couche, première rangée contre le mur', () {
    expect(parquetSteps(ParquetType.floating), [
      GuideStep.acclimatise,
      GuideStep.prepareFloor,
      GuideStep.undercutCasings,
      GuideStep.unrollUnderlay,
      GuideStep.firstRow,
      GuideStep.spacers,
      GuideStep.lastRow,
      GuideStep.removeSpacers,
      GuideStep.fitThresholds,
    ]);
  });

  test('chaque type a ses étapes propres', () {
    expect(parquetSteps(ParquetType.glued), contains(GuideStep.spreadGlue));
    expect(parquetSteps(ParquetType.glued), isNot(contains(GuideStep.unrollUnderlay)));
    expect(
      parquetSteps(ParquetType.nailed),
      containsAllInOrder([GuideStep.fixJoists, GuideStep.firstRow, GuideStep.nailInTongue]),
    );
    expect(parquetSteps(ParquetType.herringbone), contains(GuideStep.traceAxis));
    expect(parquetSteps(ParquetType.herringbone), isNot(contains(GuideStep.firstRow)));
  });

  test('plinthes : joints au mastic sauf sur clips', () {
    expect(baseboardSteps(BaseboardFixing.glued).last, GuideStep.sealJoints);
    expect(baseboardSteps(BaseboardFixing.clips), isNot(contains(GuideStep.sealJoints)));
  });

  test('outils sans doublon, selon le parquet et la fixation', () {
    final vNailed = toolsFor(ParquetType.nailed, BaseboardFixing.nailed);

    expect(vNailed.where((pTool) => pTool == Tool.nailer), hasLength(1));
    expect(vNailed, isNot(contains(Tool.tappingBlock)));
    expect(
      toolsFor(ParquetType.glued, BaseboardFixing.glued),
      containsAll([Tool.notchedTrowel, Tool.caulkGun]),
    );
    expect(
      toolsFor(ParquetType.herringbone, BaseboardFixing.clips),
      containsAll([Tool.chalkLine, Tool.pullBar]),
    );
    expect(toolsFor(ParquetType.floating, BaseboardFixing.clips).first, Tool.tapeMeasure);
  });
}
