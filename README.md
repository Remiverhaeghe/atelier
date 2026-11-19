# Atelier

Application Android pour préparer ses travaux sans erreur : coupes, quantités et budget d'un chantier, de la pièce saisie mur par mur jusqu'au bilan de fin de chantier.

Tout reste sur le téléphone, sans compte ni connexion : l'appli n'a pas la permission Internet.

## Sur iPhone

Atelier existe aussi en version web : https://remiverhaeghe.github.io/atelier/. Dans Safari, bouton Partager, puis « Sur l'écran d'accueil » : l'appli s'ouvre alors en plein écran, comme une appli installée, et marche hors ligne après la première ouverture. Les chantiers restent dans le navigateur de l'iPhone ; pour les passer d'un appareil à l'autre, utiliser l'export de chantier. Photos, télémètre Bluetooth, rappels et widget ne sont disponibles que sur Android pour l'instant.

## Aperçu

| Chantier | Reprises | Parquet | Plan de pose | Plinthes |
|---|---|---|---|---|
| ![Chantier](docs/captures/02-chantier.png) | ![Reprises](docs/captures/10-reprises.png) | ![Parquet](docs/captures/04-parquet.png) | ![Pose](docs/captures/05-pose.png) | ![Plinthes](docs/captures/06-plinthes.png) |

| Peinture | Conseil | Calculs | Étagère |
|---|---|---|---|
| ![Peinture](docs/captures/11-peinture.png) | ![Conseil](docs/captures/12-conseil.png) | ![Calculs](docs/captures/13-calculs.png) | ![Étagère](docs/captures/14-etagere.png) |

Captures faites sur un chantier fictif par le workflow Captures (`test/captures/`), à chaque changement d'interface. Les nouvelles versions sont dans l'artefact `captures` de son dernier passage.

## Ce que fait l'appli

Le détail, version par version, est dans [CHANGELOG.md](CHANGELOG.md).

| Domaine | Contenu |
|---|---|
| Pièces et plan | Saisie mur par mur ou décalque d'un plan papier, plafonds rampants à un ou deux pans, plusieurs niveaux et mezzanine, plan de la maison, vue 3D avec les meubles, export glTF et Home Assistant |
| Parquet et plinthes | Quantités, plan de pose rangée par rangée, diagonale et point de Hongrie, coupes de plinthes en schéma, barres optimisées, chutes réutilisables, mode chantier avec lecture à voix haute et commandes vocales |
| Calculs | Peinture, carrelage et faïence, placo et isolation, isolation phonique, enduit et ragréage, électricité, plomberie, ventilation, chauffage, douche de plain-pied, cuisine, escalier, porte, charpente et couverture, fenêtre de toit, fenêtre bois et son étanchéité, essences de bois, panneaux, colles et serrage, finitions (lasure, vernis, vitrificateur, huile, cire), humidité et condensation, faux plafond, placard sous rampant, façade et clôture, terrasse, jardin, étagère, armoire, chevilles, soudure, gravats |
| Chantier | Budget, courses par magasin, dépenses et tickets, échéancier, planning, temps passé, objectif du jour, attentes avec notification, widget d'écran d'accueil, carnet de la maison en PDF, avant / après, bilan, recherche dans toute l'appli, chantier partagé par fusion d'exports |
| Aide | Gestes de base animés (scier, raboter, percer, visser, poncer, mortaiser, mastic, cheville, placo, onglet, laser, joints de carrelage), caisse à outils du débutant, lexique des mots du métier avec schémas en relief, conseils et tutos, erreurs fréquentes, sécurité avant de commencer, réseaux cachés, faire soi-même ou faire faire, niveau et pente au téléphone |

La suite est dans [ROADMAP.md](ROADMAP.md). Le format du plan exporté est décrit dans [docs/format-plan.md](docs/format-plan.md), l'export pour Home Assistant dans [docs/home-assistant.md](docs/home-assistant.md).

## Installer sur le téléphone

