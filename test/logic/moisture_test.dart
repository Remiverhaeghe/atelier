import 'package:atelier/logic/moisture.dart';
import 'package:flutter_test/flutter_test.dart';

MoistureReading _at(String pDay, double pPercent) => MoistureReading(
  id: pDay,
  material: MoistureMaterial.cementScreed,
  day: pDay,
  percent: pPercent,
);

void main() {
  test('seuils par support', () {
    expect(moistureState(MoistureMaterial.cementScreed, 1.8), MoistureState.ready);
    expect(moistureState(MoistureMaterial.anhydriteScreed, 0.8), MoistureState.tooWet);
    expect(moistureState(MoistureMaterial.wood, 6), MoistureState.tooDry);
    expect(moistureState(MoistureMaterial.wood, 9), MoistureState.ready);
  });

  test('chape qui sèche : jours restants au rythme des deux derniers relevés', () {
    final vVerdict = moistureVerdict([
      _at('2026-11-10', 3.0),
      _at('2026-11-14', 2.6),
      _at('2026-11-01', 4.5),
    ])!;
    // 0,1 point par jour, 0,6 point à perdre
    expect(vVerdict.state, MoistureState.tooWet);
    expect(vVerdict.last, 2.6);
    expect(vVerdict.daysLeft, 6);
  });

  test('pas d\'estimation sans tendance, verdict vide sans relevé', () {
    expect(moistureVerdict([_at('2026-11-10', 3.0)])!.daysLeft, isNull);
    expect(moistureVerdict([_at('2026-11-10', 3.0), _at('2026-11-12', 3.2)])!.daysLeft, isNull);
    expect(moistureVerdict(const []), isNull);
  });

  test('relevé gardé avec le chantier', () {
    const vReading = MoistureReading(
      id: 'r',
      material: MoistureMaterial.wood,
      day: '2026-11-17',
      percent: 9.5,
      roomId: 'salon',
    );
    final vBack = MoistureReading.fromJson(vReading.toJson());
    expect((vBack.material, vBack.percent, vBack.roomId), (MoistureMaterial.wood, 9.5, 'salon'));
    expect(
      MoistureReading.fromJson({...vReading.toJson(), 'material': 'autre'}).material,
      MoistureMaterial.wood,
    );
  });
}
