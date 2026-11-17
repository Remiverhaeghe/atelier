import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/shelf.dart';
import '../logic/units.dart';
import '../logic/wardrobe.dart';
import 'parquet_view.dart';
import 'shelf_calculator.dart';
import 'theme.dart';

String wardrobePartLabel(AppLocalizations pText, String pName) => switch (pName) {
  topBottomPart => pText.partTopBottom,
  dividerPart => pText.partDivider,
  doorPart => pText.partDoor,
  railPart => pText.partRail,
  drawerFrontPart => pText.partDrawerFront,
  drawerSidePart => pText.partDrawerSide,
  drawerEndPart => pText.partDrawerEnd,
  drawerBottomPart => pText.partDrawerBottom,
  slidePart => pText.partSlide,
  _ => shelfPartLabel(pText, pName),
};

/// Armoire sur mesure : compartiments, liste de débit, portes et charnières, dessin coté.
class WardrobeCalculator extends StatefulWidget {
  const WardrobeCalculator({super.key});

  @override
  State<WardrobeCalculator> createState() => _WardrobeCalculatorState();
}

class _WardrobeCalculatorState extends State<WardrobeCalculator> {
  var _design = const WardrobeDesign();

  void _set(WardrobeDesign pDesign) => setState(() => _design = pDesign);

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vPlan = planWardrobe(_design);

