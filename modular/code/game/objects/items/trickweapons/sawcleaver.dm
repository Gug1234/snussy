// ===================== SAW CLEAVER (v3) =====================
// Base: Folded serrated saw. Fast slashes and precise thrusts.
// Transformed: Extended cleaver. Sweeping chops and heavy overhead cuts.
//
// 28 unique intents:
//   Base 1H (4): Quick Cut chain, Serrated Thrust, Saw Bash, Ripping Slash
//   Base 2H (4): Power Cut chain, Driving Thrust, Two-Hand Bash, Goring Rip
//   Tfm 1H (4): Cleaver Sweep chain, Heavy Chop, Pommel Strike, Executioner's Cleave
//   Tfm 2H (4): Great Sweep chain, Brutal Chop, Handle Crush, Decapitating Cleave
//   Transform attacks (2): Extending Slash, Retracting Cut
//   Running attacks (4): Dashing Cut, Charging Cut, Dashing Sweep, Charging Sweep
//   Running transform attacks (2): Running Extend, Running Retract
//   Lunge attacks (4): Leaping Cut, Plunging Cut, Leaping Cleave, Plunging Cleave
//
// BB motion values → damfactor: MV / 100 (100 = 1.0x)
// ================================================================

// ==================== BASE 1H INTENTS (4) ====================

/// Saw Cleaver base 1H — R1 chain. Fast serrated slashes.
/// 5-hit chain (BB MVs: 100→102→104→106→109)
/datum/intent/sawcleaver/base/slash
	name = "quick cut"
	icon_state = "incut"
	attack_verb = list("cuts", "saws")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/hits/cut_damage1.ogg', 'modular/sounds/trickweapons/hits/cut_damage2.ogg', 'modular/sounds/trickweapons/hits/cut_damage3.ogg', 'modular/sounds/trickweapons/hits/cut_damage4.ogg', 'modular/sounds/trickweapons/hits/cut_damage5.ogg', 'modular/sounds/trickweapons/hits/cut_damage6.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 1.0
	clickcd = 10
	item_d_type = "slash"
	combo_id = "sc_b_slash"
	combo_category = COMBO_CAT_LIGHT
	combo_max = 5
	combo_damfactors = list(1.0, 1.02, 1.04, 1.06, 1.09)
	combo_sounds = list(\
		list('modular/sounds/trickweapons/sawcleaver/sawcleaver_base_r1_1st.ogg', 'modular/sounds/trickweapons/sawcleaver/sawcleaver_base_r1_1st_alt.ogg'), \
		list('modular/sounds/trickweapons/sawcleaver/sawcleaver_base_r1_2nd.ogg'), \
		list('modular/sounds/trickweapons/sawcleaver/sawcleaver_base_r1_3rd.ogg'), \
		list('modular/sounds/trickweapons/sawcleaver/sawcleaver_base_r1_4th.ogg'), \
		list('modular/sounds/trickweapons/sawcleaver/sawcleaver_base_r1_5th.ogg'))
	combo_hitsounds = list(\
		list('modular/sounds/trickweapons/hits/cut_damage1.ogg', 'modular/sounds/trickweapons/hits/cut_damage2.ogg'), \
		list('modular/sounds/trickweapons/hits/cut_damage2.ogg', 'modular/sounds/trickweapons/hits/cut_damage3.ogg'), \
		list('modular/sounds/trickweapons/hits/cut_damage3.ogg', 'modular/sounds/trickweapons/hits/cut_damage4.ogg'), \
		list('modular/sounds/trickweapons/hits/cut_damage4.ogg', 'modular/sounds/trickweapons/hits/cut_damage5.ogg'), \
		list('modular/sounds/trickweapons/hits/cut_damage5.ogg', 'modular/sounds/trickweapons/hits/cut_damage6.ogg'))

/// Saw Cleaver base 1H — R2 thrust. Forward stab with serrated teeth.
/// BB R2: 120
/datum/intent/sawcleaver/base/thrust
	name = "serrated thrust"
	icon_state = "instab"
	attack_verb = list("stabs", "gouges")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/hits/stab_damage1.ogg', 'modular/sounds/trickweapons/hits/stab_damage2.ogg', 'modular/sounds/trickweapons/hits/stab_damage3.ogg', 'modular/sounds/trickweapons/hits/stab_damage4.ogg', 'modular/sounds/trickweapons/hits/stab_damage5.ogg', 'modular/sounds/trickweapons/hits/stab_damage6.ogg')
	swingsound = list('modular/sounds/trickweapons/sawcleaver/sawcleaver_base_r2.ogg')
	chargetime = 0
	penfactor = 25
	damfactor = 1.2
	clickcd = 12
	item_d_type = "stab"
	combo_id = "sc_b_thrust"
	combo_category = COMBO_CAT_THRUST

