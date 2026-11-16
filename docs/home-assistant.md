# Export pour Home Assistant

« Exporter pour Home Assistant », dans le menu d'un chantier, partage un fichier JSON avec les étages et les pièces de la maison, prêts à recréer dans Home Assistant.

## Contenu

```json
{
  "format": "atelier-home-assistant",
  "version": 1,
  "name": "Maison",
  "floors": [
    { "floor_id": "niveau_0", "name": "Rez-de-chaussée", "level": 0 },
    { "floor_id": "niveau_1", "name": "1er étage", "level": 1 }
  ],
  "areas": [
    {
      "area_id": "salon",
      "name": "Salon",
      "floor_id": "niveau_0",
      "icon": "mdi:sofa",
      "area_m2": 24.5,
      "sockets": 6,
      "switches": 2
    }
  ]
}
```

| Champ | Sens |
|---|---|
| `floors` | Un étage Home Assistant par niveau de la maison, `level` comme dans Home Assistant (0 au rez-de-chaussée, négatif en sous-sol) |
| `areas[].area_id` | Identifiant de la zone : nom de la pièce sans accent ni espace, suffixé `_2`, `_3` en cas de doublon |
| `areas[].icon` | Icône devinée d'après le nom (`mdi:bed` pour une chambre, `mdi:floor-plan` par défaut) |
| `areas[].area_m2` | Surface au sol, absente pour une zone sans murs |
| `areas[].sockets`, `switches` | Prises et interrupteurs placés sur le plan : un repère pour les modules à prévoir |

## Créer les zones

Dans Home Assistant, Paramètres, Zones, étiquettes et zones :

1. Créer chaque étage de `floors`, avec son niveau.
2. Créer chaque zone de `areas`, avec son nom, son icône et son étage.

Pour automatiser, l'API WebSocket de Home Assistant accepte `config/floor_registry/create` (`name`, `level`) puis `config/area_registry/create` (`name`, `icon`, `floor_id`) : un script lancé sur le réseau de la maison peut parcourir le fichier. Atelier ne s'y connecte pas lui-même, il n'a pas accès au réseau.

Le plan complet (murs, ouvertures, prises placées au millimètre) reste dans l'export du plan, décrit dans [format-plan.md](format-plan.md).
