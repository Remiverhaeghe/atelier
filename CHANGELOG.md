# Changelog

## Non publié

### Lot 6 : chantier, budget et partage
- Courses et budget du chantier : quantités de toutes les pièces (chacune arrondie à l'unité vendue), prix unitaires, total, prix manquants signalés
- Coût de chaque pièce dans la liste du chantier
- Liste de courses envoyée par message, fiche PDF à imprimer (liste, plan, rangées de parquet et coupes de plinthe)

### Lot 5 : barres de plinthe
- Morceaux répartis dans le moins de barres possible, les plus longs d'abord, trait de scie compris
- Nombre de barres à acheter, contenu de chaque barre, chutes de plus de 30 cm signalées à garder
- Chaque morceau indique la barre où le tailler ; morceau plus long qu'une barre signalé

### Lot 4 : plinthes, angles et coupes
- Onglet Plinthes : un morceau par mur, coupé entre les portes et passages, en morceaux égaux joints en biseau si le mur dépasse une barre
- Angle de scie de chaque coin (moitié de l'écart à un mur droit : 45° pour 90°, 46° pour 88°), sens de la pointe longue dit en mots, coupe droite aux bouts libres et contre les chambranles
- Fixation : cartouches de colle, ou clous, vis et clips (un à chaque bout et tous les 40 cm)
- Morceaux à cocher une fois coupés, mur surligné sur le plan

### Lot 3 : plan de pose
- Onglet Pose : longueur de chaque morceau, rangée par rangée, mesurée du mur, jeu de dilatation déduit
- Joints de deux rangées voisines écartés d'au moins 30 cm (réglable), aucun morceau de moins de 30 cm
- Chutes réutilisées pour commencer les rangées suivantes ; nombre de lames réellement entamées
- Pièce en L : chaque rangée prend sa vraie longueur ; rangées où les règles ne peuvent pas être tenues signalées
- Rangées à cocher une fois posées, avec la progression

### Lot 2 : parquet, quantités
- Onglet Parquet dans chaque pièce : type (flottant, collé, massif cloué, point de Hongrie ou bâton rompu) avec ses valeurs de départ modifiables
- Paquets, lames, sous-couche, seaux de colle et boîtes de clous, marge de chute comprise ; un paquet tout juste suffisant ne fait pas acheter le suivant
- Rangées perpendiculaires au mur choisi, jeu de dilatation déduit ; dernière rangée trop étroite équilibrée avec la première
- Point de Hongrie et bâton rompu : lames gauches et droites comptées à part

### Lot 1 : la pièce
- Chantiers et pièces : création, suppression, enregistrement sur le téléphone (fichier JSON écrit d'un coup)
- Saisie mur par mur : longueur en centimètres, angle intérieur avec le mur suivant, bout libre
- Portes, passages et obstacles (radiateur, tuyau, placard, cheminée, pied d'escalier)
- Plan à l'échelle, murs numérotés ; contrôle que le contour se referme à 1 cm près ; surface au sol sans les zones sans parquet

### Lot 0 : squelette
- Application Flutter Android, thème clair et sombre, textes en français dans `lib/l10n/app_fr.arb`
- Écran « Mes chantiers », vide pour l'instant
- CI : formatage, analyse, tests, couverture des règles de calcul (95 % minimum), APK en artefact, recherche de secrets
- Dependabot pour les paquets Dart et les actions GitHub
