### INSTALLATION
SETUP:
  1. Place this file in "Saved Games\DCS\Scripts\<Selected Folder>".
  2. Place "dbspawn.json" (the unit database) in the same folder.
  3. Download "json.lua" from https://github.com/rxi/json.lua and place it in the same folder.
  4. Load this script in your mission with a DO SCRIPT FILE trigger.

MISSION EDITOR:
  1. Add Trigger ONCE with TIME MORE 3 second and ACTION DO SCRIPT
  2. Place this dofile(lfs.writedir()..[[Scripts\<Selected Folder>markspawn.lua]])
  3. Run

### COMMAND SYNTAX
Place mark label in F10 Map then the format as follow:

>>  Single Type: spawn,type=UNIT,amount=NUM,country=C,hdg=DEG,alt=FEET,spd=KNOTS
>>  Template:    spawn,temp=TEMPLATE_NAME,country=C,hdg=DEG


### List of Template:
SAM
- SA-10SAMIR
- Heavy Searchlight
- SA-2SAMIR
- RapierSAMIR
- NASAMSNOR
- NASAMSFIN
- NASAMSCJTFBLUE
- NASAMSCJTFRED
- NASAMSUSA
- FLAK18BATT
- HawkSAMReinf
- FLAK36BAT
- SKORPIONFreya
- RapierSAMUK
- PatriotSAMNL
- BRITISHBOFORSAABAT
- SA-11SAM


