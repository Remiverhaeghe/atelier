# Changelog

## Non publié

### Calculs : étagère sur mesure
- Nouvel écran « Calculs », depuis « Mes chantiers »
- Étagère : liste de débit (montants, tablettes, fond), panneaux à acheter, vis, écart entre tablettes
- Alerte si la tablette est trop large pour le panneau choisi (aggloméré, MDF, contreplaqué, bois massif) et son épaisseur

### Icône
- Icône d'Atelier : une équerre de mètre ruban jaune sur vert sapin, icône adaptative Android
- Écran de démarrage aux mêmes couleurs

### Courses en magasin
- Chaque article se coche une fois dans le chariot
- Magasin ou rayon et référence qui convient, gardés d'une fois sur l'autre ; la liste se range par magasin

### Dépenses réelles
- Achats faits saisis dans les courses (article, montant, ticket en photo), total payé et reste du budget prévu, dépassement signalé

### Aide à la décision
- Comparaison des façons de faire, notées sur le coût, le temps et la difficulté, avec points forts et points faibles : plinthes collées, clouées ou clipsées ; parquet flottant, collé ou cloué ; mur abîmé rebouché ou doublé
- La plus simple est signalée ; accès depuis les conseils et tutos

### Planning du chantier
- Prochaine étape de chaque pièce sur l'écran du chantier, dans l'ordre : reprises, plafond, murs, boiseries, parquet, plinthes, joints
- Rappel du séchage à respecter après l'étape précédente (indicatif, la notice fait foi)
- Peinture : plafond, murs et boiseries à cocher une fois peints

### Matériel disponible
- Outils à cocher dans le guide : l'appli dit s'il manque quelque chose, et les outils manquants passent dans les courses
- Stock déjà là pour chaque article des courses, déduit de ce qu'il faut acheter et du budget
- L'objectif du jour ne propose une pose que si tous les outils de la pièce sont là

### Sauvegardes
- Copie quotidienne de tous les chantiers sur le téléphone, les 14 derniers jours gardés
- Restauration en un geste depuis « À propos », après confirmation

## 0.2.0 - 2026-11-16

### Conseils et tutos
- Fiches pas à pas, par sujet : finir les plinthes au joint, coller, clouer, murs pas droits, marge de parquet, joint de porte, entretien d'une climatisation
- Mises en garde quand il le faut (câbles derrière les plinthes, circuit de gaz réservé aux professionnels)
- Accès depuis « Mes chantiers » et depuis l'onglet Guide

### Objectif du jour et badges
- Objectif du jour SMART en haut du chantier : quelques rangées, des morceaux de plinthe une fois le parquet posé, des reprises jusqu'au passage suivant, daté du jour ; avancement ligne par ligne
- Badges du chantier : première rangée, pièce finie, plinthes coupées, dix reprises, objectifs atteints, budget complet

### Peinture
- Onglet Peinture : hauteur sous plafond par pièce, murs, plafond, portes et chambranles, sous-couche à cocher
- Surfaces sans les portes, passages et fenêtres ; couches, rendement et marge pour les retouches réglables
- Pots les moins chers pour la quantité (prix saisis dans les courses, sinon grands pots moins chers au litre), rouleaux, bâches et ruban de masquage, repris dans les courses
- Fenêtres : largeur, hauteur et allège ; la plinthe passe dessous, le plan les dessine en double trait

### Jonction entre deux pièces
- Barre de seuil à cocher sur une porte ou un passage, dans une seule des deux pièces pour ne l'acheter qu'une fois ; longueur de barre réglable
- Barres de seuil comptées dans le parquet et dans les courses
- Conseils de jonction : arrêt sous la porte, jeu de dilatation, barre plate, de niveau ou de finition
- Guide : recouper le bas des chambranles à l'égoïne, poser les barres de seuil

### Coupes en schéma et sens de pose
- Schéma de chaque morceau de plinthe vu de dessus, posé sur la scie à onglet : dos contre le guide, trait de lame en jaune, angle de chaque bout, longueur au dos, chute
- « Mesurer l'angle » dans la saisie d'un mur : deux repères à 50 cm du coin et leur écart donnent l'angle réel, pour les murs pas droits (coin rentrant ou sortant)
- Sens de pose du parquet choisi en images : la pièce rayée de lames dans chaque sens possible, nombre de rangées, sens conseillé (dans la longueur) et conseil sur la lumière
- Départ de la pose signalé sur l'aperçu des rangées

### Reprises
- Onglet Reprises dans chaque pièce : choses à faire ou à reprendre, en un ou plusieurs passages à cocher (trois couches, quatre passes d'enduit)
- Note, matériel à acheter (repris dans les courses et la liste partagée), photo prise avec l'appareil du téléphone
- Repère numéroté sur le plan, rouge à faire, vert une fois fait
- Zones sans murs (toit, extérieur, achats) : elles s'ouvrent directement sur leurs reprises
- Avancement des pièces : les passages des reprises comptent
- Saisie à la suite avec « Reprise suivante »

### Habillage et prise en main
- Thème propre à Atelier : vert sapin, jaune mètre ruban réservé aux mesures, polices Barlow embarquées, thème sombre accordé
- Plan coté sur papier quadrillé : cotes jaunes, numéros des murs, portes avec leur ouverture, obstacles hachurés
- Vignette de la forme de chaque pièce dans les listes, résumé du chantier (surface, budget, accès direct aux courses), avancement de chaque pièce
- Aperçu des rangées en lames de chêne, plus foncées une fois posées
- Icônes sur les onglets, les résultats et les outils du guide
- Saisie des murs à la suite : « Mur suivant » enregistre et ouvre le mur d'après, la touche Entrée aussi

### Captures d'écran
- Captures d'un chantier fictif à la taille d'un téléphone, en thème clair et sombre, refaites par le workflow Captures et montrées dans le README
- Bandeau « debug » retiré

## 0.1.0 - 2026-11-16

### Publication
- Une release publiée sur GitHub reçoit automatiquement les APK construites depuis son tag

### Lot 7 : guidage et finitions
- Onglet Guide : étapes de pose dans l'ordre selon le parquet et la fixation des plinthes, à cocher, et outils à préparer ; masquable par chantier
- Export d'un chantier dans un fichier JSON (partage), import sous de nouveaux identifiants sans rien remplacer
- Journal local des plantages, jamais envoyé, à partager depuis « À propos »
- Cibles tactiles plus larges, onglets défilants

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
