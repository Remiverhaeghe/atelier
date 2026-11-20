# Changelog

## Non publié

### Ajouté
- Filmer une pièce : depuis les reprises, l'appareil du téléphone filme la pièce, puis la vidéo se relit dans l'appli. À chaque défaut, « Repérer ici » garde l'image du moment, on y entoure ce qu'il faut reprendre, et chaque moment devient une reprise avec sa photo et l'heure de la vidéo. Seules les images repérées sont gardées. Pas dans la version web
- Animations : chaque écran arrive comme une page de carnet qu'on tourne, avec son ombre, pendant que la page du dessous recule ; un résultat qui change remonte en place au lieu de sauter ; dans les gestes, la sciure, la poussière de ponçage et les copeaux volent du point de contact, et le croquis se pose en apparaissant. Tout est coupé quand le téléphone demande de réduire les animations
- Relevés d'un thermo-hygromètre (ThermoPro ou autre) : le fichier CSV exporté par son appli (colonnes date, température et humidité reconnues à leur titre, °F converti, dates françaises, ISO ou américaines) donne la moyenne, les écarts et ce qu'ils annoncent : air trop humide (VMC, aération), humidité qui met plus de 2 h à partir après une douche (bouche d'extraction, détalonnage), chaleur perdue la nuit (isolation, fuites d'air), pièce froide, surchauffée ou à l'air sec. Repères écrits sous l'analyse. Depuis les reprises d'une pièce, les constats cochés deviennent des reprises
- Dessiner la pièce : on part d'un rectangle, d'un L ou d'un T, aux murs numérotés sur le plan et aux coins lettrés. On touche un mur, il passe en couleur, l'appli dit « mesure du coin A au coin B », on tape sa longueur. Les murs non mesurés se déduisent des autres pour refermer la pièce et restent en pointillés. Pas d'angle à saisir : si les murs d'en face diffèrent, l'appli demande la diagonale et calcule les angles. Hauteur sous plafond et rampants (un ou deux pans) sur le même écran ; « Autre forme » garde la saisie avec les angles
- Coûts présentés comme des estimations, avec leur base : prix saisis dans les courses (budget, bilan, comparaison des magasins, fiche PDF), fourchettes d'entrée de gamme fixées dans l'appli (caisse à outils, bon outil, par où commencer), montants saisis (louer ou acheter, faire soi-même), taux horaire saisi (coût réel), coûts moyens d'artisan (diagnostic thermique)
- Mesures plus simples : tous les murs d'une pièce sur un seul écran (une ligne par mur, coin rentrant ou sortant d'un geste, plan qui se dessine à mesure, fermeture vérifiée), pièce rectangulaire en deux cotes, longueurs en cm, m ou mm au choix. Dans les calculs, une longueur peut se taper avec son unité (« 2,45 m » dans un champ en cm), et le bouton à côté d'un champ reprend une cote d'une pièce du chantier : longueur, largeur, hauteur, tour, sol, murs ou volume
- Relevé thermique : les températures lues sur l'image (zone froide, mur à côté, pièce, dehors, humidité au choix) donnent le facteur de température de la zone et sa gravité, de « rien de marqué » à « l'eau s'y dépose déjà ». Sous 0,7, la zone risque de moisir et passe en priorité. Le relevé est gardé dans la note de la reprise. Sans 10 °C d'écart entre dedans et dehors, l'appli dit que l'image ne permet pas de conclure
- Version anglaise (lot 136) : les 3 300 textes ont leur traduction dans `app_en.arb`. L'appli suit la langue du téléphone, ou celle choisie dans « À propos » (téléphone, français, anglais). Les nombres prennent le point en anglais. Les commandes vocales du mode chantier restent en français, et les repères de normes et d'aides restent ceux de la France
- Version web : le bouton du télémètre explique que Safari n'a pas de Bluetooth et qu'on tape la mesure à la main ; les attentes et les prêts disent qu'il n'y aura pas de notification, et restent signalés à l'ouverture du chantier
- Version web : les photos (reprises, journal, avant/après, tickets, souvenirs, guides) se prennent et se gardent dans le navigateur de l'iPhone, et apparaissent aussi dans les PDF ; l'export et l'import de chantier marchent depuis Safari (menu de partage, app Fichiers), comme le partage chiffré d'un projet avec ses photos
- Sauvegarde complète (fichier daté ou chiffré) : le stock de l'atelier part avec les chantiers ; à l'import, les articles absents de l'appareil sont ajoutés
- Préparer un sol (lot 201) : chape sèche, fluide anhydrite ou ciment avec la commande (plaques et granulats, sacs ou volume coulé), l'attente avant la pose et l'humidité à atteindre, la sous-couche selon le revêtement, le jeu aux murs, les joints aux seuils et le fractionnement des grandes pièces. Le calcul du ragréage en sacs existait déjà (Enduit et ragréage)
- Portes (lot 203) : jeu sous la porte et recoupe quand le sol monte, hauteur de poignée, sens d'ouverture trouvé depuis l'un ou l'autre côté. Le bloc-porte d'après l'ouverture et le choix du sens existaient déjà
- Peindre une grande hauteur (lot 207) : manche télescopique, escabeau ou échafaudage roulant selon la hauteur, quantités mur et plafond en pots de 10 L, ordre de travail sans reprise
- Souvenirs du chantier (lot 210) : depuis le carnet, l'avant et l'après de chaque entrée en diaporama sur papier quadrillé, ou en PDF façon carnet (papier crème, photos encadrées, légendes manuscrites). La comparaison avant / après au doigt existait déjà
- Le bon outil (lot 195) : pour dix tâches courantes, l'outil à la main de la caisse du débutant quand il suffit, sinon l'outil électrique, avec le budget et le choix entre acheter, louer ou emprunter selon les jours d'utilisation. Le calcul reprend `starter_tools` et `rent_or_buy`, et propose les gestes animés de l'outil
- Outillage loué (lot 196) : dans l'écran des prêts, « Louer un outil » note le loueur, les jours, la caution et le prix par jour. L'écran affiche la date de retour, le coût, le retard éventuel, et programme un rappel la veille du retour à 18 h, annulé quand l'outil est rendu. Les prêts d'outils existaient déjà
- Déchets de chantier (lot 198) : bois traité à part, benne indiquée pour chaque déchet, pots de peinture aux déchets dangereux et kilomètres jusqu'à la déchetterie. Volumes, big bags et voyages existaient déjà
- Coût réel du chantier (lot 199) : dans l'écran du temps passé, le temps de chaque étape face à la main-d'œuvre d'un artisan, au taux horaire saisi par l'utilisateur (aucun taux proposé), plus le matériel déjà payé. Le suivi du temps et le calcul « faire soi-même ou faire faire » existaient déjà
- Comparer des devis (lot 209) : deux ou trois devis recopiés poste par poste, écarts signalés et oublis courants (protection, finitions, évacuation des déchets, nettoyage)
- Projets prêts à suivre (lot 189) : étagère murale sur tasseau caché, châssis fixe à la place d'un plexi, mezzanine simple et embrasure de fenêtre de toit. Pour les cotes saisies : croquis en relief, débit des pièces, courses à ajouter à la liste, fiche imprimable et étapes, chacune reliée à son geste animé. Les trois modèles de reprises déjà là (rafraîchir une pièce, salle de bain, sol) restent dans l'onglet Reprises
- Mode atelier (lot 188) : en plein écran, écran gardé allumé, chronomètre en très gros chiffres, étape en cours en grand, boutons de 88 points de haut pour des gants, liste des étapes avec le temps passé sur chacune. On l'ouvre depuis un projet prêt à suivre ou depuis le mode chantier, où il reprend les reprises pas finies de la pièce et les coche une à une. Le mode chantier existant (écran allumé, voix, plinthes et rangées) est inchangé
- Mesure par photo avec une feuille A4 (lot 187) : l'étalon se choisit entre la carte bancaire (déjà là), le grand côté ou le petit côté d'une feuille A4. L'écran donne aussi la marge d'erreur, plus petite avec la feuille
- Partage d'un projet chiffré (lot 190) : dans le menu d'un chantier, un fichier `.atelier` protégé par mot de passe avec tout le chantier (pièces, croquis, débit, notes) et ses photos, factures et tickets. À l'import, les photos sont recopiées sur le téléphone. La sauvegarde chiffrée de tous les chantiers existait déjà, sans les photos
- Escaliers en relief (lot 191) : l'escalier droit ou tournant dessiné en relief dans l'écran Escalier, giron et hauteur de marche, échappée au-dessus de la dernière marche sous le plancher, trémie à prévoir, et l'alerte « on se cogne à partir de la marche n » selon la taille de la personne. Même règle que la trémie déjà calculée ; le tournant est dessiné en marches droites
- Soleil par la fenêtre de toit (lot 193) : position du soleil calculée sur le téléphone (latitude réglable, nord de la France par défaut, heure légale), tache de soleil au sol et sur le mur d'en face selon l'heure, la saison et l'orientation du toit, en relief, et les heures de soleil à l'endroit prévu pour un lit ou un bureau
- Charges en clair (lot 194) : ce que porte une tablette, une poutre en C24 ou une mezzanine (capacité du plancher de `floor_capacity`), traduit en cartons de livres, packs d'eau, adultes, sacs de ciment ou lave-linge ; flèche sous les objets posés, comparée à celle admise, et dessinée exagérée sur le croquis en relief
- Débit dans le commerce (lot 181) : toutes les pièces d'un projet (fenêtre bois, étagère, mezzanine, placard sous rampant, ou pièces saisies) optimisées dans des bois et panneaux de taille standard. Chaque section de bois et chaque épaisseur de panneau sont débitées à part, chaque barre prend la plus courte longueur vendue qui contient ses morceaux, le format de panneau est celui qui demande le moins de surface. Plan de coupe dessiné barre par barre et panneau par panneau, traits de scie comptés, chutes à garder, ajout aux courses
- Défauts du bois au magasin (lot 182) : nœud, fente, gerce, bois tors, voilé ou tuilé, humidité, chacun en schéma en relief exagéré ; liste à cocher au rayon, et tri d'une planche mesurée (bonne, à surveiller, à laisser) selon l'usage, avec des seuils indicatifs et la longueur utile une fois la fente recoupée
- Stock de l'atelier (lot 183) : vis, colles, finitions, quincaillerie communs à tous les chantiers, avec un seuil d'alerte par article. Le stock est réparti entre les chantiers dans leur ordre, d'après leurs courses (article lié) ou les articles ajoutés du même nom ; « Réserver pour ce chantier » le déduit de ses courses. Liste « À racheter », outils prêtés et chutes gardées de tous les chantiers réunis
- Prises et éclairage à placer : dans « Électricité du plan », chaque pièce dit combien de prises sont posées sur le minimum courant de la norme NF C 15-100 (valeurs usuelles, à vérifier). La pièce ouverte, avec son type deviné d'après son nom et modifiable, montre les prises qui manquent réparties sur les murs libres (loin des portes et des prises déjà posées), le point lumineux au centre du plafond et l'interrupteur près de la porte, dessinés sur son plan ; un bouton les pose. Hauteurs courantes, prises de la cuisine et rappel des volumes de la salle d'eau
- Salle d'eau, dans la douche de plain-pied : volumes de sécurité 1 et 2 autour de la douche (avec ou sans paroi) dessinés en relief et ce qui y est admis, pente du receveur avec verdict (trop faible, bien, trop forte), étanchéité liquide sous carrelage (surface, résine, pots, bandes, manchettes, ordre des couches) et ventilation (débit de la bouche, renouvellement du volume, détalonnage)
- Cuisine : triangle d'activité évier, plaque, réfrigérateur avec ses alertes, débit de la hotte d'après le volume de la pièce (repris d'une pièce saisie ou à la main), implantations qui tiennent (en I, face à face, en L, en U, îlot) et une cuisine en L dessinée en relief
- Carnet de la maison, côté caché : dans chaque pièce, une section « Derrière le placo » pour repérer les solives du plancher ou du plafond (mur de repère, première solive, entraxe, section, axes calculés) et prendre des photos des murs, du sol ou du plafond avant de fermer, avec une note. Un rappel signale les murs où des réseaux sont relevés sans photo
- Dossier de la maison pour une revente, en PDF depuis le carnet : pièce par pièce, chaque mur dessiné avec ses gaines et tuyaux en couleur, longueurs relevées, solives, fenêtres et leurs cotes, matériaux et références notés au carnet, photos d'avant fermeture
- Diagnostic thermique simple : pertes du toit, des murs, des fenêtres, du plancher et de l'air, en part du total et en kWh par an, la maison dessinée en relief avec la paroi qui perd le plus surlignée, travaux classés du plus rentable au moins rentable avec un coût indicatif, aides possibles à vérifier au moment des travaux (sans montant). Surfaces reprises des pièces depuis la tuile du chantier
- Rénovation énergétique pas à pas : toit, fenêtres, murs, chauffage, ventilation, pourquoi cet ordre, baisse estimée de la facture à chaque étape et ce qu'il en reste, estimation prudente (80 % du gain calculé, prix des énergies non comptés), rappel des aides à vérifier avant chaque devis
- Isolation des murs par l'intérieur : épaisseur d'isolant selon la résistance visée, pose sur fourrures métalliques, complexe collé ou ossature bois, pare-vapeur selon l'isolant, plaques, montants, rails, appuis ou mortier adhésif, surface habitable perdue pièce par pièce d'après les murs cochés, retours en tableau des fenêtres, coupe du doublage en relief
- « Je me suis trompé » : tenon trop lâche, planche tordue, trou mal placé, coulure de vernis, joint de mastic raté et pièce coupée trop court. Pour chacun, la cause, l'attente éventuelle avant de reprendre, la réparation en trois étapes, ce qu'on peut garder ou recouper, et un lien vers le geste animé à revoir. Fiche imprimable
- Bruit et voisinage : horaires habituels des travaux bruyants (semaine, samedi, dimanche et jours fériés, fêtes mobiles comprises), à confirmer auprès de la mairie, et ce qu'il en est en ce moment. Nouvelle attente « Outil bruyant le week-end » dans la carte des attentes d'un chantier : la notification arrive un quart d'heure avant la première plage du samedi ou du dimanche
- Mode apprentissage : six petits défis guidés (couper d'équerre, percer droit, poser un joint, couper deux onglets, tracer un trait de niveau, faire un tenon), chacun relié à son geste animé, avec l'essai à faire sur une chute et le critère de réussite. On note « réussi » ou « à refaire » ; le carnet est gardé dans les réglages, et un badge discret apparaît en haut de l'écran
- Par où commencer : une fiche par type de travaux (peinture, plinthes, parquet flottant, isolation, placo, carrelage, menuiserie, plomberie, électricité), rangée par niveau (facile, moyen, à confier à un pro). Chantier de référence, temps réaliste pour un débutant (deux à trois fois celui d'un artisan), outillage minimal repris de la caisse à outils plus les outils propres à acheter ou à louer avec un coût indicatif, trois erreurs classiques, et pour la plomberie et l'électricité ce qu'on peut faire seul et ce qu'on confie. Fiche imprimable
- Contrôles qualité étape par étape (traçage, ossature, support, pose, finitions) : diagonales égales pour l'équerrage, niveau, fil à plomb, planéité à la règle de 2 m, carreaux à fleur, avec des tolérances prudentes indiquées comme indicatives. Chaque contrôle se coche, se vérifie en saisissant la mesure (bon ou à reprendre) et, ouvert depuis le guide d'une pièce, reçoit des photos gardées avec la pièce
- Sécurité par outil : scie circulaire, défonceuse, meuleuse d'angle, échelle et produits de finition, chacun avec son schéma en relief, les protections à porter, les vérifications à cocher avant de brancher (ou de monter, ou d'ouvrir le pot) et les gestes interdits. L'échelle calcule la distance du pied au mur et la longueur utile, et renvoie au travail en hauteur
- Version web installable sur l'iPhone, sans compte Apple payant : publiée sur https://remiverhaeghe.github.io/atelier/ à chaque fusion sur main, à ajouter à l'écran d'accueil depuis Safari. Chantiers et réglages restent dans le stockage du navigateur, sur l'appareil ; un service worker garde l'appli utilisable hors ligne. Les fonctions propres au téléphone (photos enregistrées, télémètre Bluetooth, rappels programmés, sauvegardes datées, widget) ne sont pas encore disponibles dans cette version
- Isoler les rampants par l'intérieur : dans la pièce sous rampants, la surface où l'on tient debout perdue selon l'épaisseur d'isolant sous les rampants et contre les jambettes, ce qui reste, et la résistance thermique obtenue
- Fenêtre de toit : une fois la référence lue, les stores et volets à commander avec le code de taille de la plaque (MK08, ou 308 sur un ancien modèle) (occultant, plissé, vénitien, pare-soleil extérieur, volet roulant), avec ce que chacun fait contre la chaleur, et l'ajout aux courses
- Fiches de chantier imprimables aussi pour la fenêtre bois, l'embrasure, la mezzanine, l'escalier et la pièce sous rampants
- Choisir un panneau : contreplaqué, OSB, MDF, latté, mélaminé ou aggloméré selon l'usage (étagère, meuble, plancher, contreventement, pièce humide, dehors, meuble à peindre), structure de chaque panneau dessinée en relief, tenue de la vis, prix relatif et poids d'une plaque selon l'épaisseur
- Colles et serrage : la colle selon ce qu'on assemble (vinylique, D3, polyuréthane, contact, époxy, mastic-colle), temps d'assemblage, de serrage et de prise, et nombre de serre-joints selon la longueur du collage
- Huit mots de plus au lexique, avec leur schéma en relief : lambourde, liteau, suspente, appui, goutte d'eau, onglet, nœud et fente
- Grille des calculs rangée par familles : une rangée de puces en haut (bien commencer, bois et menuiserie, combles et toit, murs, sols et plafonds, confort et réseaux, dehors, chantier) n'affiche que la famille choisie
- Caisse à outils du débutant : l'indispensable et ce qui vient ensuite, avec une fourchette de prix indicative et les gestes où chaque outil sert ; on coche ce qu'on a, l'écran dit ce qui manque et combien ça coûte, et l'ajoute aux courses. Chaque geste affiche aussi ses outils
- Cinq gestes de plus : poser une cheville, couper une plaque de plâtre, couper un onglet à 45°, tracer au niveau laser, faire les joints du carrelage
- Fiches de chantier imprimables : un bouton « Imprimer la fiche » dans les finitions, le faux plafond, le placard sous rampant et chaque geste de base. Une page A4 avec les mesures saisies, ce qu'il faut retenir, les achats et les étapes à cocher, et des lignes pour les notes
- Pièce sous rampants en relief : à côté de la coupe manipulable au doigt, la pièce tirée sur sa longueur, la bande où l'on tient debout surlignée au sol et la ligne des 1,80 m de chaque côté
- Gestes de base pour débuter : scier droit, raboter, percer, visser, poncer, creuser une mortaise et faire un joint de mastic, chacun joué en croquis animé en relief (quelques passes, puis l'outil reste au bout du geste ; un bouton rejoue), avec à quoi ça sert, les trois étapes, l'erreur courante, les protections à porter et les mots du métier. Tuile en tête des calculs, et lien depuis le lexique
- Huit mots de plus au lexique, avec leur schéma en relief : fil du bois, chant, chanfrein, trait de scie, avant-trou, fraisure, fourrure et pare-vapeur. Le faux plafond renvoie à « Fourrure », la condensation à « Pare-vapeur »
- Finitions du bois : lasure, vernis, vitrificateur, huile, cire et peinture microporeuse, choisies selon l'usage (meuble, sol, dehors), avec les litres, les pots les moins chers, l'attente entre les couches, l'entretien et une coupe en relief qui montre un film posé dessus ou une finition qui entre dans le bois
- Humidité et condensation : point de rosée de la pièce, température de la paroi côté intérieur (vitrage, mur ou rampant, isolé ou non), verdict, humidité à ne pas dépasser et conseils (aération, pare-vapeur, chauffage régulier)
- Faux plafond pour les pièces trop hautes : vide restant au-dessus, type de suspentes selon ce vide, fourrures, suspentes, tiges filetées, éclisses, cornières, plaques et vis, volume en moins à chauffer, alerte sous 2,20 m, et une coupe en relief
- Placard sous rampant : où poser la façade, volume de rangement, modules à une porte, montants coupés à l'angle du toit, portes et charnières, bacs sur roulettes qui vont chercher le fond, tablette, panneaux à acheter, et le placard dessiné en relief avec une porte ouverte

### Documentation
- Captures de `docs/captures/` refaites avec l'habillage carnet d'atelier, et dix nouvelles : pièce sous rampants, fenêtre bois, embrasure, lexique, finitions, condensation, faux plafond, placard sous rampant et geste « scier droit »

### Corrigé
- Croquis en relief : une étiquette plus large que le dessin (écran très étroit) faisait planter l'affichage ; elle est maintenant centrée
- Plantage au premier accès au stockage (chantiers, sauvegarde du jour) : `jni` 1.2.0 ne retrouve plus les classes Android demandées par `path_provider_android`, il est bloqué sous 1.2 en attendant une mise à jour du greffon

### Outillage
- CI plus rapide : tous les tests réunis dans un seul fichier compilé une fois (`tool/tous_les_tests.sh`) et répartis sur trois machines (couverture de `lib/logic` fusionnée), APK construite en même temps que les tests avec un cache Gradle et, sur une pull request, pour arm64 seulement ; les contrôles d'un commit dépassé sur une branche sont arrêtés
- Workflow « Mise en forme » : sur une pull request, `dart format` est appliqué et recommité sur la branche, puis les contrôles sont relancés sur le commit mis en forme

### Étanchéité des fenêtres
- Carte « Étanchéité de la pose » dans la fenêtre bois : but expliqué, coupe du tableau en relief (mousse imprégnée, mastic, adhésif pare-vapeur), mousse choisie selon le jeu, mètres et cartouches de mastic, rouleaux, pente de l'appui et goutte d'eau, ordre de pose

### Choix du bois
- Carte « Quel bois prendre » dans la fenêtre bois, la pergola, la mezzanine et l'étagère murale : classe d'emploi de l'usage, essences qui conviennent sans traitement du moins cher au plus cher, conseils de travail et de quincaillerie, alerte si l'essence choisie ne tient pas

### Lexique illustré
- Chaque mot du métier s'explique par « à quoi ça sert », puis « c'est quoi », avec un schéma en relief où la pièce concernée est surlignée (tenon et mortaise, feuillure, parclose, chevêtre, jambette…)
- La fenêtre bois est dessinée en relief, avec son épaisseur et le vitrage au milieu

### Référence de fenêtre de toit
- La référence lue sur la plaque de la fenêtre en place (MK08, GGL CK04, ou l'ancienne 308) donne la taille du cadre et règle le calcul sur la même largeur

### Embrasure de fenêtre de toit et lexique
- Nouveau calcul : embrasure à haut horizontal et bas vertical pour faire entrer le plus de lumière, coupe dessinée, ouverture à faire dans le rampant, plaques à découper
- Lexique des mots du métier (chevron, jambette, chevêtre, feuillure, tenon…) en langage courant, depuis l'écran des calculs, et puces « Mots du métier » sous les calculs concernés

### Fenêtre bois sur mesure
- Nouveau calcul pour remplacer un plexi par un châssis fixe : croquis coté du châssis, débit des montants et traverses, tenons et mortaises, feuillure, vitrage à commander et son poids, parcloses, ordre de fabrication

### Carnet d'atelier
- Les écrans sont posés sur une feuille quadrillée, comme un carnet de chantier (fond uni en mode nuit)
- Nouveau calcul « Pièce sous rampants » : coupe cotée dessinée au crayon et à l'échelle, surface habitable (au-dessus de 1,80 m), hauteur au faîtage ou au plafond plat, longueur des rampants, plaques à poser ; angle mesuré en posant le téléphone sur le rampant
- « Comment c'est calculé » : les étapes du résultat, dépliables sous le calcul
- Fiches de carnet au lieu des cartes (bord de papier, ruban adhésif, ombre légère), icônes des tuiles dessinées au trait
- Croquis écrit à la main (police Caveat, licence OFL), tracé au crayon à l'ouverture, et modifiable au doigt : poignées de la jambette et du sommet
### Installation simplifiée
- Chaque fusion sur main publie l'APK signée dans une préversion `build-N`, à suivre avec Obtainium pour installer et mettre à jour en un clic ; numéro de construction croissant pour que chaque APK remplace la précédente

### Écho d'une grande pièce
- Nouveau calcul : réverbération par la formule de Sabine selon le sol, le plafond et le mobilier, nombre de panneaux acoustiques pour revenir à 0,6 s

### Éclairage d'une pièce
- Nouveau calcul : flux nécessaire selon l'usage, nombre de lampes, quadrillage avec un écart d'au plus 1,5 fois la hauteur, puissance en LED, grande hauteur comprise

### Chauffer un grand volume
- Nouveau calcul pour les grandes hauteurs : puissance par le volume, pertes de l'air chaud sous le plafond, radiateurs, poêle de puissance courante, nombre et diamètre des brasseurs d'air, conseil rayonnement ou convection

### Échafaudage roulant
- Carte dans « Travail en hauteur » : hauteur du plancher pour atteindre un plafond, nombre d'éléments, garde-corps, stabilisateurs selon la base et le vent, limite au-delà de laquelle on fait appel à un professionnel

### Fenêtre de toit à la place d'un plexi
- Nouveau calcul : vide entre chevrons, fenêtre la plus large sans rien couper, fenêtre retenue pour la largeur voulue, chevêtre quand il faut couper un chevron, hauteur selon la pente, raccord selon la couverture et ordre de pose

### Sauvegarde chiffrée
- Écran Sauvegardes : tous les chantiers dans un fichier `.atelier` chiffré par mot de passe (AES-256-GCM, PBKDF2), à envoyer vers le PC ou un cloud ; l'import le reconnaît et demande le mot de passe

### Travail en hauteur
- Nouvel écran : vérifications à cocher avant de monter, selon la hauteur de travail et le travail sur un toit (escabeau, garde-corps, échafaudage freiné, zone balisée, harnais, météo)

### Courses par rayon
- Courses : les articles sans magasin saisi se rangent par rayon conseillé (bois, sols, peinture, colles, matériaux, quincaillerie), dans l'ordre d'un parcours en magasin ; le matériel ajouté depuis un calcul aussi

### Tiroirs et charnières
- Armoire : compartiment à tiroirs, avec façades, caissons (côtés, avant et arrière, fond) et coulisses à billes de la plus grande longueur qui tient ; une porte seulement sur les autres compartiments
- Position de chaque charnière sur la porte, à 10 cm des bords et régulièrement entre, cuvette de 35 mm à 22 mm du bord

### Étagère en niche ou sous rampant
- Nouveau calcul : tablettes sur tasseaux dans une niche (longueur avec jeu, tasseaux, vis) ou meuble sous un rampant de combles (montants coupés à l'angle de la pente, profondeur de chaque tablette)

### Ce que porte un plancher
- Nouveau calcul : charge que tient un plancher existant d'après ses solives mesurées, comparée à une chambre, une baignoire, une bibliothèque, un poêle ; effet des renforts (solives doublées, solive de plus entre chaque, poutre au milieu)

### Garde-corps d'escalier
- Escalier : garde-corps et main courante selon les côtés dans le vide (aucun, un, deux) ; longueur en pente, poteaux, barreaux et mains courantes, règles de la norme NF P01-012

### Escalier tournant
- Escalier : forme droite, quart tournant ou demi-tournant ; emprise au sol, volées avant et après le tournant, marches du tournant et marches balancées, sur une ligne de foulée au milieu de l'emmarchement

### Ajouter aux courses depuis un calcul
- Mezzanine, pergola, étagère et tablette murale : bouton « Ajouter aux courses » qui envoie bois, quincaillerie, panneaux et béton dans la liste du chantier choisi ; un article déjà là voit sa quantité augmenter
- Courses : carte « Ajouté depuis les calculs », chaque article retirable

### Gabarit de perçage
- Étagère : gabarit à imprimer à l'échelle 1 pour les tourillons, les vis d'assemblage ou les taquets (système 32 mm), avec une règle de contrôle de 10 cm

### Pergola ou auvent
- Nouveau calcul : pergola adossée ou indépendante, couverture (ouverte, polycarbonate, bac acier, tuiles) et région de neige ; chevrons, poutres et poteaux dimensionnés comme la mezzanine, plots en béton, rappel du vent qui soulève une couverture pleine

### Mezzanine en 3D
- Vue 3D de la maison : une mezzanine posée sur le plan apparaît à la hauteur de son plancher, avec ses chants et un poteau à chaque angle

### Mezzanine dans une pièce haute
- Hauteur sous plafond de la pièce : plancher placé au plus bas qui laisse 2,20 m sous la poutre, hauteur restante au-dessus (habitable dès 1,80 m, debout à 2,20 m), poteaux ramenés à la bonne hauteur d'un bouton, escalier ouvert à la hauteur du plancher

### Trémie et chevêtre
- Mezzanine : trémie d'escalier dans le plancher, avec solives coupées, longueur des solives boiteuses, chevêtre et solives d'enchevêtrure doublés dimensionnés comme les solives, sabots ; trémie trop longue signalée

### Débit des bois de la mezzanine
- Mezzanine : longueurs du commerce à acheter (3 à 6 m) choisies pour le moins de bois, coupes à faire, trait de scie compris ; poutre en lamellé-collé commandée à la longueur, pièces de plus de 6 m signalées

### Plancher et garde-corps de mezzanine
- Mezzanine : plancher en OSB/3 ou aggloméré P5 rainuré, épaisseur selon l'entraxe des solives, panneaux chutes comprises, vis, colle et conseils de pose
- Garde-corps selon la norme NF P01-012 : bord dans le vide selon l'appui, accès à l'escalier déduit, poteaux, barreaux verticaux, main courante et lisse basse

### Structure de mezzanine
- Nouveau calcul : mezzanine contre un mur, entre deux murs ou indépendante. Solives en C24 et poutre en lamellé-collé choisies par la flexion et une flèche limitée à 1/300, poteaux vérifiés au flambement, un poteau de plus au-delà de 4 m, lambourde et chevilles au mur, sabots, contreventement. Présenté comme un prédimensionnement à faire valider

### Assemblages d'étagère
- Étagère : épaisseur conseillée selon ce qu'elle porte (objets légers, livres, lourd), ou montant au milieu quand aucune ne suffit
- Assemblage des tablettes selon le panneau : vis d'assemblage dans l'aggloméré et le MDF, tourillons collés dans le bois avec diamètres et profondeurs de perçage, taquets pour des tablettes réglables
- Tenue : fixation au mur anti-basculement au-delà d'un mètre, traverse et équerres d'angle sans fond
- Nouveau calcul : tablette murale sur équerres, avec nombre et écart des équerres, débord, longueur du bras, poids chargé, traction sur la vis du haut et chevilles selon le mur

### Mesure par photo
- Nouveau calcul : sur une photo prise de face, le grand côté d'une carte au format bancaire posée à plat donne l'échelle, puis deux points donnent la longueur

### Fiche Play Store
- Descriptions courte et longue de la fiche à jour dans `docs/play-store/description.md`, longueurs vérifiées par un test ; liste de publication complétée pour les permissions et le micro

### Performance surveillée
- Un test chronomètre la vue 3D, le glTF et les courses d'une grande maison fictive de 40 pièces meublées : un calcul qui deviendrait beaucoup plus lent fait échouer la CI

### Accessibilité
- Tests des règles d'accessibilité sur l'accueil, le chantier et les calculs : boutons nommés pour TalkBack, cibles de 48 dp au moins, contraste du texte

### Tests de mutation
- `tool/mutation.py` glisse une erreur à la fois dans `lib/logic` (comparaison, opérateur, arrondi) et vérifie qu'un test la voit ; workflow à la demande et chaque lundi, score minimal de 70 %

### CI
- Tests sur émulateur : dépendances Gradle et émulateur gardés en cache, avec son instantané, pour un passage plus court et moins d'échecs réseau

### Permissions contrôlées
- `docs/securite.md` explique chaque permission ; la CI fait échouer la construction si la permission Internet apparaît dans l'APK ou si une permission n'y est pas expliquée

### Visite de la maison
- Nouvelle tuile Visite : tour des pièces avec dix points à regarder chacune (humidité, fissures, prises, fenêtres…) et cinq pour toute la maison ; les points cochés passent dans les reprises avec leur note

### Stock restant
- Les courses montrent ce qui restera du stock une fois le chantier fini, à garder pour les retouches ou à rapporter au magasin

### Dossier de devis
- Le menu du chantier prépare un PDF à envoyer aux artisans : plan et mesures de chaque pièce, travaux demandés avec photos, et ce qu'un devis doit préciser, pour comparer des devis sur la même base

### Plan en DXF
- Le menu du chantier exporte le plan de la maison en DXF : un calque par pièce, les murs en lignes et le nom de la pièce, en millimètres, pour un logiciel de dessin

### Annuler et refaire
- Dans une pièce, deux boutons annulent ou refont les dernières modifications (30 étapes, une saisie rapide comptant pour une seule)

### Télémètre laser
- Le champ de longueur d'un mur a un bouton télémètre : relié en Bluetooth à un Bosch GLM 50 C, 50-27 C et CG, 100 C, 120 C ou PLR 30, 40 et 50 C, la mesure faite avec le bouton de l'appareil remplit la longueur

### Modèles de chantier
- Dans les reprises, « Ajouter un modèle » ajoute d'un coup les étapes types d'un rafraîchissement, d'une salle de bain ou d'un changement de sol, avec leurs passages, sans doubler celles déjà notées

### Garanties
- Nouvelle tuile Garanties : conformité, parfait achèvement, biennale, décennale ou garantie du fabricant, date de fin, et celles qui finissent dans moins de deux mois en tête

### Laine soufflée
- Nouveau calcul : épaisseur à souffler en combles pour la résistance visée (R = 7 par défaut), tassement compris, sacs et piges de repère, pour la laine de verre, de roche ou la ouate de cellulose

### Gouttières
- Nouveau calcul : descentes et diamètre selon la surface du pan en plan, pente de 5 mm par mètre, crochets

### Béton
- Nouveau calcul : volume d'une dalle ou de plots, dosage à 350 kg en sacs de ciment, sable, gravier et eau, gâchées de bétonnière, sacs prêts à gâcher, et conseil de toupie à partir d'un mètre cube

### Papier peint
- Nouveau calcul : lés par rouleau selon la hauteur et le raccord du motif, rouleaux et colle, murs repris d'une pièce ouvertures déduites ; prévient quand les murs dépassent la longueur d'un rouleau

### Sol souple et moquette
- Nouveau calcul : lés selon la largeur du rouleau et le raccord du motif, sens de pose qui économise le plus, joints, colle ; dimensions reprises d'une pièce

### Ordre des travaux
- Le planning signale une étape faite avant une étape qui aurait dû la précéder (parquet posé avant la peinture des murs), pour protéger ce qui est fini

### Météo des travaux extérieurs
- Nouveau calcul : les prévisions recopiées jour par jour disent quels jours conviennent à une peinture de façade, un enduit, du béton, une lasure ou un travail sur le toit (froid, chaleur, pluie, gel après, vent)

### Liste à envoyer
- Dans les courses, « Envoyer la liste à acheter » partage par SMS ou message ce qui reste à acheter, par magasin, avec quantités et références, sans les prix

### Outils prêtés
- Nouvelle tuile Prêts : outil, à qui et depuis quand, signalé au-delà de deux semaines, rendu d'un appui

### Dupliquer une pièce
- Une pièce se duplique à l'identique ou en miroir (murs dans l'ordre inverse, ouvertures recomptées depuis l'autre bout), avancement remis à zéro ; le miroir ne reprend pas ce qui est placé par coordonnées

### Nouveautés
- Après une mise à jour, une fenêtre présente les nouveautés une seule fois ; rien à la première installation

### Mode nuit
- Le mode chantier a un mode nuit : fond noir, rouge sombre qui n'éblouit pas sous les combles, textes agrandis

### Livraison vérifiée
- Dans les courses, « Vérifier une livraison » compte ce qui est arrivé ligne par ligne contre la commande, signale les manques et le surplus, et rappelle comment noter des réserves

### Achat relié à son ticket
- Une dépense peut couvrir des articles cochés dans les courses ; la ligne achetée rappelle alors le ticket (jour, magasin, montant) et en ouvre la photo, pour une garantie ou un retour

### Avant de percer
- « Puis-je percer ici ? » donne aussi, pour un endroit sûr, la cheville, le foret, la vis et le nombre de fixations selon la matière du mur et le poids accroché

### Humidité avant la pose
- Nouvelle tuile : relevés de l'humidimètre pour la chape ciment, la chape anhydrite et le bois, feu vert pour poser le parquet et jours restants estimés au rythme du séchage

### Format des données
- Les chantiers enregistrés passent par des étapes de migration numérotées : un changement de format ne casse plus les sauvegardes existantes
- Un fichier d'une version plus récente de l'appli est refusé avec un message clair, et un fichier illisible est copié à part (`chantiers.json.illisible`) avant de repartir de zéro

### Documentation
- README : présentation à jour, tableau des domaines couverts à la place de l'avancement arrêté au lot 17

### Commandes vocales
- Bouton micro dans le mode chantier : « coupe faite », « répète la rangée » ou juste « fait » quand une seule tâche reste ouverte ; la réponse est lue à voix haute

### Widget d'écran d'accueil
- Un widget Android affiche le chantier du jour, l'avancement de l'objectif et la prochaine attente ; un appui ouvre l'appli. L'appli écrit ses lignes dans un fichier, que le widget relit toutes les 30 minutes, sans dépendance de plus

### Notification des attentes
- Une attente lancée (séchage, acclimatation) prévient par une notification Android quand elle est finie, même appli fermée ; la retirer annule la notification. Rien ne passe par le réseau

### Façade et clôture
- Nouveau calcul : surface d'une façade avec son pignon, peinture et sacs d'enduit ; clôture en panneaux rigides avec poteaux, béton et dernier panneau recoupé

### Cuisine
- Nouveau calcul : meubles bas pour un ou deux linéaires avec le moins de meubles possible et un fileur, plans de travail à acheter, hauteurs du plan, des meubles hauts et de la hotte

### Tablette et paysage
- Sur tablette ou en paysage, le plan de la pièce reste à gauche pendant qu'on parcourt les murs ; les tuiles d'accueil et les calculs prennent plus de colonnes

### Ticket de caisse
- Dans une dépense, « Coller le texte du ticket » lit le magasin, la date et le total du texte copié depuis la photo (appareil photo ou Google Lens), sans réseau ; le sous-total est ignoré

### Chantier partagé
- À l'import d'un chantier qu'on a déjà, l'appli propose de le fusionner : pièces, dépenses, carnet, temps et outils ajoutés sans rien effacer, pièce changée des deux côtés gardée en double

### Recherche
- Loupe sur l'accueil : chantiers, pièces, carnet (produits et références), calculs et fiches conseils, sans tenir compte des accents ni des majuscules

### Plan papier décalqué
- Une pièce sans murs peut partir de la photo d'un plan papier : deux points d'une cote connue donnent l'échelle, les coins touchés dans l'ordre donnent les murs, angles presque droits ramenés à 90°

### Échéancier du budget
- Dans les courses : dépenses mois par mois, somme mise de côté chaque mois, et le reste à payer étalé jusqu'au mois où tout sera réglé

### Douche de plain-pied
- Nouveau calcul : pente de 2 % vers la bonde ou le caniveau, hauteur à réserver au-dessus de la dalle avec le siphon et la pente du tuyau, surfaces d'étanchéité sous carrelage et bandes d'angle

### Isolation phonique
- Nouveau calcul : cloison ou plancher de mezzanine, plaques phoniques, laine, bande résiliente, mastic acoustique, suspentes antivibratiles et sous-couche, avec les gestes qui évitent les fuites de bruit

### Faire soi-même ou faire faire
- Nouveau calcul : le devis de l'artisan face au matériel, aux outils et au temps (compté double la première fois), aides réservées aux artisans RGE déduites, et ce que rapporte chaque heure passée

### Gravats et déchetterie
- Nouveau calcul : volume en vrac et poids de ce qu'on démolit, big bags et voyages de remorque comptés benne par benne, conseils de tri

### Carnet en PDF
- Le carnet de la maison s'imprime en PDF : pièce par pièce, produits, références, coûts, photos d'avant et d'après et factures

### Meubles en 3D
- Les meubles posés sur le plan apparaissent en volume dans la vue 3D et le fichier glTF, à leur hauteur courante
- L'export Home Assistant liste les meubles de chaque pièce (type, largeur, profondeur)

### Plexis et relevé thermique
- Le relevé thermique d'une pièce à plexis de toit les rappelle en tête, et ouvre le calcul du cadre qui les remplacera

### Électricité du plan
- Tuile « Électricité du plan » : circuits de prises et d'éclairage, gaines, fils et boîtes d'après les prises et interrupteurs posés sur les plans

### Escalier droit
- Nouveau calcul : coupe dessinée, hauteurs et giron par la loi de Blondel, marches et limons à débiter, trémie nécessaire pour garder 1,90 m d'échappée

### Chauffage
- Tuile « Chauffage » : puissance par pièce habitable selon le volume, l'isolation et la température de base, radiateurs courants conseillés, pertes des plexis, brasseur d'air sous grande hauteur

### Avant / après
- Une entrée du carnet reçoit sa photo d'avant ; avec celle d'après, « Avant / après » les superpose et la séparation suit le doigt

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
