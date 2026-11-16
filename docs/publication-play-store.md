# Publier sur le Play Store

Liste à reprendre avant chaque envoi. La console Play et l'inscription des testeurs restent à faire à la main.

## Avant le premier envoi

- [ ] Compte développeur Google Play créé (frais d'inscription uniques, vérification d'identité).
- [ ] Compte personnel créé après novembre 2023 : test fermé avec au moins 12 testeurs inscrits pendant 14 jours d'affilée avant l'accès à la production. À prévoir dans le calendrier.
- [ ] Signature d'application par Google Play activée. La clé d'importation est celle des secrets GitHub (`ANDROID_KEYSTORE_BASE64`…), gardée hors du dépôt et sauvegardée ailleurs.
- [ ] Politique de confidentialité en ligne : [docs/confidentialite.md](confidentialite.md), lien public `https://github.com/Remiverhaeghe/atelier/blob/main/docs/confidentialite.md` (ou une page du portfolio). Y ajouter une adresse de contact si la console la demande.

## À chaque envoi

- [ ] Niveau d'API cible à jour. `android/app/build.gradle.kts` fixe un plancher à l'API 36, exigée depuis le 31 août 2026 ; la règle monte chaque année (API 37 attendue en 2027), vérifier avant d'envoyer.
- [ ] `version: X.Y.Z+N` augmentée dans `pubspec.yaml` : le `versionCode` (`N`) doit dépasser celui du dernier envoi.
- [ ] Release publiée sur GitHub : la CI y joint les APK et le bundle `atelier-release.aab`, signés avec la clé d'importation. C'est le `.aab` qu'on envoie, pas une APK.
- [ ] Notes de version reprises de `CHANGELOG.md`.

## Fiche

Les images sont dans `docs/play-store/`, refaites par `python tool/fiche_play.py` (Pillow) depuis l'icône et les captures fictives de `docs/captures/`.

- [ ] Icône 512 × 512 : `icone-512.png`.
- [ ] Image de présentation 1024 × 500 : `presentation-1024x500.png`.
- [ ] Captures de téléphone (au moins deux), au choix :
  - prises sur un Android émulé (Pixel 2, 1080 × 1920) par le workflow « Captures Play Store » (Actions, Run workflow), artefact `captures-play-store` ;
  - ou `capture-1.png` à `capture-6.png`, tirées des captures de test.
- [ ] Description courte (80 caractères au plus), par exemple : « Mesurez vos pièces, calculez parquet, plinthes et peinture, suivez le chantier. »
- [ ] Description longue : reprendre l'« Aperçu » du README, sans promesse que l'appli ne tient pas.
- [ ] Catégorie : Maison et intérieur. Coordonnées du développeur.

## Formulaires de la console

- [ ] **Sécurité des données** : aucune donnée collectée, aucune donnée partagée. L'appli n'a pas la permission Internet ; elle demande celle des notifications pour la fin des attentes, programmées sur le téléphone, et celle du micro pour les commandes vocales, sans rien garder ; les exports et partages sont lancés par l'utilisateur. Revérifier si une dépendance change (`flutter pub deps`, permissions du manifeste fusionné dans `build/app/intermediates/merged_manifests`).
- [ ] **Classification du contenu** : questionnaire IARC, appli utilitaire sans contenu sensible.
- [ ] **Public cible** : adultes ; pas destinée aux enfants.
- [ ] **Publicités** : non. **Accès à l'application** : tout est accessible sans compte.
