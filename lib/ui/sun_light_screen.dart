import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/sun_light.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'sketch3d.dart';
import 'theme.dart';

/// Demi-largeur de la pièce dessinée, de part et d'autre de la fenêtre.
const _roomHalfMm = 1500.0;

/// Bandes qui dessinent la tache de soleil.
const _slices = 16;

/// Hauteur dessinée du mur d'en face, au plus.
const _wallMaxMm = 2600.0;

String _seasonName(AppLocalizations pText, Season pSeason) => switch (pSeason) {
  Season.winter => pText.sunWinter,
  Season.spring => pText.sunSpring,
  Season.summer => pText.sunSummer,
  Season.autumn => pText.sunAutumn,
};

/// Heure lisible : 13.5 donne « 13 h 30 ».
String formatHour(double pHour) {
  final vHours = pHour.floor();
  final vMinutes = ((pHour - vHours) * 60).round();
  final rText = vMinutes == 0 ? '$vHours h' : '$vHours h ${vMinutes.toString().padLeft(2, '0')}';

  return rText;
}

/// Tache de soleil d'une fenêtre de toit selon l'heure et la saison, pour placer un lit ou
/// un bureau.
class SunLightScreen extends StatefulWidget {
  const SunLightScreen({super.key});

  @override
  State<SunLightScreen> createState() => _SunLightScreenState();
}

class _SunLightScreenState extends State<SunLightScreen> {
  var _season = Season.summer;
  var _hour = 14.0;
  var _latitude = defaultLatitudeDeg;
  var _room = defaultAtticWindow;
  var _spotMm = 1600;

