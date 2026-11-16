/// Réglages d'affichage de l'application : thème et taille du texte.
library;

/// Thème : celui du téléphone, clair ou sombre.
enum ThemeChoice { system, light, dark }

/// Tailles de texte proposées : normale, grande (lecture de loin), très grande (avec des gants).
const textScales = [1.0, 1.15, 1.3];

class AppSettings {
  const AppSettings({this.theme = ThemeChoice.system, this.textScale = 1.0});

  final ThemeChoice theme;
  final double textScale;

  AppSettings copyWith({ThemeChoice? theme, double? textScale}) =>
      AppSettings(theme: theme ?? this.theme, textScale: textScale ?? this.textScale);

  Map<String, Object?> toJson() => {'theme': theme.name, 'textScale': textScale};

  /// Un fichier abîmé ou d'une autre version redonne les réglages de départ, sans planter.
  static AppSettings fromJson(Map<String, Object?> pJson) {
    final vTheme = ThemeChoice.values.where((pChoice) => pChoice.name == pJson['theme']).firstOrNull;
    final vScale = (pJson['textScale'] as num?)?.toDouble();
    final rSettings = AppSettings(
      theme: vTheme ?? ThemeChoice.system,
      textScale: textScales.contains(vScale) ? vScale! : 1.0,
    );

    return rSettings;
  }
}
