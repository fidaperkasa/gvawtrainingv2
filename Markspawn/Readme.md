# GVAW MarkSpawn v3.0.7

**Universal Spawning Script for DCS World**  
By EagleEye – DCS Indonesia  

This script provides a powerful, flexible, and user-friendly spawning system for DCS World missions. It allows mission creators and players to spawn units, templates, AWACS, tankers, JTACs, and statics dynamically using chat commands or the F10 radio menu. It also supports selective deletion, unit/task management, and enhanced embarkation features.

---

## Overview

MarkSpawn is designed to simplify dynamic mission creation and in-game control of unit spawning.  
It can:

- Spawn **templates** (groups of units with relative positions).  
- Spawn **single units** or **multiple-unit groups** with custom parameters.  
- Handle **static objects** automatically.  
- Assign **JTAC FAC tasking**, including laser and radio settings.  
- Set up **AWACS and Tanker tasks** with orbit routes and TACAN.  
- Support **troop embarkation** and helicopter transport.  
- Provide an **F10 menu** for commands, cleanup, and listings.  
- Offer **selective deletion tools** (per type, per template, single units, or specific group names).  

---

## Key Features

- **Chat Command Control**:  
  Use in-game chat to issue commands such as spawning and deletion.  
  Example:  
spawn,type=JTAC,country=USA,freq=40,laser=1688
spawn,temp=RU_FARP,country=CJTF_RED,hdg=90
spawn delete,group=US_Infantry_5212

- **F10 Radio Menu**:  
Automatically builds player menus with options for:  
- Syntax help  
- Listing templates and unit categories  
- Cleanup and deletion options  
- Transport assignment for embarkable groups  

- **Selective Cleanup**:  
- Delete **all** spawned objects  
- Delete **only templates**  
- Delete **only single units/statics**  
- Delete by **specific unit type**  
- Delete **by group name**  

- **Advanced Tasking**:  
- Tankers: Orbit race-track, TACAN setup, refueling task  
- AWACS: High-altitude orbit, EPLRS enabled by default  
- JTACs: FAC task with laser and frequency assignment  

- **Embarkation System**:  
- Infantry automatically prepared for helicopter transport  
- F10 options for assigning transports  
- Support for multiple infantry groups  

---

## Core Functions

### Database
- Loads unit and template data from `dbspawn.json`.  
- Maps unit categories (`PLANE`, `HELICOPTER`, `GROUND_UNIT`, `SHIP`, `STATIC`, `CARGO`, `TEMPLATES`).  

### Spawner
- `spawnObject`: Spawns single units or groups.  
- `spawnTemplate`: Spawns template structures (e.g., FARPs).  
- Handles **statics vs. active groups** automatically.  

### Cleanup
- `cmdDeleteAll` – Delete all spawned objects.  
- `cmdDeleteByType` – Delete by unit type (e.g., `KC-135`).  
- `cmdDeleteTemplates` – Delete template groups only.  
- `cmdDeleteSingleUnits` – Delete only individual units/statics.  
- `cmdDeleteSpecificGroup` – Delete a specific group by name.  

### Tasking
- `createTankerTask` – Defines orbit + refuel task for tankers.  
- `createAWACSTask` – Defines orbit for AWACS.  
- `createOrbitTask` – General race-track orbit.  
- `setupJTAC` – FAC task assignment for JTAC.  
- `setupInfantryEmbarkation` – Makes infantry embark-ready.  

### Event Handler
- Chat commands processed via event `id=26`.  
- Player unit entry handled with `id=15` (builds F10 menu).  

---

## Installation

1. Copy **Markspawn-v3.lua** into your DCS **Scripts** directory:  
%USERPROFILE%\Saved Games\DCS\Scripts\

2. Ensure you also include the JSON parser:  
%USERPROFILE%\Saved Games\DCS\Scripts\GVAWv2\json.lua

3. Create a **database file** (`dbspawn.json`) inside:  
%USERPROFILE%\Saved Games\DCS\Scripts\GVAWv2\

4. Load the script in your mission using a **DO SCRIPT FILE** trigger.  

5. Join the mission, type commands into chat prefixed with `spawn,` or use the **F10 -> Other -> MarkSpawn** menu.  

---

## Example Commands
- **Spawn a template**:  
spawn,temp=RU_FARP,country=CJTF_RED,hdg=90
- **Spawn multiple units**:  
spawn,type=E-3A,amount=2,country=USA,alt=25000,spd=300,hdg=180
- **Spawn JTAC**:  
spawn,type=JTAC,country=USA,freq=40,laser=1688
- **Delete a group by name**:  
spawn delete,group=US_Infantry_5212

---

## Logging & Debugging

- Debug mode enabled with:
markspawn.debug = true
- Logs messages in DCS log and in-game notifications.

- Errors (missing JSON, invalid unit types) are shown on screen.

---

## License
This script is part of GVAW (Garuda virtual Air Wing) community tools.
Free to use for non-commercial DCS missions. Attribution appreciated.
