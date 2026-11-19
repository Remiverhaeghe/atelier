import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/extra_items.dart';
import '../logic/insulation.dart';
import '../logic/interior_insulation.dart';
import '../logic/room.dart';
import '../logic/units.dart';
import 'insulation_calculator.dart';
import 'parquet_view.dart';
import 'shopping_target.dart';
import 'sketch3d.dart';
import 'theme.dart';

String liningSystemLabel(AppLocalizations pText, LiningSystem pSystem) => switch (pSystem) {
  LiningSystem.metalFrame => pText.iwiMetal,
  LiningSystem.gluedComplex => pText.iwiGlued,
  LiningSystem.timberFrame => pText.iwiTimber,
};

/// Isolation des murs par l'intérieur : isolant, ossature, pare-vapeur et surface perdue pièce
/// par pièce.
class WallLiningCalculator extends StatefulWidget {
  const WallLiningCalculator({super.key, this.rooms = const []});

  /// Pièces saisies : on coche les murs qui donnent dehors.
  final List<Room> rooms;

  @override
  State<WallLiningCalculator> createState() => _WallLiningCalculatorState();
}

class _WallLiningCalculatorState extends State<WallLiningCalculator> {
  Insulant _insulant = Insulant.glassWool;
  LiningSystem _system = LiningSystem.metalFrame;
  double _targetR = InsulatedPart.walls.targetR;
  final Map<String, Set<int>> _walls = {};

  /// Sans pièce saisie : un pan de mur à la main.
  int _lengthMm = 4000;
  int _heightMm = 2500;

  List<Room> get _rooms => [
    for (final vRoom in widget.rooms)
      if (vRoom.walls.isNotEmpty) vRoom,
  ];

