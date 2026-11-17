import 'package:atelier/logic/floor_capacity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const vJoist = (widthMm: 63, heightMm: 175);

  test('63 × 175 tous les 40 cm sur 4 m : la flèche limite à 2,6 kN/m²', () {
    final vCapacity = liveCapacityKnPerM2(vJoist, 400, 4000);

    expect(vCapacity, closeTo(2.595, 0.001));
    expect(vCapacity >= FloorUse.living.knPerM2, isTrue);
    expect(vCapacity >= FloorUse.bath.knPerM2, isFalse);
  });

  test('portée courte : la flexion limite', () {
    expect(liveCapacityKnPerM2(vJoist, 400, 2000), closeTo(15.381, 0.001));
  });

  test('solives faibles : même une chambre est de trop', () {
    expect(liveCapacityKnPerM2((widthMm: 45, heightMm: 145), 500, 3500), lessThan(1.5));
  });

  test('renforts : doubler ou resserrer les solives, ou une poutre au milieu', () {
    final vOptions = reinforcements(vJoist, 400, 4000);

    expect(vOptions.doubled, closeTo(5.69, 0.01));
    expect(vOptions.halfSpacing, closeTo(5.69, 0.01));
    expect(vOptions.midBeam, closeTo(15.381, 0.001));
  });

  test('mesure impossible : rien n\'est garanti', () {
    expect(liveCapacityKnPerM2(vJoist, 0, 4000), 0);
    expect(liveCapacityKnPerM2(vJoist, 400, 0), 0);
  });
}
