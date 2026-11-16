import 'package:atelier/logic/fixings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chaque support et chaque charge ont un conseil', () {
    for (final vSupport in WallSupport.values) {
      for (final vLoad in FixingLoad.values) {
        final vAdvice = adviseFixing(vSupport, vLoad);
        expect(vAdvice.screwLengthMm, greaterThan(0));
        expect(vAdvice.drillMm, greaterThan(0));
      }
    }
    expect(adviseFixing(WallSupport.drywall, FixingLoad.heavy).plug, PlugKind.drywallToggle);
    expect(adviseFixing(WallSupport.hollowBrick, FixingLoad.heavy).plug, PlugKind.chemical);
    expect(adviseFixing(WallSupport.wood, FixingLoad.light).plug, PlugKind.none);
  });

  test('points de fixation et charge par point, marge de deux comprise', () {
    expect(fixingPoints(3, FixingLoad.medium), 2);
    expect(fixingPoints(20, FixingLoad.medium), 3);
    expect(loadFor(20, 3), FixingLoad.medium);
    expect(loadFor(2, 2), FixingLoad.light);
    expect(loadFor(100, 2), FixingLoad.heavy);
    expect(loadFor(10, 0), FixingLoad.heavy);
  });
}
