import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/bathroom.dart';
import '../logic/bathroom_safety.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'sketch3d.dart';
import 'theme.dart';

/// Salle d'eau autour de la douche : volumes de sécurité, pente du receveur, étanchéité
/// liquide et ventilation.
class BathroomSafetyCard extends StatefulWidget {
  const BathroomSafetyCard({super.key, required this.shower});

  final Shower shower;

  @override
  State<BathroomSafetyCard> createState() => _BathroomSafetyCardState();
}

class _BathroomSafetyCardState extends State<BathroomSafetyCard> {
  bool _walkIn = false;
  int _dropMm = 18;
  int _mainRooms = 3;
  double _volume = 15;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vZones = zonePlan(widget.shower, pWalkIn: _walkIn);
    final vRun = showerRunMm(widget.shower);
    final vSlope = slopePercent(_dropMm, vRun);
    final vSeal = sealPlan(widget.shower);
    final vAir = bathAir(pMainRooms: _mainRooms, pVolumeM3: _volume);
    String vCm(int pMm) => formatCentimetres(pMm);
    final vVerdict = switch (slopeVerdict(vSlope)) {
      SlopeVerdict.tooFlat => vText.bathSlopeFlat,
      SlopeVerdict.good => vText.bathSlopeGood,
      SlopeVerdict.tooSteep => vText.bathSlopeSteep,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(vText.bathZonesTitle, style: vTheme.textTheme.titleMedium),
        AspectRatio(
          aspectRatio: 1.3,
          child: BathZonesSketch(shower: widget.shower, zones: vZones),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(vText.bathWalkIn),
          value: _walkIn,
          onChanged: (pValue) => setState(() => _walkIn = pValue),
        ),
        IconLine(
          Icons.shower_outlined,
          vText.bathZone1(vCm(vZones.zone1WidthMm), vCm(vZones.zone1DepthMm), vCm(zone1HeightMm)),
        ),
        IconLine(
          Icons.crop_free,
          vText.bathZone2(vCm(vZones.zone2WidthMm), vCm(vZones.zone2DepthMm), vCm(zone2WidthMm)),
        ),
        IconLine(Icons.power_off_outlined, vText.bathZoneRules),
        IconLine(Icons.power_outlined, vText.bathZoneOutside(vCm(zone2WidthMm))),
        const Divider(),
        Text(vText.bathSlopeTitle, style: vTheme.textTheme.titleMedium),
        NumberField<int>(
          label: vText.bathDrop,
          initial: '$_dropMm',
          parse: parseWhole,
          onValue: (pValue) => setState(() => _dropMm = pValue),
        ),
        IconLine(
          Icons.trending_down,
          vText.bathSlope(formatDecimal(vSlope), vCm(vRun), vVerdict),
          color: slopeVerdict(vSlope) == SlopeVerdict.good ? null : vTheme.colorScheme.error,
        ),
        const Divider(),
        Text(vText.bathSealTitle, style: vTheme.textTheme.titleMedium),
        IconLine(
          Icons.format_paint_outlined,
          vText.bathSeal(formatSquareMetres(vSeal.areaM2), formatDecimal(vSeal.kg), vSeal.pots),
        ),
        IconLine(
          Icons.linear_scale,
          vText.bathSealBand(formatDecimal(vSeal.bandM), vSeal.sleeves),
        ),
        IconLine(Icons.layers_outlined, vText.bathSealSteps),
        const Divider(),
        Text(vText.bathAirTitle, style: vTheme.textTheme.titleMedium),
        NumberField<int>(
          label: vText.bathMainRooms,
          initial: '$_mainRooms',
          parse: parseWhole,
          onValue: (pValue) => setState(() => _mainRooms = pValue),
        ),
        NumberField<double>(
          label: vText.bathVolume,
          initial: formatDecimal(_volume),
          parse: parseDecimal,
          onValue: (pValue) => setState(() => _volume = pValue),
        ),
        IconLine(
          Icons.air,
          vText.bathAir(vAir.flowM3h, formatDecimal(vAir.changesPerHour), vCm(vAir.undercutMm)),
        ),
        const SizedBox(height: 4),
        Text(vText.bathHint, style: vTheme.textTheme.bodySmall),
      ],
    );
  }
}

/// La douche en relief : receveur, volume 1 en verre jusqu'à 2,25 m, emprise du volume 2 au sol
/// et murs de la douche.
class BathZonesSketch extends StatelessWidget {
  const BathZonesSketch({super.key, required this.shower, required this.zones});

  final Shower shower;
  final ZonePlan zones;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vWidth = zones.zone1WidthMm.toDouble();
    final vDepth = zones.zone1DepthMm.toDouble();
    final vBand = zone2WidthMm.toDouble();
    final vWalls = shower.walls.clamp(1, 3);
    // Côtés ouverts : à droite d'abord, puis à gauche
    final vRight = vWalls < 3 ? vBand : 0.0;
    final vLeft = vWalls < 2 ? vBand : 0.0;
    final vBack = vBand + vDepth;

    return Sketch3D(
      parts: [
        Prism.box(-vLeft, vWidth + vRight, 0, vBack, -30, 0, role: PartRole.ghost),
        Prism.box(0, vWidth, vBand, vBack, 0, 40),
        Prism.box(0, vWidth, vBand, vBack, 40, zone1HeightMm.toDouble(), role: PartRole.glass),
        Prism.box(-vLeft, vWidth + vRight, vBack, vBack + 80, 0, 2500, role: PartRole.board),
        if (vWalls >= 2) Prism.box(-80, 0, vBand, vBack, 0, 2500, role: PartRole.board),
        if (vWalls >= 3)
          Prism.box(vWidth, vWidth + 80, vBand, vBack, 0, 2500, role: PartRole.board),
      ],
      callouts: [
        (
          at: (x: vWidth / 2, y: vBand, z: zone1HeightMm * 0.75),
          text: vText.bathSketchZone1,
          shift: const Offset(-70, -30),
        ),
        (
          at: (x: vWidth * 0.8, y: vBand / 2, z: 0.0),
          text: vText.bathSketchZone2,
          shift: const Offset(60, 40),
        ),
        (
          at: (x: vWidth * 0.3, y: vBand, z: 40.0),
          text: vText.bathSketchTray,
          shift: const Offset(-70, 40),
        ),
      ],
    );
  }
}
