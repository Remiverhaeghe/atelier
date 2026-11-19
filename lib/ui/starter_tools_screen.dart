import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/extra_items.dart';
import '../logic/gestures.dart';
import '../logic/starter_tools.dart';
import 'gestures_screen.dart';
import 'shopping_target.dart';
import 'theme.dart';

/// Caisse à outils du débutant : on coche ce qu'on a, l'écran dit ce qui manque et ce que ça
/// coûte, et l'ajoute aux courses.
class StarterToolsScreen extends StatefulWidget {
  const StarterToolsScreen({super.key});

  @override
  State<StarterToolsScreen> createState() => _StarterToolsScreenState();
}

class _StarterToolsScreenState extends State<StarterToolsScreen> {
  final _owned = <StarterTool>{};

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vEssential = missingTools(_owned, ToolTier.essential);
    final vNext = missingTools(_owned, ToolTier.next);

    return Scaffold(
      appBar: AppBar(title: Text(vText.toolsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(vText.toolsIntro, style: vTheme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vEssential.count == 0)
                    BigFigure(vText.toolsEssentialDone)
                  else
                    BigFigure(
                      vText.toolsEssentialMissing(
                        vEssential.count,
                        vEssential.minEuros,
                        vEssential.maxEuros,
                      ),
                    ),
                  IconLine(
                    Icons.add_box_outlined,
                    vText.toolsNextMissing(vNext.count, vNext.minEuros, vNext.maxEuros),
                  ),
                  AddToShoppingButton(
                    items: () => [
                      for (final vTool in StarterTool.values)
                        if (vTool.tier == ToolTier.essential && !_owned.contains(vTool))
                          ExtraItem(name: toolName(vText, vTool), quantity: 1),
                    ],
                  ),
                ],
              ),
            ),
          ),
          for (final vTier in ToolTier.values) ...[
            const SizedBox(height: 12),
            Text(
              vTier == ToolTier.essential ? vText.toolsEssential : vText.toolsNext,
              style: vTheme.textTheme.titleMedium,
            ),
            for (final vTool in StarterTool.values.where((pTool) => pTool.tier == vTier))
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _owned.contains(vTool),
                onChanged: (pOwned) => setState(
                  () => pOwned == true ? _owned.add(vTool) : _owned.remove(vTool),
                ),
                title: Text(toolName(vText, vTool)),
                subtitle: Text(_subtitle(vText, vTool)),
              ),
          ],
          const SizedBox(height: 8),
          Text(vText.toolsHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }

  String _subtitle(AppLocalizations pText, StarterTool pTool) {
    final vPrice = pText.toolsPrice(pTool.minEuros, pTool.maxEuros);
    final vGestures = gesturesWith(pTool);
    final rText = vGestures.isEmpty
        ? vPrice
        : pText.toolsUsedFor(
            vPrice,
            vGestures.map((pGesture) => gestureName(pText, pGesture)).join(', '),
          );

    return rText;
  }
}

String toolName(AppLocalizations pText, StarterTool pTool) => switch (pTool) {
  StarterTool.tape => pText.toolTape,
  StarterTool.pencil => pText.toolPencil,
  StarterTool.square => pText.toolSquare,
  StarterTool.spiritLevel => pText.toolSpiritLevel,
  StarterTool.cutter => pText.toolCutter,
  StarterTool.handSaw => pText.toolHandSaw,
  StarterTool.hammer => pText.toolHammer,
  StarterTool.screwdrivers => pText.toolScrewdrivers,
  StarterTool.drillDriver => pText.toolDrillDriver,
  StarterTool.bits => pText.toolBits,
  StarterTool.glasses => pText.toolGlasses,
  StarterTool.clamps => pText.toolClamps,
  StarterTool.detector => pText.toolDetector,
  StarterTool.mitreBox => pText.toolMitreBox,
  StarterTool.caulkGun => pText.toolCaulkGun,
  StarterTool.plane => pText.toolPlane,
  StarterTool.chisels => pText.toolChisels,
  StarterTool.mallet => pText.toolMallet,
  StarterTool.sander => pText.toolSander,
  StarterTool.laserLevel => pText.toolLaserLevel,
  StarterTool.groutFloat => pText.toolGroutFloat,
  StarterTool.dustMask => pText.toolDustMask,
};
