import 'package:flutter/material.dart';

import 'notebook.dart';

/// Couleurs propres à Atelier, en plus du schéma Material : mesures, bois, papier quadrillé.
@immutable
class AtelierColors extends ThemeExtension<AtelierColors> {
  const AtelierColors({
    required this.tape,
    required this.onTape,
    required this.wood,
    required this.woodLaid,
    required this.grid,
    required this.ink,
  });

  /// Jaune mètre ruban : réservé aux cotes et aux mesures.
  final Color tape;
  final Color onTape;

  /// Lame de chêne à poser, et lame déjà posée.
  final Color wood;
  final Color woodLaid;

  /// Quadrillage du plan, un carreau par mètre.
  final Color grid;

  /// Trait des murs.
  final Color ink;

  static AtelierColors of(BuildContext pContext) => Theme.of(pContext).extension<AtelierColors>()!;

  @override
  AtelierColors copyWith({
    Color? tape,
    Color? onTape,
    Color? wood,
    Color? woodLaid,
    Color? grid,
    Color? ink,
  }) => AtelierColors(
    tape: tape ?? this.tape,
    onTape: onTape ?? this.onTape,
    wood: wood ?? this.wood,
    woodLaid: woodLaid ?? this.woodLaid,
    grid: grid ?? this.grid,
    ink: ink ?? this.ink,
  );

  @override
  AtelierColors lerp(AtelierColors? pOther, double pT) {
    if (pOther == null) {
      return this;
    }

    return AtelierColors(
      tape: Color.lerp(tape, pOther.tape, pT)!,
      onTape: Color.lerp(onTape, pOther.onTape, pT)!,
      wood: Color.lerp(wood, pOther.wood, pT)!,
      woodLaid: Color.lerp(woodLaid, pOther.woodLaid, pT)!,
      grid: Color.lerp(grid, pOther.grid, pT)!,
      ink: Color.lerp(ink, pOther.ink, pT)!,
    );
  }
}

const _pine = Color(0xFF1F5A3A);
const _tape = Color(0xFFF2B230);
const _graphite = Color(0xFF24302B);

/// Police du texte courant.
const bodyFont = 'Barlow';

/// Police des titres et des grands nombres, plus étroite.
const titleFont = 'BarlowSemiCondensed';

/// Écriture manuscrite des cotes et des notes sur les croquis du carnet.
const handFont = 'Caveat';

/// Thème clair ou sombre de l'application.
/// Mode nuit du chantier : rouge très sombre, qui n'éblouit pas sous les combles et garde la
/// vision de nuit, avec des textes agrandis.
ThemeData nightTheme(ThemeData pBase) {
  const vRed = Color(0xFFFF5A4E);
  final vScheme = pBase.colorScheme.copyWith(
    brightness: Brightness.dark,
    primary: vRed,
    onPrimary: Colors.black,
    surface: Colors.black,
    onSurface: vRed,
    surfaceContainerLow: const Color(0xFF140303),
    surfaceContainer: const Color(0xFF1C0505),
    surfaceContainerHigh: const Color(0xFF240707),
    onSurfaceVariant: const Color(0xFFC94036),
    outline: const Color(0xFF7A1F19),
    outlineVariant: const Color(0xFF3D0E0B),
  );
  final rTheme = pBase.copyWith(
    colorScheme: vScheme,
    scaffoldBackgroundColor: Colors.black,
    // Pas de ruban ni d'ombre la nuit : une fiche sombre, simple
    cardTheme: pBase.cardTheme.copyWith(
      color: vScheme.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: vScheme.outlineVariant),
      ),
    ),
    appBarTheme: pBase.appBarTheme.copyWith(backgroundColor: Colors.black, foregroundColor: vRed),
    textTheme: pBase.textTheme.apply(bodyColor: vRed, displayColor: vRed, fontSizeFactor: 1.15),
    iconTheme: pBase.iconTheme.copyWith(color: vRed),
  );

  return rTheme;
}

