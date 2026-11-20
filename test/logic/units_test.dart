import 'package:atelier/logic/units.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseCentimetres', () {
    test('accepte la virgule, le point et les espaces', () {
      expect(parseCentimetres('245,5'), 2455);
      expect(parseCentimetres(' 245.5 '), 2455);
      expect(parseCentimetres('1 200'), 12000);
      expect(parseCentimetres('0'), 0);
    });

    test('arrondit au millimètre', () {
      expect(parseCentimetres('10,04'), 100);
      expect(parseCentimetres('10,06'), 101);
    });

    test('refuse le texte, le vide et les valeurs négatives', () {
      expect(parseCentimetres(''), isNull);
      expect(parseCentimetres('abc'), isNull);
      expect(parseCentimetres('-3'), isNull);
    });
  });

  group('parseDegrees', () {
    test('garde un angle entre 1 et 359', () {
      expect(parseDegrees('90'), 90);
      expect(parseDegrees('88,5'), 88.5);
      expect(parseDegrees('270'), 270);
    });

    test('refuse 0, 360 et le texte', () {
      expect(parseDegrees('0'), isNull);
      expect(parseDegrees('360'), isNull);
      expect(parseDegrees('droit'), isNull);
    });
  });

  test('formatCentimetres ne garde la décimale que si elle compte', () {
    expect(formatCentimetres(2455), '245,5');
    expect(formatCentimetres(2450), '245');
    expect(formatCentimetres(7), '0,7');
  });

  test('formatSquareMetres affiche deux décimales avec une virgule', () {
    expect(formatSquareMetres(12), '12,00');
    expect(formatSquareMetres(12.345), '12,35');
  });

  test('parseDecimal et parseWhole refusent le négatif et le texte', () {
    expect(parseDecimal('2,13'), 2.13);
    expect(parseDecimal('-1'), isNull);
    expect(parseDecimal('x'), isNull);
    expect(parseWhole('12'), 12);
    expect(parseWhole('-2'), isNull);
    expect(parseWhole('1,5'), isNull);
  });

  test('formatDecimal retire les zéros inutiles', () {
    expect(formatDecimal(2.13), '2,13');
    expect(formatDecimal(15), '15');
    expect(formatDecimal(2.5), '2,5');
  });

  test('longueur tapée avec son unité, quelle que soit celle du champ', () {
    expect(parseCentimetres('2,45 m'), 2450);
    expect(parseCentimetres('2450mm'), 2450);
    expect(parseCentimetres('245 cm'), 2450);
    expect(parseCentimetres('245'), 2450);
    expect(typedLengthMm('245'), isNull);
    expect(parseInUnit('2,45', FieldUnit.m), 2450);
    expect(parseInUnit('2450', FieldUnit.mm), 2450);
    expect(parseInUnit('30 cm', FieldUnit.m), 300);
    expect(parseInUnit('', FieldUnit.cm), isNull);
  });

  test('unité lue dans le libellé, saisie ramenée à cette unité', () {
    expect(unitOfLabel('Hauteur (cm)'), FieldUnit.cm);
    expect(unitOfLabel('Surface (m²)'), FieldUnit.m2);
    expect(unitOfLabel('Épaisseur (mm), si connue'), FieldUnit.mm);
    expect(unitOfLabel('Nombre de tablettes'), isNull);
    expect(toFieldUnit('2,45 m', FieldUnit.cm), '245');
    expect(toFieldUnit('2,45 m', FieldUnit.mm), '2450');
    expect(toFieldUnit('245 cm', FieldUnit.m), '2,45');
    expect(toFieldUnit('12', FieldUnit.cm), '12');
    expect(toFieldUnit('2 m', FieldUnit.m2), '2 m');
    expect(lengthInUnit(2455, FieldUnit.m), '2,455');
  });
}
