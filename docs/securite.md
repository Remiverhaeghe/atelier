# Sécurité et permissions

Atelier garde tout sur le téléphone. Il n'a pas la permission Internet : il ne peut rien envoyer de lui-même. Les exports et partages passent par le menu de partage d'Android, toujours à la demande de l'utilisateur.

La CI vérifie à chaque construction les permissions de l'APK (`aapt2 dump permissions`). Elle échoue si `android.permission.INTERNET` apparaît, ou si une permission n'est pas expliquée ici. Une dépendance qui en ajoute une ne passe donc pas inaperçue.

## Permissions demandées

| Permission | Pourquoi | Quand |
|---|---|---|
| `android.permission.POST_NOTIFICATIONS` | Prévenir de la fin d'une attente (séchage, acclimatation) | Demandée à la première attente lancée, Android 13 et plus |
| `android.permission.RECEIVE_BOOT_COMPLETED` | Reprogrammer les notifications après un redémarrage | Sans demande |
| `android.permission.VIBRATE` | Vibration des notifications | Sans demande |
| `android.permission.WAKE_LOCK` | Garder l'écran allumé en mode chantier | Sans demande |
| `android.permission.RECORD_AUDIO` | Commandes vocales du mode chantier | Demandée au premier appui sur le micro |
| `android.permission.BLUETOOTH_SCAN` | Trouver un télémètre laser, sans localisation | Demandée à l'ouverture du télémètre, Android 12 et plus |
| `android.permission.BLUETOOTH_CONNECT` | Se relier au télémètre | Idem |
| `android.permission.BLUETOOTH` | Bluetooth sur Android 11 et avant | Sans demande |
| `android.permission.BLUETOOTH_ADMIN` | Recherche Bluetooth sur Android 11 et avant | Sans demande |
| `android.permission.ACCESS_FINE_LOCATION` | Exigée par Android 11 et avant pour chercher un appareil Bluetooth ; la position n'est jamais lue | Demandée à l'ouverture du télémètre, Android 11 et avant |
| `android.permission.ACCESS_COARSE_LOCATION` | Idem, ajoutée par la bibliothèque Bluetooth | Idem |
| `fr.remiverhaeghe.atelier.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | Ajoutée par AndroidX pour protéger les récepteurs internes de l'appli | Sans demande |

## Ce que l'appli ne fait pas

- Pas de permission caméra ni galerie : une photo passe par l'appareil photo ou le sélecteur d'Android, à la demande.
- Pas de traceur, de publicité ni de mesure d'audience. Le journal des plantages reste sur le téléphone et ne part que si l'utilisateur le partage.
- La reconnaissance vocale passe par le service du téléphone. Chez Google, elle peut partir vers ses serveurs si le français n'est pas installé hors ligne ; Atelier ne garde que l'action comprise.

## Données

- Chantiers dans `chantiers.json`, dans le dossier privé de l'appli, avec une copie de sauvegarde par jour.
- Format numéroté et migré étape par étape (`lib/logic/data_format.dart`) ; un fichier illisible est copié à part avant de repartir de zéro.
