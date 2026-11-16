# Changelog

## Non publié

### Ventilation
- Nouveau calcul VMC simple flux : débits extraits par pièce humide selon le nombre de pièces, bouches et gaines, entrées d'air, détalonnage des portes

### Porte intérieure
- Nouveau calcul : bloc-porte standard qui entre dans l'ouverture brute, jeu à caler, hauteur, cloison épaisse, sens d'ouverture poussant droit ou gauche

### Chevilles et vis
- Nouveau calcul : cheville, foret, vis et nombre de points selon le support (placo, béton, brique, béton cellulaire, bois) et le poids à accrocher

### Avant de commencer
- Sous la prochaine étape du guide : coupures et protections à prévoir (courant, eau, masque FFP2, lunettes, casque, gants, genouillères, aération), à cocher d'un geste

### Charpente et couverture
- Nouveau calcul pour un pan de toit : chevrons, contre-liteaux, liteaux selon le pureau, tuiles ou ardoises avec la casse, faîtières, rives et écran sous toiture

### Fenêtre de toit du commerce
- Pour chaque taille de plexi : fenêtre de toit courante la plus proche et reprise du chevêtre (élargir, réduire, allonger), en évitant de couper un chevron

### Attentes en cours
- Carte « Attentes en cours » sur le chantier : acclimatation du parquet, séchage du ragréage ou de l'enduit, couche suivante, prise de la colle, ou durée libre ; l'appli dit quand c'est prêt

### Niveau et pente au téléphone
- Nouveau calcul « Niveau et pente » : niveau à bulle et inclinomètre avec l'accéléromètre, pente en degrés et en pour cent
- Plafond rampant : l'angle mesuré en posant le téléphone sur le rampant donne la largeur au sol

### Tests sur émulateur
- Deux parcours de plus sur Android : chantier relu du téléphone jusqu'à sa surface habitable, sauvegarde du jour écrite à chaque enregistrement

### Plan plus fluide
- Contour de chaque pièce calculé une seule fois au lieu de plusieurs par dessin
- Lecture et écriture JSON de la pièce dans `room_json.dart`, séparées du modèle

### Calculs reliés aux pièces
- Isolation, ragréage et faïence proposent « Reprendre d'une pièce » : rampants, murs, combles ou sol pour l'isolation, sol pour le ragréage, mur avec sa hauteur et sa fenêtre pour la faïence

### Accueil du chantier
- Tuiles sous le résumé du chantier : plan de la maison, surface habitable, carnet, temps passé, plexis, chutes, bilan ; le menu ⋮ ne garde que les exports

### PDF lisibles
- Fiche du chantier et liste de coupes imprimées avec la police de l'appli : le « € » et tous les accents s'affichent

## 0.3.0 - 2026-11-16

### Bilan de fin de chantier
- Dépensé face au prévu de la liste de courses, temps de travail et étape la plus longue, chutes gardées, reprises faites, travaux au carnet
- Leçons notées pour le prochain chantier

### Erreurs fréquentes
- Sous la prochaine étape du guide, les erreurs classiques à éviter : jeu de dilatation, sens des lames, colle mal dosée, onglet à l'envers, plinthe fixée au parquet flottant…

### Pas à pas en photos
- Chaque étape du guide reçoit ses propres photos, affichées sous l'étape : on se fait ses tutos au fil des chantiers

### Carnet de la maison
- Travaux notés pièce par pièce : date, produit, référence ou lot, coût, note, photo et photo de la facture
- Recherche de la dernière référence pour une retouche (« blanc salon »), coût total, carnet partagé en texte

### Réseaux cachés
- Gaines, tuyaux et câbles relevés mur par mur, dessinés en couleur sur le plan et exportés avec le plan
- « Puis-je percer ici ? » : réseau relevé le plus proche, bandes où passent souvent les conduits, rappel du détecteur

### Grandes hauteurs
- Hauteur du plancher d'une mezzanine : sa surface compte en surface habitable s'il reste 1,80 m au-dessus, et l'escalier proposé monte jusqu'à elle
- Échafaudage roulant conseillé en peinture au-delà de 3 m sous plafond
- Volume de chaque pièce dans la surface habitable