/// Saw Cleaver base 1H — blunt bash. Flat-side strike with the compact saw blade.
/datum/intent/sawcleaver/base/strike
	name = "saw bash"
	icon_state = "instrike"
	attack_verb = list("bashes", "clubs")
	animname = "strike"
	blade_class = BCLASS_BLUNT
	swingsound = list('modular/sounds/trickweapons/sawcleaver/sawcleaver_base_backstep_r1.ogg', 'modular/sounds/trickweapons/sawcleaver/sawcleaver_base_backstep_r1_alt.ogg')
	hitsound = list('modular/sounds/trickweapons/hits/dageki_hit1.ogg', 'modular/sounds/trickweapons/hits/dageki_hit2.ogg', 'modular/sounds/trickweapons/hits/dageki_hit3.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = NONBLUNT_BLUNT_DAMFACTOR
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	combo_id = "sc_b_strike"
	combo_category = COMBO_CAT_BLUNT

/// Saw Cleaver base 1H — charged R2. Drags serrated teeth across flesh.
/// BB Charged: 190
/datum/intent/sawcleaver/base/charged
	name = "ripping slash"
	icon_state = "incut"
	attack_verb = list("rips", "tears")
	animname = "cut"
	blade_class = BCLASS_CUT
	swingsound = list('modular/sounds/trickweapons/sawcleaver/sawcleaver_base_r2_charged.ogg')
	hitsound = list('modular/sounds/trickweapons/hits/cut_damage4.ogg', 'modular/sounds/trickweapons/hits/cut_damage5.ogg', 'modular/sounds/trickweapons/hits/cut_damage6.ogg')
	penfactor = 30
	chargetime = 5
	charged_sound = 'modular/sounds/trickweapons/hits/charge_attack_full.ogg'
	chargedrain = 1
	swingdelay = 8
	damfactor = 1.9
	clickcd = 16
	item_d_type = "slash"
	combo_id = "sc_b_charged"
	combo_category = COMBO_CAT_HEAVY

// ==================== BASE 2H INTENTS (4) ====================

/// Saw Cleaver base 2H — gripped R1 chain. Heavier two-handed saw slashes.
/// 3-hit chain, higher base damage per hit than 1H chain.
/datum/intent/sawcleaver/base/grip_slash
	name = "power cut"
	icon_state = "incut"
	attack_verb = list("cuts", "saws")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/hits/cut_damage1.ogg', 'modular/sounds/trickweapons/hits/cut_damage2.ogg', 'modular/sounds/trickweapons/hits/cut_damage3.ogg', 'modular/sounds/trickweapons/hits/cut_damage4.ogg', 'modular/sounds/trickweapons/hits/cut_damage5.ogg', 'modular/sounds/trickweapons/hits/cut_damage6.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 1.05
	clickcd = 11
	item_d_type = "slash"
	combo_id = "sc_bg_slash"
	combo_category = COMBO_CAT_LIGHT
	combo_max = 3
	combo_damfactors = list(1.05, 1.08, 1.12)
	combo_sounds = list(\
		list('modular/sounds/trickweapons/sawcleaver/sawcleaver_base_r1_1st.ogg', 'modular/sounds/trickweapons/sawcleaver/sawcleaver_base_r1_1st_alt.ogg'), \
		list('modular/sounds/trickweapons/sawcleaver/sawcleaver_base_r1_3rd.ogg'), \
		list('modular/sounds/trickweapons/sawcleaver/sawcleaver_base_r1_5th.ogg'))
	combo_hitsounds = list(\
		list('modular/sounds/trickweapons/hits/cut_damage2.ogg', 'modular/sounds/trickweapons/hits/cut_damage3.ogg'), \
		list('modular/sounds/trickweapons/hits/cut_damage4.ogg', 'modular/sounds/trickweapons/hits/cut_damage5.ogg'), \
		list('modular/sounds/trickweapons/hits/cut_damage5.ogg', 'modular/sounds/trickweapons/hits/cut_damage6.ogg'))

/// Saw Cleaver base 2H — gripped R2 thrust. Two-handed driving stab.
/// BB Dash R2: 125
/datum/intent/sawcleaver/base/grip_thrust
	name = "driving thrust"
	icon_state = "instab"
	attack_verb = list("drives", "plunges")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/hits/stab_damage1.ogg', 'modular/sounds/trickweapons/hits/stab_damage2.ogg', 'modular/sounds/trickweapons/hits/stab_damage3.ogg', 'modular/sounds/trickweapons/hits/stab_damage4.ogg', 'modular/sounds/trickweapons/hits/stab_damage5.ogg', 'modular/sounds/trickweapons/hits/stab_damage6.ogg')
	swingsound = list('modular/sounds/trickweapons/sawcleaver/sawcleaver_base_r1-r2_followup.ogg', 'modular/sounds/trickweapons/sawcleaver/sawcleaver_base_r1-r2_followup_fwd.ogg')
	chargetime = 0
	penfactor = 30
	damfactor = 1.25
	clickcd = 13
	item_d_type = "stab"
	combo_id = "sc_bg_thrust"
	combo_category = COMBO_CAT_THRUST

/// Saw Cleaver base 2H — gripped blunt. Two-handed overhead bash.
/datum/intent/sawcleaver/base/grip_strike
	name = "crushing bash"
	icon_state = "instrike"
	attack_verb = list("crushes", "batters")
	animname = "strike"
	blade_class = BCLASS_BLUNT
	swingsound = list('modular/sounds/trickweapons/sawcleaver/sawcleaver_base_r2-r2_followup.ogg')
	hitsound = list('modular/sounds/trickweapons/hits/dageki_hit1.ogg', 'modular/sounds/trickweapons/hits/dageki_hit2.ogg', 'modular/sounds/trickweapons/hits/dageki_hit3.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = NONBLUNT_BLUNT_DAMFACTOR
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	combo_id = "sc_bg_strike"
	combo_category = COMBO_CAT_BLUNT

/// Saw Cleaver base 2H — gripped charged R2. Two-handed goring rip.
/// BB Charged: 190
/datum/intent/sawcleaver/base/grip_charged
	name = "goring rip"
	icon_state = "incut"
	attack_verb = list("gores", "rends")
	animname = "cut"
	blade_class = BCLASS_CUT
	swingsound = list('modular/sounds/trickweapons/sawcleaver/sawcleaver_base_r2_charged.ogg')
	hitsound = list('modular/sounds/trickweapons/hits/cut_damage4.ogg', 'modular/sounds/trickweapons/hits/cut_damage5.ogg', 'modular/sounds/trickweapons/hits/cut_damage6.ogg')
	penfactor = 35
	chargetime = 5
	charged_sound = 'modular/sounds/trickweapons/hits/charge_attack_full.ogg'
	chargedrain = 1
	swingdelay = 8
	damfactor = 1.9
	clickcd = 16
	item_d_type = "slash"
	combo_id = "sc_bg_charged"
	combo_category = COMBO_CAT_HEAVY

// ==================== TRANSFORMED 1H INTENTS (4) ====================

/// Saw Cleaver tfm 1H — R1 chain. Wide sweeping cleaver slashes.
/// 3-hit chain (BB MVs: 97→100→102)
/datum/intent/sawcleaver/tfm/sweep
	name = "cleaver sweep"
	icon_state = "incut"
	attack_verb = list("sweeps", "slashes")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/hits/cut_damage1.ogg', 'modular/sounds/trickweapons/hits/cut_damage2.ogg', 'modular/sounds/trickweapons/hits/cut_damage3.ogg', 'modular/sounds/trickweapons/hits/cut_damage4.ogg', 'modular/sounds/trickweapons/hits/cut_damage5.ogg', 'modular/sounds/trickweapons/hits/cut_damage6.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 0.97
	clickcd = 12
	item_d_type = "slash"
	combo_id = "sc_t_sweep"
	combo_category = COMBO_CAT_LIGHT
	combo_max = 3
	combo_damfactors = list(0.97, 1.0, 1.02)
	combo_sounds = list(\
		list('modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_r1_1st.ogg', 'modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_r1_1st_alt.ogg'), \
		list('modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_r1_2nd.ogg'), \
		list('modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_r1_3rd.ogg'))
	combo_hitsounds = list(\
		list('modular/sounds/trickweapons/hits/cut_damage1.ogg', 'modular/sounds/trickweapons/hits/cut_damage2.ogg'), \
		list('modular/sounds/trickweapons/hits/cut_damage3.ogg', 'modular/sounds/trickweapons/hits/cut_damage4.ogg'), \
		list('modular/sounds/trickweapons/hits/cut_damage5.ogg', 'modular/sounds/trickweapons/hits/cut_damage6.ogg'))

/// Saw Cleaver tfm 1H — R2. Heavy overhead chop.
/// BB R2: 125
/datum/intent/sawcleaver/tfm/chop
	name = "heavy chop"
	icon_state = "inchop"
	attack_verb = list("chops", "hacks")
	animname = "chop"
	blade_class = BCLASS_CHOP
	swingsound = list('modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_r2.ogg')
	hitsound = list('modular/sounds/trickweapons/hits/cut_damage4.ogg', 'modular/sounds/trickweapons/hits/cut_damage5.ogg', 'modular/sounds/trickweapons/hits/cut_damage6.ogg')
	chargetime = 0
	penfactor = 30
	damfactor = 1.25
	clickcd = 13
	item_d_type = "slash"
	combo_id = "sc_t_chop"
	combo_category = COMBO_CAT_HEAVY

/// Saw Cleaver tfm 1H — blunt. Pommel strike with the cleaver handle.
/datum/intent/sawcleaver/tfm/strike
	name = "pommel strike"
	icon_state = "instrike"
	attack_verb = list("pommel-strikes", "clubs")
	animname = "strike"
	blade_class = BCLASS_BLUNT
	swingsound = list('modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_backstep_r1.ogg', 'modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_backstep_r1_alt.ogg')
	hitsound = list('modular/sounds/trickweapons/hits/dageki_hit1.ogg', 'modular/sounds/trickweapons/hits/dageki_hit2.ogg', 'modular/sounds/trickweapons/hits/dageki_hit3.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = NONBLUNT_BLUNT_DAMFACTOR
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	combo_id = "sc_t_strike"
	combo_category = COMBO_CAT_BLUNT

/// Saw Cleaver tfm 1H — charged R2. Massive overhead executioner's cleave.
/// BB Charged: 170
/datum/intent/sawcleaver/tfm/charged
	name = "executioner's cleave"
	icon_state = "inchop"
	attack_verb = list("cleaves", "executes")
	animname = "chop"
	blade_class = BCLASS_CHOP
	swingsound = list('modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_r2_charged.ogg')
	hitsound = list('modular/sounds/trickweapons/hits/cut_damage4.ogg', 'modular/sounds/trickweapons/hits/cut_damage5.ogg', 'modular/sounds/trickweapons/hits/cut_damage6.ogg')
	penfactor = 35
	chargetime = 5
	charged_sound = 'modular/sounds/trickweapons/hits/charge_attack_full.ogg'
	chargedrain = 1
	swingdelay = 8
	damfactor = 1.7
	clickcd = 16
	item_d_type = "slash"
	combo_id = "sc_t_charged"
	combo_category = COMBO_CAT_HEAVY

// ==================== TRANSFORMED 2H INTENTS (4) ====================

/// Saw Cleaver tfm 2H — gripped R1 chain. Two-handed great sweeps.
/// 3-hit chain, slightly higher damage than 1H.
/datum/intent/sawcleaver/tfm/grip_sweep
	name = "great sweep"
	icon_state = "incut"
	attack_verb = list("sweeps", "cleaves")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/hits/cut_damage1.ogg', 'modular/sounds/trickweapons/hits/cut_damage2.ogg', 'modular/sounds/trickweapons/hits/cut_damage3.ogg', 'modular/sounds/trickweapons/hits/cut_damage4.ogg', 'modular/sounds/trickweapons/hits/cut_damage5.ogg', 'modular/sounds/trickweapons/hits/cut_damage6.ogg')
	chargetime = 0
	penfactor = 25
	damfactor = 1.0
	clickcd = 13
	item_d_type = "slash"
	combo_id = "sc_tg_sweep"
	combo_category = COMBO_CAT_LIGHT
	combo_max = 3
	combo_damfactors = list(1.0, 1.04, 1.08)
	combo_sounds = list(\
		list('modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_r1_1st.ogg', 'modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_r1_1st_alt.ogg'), \
		list('modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_r1_2nd.ogg'), \
		list('modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_r1_3rd.ogg'))
	combo_hitsounds = list(\
		list('modular/sounds/trickweapons/hits/cut_damage2.ogg', 'modular/sounds/trickweapons/hits/cut_damage3.ogg'), \
		list('modular/sounds/trickweapons/hits/cut_damage4.ogg', 'modular/sounds/trickweapons/hits/cut_damage5.ogg'), \
		list('modular/sounds/trickweapons/hits/cut_damage5.ogg', 'modular/sounds/trickweapons/hits/cut_damage6.ogg'))

/// Saw Cleaver tfm 2H — gripped R2. Two-handed brutal overhead chop.
/// BB R2-2: 127
/datum/intent/sawcleaver/tfm/grip_chop
	name = "brutal chop"
	icon_state = "inchop"
	attack_verb = list("brutalizes", "cleaves")
	animname = "chop"
	blade_class = BCLASS_CHOP
	swingsound = list('modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_r1-r2_followup.ogg', 'modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_r1-r2_followup_fwd.ogg')
	hitsound = list('modular/sounds/trickweapons/hits/cut_damage4.ogg', 'modular/sounds/trickweapons/hits/cut_damage5.ogg', 'modular/sounds/trickweapons/hits/cut_damage6.ogg')
	chargetime = 0
	penfactor = 35
	damfactor = 1.27
	clickcd = 14
	item_d_type = "slash"
	combo_id = "sc_tg_chop"
	combo_category = COMBO_CAT_HEAVY

/// Saw Cleaver tfm 2H — gripped blunt. Two-handed handle crush.
/datum/intent/sawcleaver/tfm/grip_strike
	name = "handle crush"
	icon_state = "instrike"
	attack_verb = list("crushes", "clobbers")
	animname = "strike"
	blade_class = BCLASS_BLUNT
	swingsound = list('modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_r2-r2_followup.ogg')
	hitsound = list('modular/sounds/trickweapons/hits/dageki_hit1.ogg', 'modular/sounds/trickweapons/hits/dageki_hit2.ogg', 'modular/sounds/trickweapons/hits/dageki_hit3.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = NONBLUNT_BLUNT_DAMFACTOR
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	combo_id = "sc_tg_strike"
	combo_category = COMBO_CAT_BLUNT

/// Saw Cleaver tfm 2H — gripped charged. Devastating decapitating cleave.
/// BB Charged: 170, Chg-2: 127
/datum/intent/sawcleaver/tfm/grip_charged
	name = "decapitating cleave"
	icon_state = "inchop"
	attack_verb = list("decapitates", "executes")
	animname = "chop"
	blade_class = BCLASS_CHOP
	swingsound = list('modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_r2_charged.ogg')
	hitsound = list('modular/sounds/trickweapons/hits/cut_damage4.ogg', 'modular/sounds/trickweapons/hits/cut_damage5.ogg', 'modular/sounds/trickweapons/hits/cut_damage6.ogg')
	penfactor = 40
	chargetime = 5
	charged_sound = 'modular/sounds/trickweapons/hits/charge_attack_full.ogg'
	chargedrain = 1
	swingdelay = 8
	damfactor = 1.7
	clickcd = 16
	item_d_type = "slash"
	combo_id = "sc_tg_charged"
	combo_category = COMBO_CAT_HEAVY

// ==================== TRANSFORM ATTACK INTENTS (2) ====================

/// Saw Cleaver transform attack — base→transformed. Slashes while extending the blade.
/// BB Tfm-Atk: 130
/datum/intent/sawcleaver/xfm/extend
	name = "extending slash"
	icon_state = "incut"
	attack_verb = list("extend-slashes", "rakes")
	animname = "cut"
	blade_class = BCLASS_CUT
	swingsound = list('modular/sounds/trickweapons/sawcleaver/sawcleaver_base_l1_transform_attack.ogg', 'modular/sounds/trickweapons/sawcleaver/sawcleaver_base_l1_transform_attack_alt.ogg')
	hitsound = list('modular/sounds/trickweapons/hits/cut_damage1.ogg', 'modular/sounds/trickweapons/hits/cut_damage2.ogg', 'modular/sounds/trickweapons/hits/cut_damage3.ogg', 'modular/sounds/trickweapons/hits/cut_damage4.ogg', 'modular/sounds/trickweapons/hits/cut_damage5.ogg', 'modular/sounds/trickweapons/hits/cut_damage6.ogg')
	chargetime = 0
	penfactor = 25
	damfactor = 1.3
	clickcd = 12
	item_d_type = "slash"
	combo_id = "sc_xfm_ext"
	combo_category = COMBO_CAT_HEAVY

/// Saw Cleaver transform attack — transformed→base. Cuts while retracting the blade.
/// BB Tfm-Atk: 130
/datum/intent/sawcleaver/xfm/retract
	name = "retracting cut"
	icon_state = "incut"
	attack_verb = list("retract-cuts", "snaps")
	animname = "cut"
	blade_class = BCLASS_CUT
	swingsound = list('modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_l1_transform_attack.ogg', 'modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_l1_transform_attack_alt.ogg')
	hitsound = list('modular/sounds/trickweapons/hits/cut_damage4.ogg', 'modular/sounds/trickweapons/hits/cut_damage5.ogg', 'modular/sounds/trickweapons/hits/cut_damage6.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 1.3
	clickcd = 12
	item_d_type = "slash"
	combo_id = "sc_xfm_ret"
	combo_category = COMBO_CAT_HEAVY

// ==================== RUNNING ATTACK INTENTS (4) ====================

/// Saw Cleaver running attack — base 1H. Dashing serrated cut.
/// BB Dash R1: 109
/datum/intent/sawcleaver/run/base_cut
	name = "dashing cut"
	icon_state = "incut"
	attack_verb = list("dash-cuts", "slices")
	animname = "cut"
	blade_class = BCLASS_CUT
	swingsound = list('modular/sounds/trickweapons/sawcleaver/sawcleaver_base_running_r1.ogg', 'modular/sounds/trickweapons/sawcleaver/sawcleaver_base_running_r1_back.ogg', 'modular/sounds/trickweapons/sawcleaver/sawcleaver_base_running_r1_right.ogg')
	hitsound = list('modular/sounds/trickweapons/hits/cut_damage1.ogg', 'modular/sounds/trickweapons/hits/cut_damage2.ogg', 'modular/sounds/trickweapons/hits/cut_damage3.ogg', 'modular/sounds/trickweapons/hits/cut_damage4.ogg', 'modular/sounds/trickweapons/hits/cut_damage5.ogg', 'modular/sounds/trickweapons/hits/cut_damage6.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 1.09
	clickcd = 11
	item_d_type = "slash"
	combo_id = "sc_run_b"
	combo_category = COMBO_CAT_LIGHT

/// Saw Cleaver running attack — base 2H. Charging two-handed cut.
/// BB Dash R1: 109 (slightly higher for 2H investment)
/datum/intent/sawcleaver/run/base_grip_cut
	name = "charging cut"
	icon_state = "incut"
	attack_verb = list("charge-cuts", "carves")
	animname = "cut"
	blade_class = BCLASS_CUT
	swingsound = list('modular/sounds/trickweapons/sawcleaver/sawcleaver_base_running_r1.ogg', 'modular/sounds/trickweapons/sawcleaver/sawcleaver_base_running_r1_right.ogg')
	hitsound = list('modular/sounds/trickweapons/hits/cut_damage1.ogg', 'modular/sounds/trickweapons/hits/cut_damage2.ogg', 'modular/sounds/trickweapons/hits/cut_damage3.ogg', 'modular/sounds/trickweapons/hits/cut_damage4.ogg', 'modular/sounds/trickweapons/hits/cut_damage5.ogg', 'modular/sounds/trickweapons/hits/cut_damage6.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 1.1
	clickcd = 12
	item_d_type = "slash"
	combo_id = "sc_run_bg"
	combo_category = COMBO_CAT_LIGHT

/// Saw Cleaver running attack — tfm 1H. Dashing cleaver sweep.
/// BB Dash R1 (tfm): 115
/datum/intent/sawcleaver/run/tfm_sweep
	name = "dashing sweep"
	icon_state = "incut"
	attack_verb = list("dash-sweeps", "slashes")
	animname = "cut"
	blade_class = BCLASS_CUT
	swingsound = list('modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_running_r1.ogg', 'modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_running_r1_back.ogg', 'modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_running_r1_right.ogg')
	hitsound = list('modular/sounds/trickweapons/hits/cut_damage1.ogg', 'modular/sounds/trickweapons/hits/cut_damage2.ogg', 'modular/sounds/trickweapons/hits/cut_damage3.ogg', 'modular/sounds/trickweapons/hits/cut_damage4.ogg', 'modular/sounds/trickweapons/hits/cut_damage5.ogg', 'modular/sounds/trickweapons/hits/cut_damage6.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 1.15
	clickcd = 12
	item_d_type = "slash"
	combo_id = "sc_run_t"
	combo_category = COMBO_CAT_LIGHT

/// Saw Cleaver running attack — tfm 2H. Charging two-handed sweep.
/// BB Dash R2 (tfm): 120
/datum/intent/sawcleaver/run/tfm_grip_sweep
	name = "charging sweep"
	icon_state = "incut"
	attack_verb = list("charge-sweeps", "cleaves")
	animname = "cut"
	blade_class = BCLASS_CUT
	swingsound = list('modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_running_r2.ogg', 'modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_running_r1.ogg', 'modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_running_r1_right.ogg')
	hitsound = list('modular/sounds/trickweapons/hits/cut_damage1.ogg', 'modular/sounds/trickweapons/hits/cut_damage2.ogg', 'modular/sounds/trickweapons/hits/cut_damage3.ogg', 'modular/sounds/trickweapons/hits/cut_damage4.ogg', 'modular/sounds/trickweapons/hits/cut_damage5.ogg', 'modular/sounds/trickweapons/hits/cut_damage6.ogg')
	chargetime = 0
	penfactor = 25
	damfactor = 1.2
	clickcd = 13
	item_d_type = "slash"
	combo_id = "sc_run_tg"
	combo_category = COMBO_CAT_LIGHT

// ==================== RUNNING TRANSFORM ATTACK INTENTS (2) ====================

/// Saw Cleaver running transform attack — base→transformed while running.
/// BB Tfm-Atk: 130
/datum/intent/sawcleaver/runxfm/extend
	name = "running extend"
	icon_state = "incut"
	attack_verb = list("sprinting-extends", "rakes")
	animname = "cut"
	blade_class = BCLASS_CUT
	swingsound = list('modular/sounds/trickweapons/sawcleaver/sawcleaver_base_dodge_l1_transform.ogg', 'modular/sounds/trickweapons/sawcleaver/sawcleaver_base_dodge_l1_transform_back.ogg')
	hitsound = list('modular/sounds/trickweapons/hits/cut_damage1.ogg', 'modular/sounds/trickweapons/hits/cut_damage2.ogg', 'modular/sounds/trickweapons/hits/cut_damage3.ogg', 'modular/sounds/trickweapons/hits/cut_damage4.ogg', 'modular/sounds/trickweapons/hits/cut_damage5.ogg', 'modular/sounds/trickweapons/hits/cut_damage6.ogg')
	chargetime = 0
	penfactor = 25
	damfactor = 1.3
	clickcd = 12
	item_d_type = "slash"
	combo_id = "sc_rxfm_ext"
	combo_category = COMBO_CAT_HEAVY

/// Saw Cleaver running transform attack — transformed→base while running.
/// BB Tfm-Atk: 130
/datum/intent/sawcleaver/runxfm/retract
	name = "running retract"
	icon_state = "incut"
	attack_verb = list("sprinting-retracts", "snaps")
	animname = "cut"
	blade_class = BCLASS_CUT
	swingsound = list('modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_dodge_l1_transform.ogg')
	hitsound = list('modular/sounds/trickweapons/hits/cut_damage4.ogg', 'modular/sounds/trickweapons/hits/cut_damage5.ogg', 'modular/sounds/trickweapons/hits/cut_damage6.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 1.3
	clickcd = 12
	item_d_type = "slash"
	combo_id = "sc_rxfm_ret"
	combo_category = COMBO_CAT_HEAVY

// ==================== LUNGE ATTACK INTENTS (4) ====================

/// Saw Cleaver lunge — base 1H. Leaping serrated cut.
/// BB Jump: 140
/datum/intent/sawcleaver/lunge/base_cut
	name = "leaping cut"
	icon_state = "incut"
	attack_verb = list("leaping-cuts", "pounces")
	animname = "cut"
	blade_class = BCLASS_CUT
	swingsound = list('modular/sounds/trickweapons/sawcleaver/sawcleaver_base_rolling_r1.ogg', 'modular/sounds/trickweapons/sawcleaver/sawcleaver_base_quickstep_r1.ogg')
	hitsound = list('modular/sounds/trickweapons/hits/cut_damage4.ogg', 'modular/sounds/trickweapons/hits/cut_damage5.ogg', 'modular/sounds/trickweapons/hits/cut_damage6.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 1.4
	clickcd = 14
	item_d_type = "slash"
	combo_id = "sc_lng_b"
	combo_category = COMBO_CAT_HEAVY

/// Saw Cleaver lunge — base 2H. Two-handed plunging cut.
/// BB Jump: 140
/datum/intent/sawcleaver/lunge/base_grip_cut
	name = "plunging cut"
	icon_state = "incut"
	attack_verb = list("plunge-cuts", "impales")
	animname = "cut"
	blade_class = BCLASS_CUT
	swingsound = list('modular/sounds/trickweapons/sawcleaver/sawcleaver_base_rolling_r1.ogg', 'modular/sounds/trickweapons/sawcleaver/sawcleaver_base_backstep_r1.ogg')
	hitsound = list('modular/sounds/trickweapons/hits/cut_damage4.ogg', 'modular/sounds/trickweapons/hits/cut_damage5.ogg', 'modular/sounds/trickweapons/hits/cut_damage6.ogg')
	chargetime = 0
	penfactor = 25
	damfactor = 1.4
	clickcd = 14
	item_d_type = "slash"
	combo_id = "sc_lng_bg"
	combo_category = COMBO_CAT_HEAVY

/// Saw Cleaver lunge — tfm 1H. Leaping cleaver cleave.
/// BB Jump (tfm): 130
/datum/intent/sawcleaver/lunge/tfm_cleave
	name = "leaping cleave"
	icon_state = "inchop"
	attack_verb = list("leaping-cleaves", "crashes")
	animname = "chop"
	blade_class = BCLASS_CHOP
	swingsound = list('modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_rolling_r1.ogg')
	hitsound = list('modular/sounds/trickweapons/hits/cut_damage4.ogg', 'modular/sounds/trickweapons/hits/cut_damage5.ogg', 'modular/sounds/trickweapons/hits/cut_damage6.ogg')
	chargetime = 0
	penfactor = 25
	damfactor = 1.3
	clickcd = 14
	item_d_type = "slash"
	combo_id = "sc_lng_t"
	combo_category = COMBO_CAT_HEAVY

/// Saw Cleaver lunge — tfm 2H. Two-handed plunging cleave.
/// BB Jump (tfm): 130
/datum/intent/sawcleaver/lunge/tfm_grip_cleave
	name = "plunging cleave"
	icon_state = "inchop"
	attack_verb = list("plunge-cleaves", "devastates")
	animname = "chop"
	blade_class = BCLASS_CHOP
	swingsound = list('modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_rolling_r1.ogg', 'modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_running_r2_tr.ogg')
	hitsound = list('modular/sounds/trickweapons/hits/cut_damage4.ogg', 'modular/sounds/trickweapons/hits/cut_damage5.ogg', 'modular/sounds/trickweapons/hits/cut_damage6.ogg')
	chargetime = 0
	penfactor = 30
	damfactor = 1.3
	clickcd = 14
	item_d_type = "slash"
	combo_id = "sc_lng_tg"
	combo_category = COMBO_CAT_HEAVY

// ===================== WEAPON DEFINITION =====================

/obj/item/rogueweapon/trickweapon/sawcleaver
	name = "saw cleaver"
	desc = "One of the trick weapons of the Artificer's Guild, commonly issued to hunters tasked with culling deadites and werewolves beyond the walls. This saw, effective at slicing through Rot-hardened flesh, transforms into a long cleaver that makes use of centrifugal force."
	icon_state = "sawcleaver"
	serrated = TRUE
	item_state = "sawcleaver"
	force = 22
	force_wielded = 25
	// --- Base 1H intents ---
	possible_item_intents = list(\
		/datum/intent/sawcleaver/base/slash, \
		/datum/intent/sawcleaver/base/thrust, \
		/datum/intent/sawcleaver/base/strike, \
		/datum/intent/sawcleaver/base/charged)
	// --- Base 2H intents ---
	gripped_intents = list(\
		/datum/intent/sawcleaver/base/grip_slash, \
		/datum/intent/sawcleaver/base/grip_thrust, \
		/datum/intent/sawcleaver/base/grip_strike, \
		/datum/intent/sawcleaver/base/grip_charged)
	slot_flags = ITEM_SLOT_HIP | ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_BULKY
	wlength = WLENGTH_NORMAL
	wbalance = WBALANCE_NORMAL
	wdefense = 4
	wdefense_wbonus = 3
	minstr = 7
	max_blade_int = 200
	max_integrity = 200
	sharpness = IS_SHARP
	associated_skill = /datum/skill/combat/swords
	swingsound = list('modular/sounds/trickweapons/sawcleaver/sawcleaver_base_r1_1st.ogg', 'modular/sounds/trickweapons/sawcleaver/sawcleaver_base_r1_1st_alt.ogg')
	parrysound = list('sound/combat/parry/bladed/bladedmedium (1).ogg', 'sound/combat/parry/bladed/bladedmedium (2).ogg', 'sound/combat/parry/bladed/bladedmedium (3).ogg')
	pickup_sound = 'sound/foley/equip/swordlarge1.ogg'
	transform_sound = 'modular/sounds/trickweapons/sawcleaver/sawcleaver_l1_transform.ogg'
	untransform_sound = 'modular/sounds/trickweapons/sawcleaver/sawcleaver_l1_untransform.ogg'
	throwforce = 10
	thrown_bclass = BCLASS_CUT
	sellprice = 40
	grid_width = 32
	grid_height = 64
	// --- Transformed state: Cleaver ---
	transformed_name = "saw cleaver"
	transformed_desc = "The saw cleaver, now extended into its full form. The long, serrated blade cleaves through deadite flesh and werewolf bone with brutal centrifugal force."
	transformed_icon_state = "sawcleaver_t"
	transformed_item_state = "sawcleaver_t"
	transformed_force = 24
	transformed_force_wielded = 27
	// --- Transformed 1H intents ---
	transformed_intents = list(\
		/datum/intent/sawcleaver/tfm/sweep, \
		/datum/intent/sawcleaver/tfm/chop, \
		/datum/intent/sawcleaver/tfm/strike, \
		/datum/intent/sawcleaver/tfm/charged)
	// --- Transformed 2H intents ---
	transformed_gripped_intents = list(\
		/datum/intent/sawcleaver/tfm/grip_sweep, \
		/datum/intent/sawcleaver/tfm/grip_chop, \
		/datum/intent/sawcleaver/tfm/grip_strike, \
		/datum/intent/sawcleaver/tfm/grip_charged)
	transformed_swingsound = list('modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_r1_1st.ogg', 'modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_r1_1st_alt.ogg')
	transformed_wlength = WLENGTH_LONG
	transformed_wbalance = WBALANCE_HEAVY
	transformed_wdefense = 3
	transformed_wdefense_wbonus = 3
	transformed_minstr = 8
	transformed_associated_skill = /datum/skill/combat/axes
	transformed_sharpness = IS_SHARP
	transformed_w_class = WEIGHT_CLASS_BULKY
	special = /datum/special_intent/saw_cleaver_charge
	transformed_special = /datum/special_intent/saw_cleaver_rend
	// --- Transform attack intents (hold Space + LMB) ---
	transform_attack_intents = list(/datum/intent/sawcleaver/xfm/extend)
	transform_attack_gripped_intents = list(/datum/intent/sawcleaver/xfm/extend)
	untransform_attack_intents = list(/datum/intent/sawcleaver/xfm/retract)
	untransform_attack_gripped_intents = list(/datum/intent/sawcleaver/xfm/retract)
	// --- Running attack intents (auto-selected when m_intent == run) ---
	running_intent_base = /datum/intent/sawcleaver/run/base_cut
	running_intent_base_grip = /datum/intent/sawcleaver/run/base_grip_cut
	running_intent_tfm = /datum/intent/sawcleaver/run/tfm_sweep
	running_intent_tfm_grip = /datum/intent/sawcleaver/run/tfm_grip_sweep
	// --- Running transform attack intents (run + hold Space + LMB) ---
	running_transform_intent = /datum/intent/sawcleaver/runxfm/extend
	running_untransform_intent = /datum/intent/sawcleaver/runxfm/retract
	// --- Lunge attack intents (jump intent + MMB on mob) ---
	lunge_intent_base = /datum/intent/sawcleaver/lunge/base_cut
	lunge_intent_base_grip = /datum/intent/sawcleaver/lunge/base_grip_cut
	lunge_intent_tfm = /datum/intent/sawcleaver/lunge/tfm_cleave
	lunge_intent_tfm_grip = /datum/intent/sawcleaver/lunge/tfm_grip_cleave

// ===================== COMBO DEFINITIONS =====================
// Each combo is a named sequence of combo_id strings. When the combo buffer's
// tail matches a full sequence, the finisher hit gets bonus damage/speed.
//
// Saw Cleaver combos based on Bloodborne's actual combo routes:
//   - Quick Chain: Basic R1→R1→R1→R1→R1 (5-hit, the simplest)
//   - Saw Splice: R1→R2 followup (cut into thrust)
//   - Rend Opener: R1→R1→transform attack (mid-chain transform)
//   - Full Rend: R1→R1→transform attack→sweep (cross-form combo)
//   - Snap Back: Tfm sweep→untransform→cut (whipsaw)
//   - Cleaver Fury: Tfm sweep→sweep→chop (transformed escalation)
//   - Butcher's Chain: power cut→driving thrust→goring rip (2H specialty)
//   - Running Opener: dash cut→transform attack (momentum into transform)
//   - Leaping Rend: lunge→transform attack (high commitment, high reward)

/obj/item/rogueweapon/trickweapon/sawcleaver/Initialize(mapload)
	. = ..()
	// --- Base form combos ---
	// Quick Chain: full 5-hit R1 chain. Easy but rewarding for completing all 5.
	add_combo("Quick Chain", list("sc_b_slash", "sc_b_slash", "sc_b_slash", "sc_b_slash", "sc_b_slash"), 1.15, 1.0, null, 1, \
		list('modular/sounds/trickweapons/hits/damage1.ogg', 'modular/sounds/trickweapons/hits/damage2.ogg', 'modular/sounds/trickweapons/hits/damage3.ogg'))
	// Saw Splice: R1→R2. Classic R1-to-R2 followup.
	add_combo("Saw Splice", list("sc_b_slash", "sc_b_thrust"), 1.2, 0.85, \
		list('modular/sounds/trickweapons/sawcleaver/sawcleaver_base_r1-r2_followup.ogg', 'modular/sounds/trickweapons/sawcleaver/sawcleaver_base_r1-r2_followup_alt3.ogg'), 1, \
		list('modular/sounds/trickweapons/hits/damage1.ogg', 'modular/sounds/trickweapons/hits/damage2.ogg', 'modular/sounds/trickweapons/hits/damage3.ogg'))
	// Deep Splice: R1→R1→R2. Deeper chain into heavy finisher.
	add_combo("Deep Splice", list("sc_b_slash", "sc_b_slash", "sc_b_thrust"), 1.25, 0.8, \
		list('modular/sounds/trickweapons/sawcleaver/sawcleaver_base_r1-r2_followup_fwd.ogg'), 2, \
		list('modular/sounds/trickweapons/hits/finisher_kill_1.ogg', 'modular/sounds/trickweapons/hits/finisher_kill_2.ogg'))
	// Rend Opener: R1→R1→transform attack. Mid-chain transform.
	add_combo("Rend Opener", list("sc_b_slash", "sc_b_slash", "sc_xfm_ext"), 1.3, 1.0, null, 2, \
		list('modular/sounds/trickweapons/hits/finisher_kill_1.ogg', 'modular/sounds/trickweapons/hits/finisher_kill_2.ogg'))
	// Full Rend: R1→R1→transform→sweep. Cross-form combo.
	add_combo("Full Rend", list("sc_b_slash", "sc_b_slash", "sc_xfm_ext", "sc_t_sweep"), 1.35, 0.85, null, 3, \
		list('modular/sounds/trickweapons/hits/finisher_kill_1.ogg', 'modular/sounds/trickweapons/hits/finisher_kill_2.ogg'))

	// --- Transformed form combos ---
	// Cleaver Fury: 3-hit transformed R1 chain.
	add_combo("Cleaver Fury", list("sc_t_sweep", "sc_t_sweep", "sc_t_sweep"), 1.15, 1.0, null, 1, \
		list('modular/sounds/trickweapons/hits/damage1.ogg', 'modular/sounds/trickweapons/hits/damage2.ogg', 'modular/sounds/trickweapons/hits/damage3.ogg'))
	// Overhead Splice: Sweep→Chop. Transformed R1→R2.
	add_combo("Overhead Splice", list("sc_t_sweep", "sc_t_chop"), 1.2, 0.85, \
		list('modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_r1-r2_followup.ogg', 'modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_r1-r2_followup_alt2.ogg'), 1, \
		list('modular/sounds/trickweapons/hits/damage1.ogg', 'modular/sounds/trickweapons/hits/damage2.ogg', 'modular/sounds/trickweapons/hits/damage3.ogg'))
	// Deep Overhead: Sweep→Sweep→Chop. Deeper transformed chain.
	add_combo("Deep Overhead", list("sc_t_sweep", "sc_t_sweep", "sc_t_chop"), 1.25, 0.8, \
		list('modular/sounds/trickweapons/sawcleaver/sawcleaver_tfm_r1-r2_followup_fwd.ogg'), 2, \
		list('modular/sounds/trickweapons/hits/finisher_kill_1.ogg', 'modular/sounds/trickweapons/hits/finisher_kill_2.ogg'))
	// Snap Back: Sweep→untransform attack→cut. Whipsaw back to base.
	add_combo("Snap Back", list("sc_t_sweep", "sc_xfm_ret", "sc_b_slash"), 1.3, 0.85, null, 2, \
		list('modular/sounds/trickweapons/hits/finisher_kill_1.ogg', 'modular/sounds/trickweapons/hits/finisher_kill_2.ogg'))

	// --- Cross-form combos (high difficulty, high reward) ---
	// Reciprocating Rend: Full form cycle. Base→transform→sweep→back.
	add_combo("Reciprocating Rend", list("sc_b_slash", "sc_xfm_ext", "sc_t_sweep", "sc_xfm_ret", "sc_b_slash"), 1.5, 0.75, null, 4, \
		list('modular/sounds/trickweapons/hits/finisher_visceral.ogg'))

	// --- 2H combos ---
	// Butcher's Chain: Power cut→driving thrust→goring rip.
	add_combo("Butcher's Chain", list("sc_bg_slash", "sc_bg_thrust", "sc_bg_charged"), 1.3, 1.0, null, 2, \
		list('modular/sounds/trickweapons/hits/finisher_kill_1.ogg', 'modular/sounds/trickweapons/hits/finisher_kill_2.ogg'))
	// Great Cleave: Gripped transformed full chain.
	add_combo("Great Cleave", list("sc_tg_sweep", "sc_tg_sweep", "sc_tg_sweep"), 1.15, 1.0, null, 1, \
		list('modular/sounds/trickweapons/hits/damage1.ogg', 'modular/sounds/trickweapons/hits/damage2.ogg', 'modular/sounds/trickweapons/hits/damage3.ogg'))

	// --- Running / Lunge combos ---
	// Running Opener: dash cut→transform attack.
	add_combo("Running Opener", list("sc_run_b", "sc_xfm_ext"), 1.25, 1.0, null, 2, \
		list('modular/sounds/trickweapons/hits/finisher_kill_1.ogg', 'modular/sounds/trickweapons/hits/finisher_kill_2.ogg'))
	// Leaping Rend: lunge→transform attack. Highest commitment.
	add_combo("Leaping Rend", list("sc_lng_b", "sc_xfm_ext"), 1.35, 1.0, null, 3, \
		list('modular/sounds/trickweapons/hits/finisher_kill_1.ogg', 'modular/sounds/trickweapons/hits/finisher_kill_2.ogg'))

/// Mob render properties for one-handed and wielded display.
/// Branches on `transformed` to use different render profiles per form.
/obj/item/rogueweapon/trickweapon/sawcleaver/getonmobprop(tag)
	. = ..()
	if(tag)
		if(transformed)
			switch(tag)
				if("gen")
					return list("shrink" = 0.5,"sx" = -13,"sy" = -12,"nx" = 13,"ny" = -10,"wx" = -8,"wy" = -8,"ex" = 5,"ey" = -9,"northabove" = 1,"southabove" = 0,"eastabove" = 1,"westabove" = 0,"nturn" = 75,"sturn" = 92,"wturn" = 101,"eturn" = 69,"nflip" = 0,"sflip" = 1,"wflip" = 1,"eflip" = 0)
				if("wielded")
					return list("shrink" = 0.65,"sx" = 11,"sy" = -4,"nx" = -11,"ny" = -5,"wx" = 7,"wy" = -7,"ex" = 12,"ey" = -1,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 1,"nturn" = -194,"sturn" = 6,"wturn" = 26,"eturn" = -7,"nflip" = 1,"sflip" = 0,"wflip" = 0,"eflip" = 0)
		else
			switch(tag)
				if("gen")
					return list("shrink" = 0.35,"sx" = -3,"sy" = -6,"nx" = 3,"ny" = -4,"wx" = -1,"wy" = -5,"ex" = -3,"ey" = -6,"northabove" = 1,"southabove" = 0,"eastabove" = 1,"westabove" = 0,"nturn" = 95,"sturn" = -269,"wturn" = 104,"eturn" = 72,"nflip" = 0,"sflip" = 1,"wflip" = 1,"eflip" = 0)
				if("wielded")
					return list("shrink" = 0.45,"sx" = 0,"sy" = -3,"nx" = 0,"ny" = -3,"wx" = 2,"wy" = -3,"ex" = 3,"ey" = -1,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 1,"nturn" = -189,"sturn" = 12,"wturn" = 27,"eturn" = -9,"nflip" = 1,"sflip" = 0,"wflip" = 0,"eflip" = 0)
