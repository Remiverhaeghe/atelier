import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/board_types.dart';
import '../logic/units.dart';
import 'sketch3d.dart';
import 'theme.dart';

/// Épaisseurs courantes en magasin, en mm.
const boardThicknessesMm = [10, 12, 15, 18, 19, 22];

/// Choisir un panneau : ceux qui conviennent à l'usage, leur structure en relief, et le poids
/// d'une plaque pour savoir si on la porte seul.
class BoardTypeScreen extends StatefulWidget {
  const BoardTypeScreen({super.key});

  @override
  State<BoardTypeScreen> createState() => _BoardTypeScreenState();
}

class _BoardTypeScreenState extends State<BoardTypeScreen> {
  BoardUse _use = BoardUse.shelf;
  int _thicknessMm = 18;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(vText.boardTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(vText.boardUseQuestion, style: vTheme.textTheme.titleSmall),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final vUse in BoardUse.values)
                ChoiceChip(
                  label: Text(boardUseName(vText, vUse)),
                  selected: _use == vUse,
                  onSelected: (_) => setState(() => _use = vUse),
                ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _thicknessMm,
            decoration: InputDecoration(labelText: vText.boardThickness),
            items: [
              for (final vThickness in boardThicknessesMm)
                DropdownMenuItem(value: vThickness, child: Text('$vThickness mm')),
            ],
            onChanged: (pThickness) => setState(() => _thicknessMm = pThickness ?? _thicknessMm),
          ),
          for (final vBoard in boardsFor(_use))
            _BoardCard(board: vBoard, thicknessMm: _thicknessMm),
          const SizedBox(height: 8),
          Text(vText.boardHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _BoardCard extends StatelessWidget {
  const _BoardCard({required this.board, required this.thicknessMm});

  final BoardType board;
  final int thicknessMm;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vKg = sheetKg(board, thicknessMm);

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(boardName(vText, board), style: vTheme.textTheme.titleMedium),
            AspectRatio(aspectRatio: 2.4, child: BoardSketch(board: board)),
            Text(boardText(vText, board), style: vTheme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            IconLine(Icons.euro, vText.boardPrice('€' * board.price)),
            IconLine(Icons.hardware_outlined, switch (board.screwHold) {
              1 => vText.boardScrewWeak,
              2 => vText.boardScrewFair,
              _ => vText.boardScrewGood,
            }),
            IconLine(
              Icons.fitness_center,
              vKg > carryAloneKg
                  ? vText.boardHeavy(formatDecimal(vKg.roundToDouble()))
                  : vText.boardLight(formatDecimal(vKg.roundToDouble())),
            ),
          ],
        ),
      ),
    );
  }
}

/// Coupe d'un panneau en relief : plis croisés, copeaux, fibres, lattes ou décor.
class BoardSketch extends StatelessWidget {
  const BoardSketch({super.key, required this.board});

  final BoardType board;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vParts = switch (board) {
      BoardType.plywood => [
        for (var vPly = 0; vPly < 5; vPly++)
          Prism.box(0, 100, 0, 40, vPly * 3.0, vPly * 3.0 + 3,
              role: vPly.isEven ? PartRole.wood : PartRole.highlight),
      ],
      BoardType.osb => [
        Prism.box(0, 100, 0, 40, 0, 12, role: PartRole.board),
        for (final (vX, vY) in [(8.0, 6.0), (30.0, 22.0), (55.0, 10.0), (72.0, 28.0), (18.0, 30.0)])
          Prism.box(vX, vX + 16, vY, vY + 3, 12, 12.4, role: PartRole.highlight),
      ],
      BoardType.mdf => [Prism.box(0, 100, 0, 40, 0, 15, role: PartRole.board)],
      BoardType.blockboard => [
        Prism.box(0, 100, 0, 40, 0, 2, role: PartRole.highlight),
        for (var vStrip = 0; vStrip < 5; vStrip++)
          Prism.box(0, 100, vStrip * 8.0, vStrip * 8.0 + 7.6, 2, 13),
        Prism.box(0, 100, 0, 40, 13, 15, role: PartRole.highlight),
      ],
      BoardType.melamine => [
        Prism.box(0, 100, 0, 40, 0, 0.8, role: PartRole.glass),
        Prism.box(0, 100, 0, 40, 0.8, 14.2, role: PartRole.board),
        Prism.box(0, 100, 0, 40, 14.2, 15, role: PartRole.glass),
      ],
      BoardType.particleboard => [
        Prism.box(0, 100, 0, 40, 0, 15, role: PartRole.board),
        for (final vX in [10.0, 34.0, 61.0, 85.0]) Prism.box(vX, vX + 2, 0, 1, 5, 7, role: PartRole.ghost),
      ],
    };

    return Sketch3D(
      parts: vParts,
      callouts: [
        (at: (x: 100.0, y: 0.0, z: 7.0), text: boardStructure(vText, board), shift: const Offset(50, 20)),
      ],
    );
  }
}

String boardUseName(AppLocalizations pText, BoardUse pUse) => switch (pUse) {
  BoardUse.shelf => pText.boardUseShelf,
  BoardUse.furniture => pText.boardUseFurniture,
  BoardUse.floor => pText.boardUseFloor,
  BoardUse.bracing => pText.boardUseBracing,
  BoardUse.damp => pText.boardUseDamp,
  BoardUse.outdoor => pText.boardUseOutdoor,
  BoardUse.painted => pText.boardUsePainted,
};

String boardName(AppLocalizations pText, BoardType pBoard) => switch (pBoard) {
  BoardType.plywood => pText.boardPlywood,
  BoardType.osb => pText.boardOsb,
  BoardType.mdf => pText.boardMdf,
  BoardType.blockboard => pText.boardBlockboard,
  BoardType.melamine => pText.boardMelamine,
  BoardType.particleboard => pText.boardParticleboard,
};

String boardText(AppLocalizations pText, BoardType pBoard) => switch (pBoard) {
  BoardType.plywood => pText.boardPlywoodText,
  BoardType.osb => pText.boardOsbText,
  BoardType.mdf => pText.boardMdfText,
  BoardType.blockboard => pText.boardBlockboardText,
  BoardType.melamine => pText.boardMelamineText,
  BoardType.particleboard => pText.boardParticleboardText,
};

String boardStructure(AppLocalizations pText, BoardType pBoard) => switch (pBoard) {
  BoardType.plywood => pText.boardPlywoodLayers,
  BoardType.osb => pText.boardOsbLayers,
  BoardType.mdf => pText.boardMdfLayers,
  BoardType.blockboard => pText.boardBlockboardLayers,
  BoardType.melamine => pText.boardMelamineLayers,
  BoardType.particleboard => pText.boardParticleboardLayers,
};
