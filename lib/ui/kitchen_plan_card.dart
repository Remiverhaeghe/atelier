import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/kitchen_layout.dart';
import '../logic/room.dart';
import '../logic/slope.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'room_source.dart';
import 'sketch3d.dart';
import 'theme.dart';

String kitchenLayoutLabel(AppLocalizations pText, KitchenLayout pLayout) => switch (pLayout) {
  KitchenLayout.linear => pText.kitLinear,
  KitchenLayout.parallel => pText.kitParallel,
  KitchenLayout.lShape => pText.kitLShape,
  KitchenLayout.uShape => pText.kitUShape,
  KitchenLayout.island => pText.kitIsland,
};

String triangleIssueLabel(AppLocalizations pText, TriangleIssue pIssue) => switch (pIssue) {
  TriangleIssue.sideTooShort => pText.kitSideShort,
  TriangleIssue.sideTooLong => pText.kitSideLong,
  TriangleIssue.totalTooShort => pText.kitTotalShort,
  TriangleIssue.totalTooLong => pText.kitTotalLong,
};

/// Implantation de la cuisine : triangle d'activité, débit de la hotte selon le volume et
/// formes qui tiennent dans la pièce.
class KitchenPlanCard extends StatefulWidget {
  const KitchenPlanCard({super.key, this.rooms = const []});

  final List<Room> rooms;

  @override
  State<KitchenPlanCard> createState() => _KitchenPlanCardState();
}

class _KitchenPlanCardState extends State<KitchenPlanCard> {
  int _sinkHob = 1500;
  int _hobFridge = 2000;
  int _fridgeSink = 1800;
  int _width = 2600;
  int _length = 3400;
  int _height = 2500;
  Room? _room;

  /// Change quand une pièce remplit les champs, pour qu'ils se redessinent avec la valeur.
  int _source = 0;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vTriangle = checkTriangle(_sinkHob, _hobFridge, _fridgeSink);
    final vRoom = _room;
    final vVolume = vRoom == null ? _width * _length * _height / 1e9 : roomVolumeM3(vRoom);
    final vHood = hoodFor(vVolume);
    final vLayouts = kitchenLayouts(_width, _length);
    String vCm(int pMm) => formatCentimetres(pMm);
    NumberField<int> vField(String pKey, String pLabel, int pValue, ValueChanged<int> pSet) =>
        NumberField<int>(
          key: ValueKey('$pKey-$_source'),
          label: pLabel,
          initial: vCm(pValue),
          parse: parseCentimetres,
          onValue: (pNew) => setState(() => pSet(pNew)),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(vText.kitTriangleTitle, style: vTheme.textTheme.titleMedium),
        AspectRatio(
          aspectRatio: 1.4,
          child: KitchenSketch(widthMm: _width, lengthMm: _length),
        ),
        IconLine(
          vTriangle.issues.isEmpty ? Icons.check_circle_outline : Icons.warning_amber,
          vText.kitTriangle(formatDecimal(vTriangle.totalMm / 1000)),
          color: vTriangle.issues.isEmpty ? null : vTheme.colorScheme.error,
        ),
        for (final vIssue in vTriangle.issues)
          IconLine(Icons.warning_amber, triangleIssueLabel(vText, vIssue)),
        vField('evier', vText.kitSinkHob, _sinkHob, (pValue) => _sinkHob = pValue),
        vField('plaque', vText.kitHobFridge, _hobFridge, (pValue) => _hobFridge = pValue),
        vField('frigo', vText.kitFridgeSink, _fridgeSink, (pValue) => _fridgeSink = pValue),
        const Divider(),
        Text(vText.kitRoomTitle, style: vTheme.textTheme.titleMedium),
        RoomSourcePicker(
          rooms: widget.rooms,
          value: _room?.id,
          onChanged: (pRoom) => setState(() {
            _room = pRoom;
            if (pRoom != null) {
              final vBox = roomBox(pRoom);
              _width = vBox.widthMm;
              _length = vBox.lengthMm;
              _height = pRoom.ceilingHeightMm;
              _source++;
            }
          }),
        ),
        vField('largeur', vText.kitWidth, _width, (pValue) => _width = pValue),
        vField('longueur', vText.kitLength, _length, (pValue) => _length = pValue),
        if (vRoom == null)
          vField('hauteur', vText.kitHeight, _height, (pValue) => _height = pValue),
        IconLine(Icons.air, vText.kitHood(formatDecimal(vVolume), vHood.neededM3h, vHood.hoodM3h)),
        IconLine(Icons.info_outline, vText.kitHoodNote),
        const SizedBox(height: 6),
        Text(vText.kitLayoutsTitle, style: vTheme.textTheme.titleSmall),
        if (vLayouts.isEmpty) Text(vText.kitNoLayout),
        for (final vLayout in vLayouts) IconLine(Icons.check, kitchenLayoutLabel(vText, vLayout)),
        const SizedBox(height: 4),
        Text(vText.kitLayoutHint(vCm(runDepthMm), vCm(aisleMm)), style: vTheme.textTheme.bodySmall),
      ],
    );
  }
}

/// La cuisine en L en relief : meubles bas, plan de travail, évier, plaque et réfrigérateur.
class KitchenSketch extends StatelessWidget {
  const KitchenSketch({super.key, required this.widthMm, required this.lengthMm});

  final int widthMm;
  final int lengthMm;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    // Le linéaire du fond sur la longueur, le retour sur la largeur, bornés pour rester lisibles
    final vLong = lengthMm.clamp(2400, 6000).toDouble();
    final vShort = widthMm.clamp(1800, 4000).toDouble();
    const vDepth = 600.0;
    const vBase = 860.0;
    const vTop = 900.0;

    return Sketch3D(
      parts: [
        Prism.box(0, vLong, vShort - vDepth, vShort, 0, vBase, role: PartRole.board),
        Prism.box(0, vDepth, 0, vShort - vDepth, 0, vBase, role: PartRole.board),
        Prism.box(0, vLong, vShort - vDepth, vShort, vBase, vTop),
        Prism.box(0, vDepth, 0, vShort - vDepth, vBase, vTop),
        Prism.box(
          vLong * 0.45,
          vLong * 0.45 + 600,
          vShort - 520,
          vShort - 80,
          vTop - 10,
          vTop + 5,
          role: PartRole.glass,
        ),
        Prism.box(
          60,
          vDepth - 60,
          vShort * 0.25,
          vShort * 0.25 + 560,
          vTop,
          vTop + 10,
          role: PartRole.highlight,
        ),
        Prism.box(vLong - 600, vLong, vShort - vDepth, vShort, 0, 1850, role: PartRole.ghost),
      ],
      callouts: [
        (
          at: (x: vLong * 0.45 + 300, y: vShort - 300, z: vTop),
          text: vText.kitSketchSink,
          shift: const Offset(0, -50),
        ),
        (
          at: (x: vDepth / 2, y: vShort * 0.25 + 280, z: vTop + 10),
          text: vText.kitSketchHob,
          shift: const Offset(-60, -40),
        ),
        (
          at: (x: vLong - 300, y: vShort - vDepth, z: 1500.0),
          text: vText.kitSketchFridge,
          shift: const Offset(50, -20),
        ),
      ],
    );
  }
}
