import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/colors.dart';
import '../logic/paint.dart';

String harmonyLabel(AppLocalizations pText, Harmony pHarmony) => switch (pHarmony) {
  Harmony.analogous => pText.harmonyAnalogous,
  Harmony.complementary => pText.harmonyComplementary,
  Harmony.soft => pText.harmonySoft,
  Harmony.deep => pText.harmonyDeep,
};

Color _color(int pRgb) => Color(0xFF000000 | pRgb);

/// Pastille de couleur à toucher.
class Swatch extends StatelessWidget {
  const Swatch({super.key, required this.rgb, required this.onTap, this.size = 40});

  final int rgb;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(4),
    child: Semantics(
      button: true,
      label: '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _color(rgb),
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
        ),
      ),
    ),
  );
}

/// Couleurs des murs, du plafond et des boiseries, avec les accords proposés autour des murs.
class ColorSection extends StatelessWidget {
  const ColorSection({super.key, required this.settings, required this.onChanged});

  final PaintSettings settings;
  final ValueChanged<PaintSettings> onChanged;

  Future<void> _pick(BuildContext pContext, String pTitle, ValueChanged<int> pApply) async {
    final vText = AppLocalizations.of(pContext);
    final vWall = settings.wallColor;
    final vPicked = await showModalBottomSheet<int>(
      context: pContext,
      showDragHandle: true,
      builder: (pSheet) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shrinkWrap: true,
        children: [
          Text(pTitle, style: Theme.of(pSheet).textTheme.titleMedium),
          Text(vText.paletteCommon),
          Wrap(
            children: [
              for (final vRgb in wallPalette)
                Swatch(rgb: vRgb, onTap: () => Navigator.pop(pSheet, vRgb)),
            ],
          ),
          if (vWall != null)
            for (final vEntry in harmonies(vWall).entries) ...[
              const SizedBox(height: 8),
              Text(harmonyLabel(vText, vEntry.key)),
              Wrap(
                children: [
                  for (final vRgb in vEntry.value)
                    Swatch(rgb: vRgb, onTap: () => Navigator.pop(pSheet, vRgb)),
                ],
              ),
            ],
        ],
      ),
    );
    if (vPicked != null) {
      pApply(vPicked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vRows = [
      (
        vText.paintWallsSwitch,
        settings.wallColor,
        (int pRgb) => settings.copyWith(wallColor: pRgb),
      ),
      (
        vText.paintCeilingSwitch,
        settings.ceilingColor,
        (int pRgb) => settings.copyWith(ceilingColor: pRgb),
      ),
      (
        vText.paintWoodworkSwitch,
        settings.woodworkColor,
        (int pRgb) => settings.copyWith(woodworkColor: pRgb),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(vText.colorsTitle, style: vTheme.textTheme.titleMedium),
        Text(vText.colorsHelp, style: vTheme.textTheme.bodySmall),
        // Aperçu : la part de chaque couleur à peu près comme dans la pièce
        if (settings.wallColor != null)
          Container(
            height: 48,
            margin: const EdgeInsets.symmetric(vertical: 8),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(flex: 6, child: ColoredBox(color: _color(settings.wallColor!))),
                if (settings.ceilingColor != null)
                  Expanded(flex: 3, child: ColoredBox(color: _color(settings.ceilingColor!))),
                if (settings.woodworkColor != null)
                  Expanded(child: ColoredBox(color: _color(settings.woodworkColor!))),
              ],
            ),
          ),
        for (final (vLabel, vRgb, vApply) in vRows)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(vLabel),
            subtitle: Text(vRgb == null ? vText.colorNone : vText.colorChosen),
            trailing: vRgb == null
                ? const Icon(Icons.palette_outlined)
                : Swatch(
                    rgb: vRgb,
                    onTap: () => _pick(context, vLabel, (pRgb) => onChanged(vApply(pRgb))),
                  ),
            onTap: () => _pick(context, vLabel, (pRgb) => onChanged(vApply(pRgb))),
          ),
      ],
    );
  }
}
