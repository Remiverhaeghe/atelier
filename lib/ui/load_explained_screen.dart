import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/load_explained.dart';
import '../logic/shelf.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'sketch3d.dart';
import 'theme.dart';

/// Ce qui est chargé : une tablette, une poutre ou le plancher d'une mezzanine.
enum LoadedKind { shelf, beam, mezzanine }

String everydayName(AppLocalizations pText, EverydayLoad pLoad) => switch (pLoad) {
  EverydayLoad.booksBox => pText.loadBooks,
  EverydayLoad.waterPack => pText.loadWater,
  EverydayLoad.adult => pText.loadAdult,
  EverydayLoad.cementBag => pText.loadCement,
  EverydayLoad.washingMachine => pText.loadWasher,
};

String _materialName(AppLocalizations pText, ShelfMaterial pMaterial) => switch (pMaterial) {
  ShelfMaterial.particleBoard => pText.loadParticle,
  ShelfMaterial.mdf => pText.loadMdf,
  ShelfMaterial.plywood => pText.loadPlywood,
  ShelfMaterial.solidWood => pText.loadSolid,
};

/// Taille dessinée d'un objet : longueur, profondeur, hauteur.
(double, double, double) _objectSize(EverydayLoad pLoad) => switch (pLoad) {
  EverydayLoad.booksBox => (350, 300, 300),
  EverydayLoad.waterPack => (250, 170, 330),
  EverydayLoad.adult => (400, 300, 1700),
  EverydayLoad.cementBag => (600, 400, 150),
  EverydayLoad.washingMachine => (600, 600, 850),
};

/// Ce que porte une étagère, une poutre ou une mezzanine, en objets du quotidien, avec la
/// flèche exagérée sur le croquis.
class LoadExplainedScreen extends StatefulWidget {
  const LoadExplainedScreen({super.key});

  @override
  State<LoadExplainedScreen> createState() => _LoadExplainedScreenState();
}

class _LoadExplainedScreenState extends State<LoadExplainedScreen> {
  var _kind = LoadedKind.shelf;
  var _load = EverydayLoad.booksBox;
  var _count = 1;
  var _material = ShelfMaterial.particleBoard;
  var _spanMm = 800;
  var _depthMm = 300;
  var _thicknessMm = 18;
  var _widthMm = 63;
  var _heightMm = 175;
  var _beamSpanMm = 3000;
  var _spacingMm = 400;
  var _mezzDepthMm = 2000;
  var _mezzLengthMm = 3000;

  LoadedMember _member() => switch (_kind) {
    LoadedKind.shelf => shelfMember(_spanMm, _depthMm, _thicknessMm, _material),
    LoadedKind.beam => beamMember((widthMm: _widthMm, heightMm: _heightMm), _beamSpanMm),
    LoadedKind.mezzanine => mezzanineMember(
      (widthMm: _widthMm, heightMm: _heightMm),
      _spacingMm,
      _mezzDepthMm,
      _mezzLengthMm,
    ),
  };

  NumberField<int> _field(String pLabel, int pValue, bool pCm, ValueChanged<int> pSet) =>
      NumberField<int>(
        key: ValueKey('$_kind-$pLabel'),
        label: pLabel,
        initial: pCm ? formatCentimetres(pValue) : '$pValue',
        parse: pCm ? parseCentimetres : parseWhole,
        onValue: (pNew) => setState(() => pSet(pNew)),
      );

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vMember = _member();
    final vLoaded = loadedDeflection(vMember, _load, _count);
    final vHeld = objectsHeld(vMember, _load);
    final vMaxCount = math.max(4, 2 * vHeld + 2);
    final vCount = math.min(_count, vMaxCount);