### Meubles sur le plan
- Meubles courants posés à l'échelle sur le plan d'une pièce, tournés ou déplacés d'un geste
- Débattement des portes dessiné ; signalés : meuble qui gêne une porte, dépasse de la pièce, en chevauche un autre ou laisse un passage de moins de 60 cm

### Débit de panneaux
- Nouveau calcul : pièces à tailler dans un contreplaqué, un mélaminé ou un OSB, rangées en bandes avec le trait de scie, panneaux à acheter, chutes et plan de coupe dessiné
- Pièces tournées seulement si on l'autorise (fil du bois ou décor)

### Enduit et ragréage
- Nouveau calcul : sacs de ragréage, d'enduit de lissage ou de rebouchage selon la surface et l'épaisseur relevée à la règle, primaire, couches et attente avant de poser le revêtement

### Faïence et crédence
- Nouveau calcul : pan de mur moins une fenêtre ou une niche, rangées entières depuis le bas et coupe en haut, cartons, colle et joint
- Découpes de prises à la scie cloche et rehausses, profilés de finition, joint silicone sur le plan de travail

### Isolation
- Nouveau calcul : épaisseur d'isolant selon la résistance R visée (combles perdus, rampants, murs, plancher bas), en une couche ou deux croisées
- Paquets, sacs d'ouate à souffler, pare-vapeur et suspentes

### Plexis de toiture
- Une fenêtre de toit peut être marquée « plexi ou panneau fixe »
- Écran « Plexis à remplacer » : surface totale et tailles avec leurs pièces
- Nouveau calcul « Cadre de fenêtre » : débit des montants et traverses à mi-bois, section, feuillure, tasseaux à acheter, vitrage à commander selon double vitrage, polycarbonate, verre feuilleté ou plexi, parcloses et étapes de pose

### Combles
- Second pan de toit par pièce, pour les combles en pente des deux côtés
- Pente saisie au choix par la largeur au sol ou par la longueur du rampant, avec un schéma qui montre où mesurer
- Ligne des 1,80 m dessinée sur le plan

### Surface habitable
- Surface habitable et Loi Carrez par pièce, par niveau et pour la maison, depuis le menu du chantier
- Usage de chaque pièce (habitable, combles, cave, garage, véranda, balcon) qui décide de ce qui compte
- Retirés : parties à moins de 1,80 m sous la pente, marches et trémies d'escalier, gaines

### Conditions de chantier
- Nouveau calcul : avec la température, l'humidité et, si on l'a, la température du support, ce qu'on peut peindre, coller, vernir ou jointer
- Point de rosée calculé et risque de condensation signalé pour les peintures et vernis

### Temps passé
- Chrono par pièce et par étape, gardé même si l'appli est fermée, et temps ajouté à la main
- Temps à prévoir pour les autres pièces, au rythme constaté (minutes par m² ou par mètre de plinthe)

### Comparer les magasins
- Depuis la liste de courses : prix relevés par magasin, total de chacun (prix manquants signalés) et panier panaché le moins cher, avec l'économie par rapport au meilleur magasin unique

### Louer ou acheter
- Nouveau calcul : coût de la location face à l'achat (revente déduite), nombre de jours à partir duquel acheter est rentable, et conseil

### Sauvegarde hors du téléphone
- Rappel en haut de la liste des chantiers quand la dernière sauvegarde externe date de plus de 7 jours
- « Sauvegarder » envoie tous les chantiers dans un fichier daté, par le partage Android (Drive, carte SD, ordinateur), sans permission réseau

### Captures Play Store
- Workflow « Captures Play Store » : le chantier fictif parcouru sur un Android émulé au format 1080 × 1920, sept captures en artefact
- Les tests sur émulateur ne lancent plus que le parcours, les captures ont leur propre workflow

### Affichage
- Dans « À propos » : thème du téléphone, clair ou sombre, et taille du texte normale, grande ou très grande
- Réglages gardés dans un petit fichier, lus avant le premier affichage

