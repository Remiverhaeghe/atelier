/// Réglages d'affichage de l'application : thème et taille du texte.
library;

import 'challenges.dart';

/// Thème : celui du téléphone, clair ou sombre.
enum ThemeChoice { system, light, dark }

/// Tailles de texte proposées : normale, grande (lecture de loin), très grande (avec des gants).
const textScales = [1.0, 1.15, 1.3];

/// Délai après lequel une sauvegarde hors du téléphone est conseillée.
const externalBackupDays = 7;

/// Vrai s'il est temps d'envoyer une sauvegarde ailleurs (Drive, carte SD, ordinateur).
bool externalBackupDue(DateTime? pLast, DateTime pNow) =>
    pLast == null || pNow.difference(pLast).inDays >= externalBackupDays;

class AppSettings {
  const AppSettings({
    this.theme = ThemeChoice.system,
    this.textScale = 1.0,
    this.lastExternalBackup,
    this.newsSeen = 0,
    this.challenges = const {},
  });

  final ThemeChoice theme;
  final double textScale;

  /// Dernier envoi de tous les chantiers hors du téléphone.
  final DateTime? lastExternalBackup;

  /// Dernières nouveautés montrées (voir `newsVersion`).
  final int newsSeen;

  /// Défis du mode apprentissage : essais et réussites.
  final Map<Challenge, ChallengeRecord> challenges;

  AppSettings copyWith({
    ThemeChoice? theme,
    double? textScale,
    DateTime? lastExternalBackup,
    int? newsSeen,
    Map<Challenge, ChallengeRecord>? challenges,
  }) => AppSettings(
    theme: theme ?? this.theme,
    textScale: textScale ?? this.textScale,
    lastExternalBackup: lastExternalBackup ?? this.lastExternalBackup,
    newsSeen: newsSeen ?? this.newsSeen,
    challenges: challenges ?? this.challenges,
  );

  Map<String, Object?> toJson() => {
    'theme': theme.name,
    'textScale': textScale,
    if (lastExternalBackup != null) 'lastExternalBackup': lastExternalBackup!.toIso8601String(),
    if (newsSeen > 0) 'newsSeen': newsSeen,
    if (challenges.isNotEmpty) 'challenges': challengesToJson(challenges),
  };

  /// Un fichier abîmé ou d'une autre version redonne les réglages de départ, sans planter.
  static AppSettings fromJson(Map<String, Object?> pJson) {
    final vTheme = ThemeChoice.values
        .where((pChoice) => pChoice.name == pJson['theme'])
        .firstOrNull;
    final vScale = (pJson['textScale'] as num?)?.toDouble();
    final rSettings = AppSettings(
      theme: vTheme ?? ThemeChoice.system,
      textScale: textScales.contains(vScale) ? vScale! : 1.0,
      lastExternalBackup: DateTime.tryParse((pJson['lastExternalBackup'] as String?) ?? ''),
      newsSeen: (pJson['newsSeen'] as int?) ?? 0,
      challenges: challengesFromJson(pJson['challenges']),
    );

    return rSettings;
  }
}
