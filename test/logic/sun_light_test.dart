import 'dart:math' as math;

import 'package:atelier/logic/sun_light.dart';
import 'package:flutter_test/flutter_test.dart';

/// Plus haut du soleil dans la journée, cherché de minute en minute.
SunPosition highest(int pDay) {
  var rBest = sunPosition(pDayOfYear: pDay, pHour: 10);
  for (var vMinute = 600; vMinute <= 1020; vMinute++) {
    final vSun = sunPosition(pDayOfYear: pDay, pHour: vMinute / 60);
    if (vSun.elevationDeg > rBest.elevationDeg) {
      rBest = vSun;
    }
  }

  return rBest;
}

void main() {
  test('à Lille, le soleil monte à 63° en juin et 16° en décembre, plein sud', () {
    final vSummer = highest(Season.summer.dayOfYear);
    expect(vSummer.elevationDeg, closeTo(62.8, 0.6));
    expect(vSummer.azimuthDeg, closeTo(180, 2));
    expect(highest(Season.winter.dayOfYear).elevationDeg, closeTo(16.0, 0.6));
    expect(highest(Season.spring.dayOfYear).elevationDeg, closeTo(39.4, 1.0));
  });

  test('le matin à l\'est, le soir à l\'ouest, la nuit sous l\'horizon', () {
    final vMorning = sunPosition(pDayOfYear: Season.summer.dayOfYear, pHour: 8);
    expect(vMorning.azimuthDeg, inInclusiveRange(60, 120));
    final vEvening = sunPosition(pDayOfYear: Season.summer.dayOfYear, pHour: 20);
    expect(vEvening.azimuthDeg, inInclusiveRange(250, 310));
    expect(sunPosition(pDayOfYear: Season.winter.dayOfYear, pHour: 23).elevationDeg, lessThan(0));
    // Plus au sud, le soleil d'hiver monte plus haut
    final vSouth = sunPosition(pDayOfYear: Season.winter.dayOfYear, pHour: 13, pLatitudeDeg: 43.3);
    expect(vSouth.elevationDeg, greaterThan(20));
  });

  test('heure d\'été de fin mars à fin octobre', () {
    expect(franceUtcOffset(Season.summer.dayOfYear), 2);
    expect(franceUtcOffset(Season.winter.dayOfYear), 1);
    expect(franceUtcOffset(Season.spring.dayOfYear), 1);
    expect(franceUtcOffset(Season.autumn.dayOfYear), 2);
  });

  test('soleil plein sud à 45° : tache au sol de 1,39 × 0,78 m, rien sur le mur', () {
    final vPatch = sunPatch(defaultAtticWindow, (elevationDeg: 45, azimuthDeg: 180));
    expect(vPatch.lit, isTrue);
    expect(vPatch.floor.length, 4);
    final vXs = [for (final vPoint in vPatch.floor) vPoint.a];
    expect(vXs.reduce(math.min), closeTo(1648.5, 0.5));
    expect(vXs.reduce(math.max), closeTo(3034.5, 0.5));
    expect(patchAreaM2(vPatch.floor), closeTo(1.081, 0.002));
    expect(vPatch.wall, isEmpty);
    expect(insidePolygon(vPatch.floor, (a: 2000, b: 0)), isTrue);
    expect(insidePolygon(vPatch.floor, (a: 1000, b: 0)), isFalse);
    expect(insidePolygon(vPatch.floor, (a: 2000, b: 500)), isFalse);
  });

  test('soleil bas : la tache monte sur le mur d\'en face', () {
    final vPatch = sunPatch(defaultAtticWindow, (elevationDeg: 20, azimuthDeg: 180));
    expect(vPatch.floor, isNotEmpty);
    expect(vPatch.floor.every((pPoint) => pPoint.a <= 4000.001), isTrue);
    expect(vPatch.wall, isNotEmpty);
    expect(vPatch.wall.every((pPoint) => pPoint.b >= -0.001), isTrue);
  });

  test('soleil derrière le toit ou couché : pas de tache', () {
    expect(sunPatch(defaultAtticWindow, (elevationDeg: 30, azimuthDeg: 0)).lit, isFalse);
    final vNight = sunPatch(defaultAtticWindow, (elevationDeg: -5, azimuthDeg: 180));
    expect(vNight.lit, isFalse);
    expect(vNight.floor, isEmpty);
  });

  test('heures de soleil sur un bureau, aucune contre le mur de genou', () {
    final vDay = Season.summer.dayOfYear;
    final vPatch = sunPatch(defaultAtticWindow, sunPosition(pDayOfYear: vDay, pHour: 13.5));
    final vCenter = (
      a: vPatch.floor.map((pPoint) => pPoint.a).reduce((pA, pB) => pA + pB) / vPatch.floor.length,
      b: vPatch.floor.map((pPoint) => pPoint.b).reduce((pA, pB) => pA + pB) / vPatch.floor.length,
    );
    expect(sunnyHours(defaultAtticWindow, vCenter, pDayOfYear: vDay), contains(13.5));
    expect(sunnyHours(defaultAtticWindow, (a: 100, b: 0), pDayOfYear: vDay), isEmpty);
    expect(windowCorners(defaultAtticWindow).length, 4);
  });

  test('tache coupée en bandes, heures regroupées en plages', () {
    const vSquare = <P2>[(a: 0, b: 0), (a: 10, b: 0), (a: 10, b: 10), (a: 0, b: 10)];
    expect(polygonSpanAt(vSquare, 5), (from: 0.0, to: 10.0));
    expect(polygonSpanAt(vSquare, 20), isNull);
    const vTriangle = <P2>[(a: 0, b: 0), (a: 10, b: 0), (a: 0, b: 10)];
    expect(polygonSpanAt(vTriangle, 5), (from: 0.0, to: 5.0));
    expect(hourRanges([11, 11.5, 12, 15]), [(from: 11.0, to: 12.5), (from: 15.0, to: 15.5)]);
    expect(hourRanges(const []), isEmpty);
  });
}
