import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/eaves_storage.dart';
import '../logic/extra_items.dart';
import '../logic/glossary.dart';
import '../logic/mezzanine.dart';
import '../logic/project_cutting.dart';
import '../logic/shelf.dart';
import '../logic/units.dart';
import '../logic/wood_window.dart';
import 'glossary_view.dart';
import 'panel_calculator.dart';
import 'parquet_view.dart';
import 'project_cutting_views.dart';
import 'shopping_target.dart';
import 'theme.dart';

/// Projets dont les pièces sont reprises telles que leurs calculs les donnent.
enum CutProject { window, shelf, mezzanine, eaves, custom }

/// Pièces d'un projet modèle, avec les réglages par défaut de son calcul.
List<ProjectPiece> projectPieces(CutProject pProject) {
  switch (pProject) {
    case CutProject.window:
      return woodWindowPieces(planWoodWindow(pWidthMm: 1000, pHeightMm: 1200));
    case CutProject.shelf:
      return shelfPieces(const ShelfDesign());
    case CutProject.mezzanine:
      const vMezzanine = Mezzanine();
      return mezzaninePieces(vMezzanine, planMezzanine(vMezzanine));
    case CutProject.eaves:
      final vPlan = planEavesStorage(
        pKneeWallMm: 600,
        pSlopeDeg: 45,
        pLengthMm: 2400,
        pFrontMm: 1200,
      )!;
      return eavesPieces(vPlan, pFrontMm: 1200, pLengthMm: 2400);
    case CutProject.custom:
      return const [];
  }
}

/// Débit de toutes les pièces d'un projet dans les longueurs et formats du commerce.
class ProjectCuttingScreen extends StatefulWidget {
  const ProjectCuttingScreen({super.key});

  @override
  State<ProjectCuttingScreen> createState() => _ProjectCuttingScreenState();
}

class _ProjectCuttingScreenState extends State<ProjectCuttingScreen> {
  var _project = CutProject.window;
  var _pieces = projectPieces(CutProject.window);
  var _kerf = defaultKerfMm;
  var _rotate = false;

  String _projectLabel(AppLocalizations pText, CutProject pProject) => switch (pProject) {
    CutProject.window => pText.cutPlanWindow,
    CutProject.shelf => pText.cutPlanShelf,
    CutProject.mezzanine => pText.cutPlanMezzanine,
    CutProject.eaves => pText.cutPlanEaves,
    CutProject.custom => pText.cutPlanCustom,
  };

  Future<void> _addPiece() async {
    final vPiece = await showDialog<ProjectPiece>(
      context: context,
      builder: (_) => const ProjectPieceDialog(),
    );
    if (vPiece != null) {
      setState(() => _pieces = [..._pieces, vPiece]);
    }
  }

