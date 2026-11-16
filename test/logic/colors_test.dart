import 'package:atelier/logic/colors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('aller-retour entre couleur et teinte sans perte', () {
    for (final vColor in [
      ...wallPalette,
      0xFF0000,
      0x00FF00,
      0x0000FF,
      0x808080,
      0x000000,
      0xFFFFFF,
    ]) {
      expect(fromHsl(toHsl(vColor)), vColor);
    }
    expect(toHsl(0xFF0000).hue, 0);
    expect(toHsl(0x00FF00).hue, 120);
    expect(toHsl(0x0000FF).hue, 240);
  });

  test('accords autour d\'une teinte : voisines, opposée, claire, foncée', () {
    final vBase = toHsl(0xA7B8A0);
    final vChords = harmonies(0xA7B8A0);

    expect(toHsl(vChords[Harmony.analogous]!.first).hue, closeTo(vBase.hue - 30, 2));
    expect(toHsl(vChords[Harmony.complementary]!.single).hue, closeTo((vBase.hue + 180) % 360, 2));
    expect(toHsl(vChords[Harmony.soft]!.single).lightness, closeTo(0.93, 0.01));
    expect(toHsl(vChords[Harmony.deep]!.single).lightness, lessThan(vBase.lightness));
    expect(
      harmonies(0x808080)[Harmony.soft]!.single,
      fromHsl((hue: 0, saturation: 0, lightness: 0.93)),
    );
  });
}
