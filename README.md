# Appli-Tibu : Application de Gestion

Application mobile multiplateforme développée avec Flutter pour la gestion interne de l'organisation Tibu. Elle fournit un panneau d'administration simple et efficace pour gérer les utilisateurs et les écoles partenaires.

## Fonctionnalités

L'application est actuellement centrée sur un panneau de gestion qui offre les fonctionnalités suivantes :

-   **Tableau de bord administrateur** : Un écran central avec une navigation par onglets pour un accès rapide aux différentes sections.
-   **Gestion des Utilisateurs (CRUD)** :
    -   **Lister** tous les utilisateurs avec leurs informations (nom, email, entreprise).
    -   **Ajouter** un nouvel utilisateur via un formulaire dédié.
    -   **Modifier** les informations d'un utilisateur existant.
    -   **Supprimer** un utilisateur avec une boîte de dialogue de confirmation.
-   **Gestion des Écoles (CRUD)** :
    -   **Lister** toutes les écoles partenaires avec leur ville et le budget bénéficié.
    -   **Ajouter** une nouvelle école avec son nom, sa ville et un budget initial.
    -   **Modifier** les détails d'une école, y compris son budget.
    -   **Supprimer** une école avec confirmation.
-   **Interface Utilisateur Intuitive** : Utilisation des composants Material Design pour une expérience utilisateur claire, réactive et cohérente.

## Captures d'écran

*(N'hésitez pas à ajouter ici des captures d'écran de votre application pour illustrer ses fonctionnalités.)*

## Technologies Utilisées

-   **Framework** : [Flutter](https://flutter.dev/)
-   **Langage** : [Dart](https://dart.dev/)
-   **Architecture** : Approche basée sur les `StatefulWidget` avec gestion d'état locale (`setState`). Idéale pour des fonctionnalités ciblées et une prise en main rapide.
-   **UI/UX** : `Material Design`
-   **Données** : Actuellement, les données sont statiques (mock data) directement dans le code pour les besoins du développement et de la démonstration.

## Structure du Projet

La structure des fichiers est organisée pour séparer les vues par fonctionnalité et faciliter la maintenance.