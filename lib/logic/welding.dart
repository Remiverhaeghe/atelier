/// Soudure : procédé conseillé selon le métal, l'épaisseur et le lieu, et réglages de départ.
///
/// Réglages indicatifs, à affiner par un essai sur une chute du même métal.
library;

enum Metal { steel, stainless, aluminium }

enum WeldProcess {
  /// Électrode enrobée (MMA).
  stick,

  /// Fil plein sous gaz (MIG pour l'alu à l'argon, MAG pour l'acier à l'argon et CO2).
  migMag,

  /// Fil fourré sans gaz, qui supporte le vent.
  fluxCore,

  /// Électrode de tungstène et métal d'apport (TIG).
  tig,
}

/// Réglage de départ : intensité, et diamètre d'électrode, de fil ou de tungstène.
typedef WeldSetting = ({WeldProcess process, int minAmps, int maxAmps, double diameterMm});

/// Procédés possibles, du plus conseillé au moins conseillé ; dehors, pas de gaz qui s'envole.
List<WeldProcess> rankProcesses(Metal pMetal, double pThicknessMm, {bool pOutdoor = false}) {
  final rProcesses = switch (pMetal) {
    Metal.aluminium => [WeldProcess.tig, WeldProcess.migMag],
    Metal.stainless => pThicknessMm < 3
        ? [WeldProcess.tig, WeldProcess.migMag, WeldProcess.stick]
        : [WeldProcess.migMag, WeldProcess.tig, WeldProcess.stick],
    Metal.steel => pThicknessMm < 1.5
        ? [WeldProcess.migMag, WeldProcess.tig, WeldProcess.fluxCore]
        : [WeldProcess.migMag, WeldProcess.stick, WeldProcess.fluxCore, WeldProcess.tig],
  };
  if (!pOutdoor) {
    return rProcesses;
  }
  // Dehors, le gaz de protection part au vent : électrode et fil fourré d'abord
  final vOutdoor = [
    for (final vProcess in [WeldProcess.stick, WeldProcess.fluxCore])
      if (rProcesses.contains(vProcess)) vProcess,
    for (final vProcess in rProcesses)
      if (vProcess != WeldProcess.stick && vProcess != WeldProcess.fluxCore) vProcess,
  ];

  return vOutdoor;
}

/// Réglage de départ d'un procédé pour une épaisseur.
WeldSetting weldSetting(WeldProcess pProcess, double pThicknessMm) {
  final vThick = pThicknessMm <= 0 ? 1.0 : pThicknessMm;
  switch (pProcess) {
    case WeldProcess.stick:
      // Électrode selon l'épaisseur, environ 40 A par millimètre de diamètre
      final vDiameter = vThick <= 2
          ? 2.0
          : vThick <= 4
          ? 2.5
          : vThick <= 6
          ? 3.2
          : 4.0;
      return (
        process: pProcess,
        minAmps: (vDiameter * 35).round(),
        maxAmps: (vDiameter * 45).round(),
        diameterMm: vDiameter,
      );
    case WeldProcess.migMag || WeldProcess.fluxCore:
      final vWire = vThick <= 2 ? 0.6 : (vThick <= 5 ? 0.8 : 1.0);
      return (
        process: pProcess,
        minAmps: (vThick * 30).round(),
        maxAmps: (vThick * 40).round(),
        diameterMm: vWire,
      );
    case WeldProcess.tig:
      return (
        process: pProcess,
        minAmps: (vThick * 30).round(),
        maxAmps: (vThick * 40).round(),
        diameterMm: vThick <= 3 ? 1.6 : 2.4,
      );
  }
}