### List of Unit can be spawn:
 GROUND_UNIT
 - 1L13 EWR
 - 2B11 mortar
 - 2S6 Tunguska
 - 55G6 EWR
 - 5p73 s-125 ln
 - AA8
 - AAV7
 - ATMZ-5
 - ATZ-10
 - ATZ-5
 - ATZ-60_Maz
 - Allies_Director
 - B600_drivable
 - BMD-1
 - BMP-1
 - BMP-2
 - BMP-3
 - BRDM-2
 - BTR-80
 - BTR-82A
 - BTR_D
 - Bedford_MWD
 - Blitz_36-6700A
 - Boxcartrinity
 - Bunker
 - CCKW_353
 - Centaur_IV
 - Challenger2
 - Chieftain_mk3
 - Churchill_VII
 - Coach a passenger
 - Coach a platform
 - Coach a tank blue
 - Coach a tank yellow
 - Coach cargo open
 - Coach cargo
 - Cobra
 - Cromwell_IV
 - DRG_Class_86
 - DR_50Ton_Flat_Wagon
 - Daimler_AC
 - Dog Ear radar
 - ES44AH
 - Electric locomotive
 - Elefant_SdKfz_184
 - FPS-117 Dome
 - FPS-117 ECS
 - FPS-117
 - Flakscheinwerfer_37
 - FuMG-401
 - FuSe-65
 - GAZ-3307
 - GAZ-3308
 - GAZ-66
 - GD-20
 - Gepard
 - German_covered_wagon_G10
 - German_tank_wagon
 - Grad-URAL
 - Grad_FDDM
 - HEMTT TFFT
 - HEMTT_C-RAM_Phalanx
 - HL_B8M1
 - HL_DSHK
 - HL_KORD
 - HL_ZU-23
 - HQ-7_LN_P
 - HQ-7_LN_SP
 - HQ-7_STR_SP
 - Hawk cwar
 - Hawk ln
 - Hawk pcp
 - Hawk sr
 - Hawk tr
 - Horch_901_typ_40_kfz_21
 - Hummer
 - IKARUS Bus
 - Igla manpad INS
 - Infantry AK Ins
 - Infantry AK ver2
 - Infantry AK ver3
 - Infantry AK
 - JTAC
 - JagdPz_IV
 - Jagdpanther_G1
 - KAMAZ Truck
 - KDO_Mod40
 - KS-19
 - KrAZ6322
 - Kub 1S91 str
 - Kub 2P25 ln
 - Kubelwagen_82
 - L118_Unit
 - LARC-V
 - LAV-25
 - LAZ Bus
 - Land_Rover_101_FC
 - Land_Rover_109_S3
 - LeFH_18-40-105
 - Leclerc
 - Leopard-2
 - Leopard-2A5
 - Leopard1A3
 - LiAZ Bus
 - Locomotive
 - M 818
 - M-1 Abrams
 - M-109
 - M-113
 - M-2 Bradley
 - M-60
 - M1043 HMMWV Armament
 - M1045 HMMWV TOW
 - M1097 Avenger
 - M10_GMC
 - M1126 Stryker ICV
 - M1128 Stryker MGS
 - M1134 Stryker ATGM
 - M12_GMC
 - M1A2C_SEP_V3
 - M1_37mm
 - M2A1-105
 - M2A1_halftrack
 - M30_CC
 - M45_Quadmount
 - M48 Chaparral
 - M4A4_Sherman_FF
 - M4_Sherman
 - M4_Tractor
 - M6 Linebacker
 - M8_Greyhound
 - M978 HEMTT Tanker
 - MAZ-6303
 - MCV-80
 - MJ-1_drivable
 - MLRS FDDM
 - MLRS
 - MTLB
 - Marder
 - Maschinensatz_33
 - MaxxPro_MRAP
 - Merkava_Mk4
 - NASAMS_Command_Post
 - NASAMS_LN_B
 - NASAMS_LN_C
 - NASAMS_Radar_MPQ64F1
 - Osa 9A33 ln
 - P20_drivable
 - PL5EII Loadout
 - PL8 Loadout
 - PLZ05
 - PT_76
 - Pak40
 - Paratrooper AKS-74
 - Paratrooper RPG-16
 - Patriot AMG
 - Patriot ECS
 - Patriot EPP
 - Patriot cp
 - Patriot ln
 - Patriot str
 - Predator GCS
 - Predator TrojanSpirit
 - Pz_IV_H
 - Pz_V_Panther_G
 - QF_37_AA
 - RD_75
 - RLS_19J6
 - RPC_5N62V
 - Roland ADS
 - Roland Radar
 - S-200_Launcher
 - S-300PS 40B6M tr
 - S-300PS 40B6MD sr
 - S-300PS 40B6MD sr_19J6
 - S-300PS 54K6 cp
 - S-300PS 5H63C 30H6_tr
 - S-300PS 5P85C ln
 - S-300PS 5P85D ln
 - S-300PS 64H6E sr
 - S-60_Type59_Artillery
 - SA-11 Buk CC 9S470M1
 - SA-11 Buk LN 9A310M1
 - SA-11 Buk SR 9S18M1
 - SA-18 Igla comm
 - SA-18 Igla manpad
 - SA-18 Igla-S comm
 - SA-18 Igla-S manpad
 - SAU 2-C9
 - SAU Akatsia
 - SAU Gvozdika
 - SAU Msta
 - SD10 Loadout
 - SKP-11
 - SK_C_28_naval_gun
 - SNR_75V
 - SON_9
 - S_75M_Volhov
 - S_75_ZIL
 - Sandbox
 - Scud_B
 - Sd_Kfz_2
 - Sd_Kfz_234_2_Puma
 - Sd_Kfz_251
 - Sd_Kfz_7
 - Silkworm_SR
 - Smerch
 - Smerch_HE
 - Soldier AK
 - Soldier M249
 - Soldier M4 GRG
 - Soldier M4
 - Soldier RPG
 - Soldier stinger
 - SpGH_Dana
 - Stinger comm dsr
 - Stinger comm
 - Strela-1 9P31
 - Strela-10M3
 - Stug_III
 - Stug_IV
 - SturmPzIV
 - Suidae
 - T-55
 - T-72B
 - T-72B3
 - T-80UD
 - T-90
 - T155_Firtina
 - TACAN_beacon
 - TPZ
 - TYPE-59
 - TZ-22_KrAZ
 - Tankcartrinity
 - Tetrarch
 - Tiger_I
 - Tiger_II_H
 - Tigr_233036
 - Tor 9A331
 - Trolley bus
 - TugHarlan_drivable
 - Type_3_80mm_AA
 - Type_88_75mm_AA
 - Type_89_I_Go
 - Type_94_25mm_AA_Truck
 - Type_94_Truck
 - Type_96_25mm_AA
 - Type_98_Ke_Ni
 - Type_98_So_Da
 - UAZ-469
 - Uragan_BM-27
 - Ural ATsP-6
 - Ural-375 PBU
 - Ural-375 ZU-23 Insurgent
 - Ural-375 ZU-23
 - Ural-375
 - Ural-4320 APA-5D
 - Ural-4320-31
 - Ural-4320T
 - VAB_Mephisto
 - VAZ Car
 - Vulcan
 - Wellcarnsc
 - Wespe124
 - Willys_MB
 - ZBD04A
 - ZIL-131 KUNG
 - ZIL-135
 - ZIL-4331
 - ZSU-23-4 Shilka
 - ZSU_57_2
 - ZTZ96B
 - ZU-23 Closed Insurgent
 - ZU-23 Emplacement Closed
 - ZU-23 Emplacement
 - ZU-23 Insurgent
 - ZiL-131 APA-80
 - bofors40
 - fire_control
 - flak18
 - flak30
 - flak36
 - flak37
 - flak38
 - flak41
 - generator_5i57
 - house1arm
 - house2arm
 - houseA_arm
 - hy_launcher
 - leopard-2A4
 - leopard-2A4_trs
 - outpost
 - outpost_road
 - outpost_road_l
 - outpost_road_r
 - p-19 s-125 sr
 - r11_volvo_drivable
 - rapier_fsa_blindfire_radar
 - rapier_fsa_launcher
 - rapier_fsa_optical_tracker_unit
 - snr s-125 tr
 - soldier_mauser98
 - soldier_wwii_br_01
 - soldier_wwii_us
 - tacr2a
 - tt_B8M1
 - tt_DSHK
 - tt_KORD
 - tt_ZU-23
 - v1_launcher