  void _update({
    int? pKnee,
    double? pSlope,
    int? pDepth,
    int? pWidth,
    int? pHeight,
    int? pFrom,
    double? pFacing,
  }) => setState(
    () => _room = (
      kneeMm: pKnee ?? _room.kneeMm,
      slopeDeg: pSlope ?? _room.slopeDeg,
      depthMm: pDepth ?? _room.depthMm,
      windowWidthMm: pWidth ?? _room.windowWidthMm,
      windowHeightMm: pHeight ?? _room.windowHeightMm,
      windowFromKneeMm: pFrom ?? _room.windowFromKneeMm,
      facingDeg: pFacing ?? _room.facingDeg,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vSun = sunPosition(pDayOfYear: _season.dayOfYear, pHour: _hour, pLatitudeDeg: _latitude);
    final vPatch = sunPatch(_room, vSun);
    final vSpot = (a: _spotMm.toDouble(), b: 0.0);
    final vRanges = hourRanges(
      sunnyHours(_room, vSpot, pDayOfYear: _season.dayOfYear, pLatitudeDeg: _latitude),
    );
    final vFacings = [
      (0.0, vText.sunNorth),
      (90.0, vText.sunEast),
      (180.0, vText.sunSouth),
      (270.0, vText.sunWest),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(vText.sunTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          AspectRatio(
            aspectRatio: 1.2,
            child: SunSketch(room: _room, patch: vPatch, spotMm: _spotMm),
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final vSeason in Season.values)
                ChoiceChip(
                  label: Text(_seasonName(vText, vSeason)),
                  selected: _season == vSeason,
                  onSelected: (_) => setState(() => _season = vSeason),
                ),
            ],
          ),
          Text(vText.sunHour(formatHour(_hour)), style: vTheme.textTheme.titleSmall),
          Slider(
            value: _hour,
            min: 5,
            max: 22,
            divisions: 34,
            label: formatHour(_hour),
            onChanged: (pValue) => setState(() => _hour = pValue),
          ),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconLine(
                    Icons.wb_sunny_outlined,
                    vText.sunPosition(vSun.elevationDeg.round(), vSun.azimuthDeg.round()),
                  ),
                  if (!vPatch.lit)
                    IconLine(Icons.nights_stay_outlined, vText.sunNoLight)
                  else ...[
                    IconLine(
                      Icons.crop_square,
                      vText.sunFloor(formatSquareMetres(patchAreaM2(vPatch.floor))),
                    ),
                    if (vPatch.wall.length >= 3)
                      IconLine(
                        Icons.vertical_align_top,
                        vText.sunWall(formatSquareMetres(patchAreaM2(vPatch.wall))),
                      ),
                  ],
                  IconLine(
                    Icons.bed_outlined,
                    vRanges.isEmpty
                        ? vText.sunSpotNone(formatCentimetres(_spotMm))
                        : vText.sunSpotHours(
                            formatCentimetres(_spotMm),
                            [
                              for (final vRange in vRanges)
                                vText.sunRange(formatHour(vRange.from), formatHour(vRange.to)),
                            ].join(', '),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(vText.sunFacing, style: vTheme.textTheme.titleSmall),
          Wrap(
            spacing: 8,
            children: [
              for (final (vDeg, vLabel) in vFacings)
                ChoiceChip(
                  label: Text(vLabel),
                  selected: _room.facingDeg == vDeg,
                  onSelected: (_) => _update(pFacing: vDeg),
                ),
            ],
          ),
          NumberField<int>(
            label: vText.sunSpot,
            initial: formatCentimetres(_spotMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _spotMm = pValue),
          ),
          NumberField<double>(
            label: vText.sunLatitude,
            initial: formatDecimal(_latitude),
            parse: parseDecimal,
            onValue: (pValue) => setState(() => _latitude = pValue.clamp(0, 80).toDouble()),
          ),
          NumberField<int>(
            label: vText.sunKnee,
            initial: formatCentimetres(_room.kneeMm),
            parse: parseCentimetres,
            onValue: (pValue) => _update(pKnee: pValue),
          ),
          NumberField<int>(
            label: vText.sunSlope,
            initial: formatDecimal(_room.slopeDeg),
            parse: parseWhole,
            onValue: (pValue) => _update(pSlope: pValue.clamp(10, 75).toDouble()),
          ),
          NumberField<int>(
            label: vText.sunDepth,
            initial: formatCentimetres(_room.depthMm),
            parse: parseCentimetres,
            onValue: (pValue) => _update(pDepth: math.max(500, pValue)),
          ),
          NumberField<int>(
            label: vText.sunWindowWidth,
            initial: formatCentimetres(_room.windowWidthMm),
            parse: parseCentimetres,
            onValue: (pValue) => _update(pWidth: pValue),
          ),
          NumberField<int>(
            label: vText.sunWindowHeight,
            initial: formatCentimetres(_room.windowHeightMm),
            parse: parseCentimetres,
            onValue: (pValue) => _update(pHeight: pValue),
          ),
          NumberField<int>(
            label: vText.sunWindowFrom,
            initial: formatCentimetres(_room.windowFromKneeMm),
            parse: parseCentimetres,
            onValue: (pValue) => _update(pFrom: pValue),
          ),
          const SizedBox(height: 8),
          Text(vText.sunHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// La pièce sous rampant en relief : mur de genou, rampant et fenêtre, mur d'en face, et la
/// tache de soleil en bandes fines au sol et au mur.
class SunSketch extends StatelessWidget {
  const SunSketch({super.key, required this.room, required this.patch, required this.spotMm});

  final AtticWindow room;
  final SunPatch patch;
  final int spotMm;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vSlope = room.slopeDeg * math.pi / 180;
    final vCos = math.cos(vSlope);
    final vSin = math.sin(vSlope);
    final vDepth = room.depthMm.toDouble();
    final vKnee = room.kneeMm.toDouble();
    final vWallTop = math.min(_wallMaxMm, vKnee + vDepth * math.tan(vSlope));
    // Le rampant s'arrête où il rejoint le haut du mur d'en face
    final vRoofEnd = vSin <= 0 ? 0.0 : (vWallTop - vKnee) / vSin;
    final vLow = room.windowFromKneeMm.toDouble();
    final vHigh = math.min(vRoofEnd, vLow + room.windowHeightMm);
    final vHalf = room.windowWidthMm / 2;
    List<(double, double)> vRoof(double pFrom, double pTo) => [
      (pFrom * vCos, vKnee + pFrom * vSin),
      (pTo * vCos, vKnee + pTo * vSin),
      (pTo * vCos - 40 * vSin, vKnee + pTo * vSin + 40 * vCos),
      (pFrom * vCos - 40 * vSin, vKnee + pFrom * vSin + 40 * vCos),
    ];
    final vParts = <Prism>[
      Prism.box(-80, 0, -_roomHalfMm, _roomHalfMm, 0, vKnee, role: PartRole.board),
      Prism.box(vDepth, vDepth + 80, -_roomHalfMm, _roomHalfMm, 0, vWallTop, role: PartRole.board),
      // Lit ou bureau en transparence, pour ne pas cacher la tache ; pas de plancher dessiné :
      // sa grande face passerait devant la tache au tri des faces
      Prism.box(spotMm - 300.0, spotMm + 300.0, -450, 450, 0, 450, role: PartRole.ghost),
    ];
    for (var vIndex = 0; vIndex < _slices; vIndex++) {
      final vY0 = -_roomHalfMm + 2 * _roomHalfMm * vIndex / _slices;
      final vY1 = -_roomHalfMm + 2 * _roomHalfMm * (vIndex + 1) / _slices;
      final vMid = (vY0 + vY1) / 2;
      if (patch.floor.length >= 3) {
        if (polygonSpanAt(patch.floor, vMid) case final vSpan?) {
          vParts.add(Prism.box(vSpan.from, vSpan.to, vY0, vY1, 0, 6, role: PartRole.highlight));
        }
      }
      if (patch.wall.length >= 3) {
        if (polygonSpanAt([for (final vPoint in patch.wall) (a: vPoint.b, b: vPoint.a)], vMid)
            case final vSpan?) {
          vParts.add(
            Prism.box(
              vDepth - 6,
              vDepth,
              vY0,
              vY1,
              vSpan.from,
              math.min(vSpan.to, vWallTop),
              role: PartRole.highlight,
            ),
          );
        }
      }
    }
    // Rampant en ghost autour de la fenêtre, vitrage au milieu
    vParts.addAll([
      Prism(vRoof(0, vRoofEnd), -_roomHalfMm, -vHalf, role: PartRole.ghost),
      Prism(vRoof(0, vRoofEnd), vHalf, _roomHalfMm, role: PartRole.ghost),
      Prism(vRoof(0, vLow), -vHalf, vHalf, role: PartRole.ghost),
      if (vHigh < vRoofEnd) Prism(vRoof(vHigh, vRoofEnd), -vHalf, vHalf, role: PartRole.ghost),
      Prism(vRoof(vLow, vHigh), -vHalf, vHalf, role: PartRole.glass),
    ]);

    return Sketch3D(
      parts: vParts,
      callouts: [
        (
          at: (x: (vLow + vHigh) / 2 * vCos, y: vHalf, z: vKnee + (vLow + vHigh) / 2 * vSin),
          text: vText.sunWindowLabel,
          shift: const Offset(-60, -40),
        ),
        (
          at: (x: spotMm.toDouble(), y: -450.0, z: 450.0),
          text: vText.sunSpotLabel,
          shift: const Offset(-40, 50),
        ),
        if (patch.floor.length >= 3)
          (
            at: (x: patch.floor.first.a, y: patch.floor.first.b, z: 6.0),
            text: vText.sunPatchLabel,
            shift: const Offset(50, 60),
          ),
      ],
    );
  }
}
