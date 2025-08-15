# **Notes de Conception**  
Auteurs : Colin Boulé & Zachary Proulx / Adaptation par ChatGPT
## **Table des matières**  
1. Introduction du projet  
2. Architecture du système  
3. Planification et échéancier  
4. Détails d’implémentation  
5. Analyse de l’accélération matérielle  

---

## **1. Introduction du projet**  

**Objectif :**  
L’objectif de ce projet est de concevoir et d’implémenter, en VHDL, une pédale de guitare multi-effets démontrant les principes de l’accélération matérielle. Le système traitera l’audio entièrement en matériel, sans utiliser Qsys, Nios II ou tout autre processeur embarqué, afin de permettre un traitement temps réel avec une latence minimale.  

**Caractéristiques clés :**  
- **Entièrement matériel** : Aucun processeur embarqué, tout le traitement est fait dans des modules VHDL personnalisés.  
- **Architecture modulaire** : Chaque effet audio est encapsulé dans son propre module VHDL, favorisant la réutilisabilité et l’évolutivité.  
- **Traitement temps réel** : Le signal audio est traité avec une latence imperceptible, adapté à la performance en direct.  
- **Paramétrage dynamique (prévu)** : La possibilité de configurer les effets via des paramètres de contrôle est envisagée pour de futures améliorations. Cette fonctionnalité est déjà prise en compte dans l’architecture, mais n’est pas implémentée dans la version actuelle du projet.

**Références et inspiration :**  
Le projet s’inspire de travaux disponibles publiquement — notamment ceux de Andoni Arruti et Jose Angel Gumiel. Aucun code source n’a été copié directement. Nous avons développé notre propre implémentation, mais certains modules peuvent être similaires sur le plan logique ou structurel en raison de la nature des algorithmes de traitement audio.  

---

## **2. Architecture du système**  

### **Vue d’ensemble**  
Le système reçoit un signal d’entrée de guitare, le route vers un ou plusieurs modules d’effets, puis envoie le signal traité au codec audio. L’architecture est conçue pour être **flexible**, permettant d’ajouter ou de retirer des effets avec un minimum de modifications au niveau supérieur.  

**Composants principaux :**  
1. **Module d’entrée audio** – Interface avec le codec WM8731, reçoit le signal de guitare et le convertit en format numérique adapté au traitement.  
2. **Module de sortie audio** – Interface avec le codec pour envoyer le signal traité vers des haut-parleurs, écouteurs ou un amplificateur.  
3. **Modules d’effets** – Chaque effet est implémenté comme un bloc matériel indépendant, comprenant :  
   - Entrée et sortie audio  
   - Signal d’activation  
   - Paramètres configurables (ex. gain, seuil, vitesse de modulation)  
4. **Multiplexeur de sélection d’effet** – Route la sortie du module d’effet sélectionné vers la sortie finale. Si aucun effet n’est activé, le système passe automatiquement en **mode pass-through** (connexion directe entrée → sortie).  

### **Effets implémentés et prévus**  
Chaque module d’effet suit une interface standardisée pour simplifier son intégration dans le système.  

**Effets actuels et prévus :**  
- **Pass-Through** – Route directement l’entrée vers la sortie (référence de base).  
- **Overdrive** – Applique un écrêtage doux pour une distorsion harmonique chaude.  
- **Distorsion** – Applique un écrêtage dur pour un son plus agressif.  
- **Tremolo** – Modulation périodique de l’amplitude du signal.  
- **Fuzz** – Écrêtage extrême pour une distorsion vintage prononcée.  
- **Bitcrusher** – Réduit la résolution en bits et/ou la fréquence d’échantillonnage pour un effet numérique lo-fi.  

---

## **3. Planification et échéancier**  

**Membres de l’équipe :**  
- **Colin Boulé** – Implémentation VHDL, optimisation, documentation du projet, rédaction de la proposition.
- **Zachary Proulx** – Conception de l’architecture, stratégie de sélection des effets, recherche, documentation, analyse d'accelerateur ets refactorisation de code.  

**Date de remise :** **16 août 2025 – 23:55**  
**Plateforme de remise :** Moodle  

**Documents à remettre :**  
- Fichiers complets du projet Quartus Prime  
- Vidéo de démonstration des effets implémentés  
- Ce document de conception  
- Code source VHDL complet  

**Jalons (Milestones) :**  
1. Implémenter le module d’interface du codec.  
2. Obtenir un passage direct (pass-through) fonctionnel avec le codec.  
3. Implémenter un amplificateur simple à gain fixe.  
4. Développer un premier effet audio de base (ex. tremolo).  
5. Implémenter un effet plus complexe (ex. delay).  
6. Intégrer tous les effets possibles dans le temps et les contraintes matérielles.  