    return Scaffold(
      appBar: AppBar(title: Text(vText.wardrobeTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SizedBox(
            height: 240,
            child: CustomPaint(
              size: Size.infinite,
              painter: _WardrobePainter(
                design: _design,
                plan: vPlan,
                colors: AtelierColors.of(context),
                labelStyle: vTheme.textTheme.labelMedium!.copyWith(
                  fontFamily: titleFont,
                  fontWeight: FontWeight.w700,
                  color: AtelierColors.of(context).onTape,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vText.cutListTitle, style: vTheme.textTheme.titleMedium),
                  for (final vPart in vPlan.parts.where((pPart) => pPart.name != slidePart))
                    IconLine(
                      vPart.name == railPart ? Icons.horizontal_rule : Icons.straighten,
                      vPart.name == railPart
                          ? vText.railLine(vPart.count, formatCentimetres(vPart.lengthMm))
                          : vText.cutListLine(
                              vPart.count,
                              wardrobePartLabel(vText, vPart.name),
                              formatCentimetres(vPart.lengthMm),
                              formatCentimetres(vPart.widthMm),
                            ),
                    ),
                  if (vPlan.hinges > 0)
                    IconLine(Icons.door_back_door_outlined, vText.hinges(vPlan.hinges)),
                  if (vPlan.hinges > 0)
                    IconLine(
                      Icons.radio_button_unchecked,
                      vText.hingePositions(
                        hingePositions(vPlan.doorHeightMm).map(formatCentimetres).join(', '),
                      ),
                    ),
                  for (final vPart in vPlan.parts.where((pPart) => pPart.name == slidePart))
                    IconLine(
                      Icons.swap_vert,
                      vText.drawerSlides(vPart.count, formatCentimetres(vPart.lengthMm)),
                    ),
                  if (vPlan.tooWide)
                    IconLine(
                      Icons.warning_amber,
                      vText.shelfTooWide(formatCentimetres(vPlan.maxSpanMm)),
                      color: vTheme.colorScheme.error,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(vText.compartmentsTitle, style: vTheme.textTheme.titleMedium),
          for (var vIndex = 0; vIndex < _design.compartments.length; vIndex++)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<CompartmentKind>(
                        segments: [
                          ButtonSegment(
                            value: CompartmentKind.hanging,
                            label: Text(vText.compartmentHanging),
                            icon: const Icon(Icons.checkroom),
                          ),
                          ButtonSegment(
                            value: CompartmentKind.shelves,
                            label: Text(vText.compartmentShelves),
                            icon: const Icon(Icons.shelves),
                          ),
                          ButtonSegment(
                            value: CompartmentKind.drawers,
                            label: Text(vText.compartmentDrawers),
                            icon: const Icon(Icons.inventory_2_outlined),
                          ),
                        ],
                        selected: {_design.compartments[vIndex].kind},
                        onSelectionChanged: (pKind) => _set(
                          _design.copyWith(
                            compartments: [..._design.compartments]
                              ..[vIndex] = Compartment(
                                kind: pKind.first,
                                shelves: _design.compartments[vIndex].shelves,
                              ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: vText.delete,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _set(
                        _design.copyWith(compartments: [..._design.compartments]..removeAt(vIndex)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: () => _set(
              _design.copyWith(compartments: [..._design.compartments, const Compartment()]),
            ),
            icon: const Icon(Icons.add),
            label: Text(vText.compartmentAdd),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(vText.wardrobeDoors),
            value: _design.doors,
            onChanged: (pValue) => _set(_design.copyWith(doors: pValue)),
          ),
          DropdownButtonFormField<ShelfMaterial>(
            initialValue: _design.material,
            decoration: InputDecoration(labelText: vText.shelfMaterial),
            items: [
              for (final vMaterial in ShelfMaterial.values)
                DropdownMenuItem(
                  value: vMaterial,
                  child: Text(shelfMaterialLabel(vText, vMaterial)),
                ),
            ],
            onChanged: (pMaterial) => _set(_design.copyWith(material: pMaterial)),
          ),
          for (final (vLabel, vValue, vApply) in [
            (vText.shelfWidth, _design.widthMm, (int pValue) => _design.copyWith(widthMm: pValue)),
            (
              vText.shelfHeight,
              _design.heightMm,
              (int pValue) => _design.copyWith(heightMm: pValue),
            ),
            (vText.shelfDepth, _design.depthMm, (int pValue) => _design.copyWith(depthMm: pValue)),
          ])
            NumberField(
              label: vLabel,
              initial: formatCentimetres(vValue),
              parse: parseCentimetres,
              onValue: (pValue) => _set(vApply(pValue)),
            ),
        ],
      ),
    );
  }
}

/// Armoire vue de face, portes ouvertes : caisson, séparations, tablettes, tringles.
class _WardrobePainter extends CustomPainter {
  _WardrobePainter({
    required this.design,
    required this.plan,
    required this.colors,
    required this.labelStyle,
  });

  final WardrobeDesign design;
  final WardrobePlan plan;
  final AtelierColors colors;
  final TextStyle labelStyle;

  @override
  void paint(Canvas pCanvas, Size pSize) {
    if (design.widthMm <= 0 || design.heightMm <= 0) {
      return;
    }
    const vMargin = 36.0;
    final vScale = [
      (pSize.width - 2 * vMargin) / design.widthMm,
      (pSize.height - vMargin - 8) / design.heightMm,
    ].reduce((pA, pB) => pA < pB ? pA : pB);
    final vWidth = design.widthMm * vScale;
    final vHeight = design.heightMm * vScale;
    final vLeft = (pSize.width - vWidth) / 2;
    const vTop = 8.0;
    final vThick = (design.thicknessMm * vScale).clamp(2.0, 10.0);
    final vWood = Paint()..color = colors.woodLaid;
    final vEdge = Paint()
      ..color = colors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    pCanvas.drawRect(Rect.fromLTWH(vLeft, vTop, vWidth, vHeight), Paint()..color = colors.wood);
    void vBoard(Rect pRect) {
      pCanvas.drawRect(pRect, vWood);
      pCanvas.drawRect(pRect, vEdge);
    }

    vBoard(Rect.fromLTWH(vLeft, vTop, vThick, vHeight));
    vBoard(Rect.fromLTWH(vLeft + vWidth - vThick, vTop, vThick, vHeight));
    vBoard(Rect.fromLTWH(vLeft, vTop, vWidth, vThick));
    vBoard(Rect.fromLTWH(vLeft, vTop + vHeight - vThick, vWidth, vThick));
    final vCount = design.compartments.isEmpty ? 1 : design.compartments.length;
    final vInner = (vWidth - (vCount + 1) * vThick) / vCount;
    for (var vIndex = 0; vIndex < design.compartments.length; vIndex++) {
      final vX = vLeft + vThick + vIndex * (vInner + vThick);
      if (vIndex > 0) {
        vBoard(Rect.fromLTWH(vX - vThick, vTop + vThick, vThick, vHeight - 2 * vThick));
      }
      final vItem = design.compartments[vIndex];
      if (vItem.kind == CompartmentKind.hanging) {
        final vShelfY = vTop + vThick + hangingShelfGapMm * vScale;
        vBoard(Rect.fromLTWH(vX, vShelfY, vInner, vThick));
        final vRailY = vShelfY + vThick + railBelowShelfMm * vScale;
        pCanvas.drawLine(
          Offset(vX + 4, vRailY),
          Offset(vX + vInner - 4, vRailY),
          Paint()
            ..color = colors.ink
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
      } else if (vItem.kind == CompartmentKind.drawers) {
        final vDrawers = vItem.shelves < 1 ? 1 : vItem.shelves;
        for (var vDrawer = 1; vDrawer < vDrawers; vDrawer++) {
          final vY = vTop + vHeight * vDrawer / vDrawers;
          pCanvas.drawLine(Offset(vX, vY), Offset(vX + vInner, vY), vEdge);
        }
        for (var vDrawer = 0; vDrawer < vDrawers; vDrawer++) {
          final vY = vTop + vHeight * (vDrawer + 0.5) / vDrawers;
          pCanvas.drawCircle(Offset(vX + vInner / 2, vY), 3, Paint()..color = colors.ink);
        }
      } else {
        final vShelves = vItem.shelves < 0 ? 0 : vItem.shelves;
        for (var vShelf = 1; vShelf <= vShelves; vShelf++) {
          final vY = vTop + vThick + (vHeight - 3 * vThick) * vShelf / (vShelves + 1);
          vBoard(Rect.fromLTWH(vX, vY, vInner, vThick));
        }
      }
    }
    _tape(
      pCanvas,
      formatCentimetres(design.widthMm),
      Offset(vLeft + vWidth / 2, vTop + vHeight + 16),
    );
    _tape(pCanvas, formatCentimetres(design.heightMm), Offset(vLeft - 20, vTop + vHeight / 2));
  }

  void _tape(Canvas pCanvas, String pText, Offset pCenter) {
    final vLabel = TextPainter(
      text: TextSpan(text: pText, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final vRect = Rect.fromCenter(
      center: pCenter,
      width: vLabel.width + 12,
      height: vLabel.height + 4,
    );
    pCanvas.drawRRect(
      RRect.fromRectAndRadius(vRect, const Radius.circular(4)),
      Paint()..color = colors.tape,
    );
    vLabel.paint(pCanvas, pCenter - Offset(vLabel.width / 2, vLabel.height / 2));
  }

  @override
  bool shouldRepaint(_WardrobePainter pOld) => pOld.design != design;
}