  String _pieceLine(AppLocalizations pText, int pIndex) {
    final vPiece = _pieces[pIndex];
    final vName = pieceNameLabel(pText, vPiece.name);
    final rLine = vPiece.kind == StockKind.bar
        ? pText.cutPlanPieceBar(
            pIndex + 1,
            vName,
            vPiece.count,
            formatCentimetres(vPiece.lengthMm),
            vPiece.widthMm,
            vPiece.thicknessMm,
          )
        : pText.cutPlanPiecePanel(
            pIndex + 1,
            vName,
            vPiece.count,
            formatCentimetres(vPiece.lengthMm),
            formatCentimetres(vPiece.widthMm),
            vPiece.thicknessMm,
          );

    return rLine;
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vPlan = planProjectCutting(_pieces, pKerfMm: _kerf, pRotate: _rotate);
    String vCm(int pMm) => formatCentimetres(pMm);
    final vCuts =
        vPlan.bars.fold(0, (pSum, pBar) => pSum + pBar.cuts) +
        vPlan.panels.fold(0, (pSum, pPanel) => pSum + pPanel.cuts);
    final vKerfLoss =
        vPlan.bars.fold(0, (pSum, pBar) => pSum + pBar.kerfLossMm) +
        vPlan.panels.fold(0, (pSum, pPanel) => pSum + pPanel.kerfLossMm);
    final vOffcuts = [for (final vBar in vPlan.bars) ...vBar.plan.reusableOffcuts]
      ..sort((pA, pB) => pB.compareTo(pA));
    final vTooLong = vPlan.bars.fold(0, (pSum, pBar) => pSum + pBar.plan.tooLong.length);
    final vTooBig = vPlan.panels.fold(0, (pSum, pPanel) => pSum + pPanel.plan.tooBig.length);
    final vItems = [
      for (final vBar in vPlan.bars)
        for (final vBuy in barsToBuy(vBar.plan))
          ExtraItem(
            name: vText.cutPlanBuyBar(vBar.widthMm, vBar.thicknessMm, vCm(vBuy.lengthMm)),
            quantity: vBuy.count,
          ),
      for (final vPanel in vPlan.panels)
        ExtraItem(
          name: vText.cutPlanBuyPanel(
            vPanel.thicknessMm,
            vCm(vPanel.lengthMm),
            vCm(vPanel.widthMm),
          ),
          quantity: vPanel.plan.panels.length,
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(vText.cutPlanTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPiece,
        icon: const Icon(Icons.add),
        label: Text(vText.panelAddPart),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final vProject in CutProject.values)
                ChoiceChip(
                  label: Text(_projectLabel(vText, vProject)),
                  selected: _project == vProject,
                  onSelected: (_) => setState(() {
                    _project = vProject;
                    _pieces = projectPieces(vProject);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_pieces.isEmpty) Text(vText.cutPlanEmpty),
                  for (final vBar in vPlan.bars)
                    IconLine(
                      Icons.straighten,
                      vText.cutPlanBarResult(
                        vBar.widthMm,
                        vBar.thicknessMm,
                        [
                          for (final vBuy in barsToBuy(vBar.plan))
                            vText.cutPlanBarCount(vBuy.count, vCm(vBuy.lengthMm)),
                        ].join(', '),
                      ),
                    ),
                  for (final vPanel in vPlan.panels)
                    IconLine(
                      Icons.dashboard_outlined,
                      vText.cutPlanPanelResult(
                        vPanel.thicknessMm,
                        vText.panelCount(vPanel.plan.panels.length),
                        vCm(vPanel.lengthMm),
                        vCm(vPanel.widthMm),
                      ),
                    ),
                  if (_pieces.isNotEmpty)
                    IconLine(Icons.content_cut, vText.cutPlanKerf(vCuts, vCm(vKerfLoss))),
                  if (vOffcuts.isNotEmpty)
                    IconLine(
                      Icons.recycling,
                      vText.cutPlanOffcuts([for (final vMm in vOffcuts) vCm(vMm)].join(', ')),
                    ),
                  if (vTooLong + vTooBig > 0)
                    IconLine(
                      AtelierIcons.warning,
                      vText.cutPlanTooBig(vTooLong + vTooBig),
                      color: vTheme.colorScheme.error,
                    ),
                  AddToShoppingButton(items: () => vItems),
                ],
              ),
            ),
          ),
          for (final vBar in vPlan.bars) ...[
            const SizedBox(height: 16),
            Text(
              vText.cutPlanBarGroup(vBar.widthMm, vBar.thicknessMm),
              style: vTheme.textTheme.titleSmall,
            ),
            for (final vCutBar in vBar.plan.bars) ...[
              const SizedBox(height: 6),
              Text(vText.cutPlanBarLabel(vCm(vCutBar.barMm)), style: vTheme.textTheme.bodySmall),
              BarCutStrip(
                bar: vCutBar,
                kerfMm: _kerf,
                label: (pPosition) => '${vBar.pieceOf[vCutBar.pieceIndexes[pPosition]] + 1}',
              ),
            ],
          ],
          for (final vPanel in vPlan.panels) ...[
            const SizedBox(height: 16),
            Text(
              vText.cutPlanPanelGroup(
                vPanel.thicknessMm,
                vCm(vPanel.lengthMm),
                vCm(vPanel.widthMm),
              ),
              style: vTheme.textTheme.titleSmall,
            ),
            for (var vIndex = 0; vIndex < vPanel.plan.panels.length; vIndex++) ...[
              const SizedBox(height: 6),
              Text(vText.panelNumber(vIndex + 1), style: vTheme.textTheme.bodySmall),
              AspectRatio(
                aspectRatio: vPanel.lengthMm / vPanel.widthMm,
                child: CustomPaint(
                  painter: PanelCutPainter(
                    panel: vPanel.plan.panels[vIndex],
                    colors: AtelierColors.of(context),
                    style: vTheme.textTheme.labelSmall!,
                    label: (pPart) => '${vPanel.pieceOf[pPart] + 1}',
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          Text(vText.panelParts, style: vTheme.textTheme.titleMedium),
          for (var vIndex = 0; vIndex < _pieces.length; vIndex++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_pieceLine(vText, vIndex)),
              trailing: IconButton(
                tooltip: vText.delete,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(
                  () => _pieces = [
                    for (var vOther = 0; vOther < _pieces.length; vOther++)
                      if (vOther != vIndex) _pieces[vOther],
                  ],
                ),
              ),
            ),
          NumberField<int>(
            label: vText.panelKerf,
            initial: '$_kerf',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _kerf = pValue),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(vText.panelRotate),
            subtitle: Text(vText.panelRotateHelp),
            value: _rotate,
            onChanged: (pValue) => setState(() => _rotate = pValue),
          ),
          const TermsRow([Term.kerf, Term.grain]),
          Text(vText.cutPlanHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