PLANE
 - A-10A
 - A-10C
 - A-10C_2
 - A-20G
 - A-50
 - AJS37
 - AV8BNA
 - An-26B
 - An-30M
 - B-17G
 - B-1B
 - B-52H
 - Bf-109K-4
 - C-101CC
 - C-101EB
 - C-130
 - C-17A
 - C-47
 - Christen Eagle II
 - E-2C
 - E-3A
 - F-117A
 - F-14A-135-GR
 - F-14A
 - F-14B
 - F-15C
 - F-15E
 - F-15ESE
 - F-16A MLU
 - F-16A
 - F-16C bl.50
 - F-16C bl.52d
 - F-16C_50
 - F-4E-45MC
 - F-4E
 - F-5E-3
 - F-5E-3_FC
 - F-5E
 - F-86F Sabre
 - F-86F_FC
 - F4U-1D
 - F4U-1D_CW
 - FA-18A
 - FA-18C
 - FA-18C_hornet
 - FW-190A8
 - FW-190D9
 - Falcon_Gyrocopter
 - H-6J
 - Hawk
 - I-16
 - IL-76MD
 - IL-78M
 - J-11A
 - JF-17
 - Ju-88A4
 - KC-135
 - KC-130
 - KC135MPRS
 - KJ-2000
 - L-39C
 - L-39ZA
 - M-2000C
 - MB-339A
 - MB-339APAN
 - MQ-9 Reaper
 - MiG-15bis
 - MiG-15bis_FC
 - MiG-19P
 - MiG-21Bis
 - MiG-23MLD
 - MiG-25PD
 - MiG-25RBT
 - MiG-27K
 - MiG-29A
 - MiG-29G
 - MiG-29S
 - MiG-31
 - Mirage 2000-5
 - Mirage-F1AD
 - Mirage-F1AZ
 - Mirage-F1B
 - Mirage-F1BD
 - Mirage-F1BE
 - Mirage-F1BQ
 - Mirage-F1C-200
 - Mirage-F1C
 - Mirage-F1CE
 - Mirage-F1CG
 - Mirage-F1CH
 - Mirage-F1CJ
 - Mirage-F1CK
 - Mirage-F1CR
 - Mirage-F1CT
 - Mirage-F1CZ
 - Mirage-F1DDA
 - Mirage-F1ED
 - Mirage-F1EDA
 - Mirage-F1EE
 - Mirage-F1EH
 - Mirage-F1EQ
 - Mirage-F1JA
 - Mirage-F1M-CE
 - Mirage-F1M-EE
 - MosquitoFBMkVI
 - P-47D-30
 - P-47D-30bl1
 - P-47D-40
 - P-51D-30-NA
 - P-51D
 - RQ-1A Predator
 - S-3B Tanker
 - S-3B
 - SpitfireLFMkIX
 - SpitfireLFMkIXCW
 - Su-17M4
 - Su-24M
 - Su-24MR
 - Su-25
 - Su-25T
 - Su-25TM
 - Su-27
 - Su-30
 - Su-33
 - Su-34
 - TF-51D
 - Tornado GR4
 - Tornado IDS
 - Tu-142
 - Tu-160
 - Tu-22M3
 - Tu-95MS
 - WingLoong-I
 - Yak-40
 - Yak-52

