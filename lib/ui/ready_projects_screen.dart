import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/extra_items.dart';
import '../logic/ready_projects.dart';
import '../logic/units.dart';
import 'gestures_screen.dart';
import 'parquet_view.dart';
import 'ready_projects_texts.dart';
import 'shopping_target.dart';
import 'sketch3d.dart';
import 'theme.dart';
import 'work_sheet_pdf.dart';
import 'workshop_mode_screen.dart';

/// Projets modèles : un par carte, à ouvrir pour régler les cotes.
class ReadyProjectsScreen extends StatelessWidget {
  const ReadyProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vShopping = ShoppingTarget.maybeOf(context);

    return Scaffold(
      appBar: AppBar(title: Text(vText.readyTitle)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(vText.readyIntro, style: Theme.of(context).textTheme.bodyMedium),
          ),
          for (final vProject in ReadyProject.values)
            Card(
              child: ListTile(
                title: Text(readyProjectName(vText, vProject)),
                subtitle: Text(readyProjectIntro(vText, vProject)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    // La cible des courses suit le projet ouvert, comme pour les autres calculs
                    builder: (_) => vShopping == null
                        ? ReadyProjectScreen(project: vProject)
                        : ShoppingTarget(
                            worksites: vShopping.worksites,
                            add: vShopping.add,
                            child: ReadyProjectScreen(project: vProject),
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Un projet : cotes, croquis, débit, courses et étapes reliées aux gestes.
class ReadyProjectScreen extends StatefulWidget {
  const ReadyProjectScreen({super.key, required this.project});

  final ReadyProject project;

  @override
  State<ReadyProjectScreen> createState() => _ReadyProjectScreenState();
}

class _ReadyProjectScreenState extends State<ReadyProjectScreen> {
  late ProjectSize _size = defaultSize(widget.project);

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vProject = widget.project;
    final vUsed = usedSizes(vProject);
    final vValid = sizeIsValid(vProject, _size);
    final vPlan = projectPlan(vProject, _size);
    final vParts = [
      for (final vPart in vPlan.parts)
        vText.readyPart(
          vPart.count,
          partName(vText, vPart.kind),
          formatCentimetres(vPart.lengthMm),
          vPart.widthMm,
          vPart.thicknessMm,
        ),
    ];
    final vBuy = [
      for (final vItem in vPlan.buy)
        ExtraItem(name: buyName(vText, vItem.kind), quantity: vItem.quantity),
    ];
    final vSteps = [for (final vStep in vPlan.steps) readyStepLabel(vText, vStep.kind)];
    final vGlass = frameGlass(_size);

    return Scaffold(
      appBar: AppBar(
        title: Text(readyProjectName(vText, vProject)),
        actions: [
          if (vValid)
            PrintSheetButton(
              sheet: () => (
                title: readyProjectName(vText, vProject),
                intro: readyProjectIntro(vText, vProject),
                measures: [
                  if (vUsed.width) (vText.readyWidth, formatCentimetres(_size.widthMm)),
                  if (vUsed.height) (vText.readyHeight, formatCentimetres(_size.heightMm)),
                  if (vUsed.depth) (vText.readyDepth, formatCentimetres(_size.depthMm)),
                ],
                results: vParts,
                buy: vBuy,
                steps: vSteps,
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(readyProjectIntro(vText, vProject), style: vTheme.textTheme.bodyMedium),
          if (vUsed.width)
            NumberField<int>(
              label: vText.readyWidth,
              initial: formatCentimetres(_size.widthMm),
              parse: parseCentimetres,
              onValue: (pValue) => setState(
                () => _size = (widthMm: pValue, heightMm: _size.heightMm, depthMm: _size.depthMm),
              ),
            ),
          if (vUsed.height)
            NumberField<int>(
              label: vText.readyHeight,
              initial: formatCentimetres(_size.heightMm),
              parse: parseCentimetres,
              onValue: (pValue) => setState(
                () => _size = (widthMm: _size.widthMm, heightMm: pValue, depthMm: _size.depthMm),
              ),
            ),
          if (vUsed.depth)
            NumberField<int>(
              label: vText.readyDepth,
              initial: formatCentimetres(_size.depthMm),
              parse: parseCentimetres,
              onValue: (pValue) => setState(
                () => _size = (widthMm: _size.widthMm, heightMm: _size.heightMm, depthMm: pValue),
              ),
            ),
          const SizedBox(height: 12),
          if (!vValid)
            IconLine(Icons.warning_amber, vText.readyInvalid, color: vTheme.colorScheme.error)
          else ...[
            AspectRatio(
              aspectRatio: 1.3,
              child: ReadyProjectSketch(project: vProject, size: _size),
            ),
            if (vProject == ReadyProject.fixedFrame)
              IconLine(
                Icons.window_outlined,
                vText.readyGlass(
                  formatCentimetres(vGlass.widthMm),
                  formatCentimetres(vGlass.heightMm),
                ),
              ),
            if (vProject == ReadyProject.mezzanine)
              IconLine(
                Icons.warning_amber,
                vText.readyMezzanineWarning,
                color: vTheme.colorScheme.error,
              ),
            const SizedBox(height: 8),
            Text(vText.readyCutTitle, style: vTheme.textTheme.titleMedium),
            for (final vLine in vParts) IconLine(Icons.straighten, vLine),
            const SizedBox(height: 12),
            Text(vText.readyBuyTitle, style: vTheme.textTheme.titleMedium),
            for (final vItem in vBuy)
              IconLine(
                Icons.shopping_basket_outlined,
                vText.readyBuyLine(vItem.quantity, vItem.name),
              ),
            AddToShoppingButton(items: () => vBuy),
            const SizedBox(height: 12),
            Text(vText.readyStepsTitle, style: vTheme.textTheme.titleMedium),
            for (final (vIndex, vStep) in vPlan.steps.indexed)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text('${vIndex + 1}')),
                title: Text(vSteps[vIndex]),
                subtitle: vStep.gesture == null ? null : Text(gestureName(vText, vStep.gesture!)),
                trailing: vStep.gesture == null
                    ? null
                    : IconButton(
                        tooltip: vText.readyShowGesture,
                        icon: const Icon(Icons.play_circle_outline),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => GestureScreen(gesture: vStep.gesture!),
                          ),
                        ),
                      ),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      WorkshopModeScreen(title: readyProjectName(vText, vProject), steps: vSteps),
                ),
              ),
              icon: const Icon(Icons.timer_outlined),
              label: Text(vText.readyFollow),
            ),
          ],
        ],
      ),
    );
  }
}

/// Croquis en relief du projet, aux cotes saisies.
class ReadyProjectSketch extends StatelessWidget {
  const ReadyProjectSketch({super.key, required this.project, required this.size});