    return Scaffold(
      appBar: AppBar(title: Text(vText.loadTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SegmentedButton<LoadedKind>(
            segments: [
              ButtonSegment(value: LoadedKind.shelf, label: Text(vText.loadShelf)),
              ButtonSegment(value: LoadedKind.beam, label: Text(vText.loadBeam)),
              ButtonSegment(value: LoadedKind.mezzanine, label: Text(vText.loadMezzanine)),
            ],
            selected: {_kind},
            onSelectionChanged: (pKinds) => setState(() => _kind = pKinds.first),
          ),
          AspectRatio(
            aspectRatio: 1.6,
            child: LoadSketch(
              member: vMember,
              load: _load,
              count: vCount,
              thicknessMm: switch (_kind) {
                LoadedKind.shelf => _thicknessMm,
                _ => _heightMm,
              },
              depthMm: _kind == LoadedKind.shelf ? _depthMm : _widthMm,
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BigFigure(vText.loadHolds(vMember.maxKg.round())),
                  for (final vObject in EverydayLoad.values)
                    IconLine(
                      vObject == _load ? Icons.arrow_right : Icons.inventory_2_outlined,
                      vText.loadObjects(
                        objectsHeld(vMember, vObject),
                        everydayName(vText, vObject),
                      ),
                    ),
                  const SizedBox(height: 8),
                  IconLine(
                    vLoaded.tooMuch ? AtelierIcons.warning : Icons.check,
                    vText.loadDeflection(
                      vCount,
                      everydayName(vText, _load),
                      formatDecimal(vLoaded.deflectionMm),
                      formatDecimal(vMember.limitMm),
                    ),
                    color: vLoaded.tooMuch ? vTheme.colorScheme.error : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final vObject in EverydayLoad.values)
                ChoiceChip(
                  label: Text(everydayName(vText, vObject)),
                  selected: _load == vObject,
                  onSelected: (_) => setState(() => _load = vObject),
                ),
            ],
          ),
          Text(vText.loadCount(vCount), style: vTheme.textTheme.titleSmall),
          Slider(
            value: vCount.toDouble(),
            min: 0,
            max: vMaxCount.toDouble(),
            divisions: vMaxCount,
            label: '$vCount',
            onChanged: (pValue) => setState(() => _count = pValue.round()),
          ),
          if (_kind == LoadedKind.shelf) ...[
            DropdownButtonFormField<ShelfMaterial>(
              initialValue: _material,
              decoration: InputDecoration(labelText: vText.loadMaterial),
              items: [
                for (final vMaterial in ShelfMaterial.values)
                  DropdownMenuItem(value: vMaterial, child: Text(_materialName(vText, vMaterial))),
              ],
              onChanged: (pValue) => setState(() => _material = pValue ?? _material),
            ),
            _field(vText.loadSpan, _spanMm, true, (pValue) => _spanMm = pValue),
            _field(vText.loadDepth, _depthMm, true, (pValue) => _depthMm = pValue),
            _field(vText.loadThickness, _thicknessMm, false, (pValue) => _thicknessMm = pValue),
          ] else ...[
            _field(vText.loadWidth, _widthMm, false, (pValue) => _widthMm = pValue),
            _field(vText.loadHeight, _heightMm, false, (pValue) => _heightMm = pValue),
            if (_kind == LoadedKind.beam)
              _field(vText.loadSpan, _beamSpanMm, true, (pValue) => _beamSpanMm = pValue)
            else ...[
              _field(vText.loadSpacing, _spacingMm, true, (pValue) => _spacingMm = pValue),
              _field(vText.loadJoistSpan, _mezzDepthMm, true, (pValue) => _mezzDepthMm = pValue),
              _field(vText.loadLength, _mezzLengthMm, true, (pValue) => _mezzLengthMm = pValue),
            ],
          ],
          const SizedBox(height: 8),
          Text(vText.loadHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// La pièce chargée en relief, sur ses deux appuis : la flèche est exagérée pour se voir,
/// les objets posés suivent la courbe.
class LoadSketch extends StatelessWidget {
  const LoadSketch({
    super.key,
    required this.member,
    required this.load,
    required this.count,
    required this.thicknessMm,
    required this.depthMm,
  });

  final LoadedMember member;
  final EverydayLoad load;
  final int count;
  final int thicknessMm;
  final int depthMm;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vSpan = math.max(1, member.spanMm).toDouble();
    final vDeflection = deflectionMm(
      (load.kg * count).toDouble(),
      member.spanMm,
      member.modulusMpa,
      member.inertiaMm4,
    );
    final vScale = drawingScale(vDeflection, member.spanMm);
    final vSag = vDeflection * vScale;
    // Épaisseur grossie si besoin : une tablette de 18 mm sur 80 cm serait un trait
    final vThick = math.max(thicknessMm.toDouble(), vSpan / 30);
    final vDepth = math.max(depthMm.toDouble(), vSpan / 6);
    // Déformée d'une poutre sur deux appuis sous charge répartie, ramenée à 1 au milieu
    double vDown(double pX) {
      final vU = (pX / vSpan).clamp(0.0, 1.0);
      return vSag * 16 / 5 * (vU - 2 * vU * vU * vU + vU * vU * vU * vU);
    }

    const vSegments = 12;
    final vSupport = vSpan / 12;
    final vParts = <Prism>[
      Prism.box(-vSupport, 0, 0, vDepth, -vSpan / 5, 0, role: PartRole.board),
      Prism.box(vSpan, vSpan + vSupport, 0, vDepth, -vSpan / 5, 0, role: PartRole.board),
      for (var vIndex = 0; vIndex < vSegments; vIndex++)
        Prism(
          [
            (vSpan * vIndex / vSegments, -vDown(vSpan * vIndex / vSegments)),
            (vSpan * (vIndex + 1) / vSegments, -vDown(vSpan * (vIndex + 1) / vSegments)),
            (vSpan * (vIndex + 1) / vSegments, vThick - vDown(vSpan * (vIndex + 1) / vSegments)),
            (vSpan * vIndex / vSegments, vThick - vDown(vSpan * vIndex / vSegments)),
          ],
          0,
          vDepth,
          role: count > 0 && loadedDeflection(member, load, count).tooMuch
              ? PartRole.highlight
              : PartRole.wood,
        ),
    ];
    // Au plus huit objets dessinés, réduits pour tenir côte à côte sur la portée
    final vDrawn = math.min(count, 8);
    final (vLength, vWide, vHigh) = _objectSize(load);
    final vFit = vDrawn == 0 ? 1.0 : math.min(1.0, vSpan / vDrawn / (vLength * 1.1));
    for (var vIndex = 0; vIndex < vDrawn; vIndex++) {
      final vCenter = vSpan * (vIndex + 0.5) / vDrawn;
      final vBase = vThick - vDown(vCenter);
      vParts.add(
        Prism.box(
          vCenter - vLength * vFit / 2,
          vCenter + vLength * vFit / 2,
          (vDepth - vWide * vFit) / 2,
          (vDepth + vWide * vFit) / 2,
          vBase,
          vBase + vHigh * vFit,
          role: load == EverydayLoad.adult ? PartRole.ghost : PartRole.board,
        ),
      );
    }

    return Sketch3D(
      parts: vParts,
      callouts: [
        (
          at: (x: vSpan / 2, y: 0.0, z: -vDown(vSpan / 2)),
          text: vText.loadSagLabel(formatDecimal(vDeflection), vScale.round()),
          shift: const Offset(0, 60),
        ),
        (
          at: (x: 0.0, y: 0.0, z: -vSpan / 10),
          text: vText.loadSupportLabel,
          shift: const Offset(-50, 30),
        ),
      ],
    );
  }
}
