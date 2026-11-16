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
}