  final ReadyProject project;
  final ProjectSize size;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vW = size.widthMm.toDouble();
    final vH = size.heightMm.toDouble();
    final vD = size.depthMm.toDouble();
    Callout vLabel(P3 pAt, PartKind pKind, Offset pShift) =>
        (at: pAt, text: partName(vText, pKind), shift: pShift);

    final rSketch = switch (project) {
      ReadyProject.wallShelf => Sketch3D(
        parts: [
          Prism.box(-100, vW + 100, vD, vD + 20, 0, 600, role: PartRole.ghost),
          Prism.box(20, vW - 20, vD - 22, vD, 255, 300, role: PartRole.highlight),
          Prism.box(0, vW, 0, vD, 300, 322),
        ],
        callouts: [
          vLabel((x: vW / 2, y: 0.0, z: 322.0), PartKind.shelfBoard, const Offset(-20, -50)),
          vLabel((x: vW - 20, y: vD, z: 270.0), PartKind.cleat, const Offset(50, 40)),
        ],
      ),
      ReadyProject.fixedFrame => Sketch3D(
        parts: [
          Prism.box(
            frameSectionMm - 9.0,
            vW - frameSectionMm + 9,
            20,
            26,
            frameSectionMm - 9.0,
            vH - frameSectionMm + 9,
            role: PartRole.glass,
          ),
          Prism.box(0, frameSectionMm.toDouble(), 0, 45, 0, vH),
          Prism.box(vW - frameSectionMm, vW, 0, 45, 0, vH),
          Prism.box(frameSectionMm.toDouble(), vW - frameSectionMm, 0, 45, 0, 58),
          Prism.box(frameSectionMm.toDouble(), vW - frameSectionMm, 0, 45, vH - 58, vH),
        ],
        callouts: [
          vLabel((x: 0.0, y: 0.0, z: vH * 0.6), PartKind.stile, const Offset(-50, 0)),
          vLabel((x: vW / 2, y: 0.0, z: 0.0), PartKind.rail, const Offset(0, 40)),
        ],
      ),
      ReadyProject.mezzanine => Sketch3D(
        parts: [
          Prism.box(-100, vW + 100, vD, vD + 40, 0, vH + 600, role: PartRole.ghost),
          Prism.box(0, 90, 0, 90, 0, vH),
          Prism.box(vW - 90, vW, 0, 90, 0, vH),
          Prism.box(0, vW, vD - 45, vD, vH, vH + 195, role: PartRole.highlight),
          for (var vX = 0.0; vX <= vW - 45; vX += joistSpacingMm)
            Prism.box(vX, vX + 45, 70, vD - 45, vH + 25, vH + 220),
          Prism.box(0, vW, 0, 70, vH, vH + 220),
        ],
        callouts: [
          vLabel((x: 45.0, y: 0.0, z: vH / 2), PartKind.post, const Offset(-50, 0)),
          vLabel((x: vW / 2, y: 0.0, z: vH), PartKind.frontBeam, const Offset(0, 50)),
          vLabel((x: vW, y: vD, z: vH + 195), PartKind.ledger, const Offset(40, -30)),
        ],
      ),
      ReadyProject.roofReveal => Sketch3D(
        parts: [
          Prism.box(0, vW, vD, vD + 10, 0, vH, role: PartRole.glass),
          Prism.box(-13, 0, 0, vD, -13, vH + 13, role: PartRole.board),
          Prism.box(vW, vW + 13, 0, vD, -13, vH + 13, role: PartRole.board),
          Prism.box(0, vW, 0, vD, vH, vH + 13, role: PartRole.board),
          Prism.box(0, vW, 0, vD, -13, 0, role: PartRole.board),
        ],
        callouts: [
          vLabel((x: -13.0, y: 0.0, z: vH / 2), PartKind.sideBoard, const Offset(-40, 0)),
          vLabel((x: vW / 2, y: 0.0, z: vH + 13), PartKind.headBoard, const Offset(0, -40)),
          vLabel((x: vW / 2, y: 0.0, z: -13.0), PartKind.sillBoard, const Offset(0, 40)),
        ],
      ),
    };

    return rSketch;
  }
}