  List<RoomLining> _linings() {
    if (_rooms.isEmpty) {
      final vManual = Room(
        id: 'mur',
        name: '',
        closed: false,
        ceilingHeightMm: _heightMm,
        walls: [Wall(lengthMm: _lengthMm)],
      );

      return [
        (room: vManual, walls: {0}),
      ];
    }

    return [for (final vRoom in _rooms) (room: vRoom, walls: _walls[vRoom.id] ?? const <int>{})];
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vPlan = planLining(
      pRooms: _linings(),
      pInsulant: _insulant,
      pSystem: _system,
      pTargetR: _targetR,
    );
    String vCm(int pMm) => formatCentimetres(pMm);
    final vThickness = vPlan.layersMm.map(vCm).join(' + ');
    final vItems = [
      ExtraItem(
        name: vText.iwiInsulantItem(insulantLabel(vText, _insulant), vThickness),
        quantity: vPlan.insulantPacks,
      ),
      ExtraItem(name: vText.iwiBoardItem, quantity: vPlan.boards),
      if (_system.hasFrame) ExtraItem(name: vText.iwiStudItem, quantity: vPlan.studs),
      if (_system == LiningSystem.metalFrame)
        ExtraItem(name: vText.iwiBracketItem, quantity: vPlan.brackets),
      if (vPlan.adhesiveBags > 0)
        ExtraItem(name: vText.iwiAdhesiveItem, quantity: vPlan.adhesiveBags),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(vText.iwiTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          AspectRatio(
            aspectRatio: 1.4,
            child: LiningSketch(
              insulantMm: vPlan.layersMm.fold(0, (pSum, pLayer) => pSum + pLayer),
              system: _system,
              vapor: needsVaporBarrier(_insulant),
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BigFigure(vText.iwiDepth(vThickness, vCm(vPlan.depthMm))),
                  IconLine(
                    Icons.speed,
                    vText.insulR(formatDecimal(vPlan.achievedR), formatDecimal(_targetR)),
                  ),
                  // Rien de coché : pas de quantités à zéro, seulement l'invitation à cocher
                  if (vPlan.wallM2 <= 0)
                    IconLine(Icons.touch_app_outlined, vText.iwiPickWalls)
                  else ...[
                  IconLine(
                    Icons.crop_square,
                    vText.iwiWall(formatSquareMetres(vPlan.wallM2), vPlan.insulantPacks),
                  ),
                  if (vPlan.vaporBarrierM2 > 0)
                    IconLine(
                      Icons.water_drop_outlined,
                      vText.insulVapor(formatSquareMetres(vPlan.vaporBarrierM2)),
                    )
                  else
                    IconLine(Icons.water_drop_outlined, vText.iwiNoVapor),
                  IconLine(Icons.dashboard_outlined, vText.iwiBoards(vPlan.boards)),
                  if (_system.hasFrame)
                    IconLine(
                      Icons.view_week_outlined,
                      vText.iwiFrame(vPlan.studs, vPlan.railsMetres),
                    ),
                  if (vPlan.brackets > 0)
                    IconLine(Icons.hardware_outlined, vText.iwiBrackets(vPlan.brackets)),
                  if (vPlan.adhesiveBags > 0)
                    IconLine(Icons.inventory_2_outlined, vText.iwiAdhesive(vPlan.adhesiveBags)),
                  const Divider(),
                  Text(vText.iwiLostTitle, style: vTheme.textTheme.titleSmall),
                  for (final vRoom in vPlan.rooms)
                    IconLine(
                      Icons.square_foot,
                      vRoom.room.name.isEmpty
                          ? vText.iwiLostManual(formatSquareMetres(vRoom.lostM2))
                          : vText.iwiLostRoom(
                              vRoom.room.name,
                              formatSquareMetres(vRoom.lostM2),
                              formatSquareMetres(vRoom.floorBeforeM2),
                            ),
                    ),
                  if (vPlan.rooms.any((pRoom) => pRoom.windows > 0))
                    IconLine(
                      Icons.window_outlined,
                      vText.iwiReveals(vPlan.rooms.fold(0, (pSum, pRoom) => pSum + pRoom.windows)),
                    ),
                  AddToShoppingButton(items: () => vItems),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Insulant>(
            initialValue: _insulant,
            decoration: InputDecoration(labelText: vText.insulMaterial),
            items: [
              for (final vInsulant in Insulant.values)
                if (vInsulant != Insulant.cellulose)
                  DropdownMenuItem(value: vInsulant, child: Text(insulantLabel(vText, vInsulant))),
            ],
            onChanged: (pInsulant) => setState(() => _insulant = pInsulant!),
          ),
          DropdownButtonFormField<LiningSystem>(
            initialValue: _system,
            isExpanded: true,
            decoration: InputDecoration(labelText: vText.iwiSystem),
            items: [
              for (final vSystem in LiningSystem.values)
                DropdownMenuItem(value: vSystem, child: Text(liningSystemLabel(vText, vSystem))),
            ],
            onChanged: (pSystem) => setState(() => _system = pSystem!),
          ),
          NumberField<double>(
            label: vText.insulTarget,
            initial: formatDecimal(_targetR),
            parse: parseDecimal,
            onValue: (pValue) => setState(() => _targetR = pValue),
          ),
          const SizedBox(height: 8),
          if (_rooms.isEmpty) ...[
            Text(vText.iwiNoRooms, style: vTheme.textTheme.bodySmall),
            NumberField<int>(
              label: vText.iwiLength,
              initial: vCm(_lengthMm),
              parse: parseCentimetres,
              onValue: (pValue) => setState(() => _lengthMm = pValue),
            ),
            NumberField<int>(
              label: vText.iwiHeight,
              initial: vCm(_heightMm),
              parse: parseCentimetres,
              onValue: (pValue) => setState(() => _heightMm = pValue),
            ),
          ] else ...[
            Text(vText.iwiPickWalls, style: vTheme.textTheme.titleSmall),
            for (final vRoom in _rooms) ...[
              Padding(padding: const EdgeInsets.only(top: 8), child: Text(vRoom.name)),
              Wrap(
                spacing: 6,
                children: [
                  for (var vIndex = 0; vIndex < vRoom.walls.length; vIndex++)
                    FilterChip(
                      label: Text(vText.wallTitle(vIndex + 1)),
                      selected: _walls[vRoom.id]?.contains(vIndex) ?? false,
                      onSelected: (pOn) => setState(() {
                        final vSet = {...?_walls[vRoom.id]};
                        if (pOn) {
                          vSet.add(vIndex);
                        } else {
                          vSet.remove(vIndex);
                        }
                        _walls[vRoom.id] = vSet;
                      }),
                    ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 12),
          IconLine(Icons.lightbulb_outline, vText.iwiTip),
          Text(vText.iwiHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Coupe du doublage en relief : mur, isolant surligné, ossature, pare-vapeur et plaque.
class LiningSketch extends StatelessWidget {
  const LiningSketch({
    super.key,
    required this.insulantMm,
    required this.system,
    required this.vapor,
  });

  final int insulantMm;
  final LiningSystem system;
  final bool vapor;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    // Un morceau de mur d'1,2 m de large et 1 m de haut, vu en coupe par-dessus
    const vMasonry = 200.0;
    const vLength = 1200.0;
    const vHeight = 1000.0;
    final vInsulant = insulantMm.toDouble();
    final vInner = vMasonry + vInsulant + system.gapMm;
    final vBoard = system.boardMm.toDouble();

    return Sketch3D(
      parts: [
        Prism.box(0, vMasonry, 0, vLength, 0, vHeight, role: PartRole.ghost),
        Prism.box(vMasonry, vMasonry + vInsulant, 0, vLength, 0, vHeight, role: PartRole.highlight),
        if (system.hasFrame)
          for (final vY in [100.0, 700.0])
            Prism.box(
              system == LiningSystem.timberFrame ? vMasonry : vMasonry + vInsulant,
              vInner,
              vY,
              vY + (system == LiningSystem.timberFrame ? 45 : 50),
              0,
              vHeight,
            ),
        if (vapor) Prism.box(vInner, vInner + 4, 0, vLength, 0, vHeight, role: PartRole.glass),
        Prism.box(
          vInner + 4,
          vInner + 4 + vBoard,
          0,
          vLength * 0.8,
          0,
          vHeight,
          role: PartRole.board,
        ),
      ],
      callouts: [
        (
          at: (x: vMasonry / 2, y: 0.0, z: vHeight * 0.8),
          text: vText.iwiSketchWall,
          shift: const Offset(-50, -30),
        ),
        (
          at: (x: vMasonry + vInsulant / 2, y: 0.0, z: vHeight / 2),
          text: vText.iwiSketchInsulant,
          shift: const Offset(-60, 50),
        ),
        if (system.hasFrame)
          (
            at: (x: vInner, y: 700.0, z: vHeight),
            text: vText.iwiSketchFrame,
            shift: const Offset(10, -40),
          ),
        if (vapor)
          (
            at: (x: vInner + 2, y: vLength, z: vHeight * 0.3),
            text: vText.iwiSketchVapor,
            shift: const Offset(50, 30),
          ),
        (
          at: (x: vInner + 4 + vBoard, y: vLength * 0.4, z: vHeight * 0.2),
          text: vText.iwiSketchBoard,
          shift: const Offset(60, 40),
        ),
      ],
    );
  }
}
