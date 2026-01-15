# BCI Catalog Generator
BCI Catalog Generator est une extension pour SketchUp Pro qui automatise la production de fiches techniques et de catalogues au format LayOut (.layout / .pdf) à partir d'une sélection de composants 3D.

Elle orchestre la préparation des scènes (Staging), l'exportation d'un modèle temporaire et la mise en page automatique dans LayOut.

🚀 Fonctionnalités
Scan Intelligent : Détecte les composants sélectionnés et extrait automatiquement leurs métadonnées (Référence, Désignation, Dimensions UUID).

Staging Automatique : Génère dynamiquement des scènes standardisées (Face, Iso, Coupe) dans un fichier SketchUp temporaire sans altérer votre modèle de travail.

Génération LayOut :

Utilise un gabarit (Template) .layout fourni par l'utilisateur.

Crée une page par composant.

Insère automatiquement les vues (Viewports) et les textes (Titre, Référence) aux emplacements définis.

Export PDF : Génère automatiquement le fichier PDF final en plus du fichier LayOut.

🛠 Installation
Assurez-vous d'avoir SketchUp Pro (requis pour l'API LayOut).

Copiez le dossier bci_catalog et le fichier bci_catalog.rb dans votre dossier Plugins SketchUp.

Démarrez SketchUp. L'extension "BCI Catalog Generator" devrait apparaître dans le gestionnaire d'extensions.

📖 Utilisation
Sélection : Sélectionnez un ou plusieurs composants dans votre modèle SketchUp.

Lancement : Allez dans le menu Extensions > BCI Catalog > Générer Catalogue (Debug).

Template : Une fenêtre s'ouvre. Choisissez votre fichier gabarit .layout.

Note : Le gabarit doit être configuré pour recevoir les vues (voir section Architecture).

Résultat : L'extension travaille (Scan > Staging > LayOut) et ouvre le dossier contenant :

source_catalog.skp : Le modèle préparé avec les scènes.

catalogue.layout : Le document final.

catalogue.pdf : L'export PDF.

📂 Architecture Technique
Le code est modulaire et divisé en trois moteurs principaux :

1. Scanner (scanner.rb)
Parcourt la sélection pour construire des objets CatalogItem. Il gère la cascade de récupération des attributs (Instance > Définition > Nom) pour garantir que chaque pièce a ses métadonnées.

2. Staging Engine (staging.rb)
Ce moteur prépare le "studio photo" virtuel :

Crée un calque d'isolation (BCI_CATALOG_STUDIO).

Génère les pages (Scènes) SketchUp pour chaque vue requise (FRONT, ISO, SIDE).

Configure la caméra et masque les calques inutiles pour obtenir des vues propres.

3. Layout Engine (layout_engine.rb)
Pilote l'API LayOut pour assembler le document :

Détecte les "slots" (zones de placement) sur la première page du template.

Clone la page modèle pour chaque item.

Lie les Viewports LayOut aux scènes SketchUp spécifiques générées par le Staging.

⚠️ Pré-requis Template
Pour que le moteur de mise en page (LayoutEngine) fonctionne correctement, votre fichier .layout doit idéalement (dans une version future) contenir des éléments sur un calque CAT_SLOTS pour définir les zones d'insertion. Actuellement (MVP), les positions sont définies par défaut (hardcoded) dans le code si elles ne sont pas détectées.

📅 Roadmap
V1.0.0 (Actuel) : MVP fonctionnel avec scan, scènes basiques et export LayOut.

Futur :

Détection dynamique des slots via calques LayOut nommés.

Gestion avancée des styles de rendu (Vectoriel / Hybride).

Support des "Shared Layers" pour les cartouches fixes.