---

## **4. Détails d’implémentation**  

**Environnement de développement :**  
- **Carte FPGA** : Terasic DE1-SoC  
- **Codec audio** : WM8731 (interface I²S)  
- **Langage** : VHDL   
- **Outils** : Intel Quartus Prime Standard Edition  
- **Fréquence d’horloge** : 50 MHz  

**Considérations de conception :**  
- **Latence minimale** : Les effets doivent traiter le signal en temps réel sans délai perceptible.  
- **Réglage des paramètres** : Non implémenté dans la version actuelle, mais la fonctionnalité pourrait être ajoutée ultérieurement via des entrées FPGA (interrupteurs, boutons, potentiomètres).
- **Évolutivité** : Ajouter un effet nécessite uniquement un nouveau module et une connexion au multiplexeur.  
- **Utilisation des ressources** : Optimisation des modules pour minimiser l’utilisation logique tout en conservant la qualité audio.  
- **Indication de l’effet actif** : Les 6 afficheurs à 7 segments sont utilisés pour afficher le nom abrégé de l’effet actuellement sélectionné.

---

## **5. Analyse de l’accélération matérielle**  

Contrairement aux effets logiciels exécutés sur des processeurs généralistes, ce projet utilise des modules matériels dédiés pour chaque effet. Cette approche présente plusieurs avantages clés :

### 5.1. Traitement parallèle des modules
Chaque effet est implémenté dans son propre module matériel, pouvant traiter le signal simultanément, même s’il n’est pas activé.  
Sur CPU, toutes les étapes (incrément du compteur, comparaison, calcul du gain, multiplication) sont effectuées **séquentiellement**, ce qui consomme beaucoup plus de cycles par échantillon.  

### 5.2. Latence déterministe
Le FPGA assure une latence constante par échantillon, sans dépendre d’un OS ou d’un ordonnanceur.  
En revanche, sur CPU, la latence peut varier en fonction de la séquence d’instructions et de la prédiction de branchement, rendant le comportement moins prévisible.  

### 5.3. Haut débit / Fréquence native
Le fonctionnement à la fréquence native du FPGA permet de traiter chaque échantillon presque instantanément.  
Sur CPU, le traitement d’un échantillon de tremolo peut nécessiter **10 à 55 cycles**, selon la forme d’onde, limitant le nombre d’effets pouvant être appliqués en temps réel.  

### 5.4. Économie de ressources CPU
L’utilisation de modules FPGA libère le CPU de calculs intensifs pour le traitement du signal, permettant au processeur de gérer d’autres tâches (communication, I/O, interface utilisateur).  
Le fichier `tremolo_comparaison.c` illustre combien de cycles CPU seraient nécessaires pour un seul effet Tremolo, mettant en évidence le gain obtenu grâce à l’accélération matérielle.  

### 5.5. Modularité et enchaînement d’effets
L’architecture FPGA permet d’ajouter facilement de nouveaux effets en parallèle sans augmenter le temps de traitement par échantillon.  
Il est également possible d’enchaîner plusieurs effets l’un à la suite de l’autre : sur FPGA, la **latence supplémentaire serait d’environ 1 cycle par effet** grâce au pipeline et à la parallélisation.  
Sur CPU, chaque effet supplémentaire s’exécute **séquentiellement**, ce qui augmente directement le nombre de cycles et rallonge le temps de traitement à mesure que le nombre d’effets augmente.  

---

Cette approche illustre le principe fondamental de l’accélération matérielle : **décharger les tâches de calcul intensif du CPU vers des circuits dédiés**, améliorant à la fois la performance et la prévisibilité, tout en réduisant la latence pour les effets audio en temps réel.  
Pour plus de détails sur la simulation CPU et l’analyse des cycles, se référer au fichier `tremolo_comparaison.c`.


## **6. Éléments de Remise**  

### **Vidéo de démonstration (1 minute disponnible sur 2 plateforme)**  
- Lien Google Drive :  
- Lien OneDrive :  

### **Projet Quartus**  
- **Top Level :** `SadModz.vhdl`  
- **Dossier des sources :** `sources`  
- **Fichiers de modulations :**  
  - `Overdrive.vhdl`  
  - `Distortion.vhdl`  
  - `Tremolo.vhdl`  
  - `Fuzz.vhdl`  
  - `Bit_crusher.vhdl`  
- **Fichiers de codec :**  
  - `WM8731_config.vhdl`  
  - `audio_in.vhdl`  
  - `audio_out.vhdl`

