# Format du plan exporté

Atelier exporte le plan d'un chantier dans un fichier JSON, pour qu'une autre application (domotique, vue 3D) réutilise les mesures sans les ressaisir. Menu du chantier, « Exporter le plan ».

Le format est versionné. Une évolution compatible (champ ajouté) garde la version ; une évolution incompatible l'augmente.

## Version 1

Toutes les longueurs sont en millimètres, les angles en degrés.

```json
{
  "format": "atelier-plan",
  "version": 1,
  "units": "mm",
  "name": "Maison",
  "rooms": [
    {
      "id": "1731745200000000",
      "name": "Salon",
      "closed": true,
      "ceilingHeight": 2500,
      "floorArea": 15120000,
      "outline": [[0, 0], [4200, 0], [4200, 3600], [0, 3600]],
      "walls": [
        {
          "length": 4200,
          "angleToNext": 90,
          "openings": [
            { "kind": "window", "offset": 1000, "width": 1200, "height": 1250, "sill": 900 }
          ]
        }
      ]
    }
  ]
}
```

| Champ | Sens |
|---|---|
| `rooms` | Pièces qui ont au moins trois murs ; les zones sans murs (toit, extérieur) ne sont pas exportées |
| `closed` | Le dernier mur rejoint le premier |
| `ceilingHeight` | Hauteur sous plafond |
| `level` | Niveau : 0 pour le rez-de-chaussée, 1 pour le premier étage, -1 pour le sous-sol |
| `floorLevel` | Altitude du sol de la pièce par rapport au rez-de-chaussée, planchers de 20 cm compris |
| `slope` | Plafond rampant, absent pour un plafond plat : bas de `low` le long du mur numéro `wall` (à partir de 0), il remonte à `ceilingHeight` sur `run` mesurés au sol |
| `slope2` | Second pan, même forme que `slope`, sur un autre mur ; la hauteur retenue est celle du pan le plus bas |
| `house` | Place de la pièce dans le plan de la maison : le contour tourne de `quarterTurns` quarts de tour (sens inverse des aiguilles d'une montre) puis se décale de `x` et `y` |
| `floorArea` | Surface au sol en mm², zones sans parquet déduites |
| `outline` | Un sommet par début de mur. Le premier mur part de l'origine vers les x croissants, la pièce est parcourue dans le sens inverse des aiguilles d'une montre, y vers le haut |
| `walls[].angleToNext` | Angle intérieur avec le mur suivant : 90 pour un coin rentrant, 270 pour un coin sortant |
| `openings[].kind` | `door`, `passage` ou `window` |
| `openings[].offset` | Distance depuis le début du mur |
| `openings[].sill` | Hauteur du bas de l'ouverture au-dessus du sol : 0 pour une porte |
| `fixtures[].kind` | `socket` (prise), `lightSwitch` (interrupteur), `stairs` (escalier), `mezzanine`, `roofWindow` (fenêtre de toit), `stairwell` (trémie d'escalier, sans sol) |
| `fixtures[].x`, `y` | Centre de l'élément, dans le repère de la pièce |
| `fixtures[].width`, `depth` | Taille sur le plan, le long des x et des y, pour les éléments qui ont une surface |
| `fixtures[].count` | Nombre de prises ou d'interrupteurs regroupés au même endroit, absent pour 1 |

Les champs `fixtures`, `slope`, `slope2`, `level` et `floorLevel` sont apparus après la première publication du format : un lecteur de la version 1 doit les tolérer absents.

Chaque pièce a son propre repère (`outline`) ; le champ `house` la place dans le plan de la maison, réglé dans Atelier par « Plan de la maison ».
