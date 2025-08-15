# Notes de Conceptions
Table des matieres

1. Project Introduction
2. Design Structure
3. Planification
4. Implementation
5. Accelerator analysis

## Project Introduction

- goals : design a vhdl implementation of a multi-effect guitar modulation effect pedal that implements hardware acceleration caracteristics.
- structure : The design does not use qsys or the NIOS at all. Everything is done through hardware modules.
- ressources used : a lot of inspiratuiuon was taken from people who did similar projects and posted their work to GITHUB. We took inspiration from mainly these : Andoni Arruti and Jose Angel Gumiel.
Nothing was used as is (nothing copy and pasted) from theirs but some modules are logically or structurally the same since they execute the same tasks as their conterpart from a different author

## Design structure

### Architecture
Tous les effets de modulation seront encapsulé dans leur propre composante. Il y aurau aussi des modules individuels pour l'entrée et la sortie audio. L'entré audio sera connecté sur tous les modules d'effets puisque nous utiliseront des bits d'activation pour selectionné quel mod nous utilison. Ensuite nous utiliseront un multiplexeur pour selectionné la quel soortie des effets sera redirigé vers la sortie. Si aucun effet n'est selectionné, l'entrée audio sera automatiquement redirigé vers la sortie agissant comme un "pass-through". 


### Effets de modulation
Chaque effet aura les caracteristiques suivantes : 
- Entrée et sortie audio
- Bit d'activation
- Parametres de configuration de l'effet
- Autres selon besoins


## Planification
Équipe : Colin Boulé (BOUC85300301) & Zachary Proulx (PROZxxxxxxxx)

Contribution: 
- Colin : Implementation VHDL, optimisation, documentation, proposition de projet
- Zachary : Conception de l'architecture, choix de design, documentation, recherche, analyse, refractor

Date de Remise : 16 Aout 2025 à 23:55

Type de Remise : Moodle

Documents à remettre : 
- Projet Quartus 
- Vidéo de démontration
- Ce document de notes
- Code source

Milestones : 
1. Coder le module du codec
2. Faire un "pass-through" avec le codec
3. Faire un "ampli" avec le codec (modification la plus simple au signal)
4. Faire un effet simple 
5. Faire un effet plus compliqué
6. Ajouté tous les effets que nous pouvons implementer en VHDL


## Implementation

- Explain final product
- Show some pseudo-code or code
- Next step

## Accelerator Analysis

- Explain how come this is an accelerator
- Explain why it is hard to quantify
- Give an approximate quantification (cycles used per action by C code...)

## Explication de base des effets
### Overdrive
### Distortion
### Tremolo
### Fuzz
### Bit Crusher

## Éléments de Remise
Vidéos de 1 minutes :
- Lien Google Drive : 
- Lien OneDrive :

Projet Quartus : 
- Top Level : SadModz.vhdl
- Dossier des codes : sources
- Fichiers de modulations : Overdrive.vhdl, Distortion.vhdl, Tremolo.vhdl, Fuzz.vhdl, Bit_crusher.vhdl
- Fichiers de codec : WM8731_config.vhdl, audio_in.vhdl, audio_out.vhdl

