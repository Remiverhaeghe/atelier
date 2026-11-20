import 'package:atelier/logic/floor_capacity.dart';
import 'package:atelier/logic/load_explained.dart';
import 'package:atelier/logic/shelf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tablette d\'aggloméré de 70 cm : 21 kg, un carton de livres', () {
    final vShelf = shelfMember(700, 300, 18, ShelfMaterial.particleBoard);
    expect(vShelf.maxKg, closeTo(20.97, 0.05));
    expect(vShelf.limitMm, 3.5);
    expect(objectsHeld(vShelf, EverydayLoad.booksBox), 1);
    expect(objectsHeld(vShelf, EverydayLoad.waterPack), 2);

    final vOne = loadedDeflection(vShelf, EverydayLoad.booksBox, 1);
    expect(vOne.deflectionMm, closeTo(2.50, 0.01));
    expect(vOne.tooMuch, isFalse);
    final vTwo = loadedDeflection(vShelf, EverydayLoad.booksBox, 2);
    expect(vTwo.deflectionMm, closeTo(5.01, 0.01));
    expect(vTwo.tooMuch, isTrue);
  });

  test('le contreplaqué et le bois massif portent plus que l\'aggloméré', () {
    final vParticle = shelfMember(800, 300, 18, ShelfMaterial.particleBoard).maxKg;
    final vMdf = shelfMember(800, 300, 18, ShelfMaterial.mdf).maxKg;
    final vPlywood = shelfMember(800, 300, 18, ShelfMaterial.plywood).maxKg;
    final vSolid = shelfMember(800, 300, 18, ShelfMaterial.solidWood).maxKg;
    expect(vParticle < vMdf && vMdf < vPlywood && vPlywood < vSolid, isTrue);
    // Deux fois plus épais : huit fois plus raide
    expect(shelfMember(800, 300, 36, ShelfMaterial.mdf).maxKg, closeTo(8 * vMdf, 0.01));
  });

  test('poutre de 63 × 175 sur 3 m : 860 kg, la flexion limite avant la flèche', () {
    final vBeam = beamMember((widthMm: 63, heightMm: 175), 3000);
    expect(vBeam.maxKg, closeTo(860.7, 1));
    expect(vBeam.limitMm, 10);
    expect(objectsHeld(vBeam, EverydayLoad.adult), 10);
    final vLoaded = loadedDeflection(vBeam, EverydayLoad.adult, 10);
    expect(vLoaded.tooMuch, isFalse);
    expect(vLoaded.deflectionMm, lessThan(10));
    // Courte et basse, c'est la flèche qui limite : la charge suit la raideur
    final vLong = beamMember((widthMm: 45, heightMm: 145), 4500);
    expect(vLong.maxKg, lessThan(vBeam.maxKg));
  });

  test('mezzanine : la capacité du plancher sur toute sa surface', () {
    const vJoist = (widthMm: 63, heightMm: 175);
    final vFloor = mezzanineMember(vJoist, 400, 2000, 3000);
    expect(
      vFloor.maxKg,
      closeTo(liveCapacityKnPerM2(vJoist, 400, 2000) * 6 * 1000 / gravity, 0.01),
    );
    expect(vFloor.spanMm, 2000);
    expect(objectsHeld(vFloor, EverydayLoad.adult), greaterThan(10));
    expect(mezzanineMember(vJoist, 0, 2000, 3000).inertiaMm4, greaterThan(0));
  });

  test('flèche nulle sans portée, exagération du dessin bornée', () {
    expect(deflectionMm(10, 0, 1000, 1000), 0);
    expect(shelfMember(0, 300, 18, ShelfMaterial.mdf).maxKg, 0);
    expect(drawingScale(2.5, 700), closeTo(28, 0.01));
    expect(drawingScale(0, 700), 1);
    expect(drawingScale(0.01, 700), 200);
    expect(drawingScale(500, 700), 1);
    expect(EverydayLoad.cementBag.kg + EverydayLoad.washingMachine.kg, 105);
  });
}