HELICOPTER
 - AH-1W
 - AH-64A
 - AH-64D
 - AH-64D_BLK_II
 - CH-47D
 - CH-47Fbl1
 - CH-53E
 - Ka-27
 - Ka-50
 - Ka-50_3
 - Mi-24P
 - Mi-24V
 - Mi-26
 - Mi-28N
 - Mi-8MT
 - OH-58D
 - OH58D
 - SA342L
 - SA342M
 - SA342Minigun
 - SA342Mistral
 - SH-3W
 - SH-60B
 - UH-1H
 - UH-60A- 

SHIP
 - ALBATROS
 - BDK-775
 - CVN_71
 - CVN_72
 - CVN_73
 - CVN_75
 - CV_1143_5
 - CastleClass_01
 - Dry-cargo ship-1
 - Dry-cargo ship-2
 - ELNYA
 - Essex
 - Forrestal
 - HandyWind
 - HarborTug
 - Higgins_boat
 - IMPROVED_KILO
 - KILO
 - KUZNECOW
 - LHA_Tarawa
 - LST_Mk2
 - La_Combattante_II
 - MOLNIYA
 - MOSCOW
 - NEUSTRASH
 - PERRY
 - PIOTR
 - REZKY
 - SOM
 - Schnellboot_type_S130
 - Seawise_Giant
 - Ship_Tilde_Supply
 - Stennis
 - TICONDEROG
 - Type_052B
 - Type_052C
 - Type_054A
 - Type_071
 - Type_093
 - USS_Arleigh_Burke_IIa
 - USS_Samuel_Chase
 - Uboat_VIIC
 - VINSON
 - ZWEZDNY
 - ara_vdm
 - atconveyor
 - hms_invincible
 - leander-gun-achilles
 - leander-gun-andromeda
 - leander-gun-ariadne
 - leander-gun-condell
 - leander-gun-lynch
 - santafe
 - speedboat