Chaque fusion sur `main` publie l'APK dans une préversion `build-N` de [Releases](../../releases) (les trois dernières sont gardées). Le plus simple pour l'installer et la tenir à jour est [Obtainium](https://github.com/ImranR98/Obtainium), une appli Android gratuite qui suit les releases GitHub :

1. Installer Obtainium depuis sa page GitHub (fichier `app-arm64-v8a-release.apk` de sa dernière release) ou depuis F-Droid.
2. Dans Obtainium, « Ajouter une appli », coller `https://github.com/Remiverhaeghe/atelier`.
3. Cocher « Inclure les préversions » puis « Ajouter ». Obtainium choisit l'APK du processeur du téléphone (arm64 pour un téléphone récent).
4. « Installer ». Ensuite, Obtainium signale chaque nouvelle construction et la met à jour en un clic.

Le numéro de construction sert de `versionCode` : chaque APK remplace la précédente sans désinstaller, données gardées. Les préversions ne sont publiées qu'avec la clé de signature personnelle (secrets `ANDROID_*`), sinon deux APK successives n'auraient pas la même signature.

Les versions numérotées (`vX.Y.Z`) ont leurs APK sur leur page de release, et chaque exécution de la CI garde aussi son APK en artefact `atelier-apk` (onglet Actions).

## Publier une version

1. Dans `CHANGELOG.md`, renommer `## Non publié` en `## X.Y.Z - AAAA-MM-JJ` et augmenter `version:` dans `pubspec.yaml` (le nombre après `+` à chaque fois).
2. Sur GitHub, Releases, « Draft a new release », nouveau tag `vX.Y.Z` sur `main`, puis « Publish release ».
3. La CI construit les APK et le bundle `.aab` depuis le tag et les joint à la release.

Permissions de l'appli et ce qu'elles servent : [docs/securite.md](docs/securite.md).

Pour le Play Store : liste à cocher dans [docs/publication-play-store.md](docs/publication-play-store.md), politique de confidentialité dans [docs/confidentialite.md](docs/confidentialite.md), images de la fiche dans `docs/play-store/` (`python tool/fiche_play.py`).

## Lancer en développement

Prérequis : Flutter 3.47 et le SDK Android.

```
flutter create --platforms=android --org fr.remiverhaeghe --project-name atelier .
flutter pub get
flutter run
```

La première commande recrée les fichiers Android qui ne sont pas versionnés (Gradle, icônes, `MainActivity`) ; elle ne touche pas au code existant, dont le widget d'écran d'accueil. Pour l'icône et l'écran de démarrage : `dart run flutter_launcher_icons` puis `dart run flutter_native_splash:create`.

## Tester

```
flutter gen-l10n
dart format lib test
flutter analyze
flutter test --coverage
```

Les captures d'écran sont sautées par `flutter test`. Pour les refaire : `flutter test --tags captures --run-skipped --update-goldens test/captures` (la variable `FLUTTER_ROOT` doit pointer vers le SDK Flutter, pour les polices).

Les parcours de `integration_test/` tournent sur un vrai Android : `flutter test integration_test` avec un téléphone branché ou un émulateur lancé. En CI, le workflow « Tests sur émulateur » les passe sur chaque pull request.

Les règles de calcul vivent dans `lib/logic/`, sans dépendance à Flutter, et la CI exige qu'elles soient couvertes à 95 %.

Tests de mutation sur `lib/logic` : `python3 tool/mutation.py --max 60` (workflow « Tests de mutation », à la demande et chaque lundi). Le score doit rester au-dessus de 70 %.

## Organisation

| Dossier | Rôle |
|---|---|
| `lib/logic` | Règles de calcul en Dart pur : géométrie de la pièce, parquet, plinthes, quantités |
| `lib/storage` | Enregistrement des chantiers sur le téléphone |
| `lib/ui` | Écrans, sans règle métier |
| `lib/l10n` | Textes affichés (`app_fr.arb`) |

## Licence

[MIT](LICENSE)
