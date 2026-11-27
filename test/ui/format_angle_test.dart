import 'package:atelier/ui/dialogs.dart' show formatAngle;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('un angle entier n\'a pas de décimale', () {
    expect(formatAngle(90), '90');
    expect(formatAngle(89.96), '90');
  });

  test('un angle est arrondi au dixième, avec la virgule', () {
    expect(formatAngle(44.69999999), '44,7');
    expect(formatAngle(0.04), '0');
    expect(formatAngle(135.25), '135,3');
  });
}
