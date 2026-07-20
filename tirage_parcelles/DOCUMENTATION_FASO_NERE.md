# 📖 Documentation Officielle - Faso Néré (Administration & Déploiement)

Ce document rassemble toutes les procédures nécessaires pour maintenir, mettre à jour et gérer l'ensemble de la plateforme Faso Néré de A à Z.

---

## 1️⃣ ARCHITECTURE DU PROJET

Votre projet est divisé en 3 grandes parties :
1. **Le Backend (`faso-nere-backend`)** : Le moteur de l'application (en Python/FastAPI). Il gère la base de données, PawaPay, les tirages, etc. Il est hébergé sur **Render**.
2. **Le Tableau de Bord Admin (`faso_nere_admin`)** : L'interface web pour gérer les joueurs (en React/Vite). Hébergé sur **Render**.
3. **L'Application Mobile (`tirage_parcelles`)** : L'application installée sur les téléphones des joueurs (en Flutter).

---

## 2️⃣ COMMENT SAUVEGARDER ET METTRE EN LIGNE (GIT PUSH)

Vos serveurs (Render) sont connectés à GitHub. **Chaque fois que vous faites un "Push", Render met vos serveurs à jour automatiquement en 2-3 minutes.**

### A. La commande de base
Dans le terminal de VS Code, placez-vous dans le bon dossier selon ce que vous avez modifié, puis tapez :
```bash
git add .
git commit -m "Description de ce que vous avez modifié"
git push
```

### B. Problème de connexion (Repository not found / Authentication failed)
Si GitHub vous refuse l'accès ou demande un mot de passe :
1. Dans VS Code, appuyez sur **`Ctrl + Shift + P`**
2. Tapez **`Git: Push`** et appuyez sur Entrée.
3. Une fenêtre va s'ouvrir vous demandant de vous connecter à GitHub via votre navigateur. Acceptez et connectez-vous. Le push passera tout seul !

---

## 3️⃣ COMMENT PUBLIER UNE MISE À JOUR DE L'APPLICATION MOBILE

Nous avons mis en place un système "Appcast" qui oblige les utilisateurs à mettre à jour leur application dès que vous publiez une nouvelle version.

**Voici la procédure exacte en 4 étapes pour lancer une nouvelle mise à jour :**

#### Étape 1 : Augmenter le numéro de version
Ouvrez le fichier `pubspec.yaml` à la racine du projet Flutter et modifiez la ligne `version:` en ajoutant +1.
*Exemple : passez de `1.0.1+2` à `1.0.2+3`.*

#### Étape 2 : Modifier l'annonce sur le serveur
Ouvrez `faso-nere-backend/app/main.py` et cherchez la route `/api/appcast.xml` (vers la ligne 180).
Mettez à jour le numéro de version et la description :
```xml
<title>Version 1.0.2</title>
<description>Vos nouveautés et corrections ici !</description>
<!-- Ne pas oublier de changer aussi le paramètre sparkle -->
<enclosure url="..." sparkle:version="1.0.2" sparkle:os="android" />
```

#### Étape 3 : Fabriquer l'APK
Ouvrez un terminal dans le dossier principal `c:\pickabox\tirage_parcelles` et tapez :
```bash
flutter build apk
```

#### Étape 4 : Mettre le fichier en ligne
1. Allez récupérer le fichier généré dans `build\app\outputs\flutter-apk\app-release.apk`
2. Renommez-le en **`faso_nere.apk`**
3. Écrasez l'ancien fichier situé dans **`c:\pickabox\tirage_parcelles\faso-nere-backend\static\faso_nere.apk`**
4. Ouvrez un terminal dans `faso-nere-backend` et poussez le tout :
   ```bash
   git add .
   git commit -m "Nouvelle version mobile 1.0.2"
   git push
   ```
*Dès que Render aura redémarré le serveur, la pop-up de mise à jour s'affichera chez tous les joueurs.*

---

## 4️⃣ MANIPULATION DE LA BASE DE DONNÉES

Votre base de données est hébergée en ligne sur Render (PostgreSQL).

### A. Exécuter un script Python sur la base de données
Vous avez plusieurs scripts déjà prêts dans votre dossier `faso-nere-backend` (ex: `check_lots.py`, `migrate_users.py`, etc.).
Pour lancer un de ces scripts depuis votre ordinateur directement sur la vraie base de données :
```bash
cd c:\pickabox\tirage_parcelles\faso-nere-backend
python check_lots.py
```

### B. Voir les données manuellement (DBeaver ou pgAdmin)
Pour manipuler la base (ajouter, supprimer ou modifier des données à la main), il ne faut pas le faire à l'aveugle. 
1. Téléchargez un logiciel gratuit comme **DBeaver** ou **pgAdmin**.
2. Créez une nouvelle connexion "PostgreSQL".
3. Récupérez "l'URL Externe" (External Database URL) depuis votre tableau de bord Render (ça commence par `postgresql://...`).
4. Collez ce lien dans DBeaver. Vous verrez toutes vos tables (users, transactions, campagnes) comme dans un tableau Excel !

---

## 5️⃣ GESTION DE PAWAPAY

**Si un paiement échoue :** 
1. Allez dans le tableau de bord Admin (section Transactions). 
2. Survolez ou regardez la case d'erreur : vous verrez le message exact renvoyé par PawaPay (ex: *Insufficient funds*, *Unsupported parameter*).
3. Notre système recréditera automatiquement le joueur si une transaction de type "Retrait" échoue.

**Rappel des webhooks :** 
Votre backend écoute PawaPay sur l'URL `https://<votre_serveur>.onrender.com/api/transactions/pawapay/webhook`. Ne modifiez pas cette URL dans le tableau de bord PawaPay sous peine de ne plus recevoir les confirmations de paiement.

---

> 💡 **Conseil d'or :** Ne modifiez jamais les clés API (Variables d'Environnement) directement dans le code. Faites-le toujours depuis l'onglet **"Environment"** sur le tableau de bord Render !