ThemeData atelierTheme(Brightness pBrightness) {
  final vDark = pBrightness == Brightness.dark;
  final vScheme = ColorScheme.fromSeed(seedColor: _pine, brightness: pBrightness).copyWith(
    primary: vDark ? const Color(0xFF8CCFA4) : _pine,
    onPrimary: vDark ? const Color(0xFF0D2618) : Colors.white,
    surface: vDark ? const Color(0xFF131A16) : const Color(0xFFF1F4F0),
    onSurface: vDark ? const Color(0xFFE2EAE4) : _graphite,
    surfaceContainerLowest: vDark ? const Color(0xFF0F1512) : Colors.white,
    surfaceContainerLow: vDark ? const Color(0xFF1A221D) : const Color(0xFFFFFFFF),
    surfaceContainer: vDark ? const Color(0xFF1D2621) : const Color(0xFFE9EEE9),
    surfaceContainerHigh: vDark ? const Color(0xFF232D27) : const Color(0xFFE2E9E3),
    outlineVariant: vDark ? const Color(0xFF34413A) : const Color(0xFFD3DCD5),
    tertiary: _tape,
    onTertiary: _graphite,
  );
  final vColors = AtelierColors(
    tape: _tape,
    onTape: _graphite,
    wood: vDark ? const Color(0xFF6E5638) : const Color(0xFFE3C9A4),
    woodLaid: vDark ? const Color(0xFFB58A55) : const Color(0xFFC79A63),
    grid: vDark ? const Color(0xFF1F2924) : const Color(0xFFDDE5DF),
    ink: vScheme.onSurface,
  );
  final vBase = ThemeData(colorScheme: vScheme, useMaterial3: true, fontFamily: bodyFont);
  final vText = vBase.textTheme;
  TextStyle vTitle(TextStyle? pStyle, FontWeight pWeight) =>
      pStyle!.copyWith(fontFamily: titleFont, fontWeight: pWeight, letterSpacing: 0);

  return vBase.copyWith(
    // Densité standard : cibles de 48 dp, utiles avec des gants sur un chantier. « comfortable »
    // les ramène à 44 dp, sous le minimum d'Android.
    visualDensity: VisualDensity.standard,
    extensions: [vColors],
    // Fond transparent : chaque écran est posé sur la feuille quadrillée du carnet
    // (NotebookPageTransitionsBuilder), qui elle est opaque.
    scaffoldBackgroundColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: NotebookPageTransitionsBuilder(),
        TargetPlatform.iOS: NotebookPageTransitionsBuilder(),
        TargetPlatform.linux: NotebookPageTransitionsBuilder(),
        TargetPlatform.macOS: NotebookPageTransitionsBuilder(),
        TargetPlatform.windows: NotebookPageTransitionsBuilder(),
        TargetPlatform.fuchsia: NotebookPageTransitionsBuilder(),
      },
    ),
    textTheme: vText.copyWith(
      displaySmall: vTitle(vText.displaySmall, FontWeight.w600),
      headlineMedium: vTitle(vText.headlineMedium, FontWeight.w600),
      headlineSmall: vTitle(vText.headlineSmall, FontWeight.w600),
      titleLarge: vTitle(vText.titleLarge, FontWeight.w600),
      titleMedium: vText.titleMedium!.copyWith(fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: vScheme.surface,
      foregroundColor: vScheme.onSurface,
      scrolledUnderElevation: 0,
      titleTextStyle: vTitle(
        vText.titleLarge,
        FontWeight.w600,
      ).copyWith(fontSize: 24, color: vScheme.onSurface),
    ),
    // Fiches de carnet : bord de papier, ruban adhésif, ombre légère de feuille posée
    cardTheme: CardThemeData(
      elevation: 1.5,
      shadowColor: const Color(0x55402A10),
      color: vScheme.surfaceContainerLow,
      shape: PaperCardBorder(
        side: BorderSide(color: vScheme.outlineVariant),
        tape: _tape,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
    ),
    tabBarTheme: TabBarThemeData(
      labelStyle: vTitle(vText.titleSmall, FontWeight.w600).copyWith(fontSize: 16),
      unselectedLabelStyle: vTitle(vText.titleSmall, FontWeight.w500).copyWith(fontSize: 16),
      indicatorSize: TabBarIndicatorSize.label,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: vScheme.primary, width: 3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      ),
      dividerColor: vScheme.outlineVariant,
      tabAlignment: TabAlignment.start,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: vScheme.surfaceContainer,
      // Libellé dans la case remplie, et non sur un trait qui chevaucherait le champ du dessus
      border: UnderlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: UnderlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: UnderlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: vScheme.primary, width: 2),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: vScheme.primary,
      foregroundColor: vScheme.onPrimary,
      elevation: 2,
      extendedTextStyle: vTitle(vText.titleMedium, FontWeight.w600).copyWith(fontSize: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: vScheme.primary,
      linearTrackColor: vScheme.outlineVariant,
      linearMinHeight: 6,
      borderRadius: BorderRadius.circular(3),
    ),
    dividerTheme: DividerThemeData(color: vScheme.outlineVariant, space: 1),
    listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 20)),
  );
}

/// Grand nombre d'un résultat (paquets, barres, total), dans la police des titres.
class BigFigure extends StatelessWidget {
  const BigFigure(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final vTheme = Theme.of(context);

    return Text(
      text,
      style: vTheme.textTheme.headlineMedium!.copyWith(
        color: vTheme.colorScheme.primary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Ligne de résultat précédée de son icône, pour lire la liste d'un coup d'œil.
class IconLine extends StatelessWidget {
  const IconLine(this.icon, this.text, {super.key, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final vColors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color ?? vColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}

/// Icônes communes aux onglets, aux résultats et aux listes.
abstract final class AtelierIcons {
  static const room = Icons.square_foot;
  static const touchUps = Icons.checklist;
  static const parquet = Icons.view_stream_outlined;
  static const laying = Icons.format_list_numbered;
  static const baseboard = Icons.carpenter;
  static const guide = Icons.menu_book_outlined;
  static const paint = Icons.format_paint_outlined;
  static const area = Icons.crop_free;
  static const planks = Icons.reorder;
  static const underlay = Icons.layers_outlined;
  static const glue = Icons.format_color_fill;
  static const nails = Icons.push_pin_outlined;
  static const cartridges = Icons.colorize;
  static const rows = Icons.density_medium;
  static const length = Icons.straighten;
  static const warning = Icons.warning_amber;
}

/// Cote sur étiquette jaune mètre ruban, comme sur le plan.
class TapeLabel extends StatelessWidget {
  const TapeLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final vColors = AtelierColors.of(context);

    return Container(
      constraints: const BoxConstraints(minWidth: 52),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: vColors.tape, borderRadius: BorderRadius.circular(6)),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: titleFont,
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: vColors.onTape,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
