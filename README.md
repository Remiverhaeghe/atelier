# Atelier

Application Android pour préparer ses travaux sans erreur : coupes, quantités et budget d'un chantier. Elle commence par le parquet et les plinthes ; la peinture, le carrelage, le placo, l'électricité et la plomberie suivront.

Tout reste sur le téléphone, sans compte ni connexion.

## Avancement

| Lot | Contenu | État |
|---|---|---|
| 0 | Squelette, CI, APK | fait |
| 1 | Saisie d'une pièce mur par mur, plan | fait |
| 2 | Parquet : surface, paquets, rangées, sous-couche | fait |
| 3 | Parquet : plan de pose rangée par rangée | fait |
| 4 | Plinthes : angles et liste des coupes | fait |
| 5 | Plinthes : optimisation des barres | fait |
| 6 | Chantier de plusieurs pièces, budget, liste de courses, PDF | fait |
| 7 | Guidage pas à pas, export, finitions | fait |

## Installer

Les APK de chaque version sont jointes à sa page dans [Releases](../../releases). Prendre `app-arm64-v8a-release.apk` pour un téléphone récent.

Entre deux versions, chaque exécution de la CI produit aussi une APK (onglet Actions, artefact `atelier-apk`).

## Publier une version

1. Dans `CHANGELOG.md`, renommer `## Non publié` en `## X.Y.Z - AAAA-MM-JJ` et augmenter `version:` dans `pubspec.yaml` (le nombre après `+` à chaque fois).
2. Sur GitHub, Releases, « Draft a new release », nouveau tag `vX.Y.Z` sur `main`, puis « Publish release ».
3. La CI construit les APK depuis le tag et les joint à la release.

## Lancer en développement

Prérequis : Flutter 3.47 et le SDK Android.

```
flutter create --platforms=android --org fr.remiverhaeghe --project-name atelier .
flutter pub get
flutter run
```

La première commande recrée les fichiers Android qui ne sont pas versionnés (Gradle, icônes) ; elle ne touche pas au code existant.

## Tester

```
flutter gen-l10n
dart format lib test
flutter analyze
flutter test --coverage
```

Les règles de calcul vivent dans `lib/logic/`, sans dépendance à Flutter, et la CI exige qu'elles soient couvertes à 95 %.

## Organisation

| Dossier | Rôle |
|---|---|
| `lib/logic` | Règles de calcul en Dart pur : géométrie de la pièce, parquet, plinthes, quantités |
| `lib/storage` | Enregistrement des chantiers sur le téléphone |
| `lib/ui` | Écrans, sans règle métier |
| `lib/l10n` | Textes affichés (`app_fr.arb`) |

## Licence

[MIT](LICENSE)
