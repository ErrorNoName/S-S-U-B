# Steam Snapshot Manager UI

## 📋 Table des Matières
- [📖 Description](#-description)
- [🚀 Fonctionnalités](#-fonctionnalités)
- [🔧 Installation](#-installation)
- [🛠️ Utilisation](#-utilisation)
- [⚙️ Configuration](#-configuration)
- [🐞 Résolution des Problèmes](#-résolution-des-problèmes)
- [⚠️ Avertissements Importants](#-avertissements-importants)
- [📄 Licence](#-licence)
- [🙏 Remerciements](#-remerciements)

## 📖 Description

**Steam Snapshot Manager UI** est un script Bash innovant conçu pour les utilisateurs d'ArchLinux qui souhaitent reprendre le contrôle de leurs jeux Steam.  
Il propose une interface en mode texte graphique ultra conviviale grâce à **dialog**, permettant de gérer les snapshots (copies de sauvegarde) de vos jeux, de restaurer des versions antérieures et de bloquer ou débloquer les mises à jour automatiques.  
De plus, il intègre un mod loader/App Store spécialement pensé pour installer ou noter des mods/plugins (comme pour VRChat), avec une communication automatisée via Discord pour signaler les demandes d'amélioration.

## 🚀 Fonctionnalités

- **Interface Graphique en Mode Texte**  
  Une navigation intuitive via `dialog` pour accéder rapidement aux fonctionnalités.

- **Gestion des Snapshots**  
  - Création automatique d'un snapshot avec identifiant unique (basé sur la date et l'heure).
  - Restauration simple et sécurisée d'une version antérieure en remplaçant entièrement le dossier du jeu.

- **Blocage/Déblocage des Mises à Jour**  
  - Empêcher les mises à jour en rendant le fichier manifeste Steam (appmanifest_*.acf) **immutable**.
  - Rétablir les permissions quand nécessaire.

- **Mod Store Intégré**  
  - Parcours et installation des mods/plugins directement depuis GitHub (branche personnalisable, par exemple "VRChat").
  - Possibilité de noter un mod (fonctionnel ou non) et d'envoyer une demande de mise à jour via webhook Discord.
  - Indicateurs visuels (🟢 pour à jour, 🟠 pour obsolète) basés sur la date du dernier commit.

- **Opérations Sécurisées et Confirmaées**  
  - Demande de confirmation avant toute opération destructive (par exemple, restauration de snapshot).

## 🔧 Installation

### Prérequis
- **Bash** (installé par défaut sur ArchLinux)
- **dialog**  
  Installez-le avec :
  ```bash
  sudo pacman -S dialog
  ```
- **rsync** (pour la copie et la synchronisation des dossiers)
- **chattr** (inclus dans le paquet e2fsprogs)
- **curl**, **jq** et **unzip** (pour les appels API et le traitement des archives)

### Étapes d'Installation

1. **Cloner le Répertoire**
   ```bash
   git clone https://github.com/ErrorNoName/S-S-U-B.git
   cd S-S-U-B
   ```

2. **Rendre le Script Exécutable**
   ```bash
   chmod +x steam_manager_ui.sh
   ```

3. **Lancer le Script**
   ```bash
   ./steam_manager_ui.sh
   ```

## 🛠️ Utilisation

1. **Lancement**
   - Exécutez le script et l'interface graphique en mode texte s'affichera automatiquement.

2. **Sélection d'un Jeu**
   - Choisissez dans la liste le jeu Steam à gérer (il est recherché dans `~/.local/share/Steam/steamapps/common`).

3. **Gestion des Snapshots & Mises à Jour**
   - **Créer un snapshot :** Sauvegarde de l'état actuel du jeu.
   - **Restaurer un snapshot :** Remplacement complet du dossier par la version sélectionnée.
   - **Bloquer/Débloquer les mises à jour :** Gérer le fichier manifeste pour empêcher ou permettre les mises à jour automatiques.

4. **Accès au Mod Store**
   - Parcourez la liste des mods disponibles (les états sont indiqués avec des marqueurs).
   - Après sélection, choisissez d’**installer** le mod ou de **noter** (fonctionnel/non fonctionnel) pour envoyer un retour via Discord.
   - Vous avez également la possibilité d'envoyer une demande de mise à jour des snapshots de mods via une option dédiée.

## ⚙️ Configuration

### Chemins Steam
- **STEAM_COMMON** : `~/.local/share/Steam/steamapps/common`
- **STEAM_APPS** : `~/.local/share/Steam/steamapps`
  
   Si vos jeux sont installés ailleurs, modifiez ces variables en début de script.

### Répertoire des Snapshots
- Par défaut, les snapshots sont enregistrés dans `~/steam_snapshots`.
  
  Vous pouvez modifier cette variable pour changer l'emplacement de sauvegarde.

### Droits Système
- Les opérations de blocage/déblocage reposent sur `chattr` et nécessitent l'utilisation de `sudo`.
  Assurez-vous d’avoir les permissions nécessaires ou configurez votre sudo pour une exécution sans mot de passe pour `chattr` si besoin.

## 🐞 Résolution des Problèmes

1. **dialog n'est pas installé**
   - *Symptôme* : Erreur indiquant que `dialog` est introuvable.
   - *Solution* : Installez-le avec `sudo pacman -S dialog`.

2. **Problème de Permissions sur les Fichiers Manifeste**
   - *Symptôme* : Échec du blocage/déblocage des mises à jour.
   - *Solution* : Vérifiez vos droits sudo ou exécutez le script en tant que root si nécessaire.

3. **Aucun Jeu Détecté**
   - *Symptôme* : Le script ne trouve aucun jeu dans `STEAM_COMMON`.
   - *Solution* : Vérifiez l'emplacement d'installation de vos jeux ou modifiez la variable `STEAM_COMMON`.

## ⚠️ Avertissements Importants

- **Opérations Destructrices**  
  La restauration d'un snapshot supprimera définitivement le dossier actuel du jeu. Sauvegardez vos données avant toute action.

- **Utilisation de chattr**  
  La fonctionnalité de blocage des mises à jour repose sur la modification des attributs système du fichier manifeste. Utilisez-la avec précaution.

- **Dépendances**  
  Assurez-vous que les outils comme `dialog`, `rsync`, `curl`, `jq`, `unzip` et `chattr` sont installés et opérationnels.

## 📄 Licence

Ce projet est sous licence **MIT**.  
Consultez le fichier [LICENSE](https://github.com/ErrorNoName/S-S-U-B/blob/main/LICENSE) pour plus de détails.

## 🙏 Remerciements

- **dialog** pour l'interface utilisateur en mode texte.
- **rsync** pour la gestion efficace des snapshots.
- **chattr** pour la sécurisation des mises à jour.
- Merci à la communauté ArchLinux et aux utilisateurs de Steam pour leurs retours constructifs et leur soutien.