### Export 3D
- « Exporter la maison en 3D (glTF) » : sols, murs, portes et fenêtres, étages empilés, en mètres
- Fichier .gltf autonome, lisible par Blender, Sweet Home 3D (après conversion) ou un visualiseur web

### Export Home Assistant
- « Exporter pour Home Assistant » dans le menu du chantier : étages et zones à recréer, avec icône, surface, prises et interrupteurs
- Format décrit dans `docs/home-assistant.md`

### Chutes réutilisables
- « Chutes » dans le menu du chantier : on note les chutes de lame ou de plinthe gardées
- L'appli attribue chaque chute au plus long morceau qu'elle peut fournir, dans toutes les pièces, trait de scie compté

### Liste de coupes
- Bouton ciseaux en haut d'une pièce : liste de coupes imprimable (PDF), plinthes et lames recoupées
- Morceaux identiques regroupés, de la plus longue à la plus courte, avec les murs ou rangées concernés et une case à cocher

### Mode chantier
- Bouton chantier en haut d'une pièce : la prochaine coupe de plinthe et la prochaine rangée de parquet, en gros caractères
- « Lire à voix haute » par le moteur vocal du téléphone, « Fait » coche la coupe ou la rangée
- L'écran reste allumé tant que le mode est ouvert

### Mesure assistée
- « Contrôler par la diagonale » sous le plan : la diagonale du coin A au coin C, mesurée, est comparée à celle du plan
- Pièce à quatre murs : les vrais angles sont recalculés depuis la diagonale (loi des cosinus) et corrigés d'un appui
- Murs opposés de longueurs différentes signalés dans une pièce saisie d'équerre

### Plusieurs niveaux
- Plan de la maison par niveau : rez-de-chaussée, étages et sous-sols, avec le niveau du dessous en transparence pour caler les murs
- Une pièce monte ou descend d'un niveau depuis le plan ; « Étage » ajoute un niveau vide
- Vue 3D empilée : chaque étage posé sur le précédent, plancher de 20 cm compris
- Trémie d'escalier dans les éléments du plan : sa surface est retirée du sol à couvrir
- Niveau et altitude du sol exportés (`level`, `floorLevel`)

### Plafond rampant
- Dans la peinture : mur du côté bas, hauteur de ce côté et largeur de la pente au sol
- Surfaces réelles : murs en trapèze sous la pente, plafond incliné plus grand que son ombre au sol
- Surface où l'on tient debout (1,80 m et plus) ; partie en pente grisée sur le plan
- Pente exportée avec le plan (champ `slope`)

### Saisie guidée et éléments du plan
- Coins de la pièce nommés A, B, C sur le plan ; la saisie d'un mur dit « Mesurez du coin B au coin C, au ras du sol », avec le plan et le mur surligné
- Prises, interrupteurs, escalier, mezzanine et fenêtre de toit placés d'un appui sur le plan
- Escalier calculé par la loi de Blondel : nombre de marches, hauteur, giron et longueur au sol
- Fenêtres de toit retirées du plafond à peindre ; surface de la mezzanine affichée
- Les éléments partent dans l'export du plan pour la domotique (champ `fixtures`)

### Préparation du Play Store
- Liste de publication à cocher et politique de confidentialité dans `docs/`
- Images de la fiche (icône 512, présentation 1024 × 500, six captures en 1080 × 1920) générées par `tool/fiche_play.py`
- Bundle `.aab` joint aux releases avec les APK
- Niveau d'API cible au moins 36, exigé par le Play Store depuis le 31 août 2026

### Tests sur émulateur
- Parcours lancé sur un Android émulé en CI : saisie d'un chantier et d'une pièce, écriture du fichier sur le téléphone, relecture comme au redémarrage

### Vue 3D
- Dans le plan de la maison, bascule en 3D : murs élevés à la hauteur sous plafond, sols, portes et fenêtres à leur place
- Rotation autour de la maison d'un glissement du doigt

