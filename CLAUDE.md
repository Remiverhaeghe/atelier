# Atelier

Application Android en Flutter pour préparer des travaux : parquet et plinthes d'abord, puis peinture, carrelage, placo, électricité et plomberie. Suivre les conventions de Rémi (skills `conventions-remi` et `flutter-mobile-remi`). Toujours répondre en français.

- Cahier des charges : `D:\Projet_dev\_idees\atelier-cahier-des-charges.md` (lots 0 à 7).
- Règles de calcul dans `lib/logic/`, en Dart pur, sans Flutter, testées unitairement et couvertes à 95 % au moins (contrôlé par la CI).
- Aucun texte affiché en dur dans un widget : tout passe par `lib/l10n/app_fr.arb`.
- Longueurs en millimètres entiers dans le code, angles en degrés ; conversion seulement à l'affichage.
- Données sur le téléphone uniquement, aucune permission réseau.
- Côté Android, seuls `android/app/build.gradle.kts`, le manifeste et les fichiers du widget d'écran d'accueil (`ObjectifWidget.kt`, `res/layout/objectif_widget.xml`, `res/xml/objectif_widget_info.xml`) sont versionnés : `flutter create --platforms=android --org fr.remiverhaeghe --project-name atelier .` recrée le reste.
- Avant de valider : `flutter gen-l10n`, `dart format lib test`, `flutter analyze`, `flutter test`.
- `README.md` et `CHANGELOG.md` à jour après chaque lot ; fichiers de moins de 1000 lignes.
