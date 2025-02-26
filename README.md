```markdown
# Steam Snapshot Manager UI

## 📋 **Table des Matières**
- [📖 Description](#-description)
- [🚀 Fonctionnalités](#-fonctionnalités)
- [🔧 Installation](#-installation)
- [🛠️ Utilisation](#️-utilisation)
- [⚙️ Configuration](#-configuration)
- [🐞 Résolution des Problèmes](#-résolution-des-problèmes)
- [⚠️ Avertissements Importants](#-avertissements-importants)
- [📄 Licence](#-licence)
- [🙏 Remerciements](#-remerciements)

## 📖 **Description**

**Steam Snapshot Manager UI** est un script Bash destiné aux utilisateurs d'ArchLinux pour gérer facilement leurs jeux Steam.  
Il permet de :
- Lister vos jeux Steam installés.
- Créer des snapshots (copies de sauvegarde) de vos jeux avec un identifiant unique basé sur la date.
- Restaurer une version précédente en remplaçant totalement le dossier actuel du jeu.
- Bloquer ou débloquer les mises à jour automatiques d'un jeu en modifiant le fichier manifeste Steam associé.

Ce script utilise l'utilitaire **dialog** pour offrir une interface en mode texte graphique, simple et rapide à utiliser.

## 🚀 **Fonctionnalités**

- **Interface Graphique en Mode Texte :**  
  Une navigation intuitive grâce à `dialog` pour sélectionner vos jeux et actions.

- **Gestion des Snapshots :**  
  - Création automatique d'un snapshot avec un identifiant unique (basé sur la date et l'heure).
  - Restauration des snapshots disponibles pour revenir à une version antérieure du jeu.

- **Blocage/Déblocage des Mises à Jour :**  
  - Bloquer les mises à jour en rendant le fichier manifeste Steam (appmanifest_*.acf) du jeu **immutable**.
  - Débloquer en rétablissant les permissions d'écriture.

- **Opérations Sécurisées :**  
  Confirmation avant toute opération destructrice (restauration qui supprime le dossier actuel du jeu).

## 🔧 **Installation**

### **Prérequis**
- **Bash** (installé par défaut sur ArchLinux)
- **dialog**  
  Installez-le via :
  ```bash
  sudo pacman -S dialog
  ```
- **rsync** (pour la copie des dossiers)
- **chattr** (inclus dans le paquet e2fsprogs)

### **Étapes d'Installation**

1. **Cloner le Répertoire :**
   ```bash
   git clone https://github.com/ErrorNoName/S-S-U-B.git
   cd S-S-U-B
   ```

2. **Rendre le Script Exécutable :**
   ```bash
   chmod +x SnapSteam.sh
   ```

## 🛠️ **Utilisation**

1. **Lancer le Script :**
   ```bash
   ./steam_manager_ui.sh
   ```

2. **Sélectionner un Jeu :**
   - Une interface graphique en mode texte s'affichera listant tous les jeux Steam installés (par défaut dans `~/.local/share/Steam/steamapps/common`).

3. **Choisir une Action :**
   - **Créer un snapshot :** Sauvegarder l'état actuel du jeu.
   - **Restaurer un snapshot :** Remplacer le dossier du jeu par une version sauvegardée.
   - **Bloquer les mises à jour :** Rendre le manifeste du jeu immutable pour empêcher les mises à jour.
   - **Débloquer les mises à jour :** Restaurer les permissions d'écriture sur le manifeste.

4. **Confirmer les Opérations :**
   - Le script demande confirmation avant toute action susceptible de supprimer des données existantes.

## ⚙️ **Configuration**

### **Chemins Steam**
- Par défaut, le script utilise :
  - `STEAM_COMMON` : `~/.local/share/Steam/steamapps/common`
  - `STEAM_APPS` : `~/.local/share/Steam/steamapps`
- Si vos dossiers Steam sont installés ailleurs, modifiez ces variables en début de script.

### **Répertoire des Snapshots**
- Les snapshots sont sauvegardés dans le dossier : `~/steam_snapshots`
- Vous pouvez modifier cette variable pour changer l'emplacement de stockage.

### **Droits Système**
- Pour bloquer/débloquer les mises à jour, le script utilise `chattr` avec `sudo`.  
  Assurez-vous d'avoir les droits sudo ou configurez sudo pour ne pas demander de mot de passe pour `chattr` si nécessaire.

## 🐞 **Résolution des Problèmes**

### **1. dialog n'est pas installé**
- **Symptôme :** Le script affiche une erreur indiquant que `dialog` est introuvable.
- **Solution :** Installez dialog avec la commande `sudo pacman -S dialog`.

### **2. Problème de Permissions sur les Fichiers Manifeste**
- **Symptôme :** Erreur lors du blocage/déblocage des mises à jour.
- **Solution :** Vérifiez que vous disposez des droits suffisants pour utiliser `sudo chattr`.  
  Vous pouvez également lancer le script en tant que root, si besoin.

### **3. Absence de Jeux dans le Répertoire**
- **Symptôme :** Le script ne trouve aucun jeu dans le dossier `STEAM_COMMON`.
- **Solution :** Assurez-vous que vos jeux sont installés dans le répertoire configuré ou modifiez la variable `STEAM_COMMON`.

## ⚠️ **Avertissements Importants**

- **Opérations Destructrices :**  
  La restauration d’un snapshot supprime complètement le dossier actuel du jeu.  
  **Assurez-vous de sauvegarder vos données avant toute restauration.**

- **Utilisation de chattr :**  
  Le blocage des mises à jour repose sur la modification des permissions du fichier manifeste.  
  Utilisez cette fonctionnalité avec précaution pour éviter tout problème de mise à jour futur.

- **Dépendances Système :**  
  Le script nécessite des outils comme `dialog`, `rsync` et `chattr`. Vérifiez leur présence avant utilisation.

## 📄 **Licence**

Ce projet est sous licence **MIT**.  
Voir le fichier [LICENSE](https://github.com/VotreNom/Steam-Snapshot-Manager-UI/blob/main/LICENSE) pour plus de détails.

## 🙏 **Remerciements**

- **dialog** : Pour offrir une interface en mode texte conviviale.
- **rsync** : Pour la gestion efficace des copies de dossiers.
- **chattr** : Pour la sécurisation des fichiers en bloquant les mises à jour non souhaitées.
- Merci à la communauté ArchLinux et aux utilisateurs de Steam pour leurs retours et suggestions.