### Plan de la maison
- « Plan de la maison » dans le menu du chantier : toutes les pièces sur le même plan, à faire glisser et à tourner d'un quart de tour, aimantées tous les 5 cm
- Rangement automatique des pièces pas encore placées
- La place de chaque pièce part dans l'export du plan (champ `house`, compatible avec la version 1)

### CI
- NDK Android installé avant la construction de l'APK, avec trois essais : une coupure réseau ne fait plus échouer le passage après 15 minutes

### Contrôle de finition
- « Contrôle de finition » dans les reprises : photo de la pièce, cercles autour de ce qui ne va pas, reprise créée avec sa photo
- Toute photo de reprise peut être annotée de la même façon ; le nombre d'endroits entourés s'affiche sur la reprise

### Pose en diagonale et point de Hongrie
- Pose en diagonale à 45° du mur choisi : rangées et plan de pose recalculés, 5 % de chute en plus, sens dessiné en biais
- Point de Hongrie : motif dessiné dans la pièce avec son axe, et la façon de le poser

### Calculs : carrelage et faïence
- Calepinage centré (coupes égales, jamais plus étroites qu'un tiers de carreau) ou depuis un bord, dessiné avec les coupes en couleur
- Carreaux et cartons marge comprise, colle, joint selon la taille et l'épaisseur des carreaux, croisillons

### Export du plan
- « Exporter le plan » dans le menu du chantier : pièces, contours, hauteurs, murs et ouvertures en JSON, pour une application de domotique ou une vue 3D
- Format décrit et versionné dans docs/format-plan.md

### Caméra thermique
- « Relevé thermique » dans les reprises : image de la caméra prise dans la galerie, défaut choisi (fenêtre, porte, prise, pont thermique, plafond, coffre de volet)
- Préconisation et matériel à acheter repris dans la reprise, à placer ensuite sur le plan ; isolation signalée comme à faire chiffrer

### Calculs : soudure
- Procédés classés selon le métal (acier, inox, alu), l'épaisseur et le lieu (dehors, au vent) : électrode enrobée, MIG/MAG, fil fourré, TIG
- Réglages de départ : intensité, diamètre d'électrode, de fil ou de tungstène, courant alternatif pour l'alu en TIG
- Mise en garde : équipement de protection, aération, essai sur une chute

### Calculs : plomberie
- Appareils à raccorder avec leur longueur de tuyau : PVC d'évacuation par diamètre, dénivelé à prévoir (1 à 3 cm par mètre), multicouche pour l'eau froide et chaude, coudes et raccords

### Calculs : électricité
- Repères de quantités par pièce d'après les minimums courants de la norme NF C 15-100 : prises, points lumineux, interrupteurs, boîtes, circuits spécialisés de cuisine, gaine et fil
- Mise en garde en tête : couper le courant, faire valider par un électricien ; pas de schéma de tableau

### Calculs : terrasse bois
- Lames (5 % de marge), lambourdes espacées selon l'épaisseur des lames, plots, vis inox
- Terrasse dessinée vue de dessus, joints décalés, lambourdes dessous

### Calculs : armoire sur mesure
- Compartiments de gauche à droite, en penderie (tablette haute et tringle) ou en étagères
- Liste de débit (montants, dessus et dessous, séparations, tablettes en retrait des portes, fond, portes), tringles, charnières selon la hauteur des portes
- Dessin de face, coté, et alerte si les tablettes sont trop larges pour le panneau

### Calculs : placo et isolation
- Doublage ou cloison : plaques, rails, montants (aboutés au-delà de 3 m), vis, bandes, enduit, rouleaux de laine
- Résistance thermique de la laine selon son épaisseur et sa conductivité

### Aide à la déco
- Couleurs des murs, du plafond et des boiseries dans l'onglet Peinture, avec un aperçu de leur part dans la pièce
- Teintes courantes, puis accords proposés autour de la couleur des murs : teintes voisines, teinte opposée adoucie, plus claire pour le plafond, plus foncée pour un mur d'accent

### Calculs : jardin
- Pelouse semée ou en rouleaux, terre végétale et paillage des massifs, nombre de plants

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