STATIC
 - 345 Excavator
 - AM32a-60_01
 - AM32a-60_02
 - APFC fuel
 - Airshow_Cone
 - Airshow_Crowd
 - B600
 - Barracks 2
 - Barrier A
 - Barrier B
 - Barrier C
 - Barrier D
 - Beer Bomb
 - Belgian gate
 - Black_Tyre
 - Black_Tyre_RF
 - Black_Tyre_WF
 - Boiler-house A
 - BoomBarrier_closed
 - BoomBarrier_open
 - Building01_PBR
 - Building02_PBR
 - Building03_PBR
 - Building04_PBR
 - Building05_PBR
 - Building06_PBR
 - Building07_PBR
 - Building08_PBR
 - Cafe
 - Camouflage01
 - Camouflage02
 - Camouflage03
 - Camouflage04
 - Camouflage05
 - Camouflage06
 - Camouflage07
 - Cargo01
 - Cargo02
 - Cargo03
 - Cargo04
 - Cargo05
 - Cargo06
 - Chemical tank A
 - Comms tower M
 - Concertina wire
 - Cone01
 - Cone02
 - Container brown
 - Container red 1
 - Container red 2
 - Container red 3
 - Container white
 - Container_10ft
 - Container_generator
 - Container_office
 - Container_watchtower
 - Container_watchtower_lights
 - Czech hedgehogs 1
 - Czech hedgehogs 2
 - Dragonteeth 1
 - Dragonteeth 2
 - Dragonteeth 3
 - Dragonteeth 4
 - Dragonteeth 5
 - Electric power box
 - ElevatedPlatform_down
 - ElevatedPlatform_up
 - FARP Ammo Dump Coating
 - FARP CP Blindage
 - FARP Fuel Depot
 - FARP Tent
 - Farm A
 - Farm B
 - FarpHide_Dmed
 - FarpHide_Dsmall
 - FarpHide_Med
 - FarpHide_small
 - Fire Control Bunker
 - FireExtinguisher01
 - FireExtinguisher02
 - FireExtinguisher03
 - FlagPole
 - Freya_Shelter_Brick
 - Freya_Shelter_Concrete
 - Fuel tank
 - Garage A
 - Garage B
 - Garage small A
 - Garage small B
 - GeneratorF
 - HESCO_generator
 - HESCO_post_1
 - HESCO_wallperimeter_1
 - HESCO_wallperimeter_2
 - HESCO_wallperimeter_3
 - HESCO_wallperimeter_4
 - HESCO_wallperimeter_5
 - HESCO_watchtower_1
 - HESCO_watchtower_2
 - HESCO_watchtower_3
 - Hangar A
 - Hangar B
 - Haystack 1
 - Haystack 2
 - Haystack 3
 - Haystack 4
 - Hemmkurvenhindernis
 - Jerrycan
 - LHD_LHA
 - Ladder
 - Landmine
 - Log posts 1
 - Log posts 2
 - Log posts 3
 - Log ramps 1
 - Log ramps 2
 - Log ramps 3
 - M32-10C_01
 - M32-10C_02
 - M32-10C_03
 - M32-10C_04
 - MJ-1_01
 - MJ-1_02
 - Military staff
 - NF-2_LightOff01
 - NF-2_LightOff02
 - NF-2_LightOn
 - Nodding_Donkey_Pump
 - Oil Barrel
 - Oil derrick
 - Oil platform
 - Orca
 - P20_01
 - Pile of Woods
 - Pump station
 - Railway crossing A
 - Railway crossing B
 - Railway station
 - Red_Flag
 - Repair workshop
 - Restaurant 1
 - Revetment_x4
 - Revetment_x8
 - Sandbag_01
 - Sandbag_02
 - Sandbag_03
 - Sandbag_04
 - Sandbag_05
 - Sandbag_06
 - Sandbag_07
 - Sandbag_08
 - Sandbag_09
 - Sandbag_10
 - Sandbag_11
 - Sandbag_12
 - Sandbag_13
 - Sandbag_15
 - Sandbag_16
 - Sandbag_17
 - Shelter B
 - Shelter
 - Shelter01
 - Shelter02
 - Shop
 - Siegfried Line
 - Small house 1A area
 - Small house 1A
 - Small house 1B area
 - Small house 1B
 - Small house 1C area
 - Small house 2C
 - Small werehouse 1
 - Small werehouse 2
 - Small werehouse 3
 - Small werehouse 4
 - Small_LightHouse
 - Stanley_LightHouse
 - Subsidiary structure 1
 - Subsidiary structure 2
 - Subsidiary structure 3
 - Subsidiary structure A
 - Subsidiary structure B
 - Subsidiary structure C
 - Subsidiary structure D
 - Subsidiary structure E
 - Subsidiary structure F
 - Subsidiary structure G
 - Supermarket A
 - TV tower
 - Tech combine
 - Tech hangar A
 - Tent01
 - Tent02
 - Tent03
 - Tent04
 - Tent05
 - Tetrahydra
 - Toolbox01
 - Toolbox02
 - Tower Crane
 - TugHarlan
 - Twall_x1
 - Twall_x6
 - Twall_x6_3mts
 - WC
 - Water tower A
 - White_Flag
 - White_Tyre
 - WindTurbine
 - WindTurbine_11
 - Windsock
 - Workshop A
 - af_hq
 - billboard_motorized
 - container_20ft
 - container_40ft
 - ip_tower
 - offshore WindTurbine
 - offshore WindTurbine2
 - r11_volvo
 - warning_board_a
 - warning_board_b
 - .Ammunition depot
 - Tank 2
 - Tank 3
 - Tank
 - Warehouse

CARGO
 - L118
 - ammo_cargo
 - barrels_cargo
 - container_cargo
 - f_bar_cargo
 - fueltank_cargo
 - iso_container
 - iso_container_small
 - m117_cargo
 - oiltank_cargo
 - pipes_big_cargo
 - pipes_small_cargo
 - tetrapod_cargo
 - trunks_long_cargo
 - trunks_small_cargo
 - uh1h_cargo
