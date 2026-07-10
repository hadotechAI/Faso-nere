# Documentation : Intégration des Paiements Mobiles (Faso Néré)

Ce document explique l'architecture et la stratégie recommandées pour l'intégration des vrais paiements mobiles (Orange Money, Moov, etc.) au Burkina Faso, en utilisant un agrégateur de paiement (ex: **PawaPay**).

---

## 1. Dépôts / Achat de Packs (Encaissements)

C'est l'action par laquelle l'utilisateur paie pour acheter des tentatives sur l'application. Cette partie doit être **100% automatisée** pour que l'utilisateur reçoive ses crédits instantanément, même à 3h du matin.

### Architecture du flux (Workflow) :
1. **Initialisation (Flutter)** : L'utilisateur clique sur "Payer un Pack". L'application Flutter appelle le backend.
2. **Création de la transaction (Backend)** : Le serveur FastAPI enregistre la transaction en base de données avec le statut `en attente` et demande un paiement à PawaPay.
3. **Paiement (Mobile)** : PawaPay déclenche un prompt USSD sur le téléphone du joueur. L'utilisateur valide avec son code secret.
4. **Validation silencieuse (Webhook)** : Dès que l'argent est débité, PawaPay contacte de manière invisible notre backend (sur la route `/transactions/pawapay/webhook`).
5. **Livraison** : Le backend reçoit la confirmation, passe la transaction en statut `succès` et ajoute automatiquement les tentatives au compte de l'utilisateur.

---

## 2. Retraits (Transferts vers les joueurs)

C'est l'action par laquelle l'application envoie les gains (FCFA) à l'utilisateur. Cette partie **ne doit jamais être automatisée à 100%** pour des raisons critiques de sécurité.

### Le risque de l'automatisation totale :
Si un hacker trouve une faille ou usurpe un compte, il pourrait demander des centaines de retraits automatiques et vider complètement votre compte marchand PawaPay en quelques minutes.

### Les Stratégies Recommandées pour les Retraits :

#### Stratégie A : Semi-Automatique (Sécurisée et Professionnelle)
1. L'utilisateur demande un retrait depuis l'application.
2. La demande s'affiche en statut `en attente` sur votre **Panel d'Administration**.
3. Un administrateur humain vérifie que l'utilisateur n'a pas triché.
4. L'administrateur clique sur un bouton **"Payer via PawaPay"** dans le panel.
5. Le backend déclenche l'API "Transfert" de PawaPay, qui envoie automatiquement l'argent sur le téléphone du client.

#### Stratégie B : Manuelle (La plus économique)
1. L'utilisateur demande un retrait.
2. L'administrateur voit la demande sur le Panel Admin avec le numéro du joueur.
3. L'administrateur prend son propre téléphone marchand (ex: code USSD) et fait un transfert manuel vers le joueur.
4. L'administrateur clique sur **"Marquer comme payé"** sur le panel.
*(Avantage : Vous ne payez pas les frais de transfert B2C facturés par PawaPay).*

---

## 3. Ce que vous (le propriétaire) devez préparer

1. **Création du compte** : Aller sur [pawapay.io](https://pawapay.io/) et créer un compte marchand.
2. **Documents** : Fournir les documents d'identification pour débloquer les limites.
3. **Clés API** : Récupérer le `JWT` et le `WEBHOOK_SECRET` depuis le tableau de bord PawaPay pour les intégrer au backend (`.env`).

---

## 4. Routes API (implémentées)

| Méthode | Route | Auth | Description |
|---------|-------|------|-------------|
| POST | `/api/transactions/depot/initier-pawapay` | JWT | Crée transaction `pending` |
| POST | `/api/transactions/pack/initier-pawapay` | JWT | Idem pour achat de pack |
| GET | `/api/transactions/statut/{reference}` | JWT | Polling statut après paiement |
| POST | `/api/transactions/pawapay/webhook` | Non | Webhook PawaPay (URL à configurer dans `.env`) |

Variables `.env` : voir `faso-nere-backend/.env.example`.

## 5. Prochaines étapes

1. **Configurer `.env`** avec vos clés PawaPay et une URL HTTPS publique (ngrok en dev).
2. **Flutter** : utiliser `initierDepotPawaPay` / `initierPackPawaPay` + polling `statut`.
3. **Panel Admin** : bouton « Payer via PawaPay » pour les retraits (API transfert — à venir).
