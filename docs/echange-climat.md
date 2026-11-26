# Échange des relevés de capteurs

Atelier lit les relevés de plusieurs thermo-hygromètres d'un coup (écran « Capteurs de la maison » du
chantier). Deux formes de fichier sont reconnues.

## Export CSV d'un capteur

Le fichier exporté par l'appli du capteur : colonnes date, température et humidité reconnues à leur
titre. Le nom du fichier désigne la pièce : `Salle de bain.csv` va dans la pièce « Salle de bain ».
Un nom plus long qui contient celui d'une pièce convient aussi (`Capteur salle de bain.csv`). Quand
aucune pièce ne convient, ou que deux conviennent aussi bien, l'écran demande laquelle.

## Fichier d'échange JSON

Pour un logiciel qui range plusieurs capteurs dans un même fichier, comme le futur projet de domotique :

```json
{
  "version": 1,
  "sensors": [
    {
      "name": "Salle de bain",
      "readings": [{ "at": "2026-12-01T08:00:00", "temp": 20.5, "humidity": 61 }]
    }
  ]
}
```

- `version` vaut 1 ; un autre numéro est refusé.
- `name` suit la même règle que le nom d'un fichier CSV.
- `at` est une date ISO 8601, `temp` en °C, `humidity` en %. Un relevé invalide est ignoré.

Seules les moyennes de chaque jour sont gardées dans la pièce (deux ans au plus) ; ré-importer un
capteur remplace les jours déjà là, sans les doubler.
