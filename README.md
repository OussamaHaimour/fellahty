# Fellahty (anciennement AgriWork) 🌾

Fellahty est une application mobile révolutionnaire conçue pour transformer et moderniser le secteur agricole en connectant directement les agriculteurs, les ouvriers agricoles et les propriétaires d'équipements. 

Ce projet vise à faciliter la recherche de main-d'œuvre qualifiée, la location de matériel agricole et à sécuriser les transactions entre les différents acteurs du domaine.

## 🎯 Objectif du Projet
L'objectif principal de Fellahty est de :
- **Digitaliser** le recrutement agricole pour le rendre plus transparent et efficace.
- **Connecter** les agriculteurs ayant besoin de bras ou de machines avec les ouvriers et les propriétaires d'équipements.
- **Sécuriser** le suivi quotidien du travail (pointage) et garantir les paiements grâce à une gestion dématérialisée et un système d'évaluation mutuelle.

## 🛠️ Outils et Technologies

### 🎨 Frontend (Interface Utilisateur)
- **Flutter** : Framework de base pour le développement mobile multiplateforme (Android et iOS).
- **Dart** : Langage de programmation principal.
- **Material Design 3** : Pour une interface moderne, fluide et réactive.
- **Provider / setState** : Gestion de l'état simple et efficace.
- **flutter_localizations** : Support multi-langues robuste (Arabe, Français, Anglais).

### ⚙️ Backend (Serveur et Base de données)
- **Firebase Authentication** : Gestion de l'authentification et de l'inscription des utilisateurs (Email / Mot de passe).
- **Cloud Firestore** : Base de données NoSQL hébergée sur le cloud de Google pour stocker et synchroniser les données en temps réel (Utilisateurs, Offres d'emploi, Candidatures, Équipements, Locations).
- **Règles de sécurité Firestore** : Garantissent que chaque utilisateur n'a accès qu'à ses propres données ou à celles dont il a l'autorisation.

## ✨ Fonctionnalités Principales

### 👨‍🌾 Pour l'Agriculteur (Farmer)
- **Création d'offres d'emploi** : Publier des annonces pour recruter des ouvriers (selon le nombre de jours, le salaire, et les compétences).
- **Location d'équipements** : Parcourir et réserver des équipements agricoles (tracteurs, moissonneuses, etc.).
- **Gestion des candidatures** : Accepter ou rejeter les demandes des ouvriers et des propriétaires d'équipement.
- **Suivi et Paiement** : Suivi des journées de travail via un système de "Fin de travail" / "Fin de location" et paiement direct via le portefeuille virtuel de l'application.

### 👷 Pour l'Ouvrier (Worker)
- **Recherche d'emploi** : Consulter les offres d'emploi disponibles dans la région.
- **Candidature** : Postuler facilement aux offres qui correspondent à ses compétences.
- **Suivi du travail** : Confirmer la fin du travail auprès de l'agriculteur avec notification de paiement et réception des fonds dans son portefeuille ("Wallet").

### 🚜 Pour le Propriétaire d'Équipement (Equipment Owner)
- **Ajout de matériel** : Mettre en ligne des machines avec des photos, prix à la journée et spécifications.
- **Gestion des locations** : Recevoir des demandes, les accepter, et confirmer la fin de la location pour réclamer le paiement garanti par Fellahty.

### 🛡️ Pour l'Administrateur (Admin)
- **Tableau de bord complet** : Panneau de contrôle avec statistiques temps réel (nombre d'utilisateurs, emplois, locations).
- **Modération** : Possibilité de bannir/débannir des utilisateurs et surveiller la plateforme.

## 📂 Architecture de la Base de Données
Le backend Firestore s'articule autour de plusieurs collections clés :
* `users` : Contient le profil de l'utilisateur (portefeuille, région, rôle : worker, farmer, equipment_owner, admin).
* `jobs` : Offres d'emploi postées par les agriculteurs.
* `applications` : Demandes d'emploi postées par les ouvriers liées à un job.
* `equipment` : Matériel de location mis à disposition.
* `rentals` : Contrats de location entre l'agriculteur et le propriétaire.
* `commissions` : Suivi des frais perçus par l'application pour chaque transaction.

---
**Note** : Afin d'assurer la sécurité du système, les clés d'API, la configuration Firebase (`google-services.json`), le code source sensible (`firebase_options.dart`) et les traces de test et d'IA ne sont pas inclus dans le dépôt GitHub (ils sont ajoutés au fichier `.gitignore`).
