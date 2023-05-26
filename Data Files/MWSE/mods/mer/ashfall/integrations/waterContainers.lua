local interop = require("mer.ashfall.interop")

interop.registerWaterContainers({
    --ashfall stuff
    ashfall_waterskin = {
        capacity = 90
    },
    ashfall_teacup_01 = {
        capacity = 25,
        waterMaxScale = 1.9,
        waterMaxHeight = 2.5,
    },
    ashfall_teacup_02 = {
        capacity = 25,
        waterMaxScale = 1.9,
        waterMaxHeight = 2.5,
    },
    ashfall_teacup_03 = {
        capacity = 25,
        waterMaxScale = 1.9,
        waterMaxHeight = 2.5,
    },

    ashfall_bowl_01 = {
        capacity = 60,
        waterMaxScale = 1.8,
        waterMaxHeight = 4.0,
    },
    ashfall_cup_01 = {
        capacity = 25,
        waterMaxScale = 1.3,
        waterMaxHeight = 4.0,
    },
    ashfall_cup_02 = {
        capacity = 35,
        waterMaxScale = 1.3,
        waterMaxHeight = 4.0,
    },

    t_nor_drinkinghorn_01 = { capacity = 30 },
    t_nor_drinkinghorn_02 = { capacity = 30 },
    t_nor_drinkinghorn_03 = { capacity = 30 },
    t_com_potionbottle_01 = { capacity = 90, weight = 4 },
    t_com_potionbottle_02 = { capacity = 90, weight = 4 },
    t_com_potionbottle_03 = { capacity = 90, weight = 4 },
    t_com_potionbottle_04 = { capacity = 90, weight = 4 },
    t_imp_silverwarecup_01 = { capacity = 25 },
    t_imp_silverwarecup_02 = { capacity = 25 },
    t_imp_silverwarecup_03 = { capacity = 25 },
    t_de_stonewarecup_01 = { capacity = 25 },
    t_de_stonewarecup_02 = { capacity = 25 },
    t_de_stonewarejug_01 = { capacity = 200 },
    t_de_stonewarepitcher_01 = { capacity = 190 },
    --vial
    misc_skooma_vial = "glass",
    --glasses
    misc_de_glass_green_01 = "glass",
    misc_de_glass_yellow_01 = "glass",
    --cups
    misc_com_redware_cup = "cup",
    misc_com_wood_cup_01 = "cup",
    misc_com_wood_cup_02 = "cup",
    misc_lw_cup = "cup",
    misc_imp_silverware_cup = "cup",
    misc_imp_silverware_cup_01 = "cup",
    --goblets
    misc_com_metal_goblet_01 = "goblet",
    misc_com_metal_goblet_02 = "goblet",
    misc_de_goblet_01 = "goblet",
    misc_de_goblet_02 = "goblet",
    misc_de_goblet_03 = "goblet",
    misc_de_goblet_04 = "goblet",
    misc_de_goblet_05 = "goblet",
    misc_de_goblet_06 = "goblet",
    misc_de_goblet_07 = "goblet",
    misc_de_goblet_08 = "goblet",
    misc_de_goblet_09 = "goblet",
    misc_dwrv_goblet00 = "goblet",
    misc_dwrv_goblet10 = "goblet",
    misc_dwrv_goblet00_uni = "goblet",
    misc_dwrv_goblet10_uni = "goblet",
    misc_dwrv_goblet10_tgcp = "goblet",
    misc_de_goblet_01_redas = "goblet",
    --tankards
    misc_com_tankard_01 = "tankard",
    misc_de_tankard_01 = "tankard",
    t_imp_silverwarepot_01 = "noValPot",
    --mugs
    misc_dwrv_mug00 = "mug",
    misc_dwrv_mug00_uni = "mug",
    --flasks
    misc_flask_01 = "flask",
    misc_flask_02 = "flask",
    misc_flask_03 = "flask",
    misc_flask_04 = "flask",
    misc_com_redware_flask = "flask",
    misc_lw_flask = "limewareFlask",
    --bottles
    misc_com_bottle_01 = "bottle",
    misc_com_bottle_02 = "bottle",
    misc_com_bottle_04 = "bottle",
    misc_com_bottle_05 = "bottle",
    misc_com_bottle_06 = "bottle",
    misc_com_bottle_08 = "bottle",
    misc_com_bottle_09 = "bottle",
    misc_com_bottle_10 = "bottle",
    misc_com_bottle_11 = "bottle",
    misc_com_bottle_13 = "bottle",
    misc_com_bottle_14 = "bottle",
    misc_com_bottle_14_float = "bottle",
    misc_com_bottle_15 = "bottle",
    --pots
    misc_de_pot_blue_01 = "pot",
    misc_de_pot_blue_02 = "pot",
    misc_de_pot_glass_peach_01 = "pot",
    misc_de_pot_glass_peach_02 = "pot",
    misc_de_pot_green_01 = "pot",
    misc_de_pot_mottled_01 = "pot",
    --redware pots
    misc_de_pot_redware_01 = "redwarePot",
    misc_de_pot_redware_02 = "redwarePot",
    misc_de_pot_redware_03 = "redwarePot",
    misc_de_pot_redware_04 = "redwarePot",
    misc_de_pot_redware_04_uni = "redwarePot",
    --jugs
    misc_com_bottle_03 = "jug",
    misc_com_bottle_07 = "jug",
    misc_com_bottle_07_float = "jug",
    misc_com_bottle_12 = "jug",
    --pitchers
    misc_de_pitcher_01 = "pitcher",
    misc_com_redware_pitcher = "redwarePitcher",
    misc_com_pitcher_metal_01 = "metalPitcher",
    misc_imp_silverware_pitcher = "silverwarePitcher",
    misc_imp_silverware_pitcher_uni = "silverwarePitcher",
    misc_dwrv_pitcher00 = "dwarvenPitcher",
    misc_dwrv_pitcher00_uni = "dwarvenPitcher",
    --MODS
    --seydaneen gateway
    misc_com_bottle_water = "bottle",
    --Tamriel Data
    t_ayl_claycup_01 = "cup",
    t_ayl_claypot_01 = "pot",
    t_ayl_claypot_02 = "pot",
    t_ayl_claypot_03 = "pot",
    t_imp_goldpitcher_01 = "pitcher",
    t_rga_pitcher_01 = "pitcher",
    t_nor_claypot_01 = "pot",
    t_nor_claypot_02 = "pot",
    t_rga_blackwarecup_01 = "cup",
    t_rga_redwarecup_01 = "cup",
    t_rga_redwarecup_02 = "cup",
    t_rga_redwarecup_03 = "cup",
    t_he_dirennicup_01 = "cup",
    t_he_dirennicup_02 = "cup",
    t_he_direnniflask_01a = "limewareFlask",
    t_he_direnniflask_02a = "limewareFlask",
    t_he_direnniflask_03a = "limewareFlask",
    t_he_direnniflask_04a = "limewareFlask",
    t_he_direnniflask_05a = "limewareFlask",
    t_he_direnniflask_06a = "limewareFlask",
    t_he_direnniflask_07a = "limewareFlask",
    t_he_direnniflask_07b = "limewareFlask",
    t_he_dirennipot_01 = "noValPot",
    t_he_dirennipot_02 = "noValPot",
    t_he_dirennipot_03 = "noValPot",
    t_he_dirennipot_04 = "noValPot",
    t_nor_flaskblue_01 = "flask",
    t_nor_flaskblue_02 = "flask",
    t_nor_flaskblue_03 = "flask",
    t_nor_flaskblue_04 = "flask",
    t_nor_flaskgreen_01 = "flask",
    t_nor_flaskgreen_02 = "flask",
    t_nor_flaskgreen_03 = "flask",
    t_nor_flaskgreen_04 = "flask",
    t_nor_flaskred_01 = "flask",
    t_nor_flaskred_02 = "flask",
    t_nor_flaskred_03 = "flask",
    t_nor_flaskred_04 = "flask",
    t_rga_flask_01 = "limewareFlask",
    t_de_stonewarepot_01 = "noValPot",
    t_de_stonewarepot_02 = "noValPot",
    t_de_stonewarepot_03 = "noValPot",
    t_com_woodencup_01 = "cup",
    t_nor_woodengoblet_01a = "goblet",
    t_nor_woodengoblet_01b = "goblet",
    t_nor_woodengoblet_01c = "goblet",
    t_nor_woodengoblet_02a = "goblet",
    t_nor_woodengoblet_02b = "goblet",
    t_nor_woodengoblet_03a = "goblet",
    t_nor_woodengoblet_03b = "goblet",
    t_nor_woodengoblet_04a = "goblet",
    t_nor_woodengoblet_04b = "goblet",
    t_nor_woodentankard_01a = "mug",
    t_nor_woodentankard_01b = "mug",
    t_nor_woodenpot_01a = "noValPot",
    t_nor_woodenpot_01b = "noValPot",
    t_nor_woodenpot_02a = "noValPot",
    t_nor_woodenpot_02b = "noValPot",
    t_nor_woodenpot_03a = "noValPot",
    t_nor_woodenpot_03b = "noValPot",
    t_de_telvannitankard_01 = "tankard",
    t_com_tankard_01 = "tankard",
    t_de_bluewaretankard01 = "tankard",
    t_de_yellowglasscup01 = "cup",
    t_de_yellowglassflask01 = "flask",
    t_de_yellowglasspot01 = "noValPot",
}, true)