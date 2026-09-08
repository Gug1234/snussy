# Per-Weapon Unique Payoff Catalog

> **Last updated:** Session — Full unique payoff redesign
> **Companion to:** COMBO_SYSTEM_DESIGN.md

---

## Philosophy Change: Generic → Unique

The original 18 generic payoffs (Stumble, Guard Break, Camera Jerk, etc.) are now **template mechanics only**. No weapon's combo should reference `PAYOFF_STUMBLE` directly. Instead, each weapon gets its own version — mechanically similar but themed to the weapon's identity with unique names, parameters, and sometimes additional effects layered on top.

**Implementation note:** The generic payoff *procs* (`proc/payoff_stumble()`, `proc/payoff_camera_jerk()`, etc.) remain as shared backend code. Weapon-specific defines dispatch to those procs with custom parameters. Only truly novel mechanics need new proc code.

### Per-weapon target: 10–14 unique payoffs
- ~2–4 combos per weapon stay **damage-only** (no payoff, use the stacking damage decay system)
- Remaining ~10–12 combos each get a **unique payoff** from that weapon's palette
- Payoffs are tiered 1–5 to match combo difficulty guidelines

### Tier Guide
| Tier | Combo Difficulty | Effect Power | CD Range |
|---|---|---|---|
| 1 | Easy (diff 1–2) | Minor disruption, psychological | 10–15s |
| 2 | Medium-Easy (diff 2) | Moderate control or damage amp | 15–20s |
| 3 | Medium-Hard (diff 3) | Strong weapon-identity effect | 20–25s |
| 4 | Expert (diff 4) | Powerful unique mechanic | 25–35s |
| 5 | Legendary (diff 5) | One-of-a-kind, fight-defining | 60–120s |

---

## 1. Saw Cleaver — Serrated Aggression

**Identity:** The workhorse hunter's weapon. Fast horizontal alternating slashes (normal), narrow vertical cuts for tight work (transformed). Serrated in transformed form. Street-level butcher tool — practical, bloody, relentless.

**BB Reference:** Normal R1 1.00x–1.09x alternating horizontal. Transformed R1 0.97x–1.02x vertical up/down. Charged normal 1.90x overhead. Transformed R2 1.25x wide sweep for crowd control.

| # | Payoff Name | Define | Effect | Tier | CD |
|---|---|---|---|---|---|
| 1 | Serrated Rip | `PAYOFF_SERRATED_RIP` | +30% wound severity on beast/anthromorph targets. Stacks with serrated system. | 3 | 20s |
| 2 | Saw Lock | `PAYOFF_SAW_LOCK` | Next R1 chain drains 10% of target's *current* blood per connecting, penetrating hit. If blocked by armor → drains armor integrity instead. If dodged/parried → drains stamina instead. | 4 | 25s |
| 3 | Hacksaw | `PAYOFF_SC_HACKSAW` | Struck armor piece loses 15% of its current integrity. Represents sawing through protection. | 2 | 20s |
| 4 | Meat Hook | `PAYOFF_SC_MEAT_HOOK` | Pull target 1 tile toward attacker (via `throw_at`) + brief OffBalance (6ds). The aggressive closer. | 2 | 15s |
| 5 | Butcher's Tempo | `PAYOFF_SC_BUTCHERS_TEMPO` | Next 3 attacks have 30% reduced clickCD. Rewarding aggressive follow-up after a successful combo. | 3 | 20s |
| 6 | Street Sweep | `PAYOFF_SC_STREET_SWEEP` | 3×1 arc damage on finisher. Wide horizontal cleaver sweep hits target + both adjacent tiles. | 3 | 20s |
| 7 | Tendon Cut | `PAYOFF_SC_TENDON_CUT` | Stumbling walk for 3 seconds, target cannot sprint. Serrated teeth catch in the back of the leg. | 1 | 12s |
| 8 | Flay | `PAYOFF_SC_FLAY` | Reduce target's peel threshold on hit zone by 1. Serrated edge peels armor layer by layer. | 4 | 30s |
| 9 | Jaw Breaker | `PAYOFF_SC_JAW_BREAKER` | Force target's eyes closed (flinch). Must click eye HUD to reopen. Concussive cleaver pommel strike. | 1 | 15s |
| 10 | Crimson Splatter | `PAYOFF_SC_CRIMSON_SPLATTER` | Blood splash on finisher: all mobs within 1 tile of target take minor brute damage (0.3× finisher). | 2 | 15s |
| 11 | Bind and Tear | `PAYOFF_SC_BIND_TEAR` | Target's weapon clickCD +25% for 5 seconds. Saw blade catches their weapon and jams the motion. | 2 | 20s |
| 12 | Panic Response | `PAYOFF_SC_PANIC_RESPONSE` | Counter-tempo: if attacker takes a hit within 2 seconds, next attack deals 1.4× damage. Desperate butcher's instinct. | 3 | 15s |

---

## 2. Saw Spear — Serrated Reach

**Identity:** Sister to Saw Cleaver but transforms sword → polearm (reach=2). Serrated in BOTH forms (unique among trick weapons). Normal is alternating slashes. Transformed has thrusting reach advantage with serrated edge. Combines bleed with spacing.

**BB Reference:** Normal R1 1.00x–1.09x alternating slashes. Transformed R1 1.09x–1.11x with thrust, reach advantage. Charged transformed 1.73x. Emphasizes reach in transformed form.

| # | Payoff Name | Define | Effect | Tier | CD |
|---|---|---|---|---|---|
| 1 | Skewering Thrust | `PAYOFF_SS_SKEWER` | Charged thrust pins target: 1s immobilize. All mobs in 1×3 line behind target take 50% finisher damage (overpen). The spear goes through. | 4 | 25s |
| 2 | Serrated Drag | `PAYOFF_SS_SERRATED_DRAG` | Pull target 1 tile via `throw_at` + apply serrated bleed tick during the drag. Barbed edge tears on the way in. | 3 | 20s |
| 3 | Impaling Lunge | `PAYOFF_SS_IMPALING_LUNGE` | Running attack payoff: bonus +30% damage from momentum. The spear is built for charging. | 3 | 20s |
| 4 | Barbed Catch | `PAYOFF_SS_BARBED_CATCH` | Target's passive dodge chance reduced 30% for 3 seconds. Serrated barbs lodged in flesh restrict movement. | 3 | 20s |
| 5 | Polearm Sweep | `PAYOFF_SS_POLEARM_SWEEP` | 3×1 arc damage in transformed form. Long polearm reaches adjacent tiles easily. | 2 | 15s |
| 6 | Puncture Wound | `PAYOFF_SS_PUNCTURE` | Precision thrust to hit zone. If wound already exists on that zone, severity +1. Aggravates existing damage. | 3 | 20s |
| 7 | Raking Cut | `PAYOFF_SS_RAKING_CUT` | Stumbling walk for 2 seconds. Serrated teeth catch and drag against flesh on withdrawal. | 1 | 12s |
| 8 | Spear Wall | `PAYOFF_SS_SPEAR_WALL` | Knockback target 2 tiles. Polearm thrust creates distance. Wall collision = brief knockdown. | 2 | 15s |
| 9 | Double Serration | `PAYOFF_SS_DOUBLE_SERRATION` | Both forms' serrated multiplier boosted +50% for next 3 hits. Saw Spear's unique dual-form serration weaponized. | 2 | 20s |
| 10 | Hamstring | `PAYOFF_SS_HAMSTRING` | Target's movement speed reduced 40% for 4 seconds. Spear tip slashes the back of the knee. | 2 | 15s |
| 11 | Reach Advantage | `PAYOFF_SS_REACH_ADV` | For 3 seconds, any target that moves within 1 tile of attacker takes an automatic free poke (0.5× damage). Zone denial. | 4 | 30s |
| 12 | Counter-Thrust | `PAYOFF_SS_COUNTER_THRUST` | If attacker is hit within 2 seconds, auto-riposte thrust at 1.3× damage. Spear pointed and ready. | 3 | 20s |

---

## 3. Hunter Axe — Aggressive Hooking

**Identity:** Slow but devastating. Normal has overhead slams and hook attacks. Transformed has long-reach 360° spin attacks and sweeping combos. The weapon of the aggressive hunter who controls space by threatening it. Rally weapon in BB — we replace rally with a similar "aggressive recovery" payoff.

**BB Reference:** Normal R2 1.35x overhead. Charged 2.00x, 75 stamina. Transformed R1 5-hit combo. Transformed Charged 1.30x 360° spin arc. L2 1.25x–1.35x three-hit wide arc combo.

| # | Payoff Name | Define | Effect | Tier | CD |
|---|---|---|---|---|---|
| 1 | Tempo Surge | `PAYOFF_TEMPO_SURGE` | Reduced clickCD by 30% on next 2 attacks. Rewards aggressive follow-up after landing the combo. | 2 | 20s |
| 2 | Leg Hook | `PAYOFF_LEG_HOOK` | Hook the back of target's leg with axe head. Pull 1 tile via `throw_at` + trip (OffBalance 8ds). | 3 | 25s |
| 3 | Cleave Through | `PAYOFF_CLEAVE_THROUGH` | Finisher cleaves in a 3×1 arc. Hits target + both adjacent tiles. One big swing, multiple victims. | 3 | 25s |
| 4 | Spinning Cleave | `PAYOFF_SPINNING_CLEAVE` | 360° spin AoE: all adjacent tiles (3×3 centered on attacker) take finisher damage. The iconic axe spin. | 4 | 30s |
| 5 | Head Splitter | `PAYOFF_HA_HEAD_SPLITTER` | Force zone to head. Next hit ignores helmet armor class. The overhead slam purpose-built to crack skulls. | 4 | 30s |
| 6 | Axe Pommel | `PAYOFF_HA_AXE_POMMEL` | Flinch: force eyes closed. Pommel butt strike to the jaw. | 1 | 12s |
| 7 | Rally Cry | `PAYOFF_HA_RALLY_CRY` | Attacker recovers 15 HP if finisher connects. The axe's BB rally identity expressed as combo reward. | 3 | 25s |
| 8 | Shield Breaker | `PAYOFF_HA_SHIELD_BREAKER` | If target is wielding a shield: force un-block + OffBalance 8ds. The axe hooks over and past the shield. | 3 | 20s |
| 9 | Ground Pound | `PAYOFF_HA_GROUND_POUND` | Overhead slam: camera jerk to target + all mobs within 1 tile. The earth shakes. | 2 | 15s |
| 10 | Execution Swing | `PAYOFF_HA_EXECUTION` | Execute mechanic: +40% bonus damage when target at ≤25% HP. The finishing blow. | 3 | 20s |
| 11 | Iron Will | `PAYOFF_HA_IRON_WILL` | On finisher, attacker gains 20% damage reduction for 3 seconds. Aggressive confidence. | 2 | 20s |
| 12 | Crowd Clear | `PAYOFF_HA_CROWD_CLEAR` | AoE pushback: all mobs within 1 tile of attacker pushed 2 tiles away. Creates space. | 3 | 20s |

---

## 4. Threaded Cane — Range and Elegance

**Identity:** Gentleman's weapon. Normal is precise cane thrusts and strikes. Transformed is whip with wide arcs and crowd control. Wall recoil is characteristic. NO charged attack in whip form. The weapon of refinement that punishes from range.

**BB Reference:** Normal R1 horizontal slashes, R2 thrust 1.35x. Transformed R1 wide whip arcs 0.95x–1.00x. NO charged in whip. Whip has range but recoils near walls. Cane is precise, whip is sweeping.

| # | Payoff Name | Define | Effect | Tier | CD |
|---|---|---|---|---|---|
| 1 | Lash Bind | `PAYOFF_LASH_BIND` | Heavy slowdown via `add_movespeed_modifier` for 5s + pull target 1 tile via `throw_at`. Whip wraps ankle and drags. | 3 | 20s |
| 2 | Crack the Whip | `PAYOFF_CRACK_WHIP` | 3×1 arc: whip sweeps through target + both adjacent tiles. Crowd-control from range. | 2 | 15s |
| 3 | Precise Thrust | `PAYOFF_TC_PRECISE_THRUST` | Cane mode: BCLASS_PICK-like precision to target zone with +50% pen factor. The refined gentleman's strike. | 4 | 25s |
| 4 | Gentleman's Rebuke | `PAYOFF_TC_REBUKE` | Counter-tempo: if attacker takes hit within 2s, riposte at 1.3× + camera jerk on target. An insulting counter. | 3 | 20s |
| 5 | Cane Pommel | `PAYOFF_TC_CANE_POMMEL` | Target's clickCD +30% for 5s. Pommel strike to the wrist numbs the hand. | 2 | 15s |
| 6 | Entangle | `PAYOFF_TC_ENTANGLE` | Whip wraps target: immobilize for 1.5 seconds. Bound and helpless. | 3 | 25s |
| 7 | Flaying Lash | `PAYOFF_TC_FLAYING_LASH` | Whip reduces peel threshold on hit zone by 1. Strips armor from range — a luxury no other weapon has. | 4 | 30s |
| 8 | Trip Wire | `PAYOFF_TC_TRIP_WIRE` | Stumbling walk for 3s. Whip crack to the ankles. Can't sprint. | 1 | 12s |
| 9 | Whip Snap | `PAYOFF_TC_WHIP_SNAP` | Frighten: mood debuff. The sharp crack of the whip startles and intimidates. | 1 | 10s |
| 10 | Serpentine Strike | `PAYOFF_TC_SERPENTINE` | Whip curves around guard: this hit bypasses the target's parry check entirely. Cannot be parried. | 4 | 30s |
| 11 | Disarming Lash | `PAYOFF_TC_DISARM_LASH` | Whip yanks target's weapon: modified disarm attempt via `/datum/intent/sword/disarm`. | 3 | 25s |
| 12 | Reach Denial | `PAYOFF_TC_REACH_DENIAL` | Knockback target 2 tiles. Whip cracks them backwards, resets spacing in attacker's favor. | 2 | 15s |

---

## 5. Kirkhammer — Overwhelming Force

**Identity:** Elegant one-handed sword (normal, low motion values 0.70x base) versus devastating two-handed hammer (transformed, Charged 3.10x). Backstep hammer is a push/shove. The weapon embodies two extremes: finesse and annihilation.

**BB Reference:** Normal is a 5-hit sword combo at 0.70x–0.76x. Transformed hammer: Charged 3.10x "brought violently into ground." Backstep R1 is a push/shove. Transformed R2 1.25x "wide horizontal sweep."

| # | Payoff Name | Define | Effect | Tier | CD |
|---|---|---|---|---|---|
| 1 | Seismic Impact | `PAYOFF_SEISMIC_IMPACT` | Ground slam AoE: 3×2 area in front. Short OffBalance (10ds) to all. Mobs in 3×1 closest tiles also take damage. | 4 | 25s |
| 2 | Shove | `PAYOFF_KH_SHOVE` | If target adjacent to wall/structure: bonus 1.5× damage + push INTO wall via `throw_at`, triggering knockdown. | 3 | 30s |
| 3 | Skull Ring | `PAYOFF_KH_SKULL_RING` | Daze: reversed WASD movement for 3s. Hammer impact to the head rattles the brain. | 3 | 20s |
| 4 | Stone Breaker | `PAYOFF_KH_STONE_BREAKER` | Struck armor piece loses 25% of current integrity. The hammer doesn't care what you're wearing. | 3 | 20s |
| 5 | Sword Finesse | `PAYOFF_KH_SWORD_FINESSE` | Sword mode: next 2 attacks get advantage on hit dice rolls. The refined blade finds openings. | 3 | 25s |
| 6 | Hammer Down | `PAYOFF_KH_HAMMER_DOWN` | Knockback 2 tiles. Wall collision = OffBalance 10ds. Pure displacement force. | 2 | 20s |
| 7 | Quake Stomp | `PAYOFF_KH_QUAKE_STOMP` | Camera jerk AoE: all mobs within 2 tiles get viewport snap. The ground shakes. | 1 | 10s |
| 8 | Concussion | `PAYOFF_KH_CONCUSSION` | Tunnel vision: reduced view range + disabled chat for 5s. Blunt force trauma. | 3 | 20s |
| 9 | Plate Crusher | `PAYOFF_KH_PLATE_CRUSHER` | Guard break: target's armor class negated for the NEXT incoming hit (or 3s). | 3 | 20s |
| 10 | Pommel Bash | `PAYOFF_KH_POMMEL_BASH` | Flinch: force eyes closed. Sword pommel to the face. | 1 | 12s |
| 11 | Demolition | `PAYOFF_KH_DEMOLITION` | Charged hammer: double damage to structures/doors/barricades within AoE. Siege weapon. | 2 | 25s |
| 12 | Pendulum Swing | `PAYOFF_KH_PENDULUM` | Transform attack: momentum from sword→hammer adds +50% damage. The weight of transformation. | 2 | 20s |

---

## 6. Ludwig's Holy Blade — Cascading Steel

**Identity:** Elegant rapier-like sword (normal, 5-hit combo, low motion values 0.70x–0.76x) to massive greatsword (transformed, devastating slams). L2 is a 4-hit diagonal combo. `is_silver=TRUE` for undead bonus. The holy weapon of a noble hunter.

**BB Reference:** Normal R1 0.70x–0.76x 5-hit. Transformed Charged 2.20x. L2 4-hit diagonal combo 1.15x each. Transformed R2 1.25x. The sword mode is weak individually but combos quickly; greatsword is commitment and devastation.

| # | Payoff Name | Define | Effect | Tier | CD |
|---|---|---|---|---|---|
| 1 | Descending Cleave | `PAYOFF_DESCENDING_CLEAVE` | Multi-zone finisher: hits head → chest → groin in sequence. Each hit rolls separately. Devastating if all land. | 4 | 25s |
| 2 | Holy Shockwave | `PAYOFF_HOLY_SHOCKWAVE` | Greatsword slam AoE: 3×2 area. All targets take brute + brief OffBalance (6ds). `is_silver` bonus applies to undead. | 4 | 30s |
| 3 | Silver Judgement | `PAYOFF_LHB_SILVER_JUDGE` | Bonus +25% damage vs undead. Stacks with existing `is_silver`. The blade's holy purpose. | 2 | 15s |
| 4 | Sword Dance | `PAYOFF_LHB_SWORD_DANCE` | Each successive hit in a completed 5-hit R1 chain gains +10% damfactor. Fifth hit at +40%. Rewards commitment. | 3 | 20s |
| 5 | Cleansing Sweep | `PAYOFF_LHB_CLEANSING_SWEEP` | 3×1 arc: greatsword wide sweep hits target + adjacent tiles. | 3 | 20s |
| 6 | Weight of Justice | `PAYOFF_LHB_WEIGHT` | Target's movement speed halved for 3s. Greatsword impact pins them to the ground. | 2 | 15s |
| 7 | Holy Guard | `PAYOFF_LHB_HOLY_GUARD` | Attacker gains 25% damage reduction for 3s. Greatsword defensive posture radiates protection. | 2 | 20s |
| 8 | Disembowel | `PAYOFF_LHB_DISEMBOWEL` | Sword precision: forced zone to chest, wound severity +1. The rapier finds the gap. | 3 | 25s |
| 9 | Greatsword Slam | `PAYOFF_LHB_GS_SLAM` | Knockback 2 tiles + OffBalance 8ds. Sheer mass displacement. | 2 | 20s |
| 10 | Blinding Light | `PAYOFF_LHB_BLINDING` | Flinch: force eyes closed. Silver blade flashes in the light. | 1 | 12s |
| 11 | Momentum Shift | `PAYOFF_LHB_MOMENTUM` | Transform attack payoff: next 2 attacks get +40% damage. The transformation itself is a weapon. | 2 | 20s |
| 12 | Final Judgement | `PAYOFF_LHB_FINAL_JUDGE` | Execute: +60% bonus damage when target at ≤20% HP. The greatsword's verdict. | 4 | 30s |

---

## 7. Stake Driver — Explosive Commitment

**Identity:** Punches and slashes (normal) to rapid jabs (transformed). THE signature move: Charged 3.55x with an EXPLOSION. Short range, enormous risk/reward. Glass cannon — get close, commit, detonate.

**BB Reference:** Normal is punches/slashes. Transformed is rapid jabs. Charged transformed 3.55x "accompanied by an explosion" — the highest single-hit multiplier in Bloodborne. The weapon for lunatics who like to live dangerously.

| # | Payoff Name | Define | Effect | Tier | CD |
|---|---|---|---|---|---|
| 1 | Pile Bunker | `PAYOFF_PILE_BUNKER` | Next transformation attack has 2× damage. The combo IS the setup for the nuke. | 4 | 45s |
| 2 | Blast Punt | `PAYOFF_BLAST_PUNT` | Knockback 2 tiles + apply 1 fire stack via `adjust_fire_stacks()`. Explosive displacement. | 2 | 25s |
| 3 | Concussive Blast | `PAYOFF_SD_CONCUSSIVE` | Charged explosion AoE: 3×3 centered on target. Everyone in range (including attacker!) takes OffBalance 10ds. Commitment. | 4 | 30s |
| 4 | Piston Jab | `PAYOFF_SD_PISTON_JAB` | ClickCD eliminated for next hit — instant second attack. The driver recoils and fires again. | 3 | 20s |
| 5 | Shrapnel | `PAYOFF_SD_SHRAPNEL` | All mobs within 2 tiles of target take minor brute (0.25× finisher). Explosion sends debris. | 2 | 20s |
| 6 | Sucker Punch | `PAYOFF_SD_SUCKER_PUNCH` | Camera jerk + force eyes closed. The cheap shot you never see coming. | 2 | 15s |
| 7 | Gut Punch | `PAYOFF_SD_GUT_PUNCH` | Stumbling walk for 2s. Body blow doubles them over. | 1 | 12s |
| 8 | Fuse Arm | `PAYOFF_SD_FUSE_ARM` | Next charged attack has 20% reduced charge time. Priming the mechanism. | 3 | 25s |
| 9 | Flash Burn | `PAYOFF_SD_FLASH_BURN` | Explosion flash: target's screen white for 1s (flashbang effect via TRAIT_NOCSHADES bypass). | 3 | 25s |
| 10 | Point Blank Detonation | `PAYOFF_SD_POINT_BLANK` | Must be adjacent. +80% finisher damage but attacker takes 20% of the damage as self-harm. Maximum commitment. | 4 | 30s |
| 11 | Rattled | `PAYOFF_SD_RATTLED` | Target's hit dice get disadvantage for 5s. Concussive force scrambles aim. | 2 | 15s |
| 12 | Staggering Blow | `PAYOFF_SD_STAGGER` | OffBalance 8ds from explosive impact. Simple but effective. | 1 | 12s |

---

## 8. Rifle Spear — Impale and Fire

**Identity:** Thrust-focused spear (normal) to halberd with integrated gunfire (transformed). Dual-purpose — poke then shoot. The weapon of the methodical hunter who pins prey and finishes from range.

**BB Reference:** Normal R1 alternating thrusts. Transformed adds halberd slashes + gun fire. Charged transformed 2.47x lunging thrust. Transform attack fires the gun at zero stamina cost.

| # | Payoff Name | Define | Effect | Tier | CD |
|---|---|---|---|---|---|
| 1 | Impale & Fire | `PAYOFF_IMPALE_FIRE` | Pin (1s immobilize) then auto-fire overpen 1×3 line. Primary: full, behind: 60%, furthest: 30%. | 4 | 25s |
| 2 | Bayonet Twist | `PAYOFF_BAYONET_TWIST` | Twist spear in wound: all wounds on hit bodypart gain +1 severity for 15s. Aggravates damage. | 3 | 20s |
| 3 | Gunshot Flinch | `PAYOFF_RS_GUN_FLINCH` | Gun fires: force eyes closed (flinch) from muzzle flash. | 1 | 12s |
| 4 | Penetrating Thrust | `PAYOFF_RS_PEN_THRUST` | This hit ignores armor class entirely. The spear punches clean through. | 4 | 30s |
| 5 | Sweeping Halberd | `PAYOFF_RS_HALBERD_SWEEP` | 3×1 arc in transformed mode. Halberd reach clears a line. | 2 | 15s |
| 6 | Anchoring Stab | `PAYOFF_RS_ANCHOR` | Target pinned for 1.5s — cannot move. Spear through the foot. | 3 | 25s |
| 7 | Suppressing Fire | `PAYOFF_RS_SUPPRESS` | Auto-fire at target: movement speed -30% for 3s. Forced to duck and weave. | 2 | 15s |
| 8 | Cross-Form Volley | `PAYOFF_RS_CROSS_VOLLEY` | Spear thrust then seamless gun discharge = two separate damage rolls on one combo finish. | 3 | 20s |
| 9 | Disabling Shot | `PAYOFF_RS_DISABLE_SHOT` | Gun fires at weapon hand: target's clickCD +30% for 5s. Hand numb from impact. | 3 | 20s |
| 10 | Spear Wall | `PAYOFF_RS_SPEAR_WALL` | Knockback 2 tiles from lunging thrust. Creates comfortable spear range. | 2 | 15s |
| 11 | Barrage | `PAYOFF_RS_BARRAGE` | Next 2 gun-accompanied attacks fire bonus shots for free (no ammo cost). Rapid fire window. | 3 | 25s |
| 12 | Execution Thrust | `PAYOFF_RS_EXECUTION` | Execute: +40% bonus damage when target at ≤30% HP. Pin and finish. | 3 | 20s |

---

## 9. Reiterpallasch — Rapier Precision

**Identity:** Rapier thrusts (normal). Transform fires pistol seamlessly. Zero stamina transform attack. The gentleman duelist's weapon — precision, economy, and a hidden gun. Every attack is efficient; nothing is wasted.

**BB Reference:** Normal R1 alternating thrusts. R2 1.25x. Backstep R1 1.50x high. Transform attack fires gun at 0 stamina. Transformed is shorter blade with gun integration. The weapon of the skilled duelist.

| # | Payoff Name | Define | Effect | Tier | CD |
|---|---|---|---|---|---|
| 1 | Wrist Stab | `PAYOFF_WRIST_STAB` | BCLASS_PICK forced to target's weapon hand, penfactor 90. Surgical strike to disarm potential. | 4 | 30s |
| 2 | Point Blank | `PAYOFF_POINT_BLANK` | Finisher seamlessly fires bonus pistol shot at melee range. Free attack, costs 1 ammo. | 2 | 20s |
| 3 | Riposte | `PAYOFF_RP_RIPOSTE` | If target's attack is dodged/parried within 2s of finisher, auto-thrust at 1.5× damage. The fencer's counter. | 4 | 25s |
| 4 | Duelist's Flourish | `PAYOFF_RP_FLOURISH` | After finisher, +30% passive dodge for 3s. Hard to pin down after a combo. | 3 | 20s |
| 5 | Arteria Strike | `PAYOFF_RP_ARTERIA` | Precision stab forced to neck zone. Bleed wound guaranteed on penetration. | 4 | 30s |
| 6 | Disarming Parry | `PAYOFF_RP_DISARM_PARRY` | Modified disarm attempt + OffBalance 6ds. Rapier work pries the weapon loose. | 3 | 25s |
| 7 | Pistol Whip | `PAYOFF_RP_PISTOL_WHIP` | Force eyes closed from gunstock impact. Blunt and ignoble. | 1 | 12s |
| 8 | Puncture Series | `PAYOFF_RP_PUNCTURE_SERIES` | Next 3 thrusts gain +20% pen factor. A focused offensive pushing through defense. | 2 | 15s |
| 9 | Fencing Footwork | `PAYOFF_RP_FOOTWORK` | Stumbling walk 3s from rapier-work to the legs. Disrupts their stance. | 1 | 12s |
| 10 | Vital Precision | `PAYOFF_RP_VITAL_PREC` | Force zone to head + advantage on hit dice. Finding the kill shot. | 3 | 20s |
| 11 | Suppressive Discharge | `PAYOFF_RP_SUPPRESS` | Gun fires: camera jerk + flinch. Blinding muzzle flash at close range. | 2 | 15s |
| 12 | En Garde | `PAYOFF_RP_EN_GARDE` | False opening bait: if target attacks within 2s, auto-dodge + riposte at 1.3×. The duelist's trap. | 3 | 25s |

---

## 10. Tonitrus — Voltaic Brutality

**Identity:** Simple mace (normal). Transformed doesn't change moveset — just increases bolt damage on all attacks. A buff-stick. Our version leans into the "charge up" concept: the mace builds electrical energy through combos that discharges in shocking ways.

**DESIGN NOTE:** BURN damage is extremely painful in-game and can end fights. Tonitrus payoffs use STAMINA damage for "electrical" effects instead of BURN, with BURN reserved for only the highest-tier payoffs at low values. The shock is neuromuscular disruption, not tissue damage.

**BB Reference:** Normal R1 1.00x–1.08x 5-hit combo. R2 1.20x. Charged 1.90x. Transformed is IDENTICAL moveset with bolt buff. The simplest weapon mechanically.

| # | Payoff Name | Define | Effect | Tier | CD |
|---|---|---|---|---|---|
| 1 | Static Discharge | `PAYOFF_TON_STATIC` | Camera jerk + brief screen flash. Electrical snap on finisher. | 1 | 12s |
| 2 | Galvanic Shock | `PAYOFF_TON_GALVANIC` | Reversed left/right movement for 3s. Electrical interference with motor control. | 3 | 20s |
| 3 | Lightning Rod | `PAYOFF_TON_LIGHTNING_ROD` | If target wears metal armor: +30% finisher damage. Electricity finds the conductor. | 3 | 20s |
| 4 | Nerve Overload | `PAYOFF_TON_NERVE_OVERLOAD` | Target cannot sprint for 4s. Neuromuscular disruption. | 2 | 15s |
| 5 | Arc Flash | `PAYOFF_TON_ARC_FLASH` | Flinch: force eyes closed from electrical arc flash. | 1 | 12s |
| 6 | Charged Slam | `PAYOFF_TON_CHARGED_SLAM` | Ground slam AoE: 3×2 area. All targets take 30 stamina damage via `stamina_add()`. Electrical grounding. | 3 | 25s |
| 7 | Conducted Strike | `PAYOFF_TON_CONDUCTED` | If target is wet (rain, water tile): damage ×1.5. Conductivity bonus. | 2 | 15s |
| 8 | Voltage Spike | `PAYOFF_TON_VOLTAGE_SPIKE` | Target's weapon clickCD +30% for 5s. Hand spasms from electrical discharge. | 2 | 20s |
| 9 | EMP Pulse | `PAYOFF_TON_EMP` | Guard break: target's armor gives 0 protection for next hit. Electrical bypass. | 3 | 20s |
| 10 | Stun Lock | `PAYOFF_TON_STUN_LOCK` | Brief immobilize (1 second) from full-body electrical seizure. | 4 | 30s |
| 11 | Chain Lightning | `PAYOFF_TON_CHAIN` | Finisher also zaps 1 additional mob within 2 tiles of target at 40% damage. Arcs between conductors. | 3 | 25s |
| 12 | Overcharge | `PAYOFF_TON_OVERCHARGE` | Self-buff: next 3 attacks deal +10 stamina damage on each hit. The mace crackles with stored energy. | 2 | 20s |

---

## 11. Beast Cutter — Rending Range ★ PRIORITY

**Identity:** Short serrated club (normal) to long serrated whip (transformed). Normal has heavy overhead smashes and thrusting jabs. Transformed has slow but MASSIVE reach horizontal sweeps. The chain mechanism extends and contracts. Serrated in both forms. THE weapon for controlling space with brutality.

**User's favorite weapon. Gets 14 unique payoffs — every combo slot filled.**

**BB Reference:** Normal R1 starts with downward slash, varies through backhand sweeps and uppercuts, 5-hit combo. Charged normal 1.90x overhead. Transformed R1 0.95x–1.00x slow horizontal sweeps alternating direction. Transformed R2 1.30x + 1.50x chain disengage slam combo. Transform attack to whip 1.40x overhead slam; transform back 1.50x ground slam.

| # | Payoff Name | Define | Effect | Tier | CD |
|---|---|---|---|---|---|
| 1 | Rending Pull | `PAYOFF_BC_RENDING_PULL` | Whip catches target, drags 1 tile toward attacker via `throw_at` + serrated bleed tick on the drag. Barbed chain tears. | 3 | 20s |
| 2 | Serrated Snare | `PAYOFF_BC_SERRATED_SNARE` | % blood drain: 5% of target's current `blood_volume` per tick + 20% movement slow. Lasts 10 seconds. Serrated chain wrapped tight. | 4 | 25s |
| 3 | Chain Lash | `PAYOFF_BC_CHAIN_LASH` | 3×1 arc damage. Massive reach sweep — the chain extends to its full terrifying length. | 2 | 15s |
| 4 | Bone Crusher | `PAYOFF_BC_BONE_CRUSHER` | Club mode: struck armor piece loses 20% of current integrity. Serrated mace head chews metal. | 3 | 20s |
| 5 | Flensing Strike | `PAYOFF_BC_FLENSING` | Reduce peel threshold on hit zone by 1. Whip strips armor layer by layer from a distance. | 4 | 30s |
| 6 | Cracking Whip | `PAYOFF_BC_CRACK` | Frighten: mood debuff. The terrifying crack of the Beast Cutter's chain-whip echoes. | 1 | 10s |
| 7 | Anchored In | `PAYOFF_BC_ANCHORED` | Whip wraps target: immobilize 1.5s + attacker is pulled 1 tile closer (mutual engagement). Both committed. | 3 | 25s |
| 8 | Mauling Overhead | `PAYOFF_BC_MAULING` | Club mode overhead: OffBalance 10ds + camera jerk. The simple brutality of a heavy serrated club to the skull. | 2 | 15s |
| 9 | Tenderize | `PAYOFF_BC_TENDERIZE` | Next 3 hits against this target deal +15% damage. The flesh is softened, the armor dented. Target is marked. | 2 | 15s |
| 10 | Chain Trip | `PAYOFF_BC_CHAIN_TRIP` | Whip to ankles: stumbling walk 4s + cannot sprint. The chain wraps the legs. | 2 | 12s |
| 11 | Disemboweling Drag | `PAYOFF_BC_DISEMBOWEL` | Whip hooks into body: on pull, wound severity +1 on hit zone. The serrated chain tears on withdrawal. | 4 | 30s |
| 12 | Beast Breaker | `PAYOFF_BC_BEAST_BREAKER` | +30% wound severity on beast/anthromorph targets. Stacks with serrated system. This is what the weapon was made for. | 3 | 20s |
| 13 | Ground Slam | `PAYOFF_BC_GROUND_SLAM` | Club smashes ground: AoE 3×2 stagger. All mobs in front get OffBalance 8ds. | 3 | 25s |
| 14 | Punishing Reach | `PAYOFF_BC_PUNISHING_REACH` | Counter: if target moves away from attacker within 3s, free whip strike at 1.3× damage. You can't run from the Beast Cutter. | 3 | 20s |

---

## 12. Amygdalan Arm — Cosmic Horror

**Identity:** Grotesque club made from an Amygdala's arm (normal, ground slams) to extended tentacle-arm (transformed, the appendage independently rotates and strikes). The tentacle acts on its own — twisting, grasping, lashing. Deeply unsettling.

**BB Reference:** Normal R1 four ground slams, scaling 1.00x–1.20x. Normal charged 1.80x + 1.80x follow-up slam. Transformed R1 varied combo with horizontal sweeps. Transformed R2 1.20x+80 — appendage rotates and slashes back independently. Transformed charged 1.70x+80+85 ground slam with appendage slash. Transform attack 1.50x spinning slam.

| # | Payoff Name | Define | Effect | Tier | CD |
|---|---|---|---|---|---|
| 1 | Eldritch Grip | `PAYOFF_AA_ELDRITCH_GRIP` | Tentacle wraps target: immobilize 1.5s — BUT attacker is also locked (can't act). Mutual commitment, favors the ambusher. | 3 | 25s |
| 2 | Appendage Lash | `PAYOFF_AA_APPENDAGE` | Tentacle extends: free bonus hit at range 2 from the appendage acting independently. 0.6× damage. The arm has a mind of its own. | 3 | 20s |
| 3 | Cosmic Dread | `PAYOFF_AA_COSMIC_DREAD` | Mood debuff + tunnel vision (reduced view range) for 5s. Seeing the arm's true nature overwhelms. | 4 | 30s |
| 4 | Limb Crush | `PAYOFF_AA_LIMB_CRUSH` | Club slam: joint lock effect. Disables target's arm (can't use items in that hand) for 3s. | 3 | 25s |
| 5 | Tentacle Flail | `PAYOFF_AA_TENTACLE_FLAIL` | 360° AoE: all adjacent mobs take 0.5× finisher damage from flailing tentacle. It thrashes wildly. | 3 | 25s |
| 6 | Parasite Grasp | `PAYOFF_AA_PARASITE_GRASP` | Tentacle grabs target's weapon hand: force swap hands. Weird alien strength in the wrong direction. | 2 | 15s |
| 7 | Ground Pound | `PAYOFF_AA_GROUND_POUND` | Normal overhead slam: knockback 1 tile + camera jerk. Simple club brutality. | 2 | 15s |
| 8 | Unsettling Twitch | `PAYOFF_AA_TWITCH` | Daze: reversed WASD for 3s. The wrongness of the arm's alien movement gets under the skin. | 3 | 20s |
| 9 | Visceral Horror | `PAYOFF_AA_VISCERAL_HORROR` | Flinch: force eyes closed. The sight of the tentacle unfurling makes you look away. | 1 | 12s |
| 10 | Crushing Weight | `PAYOFF_AA_CRUSHING` | Target's movement speed halved for 4s from sheer mass of impact. | 2 | 15s |
| 11 | Reaching Strike | `PAYOFF_AA_REACHING` | Transformed finisher gains range 2. The tentacle extends farther than expected. | 2 | 15s |
| 12 | Aberrant Slam | `PAYOFF_AA_ABERRANT` | Transform attack: spinning slam AoE 3×2 + OffBalance (10ds) to all in range. The arm whirls grotesquely. | 4 | 30s |

---

## 13. Boom Hammer — Ignition Burst

**Identity:** Simple hammer. Transform = single fire-enhanced hit, then reverts to unignited. One-shot ignition per transform. The brute simplicity: crush them, then burn them. No lingering fire, no sustained flames — one explosive moment.

**BB Reference:** Normal R1 1.00x–1.04x 3-hit swipes. Transformed is ONE ignited hit then reverts. Charged transformed 1.80x with small AoE explosion. Transform attack 0.90x (low — the ignition IS the point, not the swing).

| # | Payoff Name | Define | Effect | Tier | CD |
|---|---|---|---|---|---|
| 1 | Ignition Blast | `PAYOFF_IGNITION_BLAST` | 3×2 fire AoE in front: all mobs take burn + 2 fire stacks via `adjust_fire_stacks()`. Consumes igniter charge. | 4 | 30s |
| 2 | Hammer Blow | `PAYOFF_BH_HAMMER_BLOW` | Knockback 2 tiles from sheer force. Wall collision = knockdown. | 2 | 15s |
| 3 | Flash Ignition | `PAYOFF_BH_FLASH_IGN` | Force eyes closed from explosion flash. The ignition blinds. | 1 | 12s |
| 4 | Concussive Impact | `PAYOFF_BH_CONCUSSIVE` | Daze: reversed WASD for 3s. Hammer concussion rattles the brain. | 3 | 20s |
| 5 | Armor Dent | `PAYOFF_BH_ARMOR_DENT` | Struck armor piece loses 20% of current integrity. Hammer doesn't cut — it caves in. | 2 | 20s |
| 6 | Igniter Charge | `PAYOFF_BH_IGNITER` | Next transform attack has +50% ignition damage. Double-loaded. | 3 | 25s |
| 7 | Blast Stagger | `PAYOFF_BH_BLAST_STAGGER` | OffBalance 10ds + stumbling walk 3s. Concussive + thermal shock. | 2 | 15s |
| 8 | Scorched Earth | `PAYOFF_BH_SCORCHED` | Explosion leaves 1-tile fire hazard for 5s. Environmental area denial. | 3 | 25s |
| 9 | Thermal Shock | `PAYOFF_BH_THERMAL` | If target is wet: +30% finisher damage. Water meets fire meets pain. | 2 | 15s |
| 10 | Demolisher | `PAYOFF_BH_DEMOLISHER` | Double damage to structures/doors. The hammer's purpose beyond flesh. | 2 | 20s |

---

## 14. Beasthunter Saif — Gap Control

**Identity:** Normal = slow overhead swipes, but the transform attack LUNGES FORWARD with a sweeping strike. Transformed = fast cleaver with an opening upward lunge, and the transform-BACK sweeps while dodging BACKWARD. The Saif is THE gap control weapon — it closes when you want in and retreats when you want out.

**BB Reference:** Normal R1 1.00x–1.05x slow overheads. Transform attack 1.045x lunges forward. Transformed R1 0.85x–0.91x with upward lunge opener. Transform back 1.00x sweeps while retreating backward. Charged 1.63x 360° ground smash. Charged transformed 1.45x ground slam.

| # | Payoff Name | Define | Effect | Tier | CD |
|---|---|---|---|---|---|
| 1 | Closing Lunge | `PAYOFF_BS_CLOSING_LUNGE` | Gap close: attacker moves 1 tile toward target + +30% bonus damage from momentum. Saif built for the approach. | 3 | 20s |
| 2 | Tactical Retreat | `PAYOFF_BS_TACTICAL_RETREAT` | Transform-back payoff: attacker moves 2 tiles away + OffBalance (6ds) to anyone adjacent on departure. Dodge backward. | 2 | 15s |
| 3 | Forward Pressure | `PAYOFF_BS_FORWARD_PRESSURE` | Target's retreat speed halved for 3s. Any movement AWAY from attacker costs double stamina. Trapped in the kill zone. | 4 | 30s |
| 4 | Disengaging Slash | `PAYOFF_BS_DISENGAGE` | Attacker moves 2 tiles away after hit + damage on departure. Kiting blade. | 2 | 15s |
| 5 | Ankle Reaper | `PAYOFF_BS_ANKLE_REAPER` | Stumbling walk for 4s + cannot sprint. Low sweeping cut catches the tendons. | 2 | 12s |
| 6 | Overhead Crush | `PAYOFF_BS_OVERHEAD` | Normal mode: OffBalance 8ds + camera jerk. Heavy overhead slam impact. | 2 | 15s |
| 7 | Blitz Strike | `PAYOFF_BS_BLITZ` | Transformed gap-close with +40% damage from forward momentum. The Saif leaps into the fray. | 3 | 20s |
| 8 | Retreating Counter | `PAYOFF_BS_RETREAT_COUNTER` | False opening: step back. If target follows within 2s, auto-counter at 1.4×. Punishes pursuit. | 3 | 25s |
| 9 | Zone Denial | `PAYOFF_BS_ZONE_DENIAL` | 3×1 arc sweep: all in arc take damage + stumbling walk 2s. Controls the space ahead. | 3 | 20s |
| 10 | Pursuit Cut | `PAYOFF_BS_PURSUIT` | If target moved in the last 2 seconds (fleeing or repositioning), +30% finisher damage. Catches runners. | 2 | 15s |
| 11 | Pinning Slam | `PAYOFF_BS_PINNING` | Charged slash: immobilize 1s + armor integrity -15% on struck zone. Pins them for the follow-up. | 3 | 25s |
| 12 | Serrated Rend | `PAYOFF_BS_SERRATED_REND` | +20% wound severity on beast/anthromorph targets. The Beasthunter's purpose. | 2 | 15s |

---

## 15. Blade of Mercy — Speed Kills

**Identity:** Short sword (normal) to dual daggers (transformed). 8-hit flurry combo with escalating speed. Quickstep and backstep have 1.50x multipliers — the weapon rewards dodging INTO attacks. Speed demon. Not true dual-wield in code (single item + `dualwielder_force_bonus`).

**BB Reference:** Normal R1 3-hit combo. Backstep R1 1.50x. Transformed R1 8-hit flurry 0.90x each escalating. L2 hop backward + X-slash. The fastest weapon in BB, designed for relentless aggression and evasive fighting.

| # | Payoff Name | Define | Effect | Tier | CD |
|---|---|---|---|---|---|
| 1 | Thousand Cuts | `PAYOFF_BM_THOUSAND_CUTS` | Each hit in the completed chain retroactively applies a stacking bleed tick. 8-hit flurry = 8 bleed procs. Death by accumulation. | 4 | 25s |
| 2 | Mercury Slash | `PAYOFF_BM_MERCURY` | After finisher, next 3 attacks have 40% reduced clickCD. Speed begets speed. | 3 | 20s |
| 3 | Evasion Strike | `PAYOFF_BM_EVASION_STRIKE` | If attacker dodged/stepped within 2s before finisher, +50% finisher damage. Rewards dodge→attack playstyle. | 3 | 20s |
| 4 | Quicksilver | `PAYOFF_BM_QUICKSILVER` | +30% passive dodge for 4s after finisher. Too fast to punish. | 3 | 20s |
| 5 | Flurry Blitz | `PAYOFF_BM_FLURRY` | Finisher strikes 3 times instead of once at 40% each. A blur of steel. | 4 | 30s |
| 6 | Nerve Cut | `PAYOFF_BM_NERVE_CUT` | Target's clickCD +30% for 5s. Precision strikes to the tendons slow their hands. | 2 | 15s |
| 7 | Vanishing Step | `PAYOFF_BM_VANISH` | After finisher, attacker moves 1 tile in a random adjacent direction. Evasive repositioning. | 2 | 15s |
| 8 | Scissor Cut | `PAYOFF_BM_SCISSOR` | Cross-slash: deals damage to target zone AND one adjacent zone simultaneously. Dual blades, dual wounds. | 3 | 20s |
| 9 | Blinding Speed | `PAYOFF_BM_BLINDING` | Flinch: force eyes closed. Too fast for the eye to track. | 1 | 12s |
| 10 | Arterial Nick | `PAYOFF_BM_ARTERIAL` | Small precision cut: bleed wound guaranteed on target zone. Low base damage but guaranteed bleed. | 2 | 15s |
| 11 | Dancer's Retreat | `PAYOFF_BM_RETREAT` | L2-style payoff: hop backward (move 1 tile away) + damage on departure. Disengage offense. | 2 | 15s |
| 12 | Death By A Thousand | `PAYOFF_BM_DEATH_THOUSAND` | Execute payoff: +60% finisher damage when target below 25% HP. All those small cuts, accumulated. | 4 | 30s |

---

## 16. Burial Blade — Reaper's Craft

**Identity:** Curved sword (normal) to scythe (transformed). Scythe has pulling motions, wide arcs, 360° charged sweep at 3.0x. L2 is a four-hit combo. The original hunter's weapon — power from skill, not magic. Gehrman's blade.

**BB Reference:** Normal R1 curved slashes. Charged 2.5x full-circle. Transform attack 2.3x fast scythe deploy. Transformed R2 1.95x 180° sweep. Charged scythe 3.0x. L2 four-hit combo at 1.40x/1.25x/1.50x/1.50x. The granddaddy of trickweapons.

| # | Payoff Name | Define | Effect | Tier | CD |
|---|---|---|---|---|---|
| 1 | Reaper's Harvest | `PAYOFF_REAPERS_HARVEST` | Execute: +50% bonus damage when target at ≤25% HP. The reaper comes for the wounded. | 4 | 25s |
| 2 | Soul Rend | `PAYOFF_SOUL_REND` | Drains 40 stamina via `stamina_add()`. Target exhausted — defensive capability crippled. | 3 | 25s |
| 3 | Scythe Sweep | `PAYOFF_BB_SCYTHE_SWEEP` | 3×1 wide arc. The classic reaper sweep. Multiple targets, one motion. | 2 | 15s |
| 4 | Drag to Hell | `PAYOFF_BB_DRAG` | Scythe hooks target: pull 1 tile via `throw_at` + OffBalance 8ds. The blade's curved head grabs and yanks. | 3 | 20s |
| 5 | Reaping Arc | `PAYOFF_BB_REAPING_ARC` | 360° AoE: all adjacent mobs take damage + stumbling walk 2s. The full-circle sweep. Iconic. | 4 | 30s |
| 6 | Wrist Reap | `PAYOFF_BB_WRIST_REAP` | Scythe hooks weapon hand: modified disarm attempt. The curved blade is natural for this. | 3 | 25s |
| 7 | Grave Dust | `PAYOFF_BB_GRAVE_DUST` | Frighten: mood debuff. The presence of the First Hunter's weapon chills the soul. | 1 | 10s |
| 8 | Curved Bite | `PAYOFF_BB_CURVED_BITE` | Sword mode: wound severity +1 on hit zone. Curved blade hooks into flesh and tears on withdrawal. | 3 | 20s |
| 9 | Phantom Step | `PAYOFF_BB_PHANTOM` | After finisher, attacker's icon becomes semi-transparent for 2s + movement is silent (no footstep sounds). Ghostly. | 3 | 25s |
| 10 | Harvest Moon | `PAYOFF_BB_HARVEST_MOON` | Charged scythe vs target below 50% HP: advantage on ALL dice rolls for this hit. The reaper senses weakness. | 4 | 30s |
| 11 | Momentum Transfer | `PAYOFF_BB_MOMENTUM` | Transform attack: sword→scythe deployment hit at +40% damage. The unfolding IS the strike. | 2 | 20s |
| 12 | First Hunter's Technique | `PAYOFF_BB_FIRST_HUNTER` | Counter-tempo: if attacker takes hit within 2s, next scythe attack at 1.5× damage. The old hunter's patience. | 3 | 20s |

---

## 17. Chikage — Blood Price

**Identity:** Katana (normal, clean slashes) to blood-katana (transformed, costs HP to wield). R2 is an iaido draw at 1.50x. Charged transformed 2.25x + follow-up. L2 is thrust+slash. The weapon of blood — power through self-sacrifice, risk through reward.

**BB Reference:** Normal R1 5-hit flurry 1.00x–1.10x. Transformed R2 iaido draw 1.50x. Charged transformed 2.25x + 1.92x follow-up. L2 thrust+slash two-hit 1.27x each. Transform attack 1.42x (costs HP). Blood-soaked identity throughout.

| # | Payoff Name | Define | Effect | Tier | CD |
|---|---|---|---|---|---|
| 1 | Blood Price | `PAYOFF_BLOOD_PRICE` | Finisher damage scales with ATTACKER's missing HP. Max +80% at ≤20% HP. The closer to death, the deadlier. | 4 | 20s |
| 2 | Crimson Mist | `PAYOFF_CRIMSON_MIST` | Blood AoE burst: all mobs within 1 tile of target take splash damage (0.4× finisher). Costs attacker 10 HP. | 3 | 30s |
| 3 | Iaido Draw | `PAYOFF_CHK_IAIDO` | If first hit after transforming: +50% damage. The iconic quickdraw. Transform → immediate devastating strike. | 3 | 20s |
| 4 | Blood Blade | `PAYOFF_CHK_BLOOD_BLADE` | Self-bleed: lose 5 HP, next 3 attacks +15% damage from blood-infused cutting edge. | 2 | 15s |
| 5 | Crimson Fountain | `PAYOFF_CHK_FOUNTAIN` | If finisher drops target to 0: blood burst AoE — all within 1 tile take 25 brute. The killing blow erupts. | 4 | 45s |
| 6 | Hemorrhagic Slash | `PAYOFF_CHK_HEMORRHAGIC` | All existing bleed wounds on target worsen by +1 severity. Opens what's already bleeding. | 3 | 20s |
| 7 | Exsanguinate | `PAYOFF_CHK_EXSANGUINATE` | Remove 10% of target's current `blood_volume` on hit. Direct blood drain. | 3 | 25s |
| 8 | Blood Frenzy | `PAYOFF_CHK_BLOOD_FRENZY` | Each transform-cost HP spent this fight increases attacker's next combo finisher by +10% (stacks 3×). Snowball risk/reward. | 3 | 20s |
| 9 | Crimson Veil | `PAYOFF_CHK_CRIMSON_VEIL` | Blood splatter across target's screen: camera jerk + red overlay for 2s. | 1 | 12s |
| 10 | Katana Precision | `PAYOFF_CHK_PRECISION` | Normal mode: force zone to neck, +40% pen factor. Clean decapitation attempt. | 4 | 30s |
| 11 | Sakura Slash | `PAYOFF_CHK_SAKURA` | Rapid 2-hit draw: first hit at 1.0×, second at 0.6×. Two separate damage rolls. | 2 | 15s |
| 12 | Last Stand | `PAYOFF_CHK_LAST_STAND` | When attacker below 30% HP: ALL attacks gain +20% damage passively for 10s. The dying samurai fights hardest. | 4 | 45s |

---

## 18. Logarius' Wheel — Fanatical Zeal

**Identity:** Overhead wheel smashes (normal). Transformed has escalating 3-hit R2 with ground sparks, L2 "enhances subsequent attacks" spin with skulls, Transform Attack is AoE bloody vapor. Fanaticism and self-sacrifice — the Executioner's weapon.

**BB Reference:** Normal R1 1.00x 3-hit. Charged 1.60x spin. Transformed R2 escalating 3-hit: 1.17×+15×2, 1.30×+15×2, 1.44×+15×2. L2 enhances arcane damage (spin with skull effects). Transform attack 0.10×3+0.93x AoE bloody vapor. Self-harm theme matches the Executioners' fanaticism.

| # | Payoff Name | Define | Effect | Tier | CD |
|---|---|---|---|---|---|
| 1 | Zealot's Frenzy | `PAYOFF_ZEALOTS_FRENZY` | Multi-hit: the completing blow strikes 3 times rapidly instead of once. Each hit rolls separately. | 3 | 25s |
| 2 | Martyr's Offering | `PAYOFF_MARTYRS_OFFERING` | Self-harm 15 HP → finisher at 2.0× damage. Maximum commitment. | 4 | 30s |
| 3 | Crushing Wheel | `PAYOFF_LW_CRUSHING` | OffBalance 10ds + camera jerk from wheel slam. The absurd weight of an executioner's wheel. | 2 | 15s |
| 4 | Skull Procession | `PAYOFF_LW_SKULL_PROC` | L2 spin: all adjacent mobs take damage + frighten (mood debuff). The skulls emerge and wail. | 3 | 25s |
| 5 | Blood Mist | `PAYOFF_LW_BLOOD_MIST` | Transform attack AoE: 3×3 bloody vapor. All in range lose 5% current `blood_volume`. | 3 | 25s |
| 6 | Fanatical Charge | `PAYOFF_LW_FANATIC_CHARGE` | Running attack: gap close 1 tile + knockback target 2 tiles. Unstoppable zealot. | 2 | 15s |
| 7 | Penitent Strike | `PAYOFF_LW_PENITENT` | Self-harm 10 HP → next hit ignores armor class completely. Pain buys passage. | 3 | 25s |
| 8 | Wheel Lock | `PAYOFF_LW_WHEEL_LOCK` | Wheel catches target's weapon: clickCD +40% for 5s. Jammed in the spokes. | 2 | 15s |
| 9 | Martyr's Resilience | `PAYOFF_LW_RESILIENCE` | After any self-harm payoff: attacker gains 30% damage reduction for 3s. Suffering fuels endurance. | 2 | 15s |
| 10 | Escalating Strikes | `PAYOFF_LW_ESCALATING` | R2 combo: each successive hit deals +20% more. 3rd hit at +40% base. Building fanatical momentum. | 3 | 20s |
| 11 | Devotional Fervor | `PAYOFF_LW_FERVOR` | The more HP attacker is missing, the faster attacks (up to 25% clickCD reduction at ≤30% HP). Pain is motivation. | 3 | 20s |
| 12 | Holy Grinding | `PAYOFF_LW_GRINDING` | Wheel grinds against target: armor integrity on struck zone -20% per hit for this 3-hit combo. Progressive destruction. | 3 | 20s |

---

## 19. Rakuyo — Twin Dance

**Identity:** Saber (normal) to saber+dagger dual-wield (transformed). Complex 7-hit alternating combos. L2 is 360° dual slash (spin, counter-spin). Highest skill ceiling in Bloodborne. Not true dual-wield in code. Demands dexterity, rewards it generously.

*"A trick sword that feeds not off blood, but instead demands great dexterity. Lady Maria was fond of this aspect."*

**BB Reference:** Normal R1 1.00x/0.90x/1.00x/1.15x 7-hit combo. Transformed R1 alternating dual slashes. Transformed R2 triple alternating thrusts 0.90x/0.95x/0.90x. L2 360° dual slash 0.95×+100 / 1.05×+110 with spin/counter-spin variations. Transform attack 1.50x reuniting thrust.

| # | Payoff Name | Define | Effect | Tier | CD |
|---|---|---|---|---|---|
| 1 | Twin Fang | `PAYOFF_TWIN_FANG` | Double-hit: finisher hits twice, second at 0.8×. Two damage rolls, two dodge/parry checks. | 3 | 20s |
| 2 | Dancer's Grace | `PAYOFF_DANCERS_GRACE` | +30% passive dodge for 3s after finisher. Lady Maria's elegance. | 2 | 20s |
| 3 | Pirouette | `PAYOFF_RAK_PIROUETTE` | L2 spin: 360° AoE all adjacent take damage + attacker moves 1 tile in facing direction. Dancing through the fight. | 4 | 25s |
| 4 | Dueling Mastery | `PAYOFF_RAK_DUELING` | After finisher, next parry attempt auto-succeeds. Perfect read rewarded. | 4 | 30s |
| 5 | Cross Slash | `PAYOFF_RAK_CROSS_SLASH` | Dual blades hit target zone AND adjacent zone simultaneously. X-pattern cut. | 3 | 20s |
| 6 | Counter Dance | `PAYOFF_RAK_COUNTER_DANCE` | If target misses attacker within 2s, auto-riposte at 1.5×. Dodge-into-punish. | 4 | 25s |
| 7 | Flowing Combo | `PAYOFF_RAK_FLOWING` | If entire combo completed without attacker taking damage: +30% finisher damage. Untouchable execution bonus. | 3 | 20s |
| 8 | Saber Thrust | `PAYOFF_RAK_SABER_THRUST` | Precision: force zone to chest, +50% pen factor. Clean rapier-style thrust through the guard. | 3 | 25s |
| 9 | Dagger Flick | `PAYOFF_RAK_DAGGER_FLICK` | Flinch: force eyes closed. Off-hand dagger snaps across the face. Too quick to parry. | 1 | 12s |
| 10 | Whirlwind | `PAYOFF_RAK_WHIRLWIND` | Running attack: 3×1 arc while gap closing. Spinning entry with both blades extended. | 3 | 20s |
| 11 | Lion's Roar | `PAYOFF_RAK_LIONS_ROAR` | After completing a 7+ hit combo: +20% damage and +20% clickCD reduction for 5s. The longest combos reward the most. | 4 | 30s |
| 12 | Evasive Riposte | `PAYOFF_RAK_EVASIVE_RIPOSTE` | After successful dodge: instant free counter at 1.0× damage. Active defense becomes offense. | 3 | 20s |

---

## 20. Simon's Bowblade — Hybrid Marksman

**Identity:** Sword (normal, varied 7-hit slash/thrust combo) to bow (transformed, fires arrows consuming ammo). Transform attack fires an arrow while disengaging backward. L2 in bow form is a melee swipe. The weapon bridging melee and ranged, rewarding cross-form play.

**BB Reference:** Normal R1 7-hit combo with slashes/thrusts. Charged normal 0.80x+1.70x 360° double sweep. Transformed fires arrows at 0.85x–1.40x (charged). L2 melee swipe 0.70x. Transform attack fires arrow + backstep. The sniper's melee weapon.

| # | Payoff Name | Define | Effect | Tier | CD |
|---|---|---|---|---|---|
| 1 | Pinning Shot | `PAYOFF_SB_PINNING` | Arrow pins target: immobilize 1.5s. Stuck to the ground by an arrow through the boot. | 3 | 25s |
| 2 | Mark Target | `PAYOFF_SB_MARK` | Arrow marks target: all subsequent attacks against marked target deal +15% damage for 10s. Visible mark. | 3 | 25s |
| 3 | Sword-to-Shot | `PAYOFF_SB_SWORD_SHOT` | Transform attack: fire arrow + move 1 tile backward. Free ranged hit + disengage. | 2 | 15s |
| 4 | Crippling Arrow | `PAYOFF_SB_CRIPPLING` | Arrow to leg: stumbling walk 4s + cannot sprint. Pin them, then approach at leisure. | 3 | 20s |
| 5 | Covering Fire | `PAYOFF_SB_COVERING` | After ranged hit, attacker gains +25% dodge for 3s. Suppressive stance — hard to approach. | 2 | 15s |
| 6 | Heavy Draw | `PAYOFF_SB_HEAVY_DRAW` | Charged bow: +60% arrow damage. Long commitment, devastating payoff. | 3 | 20s |
| 7 | Close Quarters | `PAYOFF_SB_CLOSE_QUARTERS` | L2 melee swipe in bow form: camera jerk + force throw intent (loose grip). Panic close-range defense. | 2 | 15s |
| 8 | Volley | `PAYOFF_SB_VOLLEY` | Fire 2 arrows in rapid succession. Second arrow at 0.5× damage. Costs 2 ammo. | 3 | 25s |
| 9 | Precision Shot | `PAYOFF_SB_PRECISION` | Force zone to struck area + wound severity +1. Surgical arrow placement. | 4 | 30s |
| 10 | Kiting Dance | `PAYOFF_SB_KITING` | After any ranged attack, attacker auto-moves 1 tile away from target. Shoot and retreat. | 1 | 10s |
| 11 | Sword Finisher | `PAYOFF_SB_SWORD_FINISH` | If target currently has a Pinning Shot debuff active, sword attacks deal +30%. Pin then stab. Cross-form synergy. | 3 | 20s |
| 12 | Hunter's Patience | `PAYOFF_SB_PATIENCE` | If attacker hasn't taken damage in 5s: next attack (ranged or melee) deals +40%. The patient hunter's reward. | 4 | 30s |

---

## 21. Whirligig Saw — Grinding Machine

**Identity:** Mace/thrust weapon (normal) to pizza cutter (transformed). L2 is continuous spinning saw that drains stamina while held. Very high motion values in transformed (2.00x leap!). The saw_grind_tick system already exists (0.5× force_dynamic per tick). Serrated in transformed.

**BB Reference:** Normal R1 varied combo with thrusts and slashes. Transformed R1 much higher: 1.33x–1.49x. L2 hold-to-grind (1.06x+65+30+65, stamina 25+10+10 continuous). Transformed leap 2.00x — highest leap in BB. Transformed charged: (30×3+180) multihit ground slam.

| # | Payoff Name | Define | Effect | Tier | CD |
|---|---|---|---|---|---|
| 1 | Sawblade Burst | `PAYOFF_SAWBLADE_BURST` | 180° serrated AoE: all mobs in front within 1 tile take serrated damage. Uses `transformed_serrated` flag. | 3 | 25s |
| 2 | Pizza Cutter | `PAYOFF_WS_PIZZA_CUTTER` | L2 grind payoff: each grind tick reduces target's armor integrity by 3% of current. Sustained grinding = sustained destruction. | 3 | 20s |
| 3 | Grinding Halt | `PAYOFF_WS_GRINDING_HALT` | Saw grind finisher: target immobilized 1s. Saw blade caught in armor/flesh. | 3 | 25s |
| 4 | Serrated Ruin | `PAYOFF_WS_SERRATED_RUIN` | Peel threshold on hit zone -1 from saw grinding. Armor peeled by machine. | 4 | 30s |
| 5 | Buzzsaw Sweep | `PAYOFF_WS_BUZZSAW` | 3×1 arc: spinning saw sweeps in a line. Multiple targets, one messy sweep. | 2 | 15s |
| 6 | Sparks Fly | `PAYOFF_WS_SPARKS` | Camera jerk + flinch from saw blade sparks on metal armor. Blinding shower. | 1 | 12s |
| 7 | Mace Slam | `PAYOFF_WS_MACE_SLAM` | Normal mode: knockback 1 tile + OffBalance 8ds. Simple blunt trauma. | 2 | 15s |
| 8 | Rev Up | `PAYOFF_WS_REV_UP` | Next saw_grind_tick session does +50% damage per tick for 5s. Revving the motor. | 3 | 20s |
| 9 | Flesh Ripper | `PAYOFF_WS_FLESH_RIPPER` | Saw grind on flesh (unarmored zone): wound severity +1 + serrated bleed stack. Horrifying. | 4 | 30s |
| 10 | Stalling Grind | `PAYOFF_WS_STALLING` | Target's clickCD +35% while being ground on. Can't swing while a saw is eating your armor. | 2 | 15s |
| 11 | Serrated Cascade | `PAYOFF_WS_CASCADE` | After grind ends: target bleeds (serrated) for 10s. The saw leaves its mark. | 3 | 20s |
| 12 | Industrial Demolition | `PAYOFF_WS_DEMOLITION` | Double damage to structures/doors. The saw cuts through everything. | 2 | 20s |

---

## 22. Beast Claws — Feral Fury

**Identity:** Rapid punches/claw swipes. Very low stamina per hit (14–20). Beast Embrace adds dual-claw moves and +60 damage on various attacks. 5+ hit combos that pursue opponents. Feral, aggressive, relentless. Not true dual-wield in code.

**BB Reference:** Normal R1 5-hit combo 1.00x–1.08x. Transformed adds dual-claw: L2 three-hit scissoring combo 1.23x. Beast Embrace version adds +60 damage to backstep/dash attacks. Normal leap 1.53x "claws punched into the ground." The feral predator who never stops attacking.

| # | Payoff Name | Define | Effect | Tier | CD |
|---|---|---|---|---|---|
| 1 | Feral Frenzy | `PAYOFF_FERAL_FRENZY` | After finisher, next 3 attacks have 40% reduced clickCD. The frenzy continues. | 3 | 20s |
| 2 | Rake | `PAYOFF_BCL_RAKE` | Each claw swipe in the completed combo retroactively applies a bleed tick. 5-hit = 5 bleeds. Shredded. | 4 | 25s |
| 3 | Bestial Roar | `PAYOFF_BCL_ROAR` | AoE frighten: all mobs within 2 tiles get mood debuff + camera jerk. Inhuman scream. | 3 | 25s |
| 4 | Savage Pounce | `PAYOFF_BCL_POUNCE` | Running attack: gap close 2 tiles + OffBalance 10ds. Tackle from a charge. | 3 | 20s |
| 5 | Rend | `PAYOFF_BCL_REND` | Claw tears armor: peel threshold -1 on hit zone. Armor shredded by feral claws. | 3 | 25s |
| 6 | Mauling Flurry | `PAYOFF_BCL_MAULING` | Finisher strikes 3 times at 35% each instead of once. A blur of claws. | 3 | 20s |
| 7 | Instinctive Dodge | `PAYOFF_BCL_INSTINCT` | After finisher, +25% passive dodge for 3s. Animal reflexes kick in. | 2 | 15s |
| 8 | Hamstring | `PAYOFF_BCL_HAMSTRING` | Claw to legs: stumbling walk 3s + cannot sprint. Brought low. | 1 | 12s |
| 9 | Predator Sense | `PAYOFF_BCL_PREDATOR` | After combo completion: target highlighted (visible through darkness/smoke) for 10s. Marked as prey. | 2 | 15s |
| 10 | Face Rake | `PAYOFF_BCL_FACE_RAKE` | Flinch: force eyes closed. Claws across the face. | 1 | 12s |
| 11 | Scissoring Claws | `PAYOFF_BCL_SCISSOR` | Both claws from opposite sides: damage to target zone + adjacent zone simultaneously. | 3 | 20s |
| 12 | Blood Frenzy | `PAYOFF_BCL_BLOOD_FRENZY` | Each hit in combo stacks +5% finisher damage. 5-hit = +25% on last. Building momentum. | 2 | 15s |

---

## 23. Church Pick — Righteous Precision

**Identity:** War pick (normal, thrust-focused) to halberd (transformed, sweeps + devastating two-hit charged 2.00x+2.21x). Serrated in transformed. `is_silver=TRUE` for undead. BCLASS_PICK in pick form bypasses most armor crit protection. The church's weapon of righteous judgment — precision, not brutality.

**CAUTION:** BCLASS_PICK can one-shot through full plate on lucky arterial crits. Payoffs lean into precision and wound manipulation rather than making the pick more lethal.

**BB Reference:** Normal R1 thrust into sweep combo. R2 forceful thrust 1.37x. Transformed R1 overhand slam → sweeps. Charged transformed TWO HITS: 2.00x+2.21x — devastating. L2 quick swipe 0.53x (fast interrupt). Serrated in transformed form.

| # | Payoff Name | Define | Effect | Tier | CD |
|---|---|---|---|---|---|
| 1 | Righteous Judgment | `PAYOFF_CP_RIGHTEOUS` | +20% damage vs undead. Stacks with `is_silver`. The church's mandate. | 2 | 15s |
| 2 | Pick Through | `PAYOFF_CP_PICK_THROUGH` | BCLASS_PICK forced to target zone with +30% pen. The surgical armor-bypass strike. (No crit bonus — balanced.) | 4 | 30s |
| 3 | Armor Puncture | `PAYOFF_CP_ARMOR_PUNCT` | This hit ignores armor class. But no BCLASS_PICK bonus on this one — pure penetration, controlled lethality. | 3 | 25s |
| 4 | Halberd Sweep | `PAYOFF_CP_HALBERD_SWEEP` | 3×1 arc in transformed mode. Halberd sweep clears the field. | 2 | 15s |
| 5 | Sermon | `PAYOFF_CP_SERMON` | Frighten: mood debuff. The church's judgment delivered through steel. | 1 | 10s |
| 6 | Serrated Hook | `PAYOFF_CP_SERRATED_HOOK` | Transformed serrated: wound severity +1 on hit zone + serrated bleed. The pick's teeth catch. | 3 | 20s |
| 7 | Anchoring Pick | `PAYOFF_CP_ANCHORING` | Pick lodges in target: immobilize 1s. Spiked into bone. | 3 | 25s |
| 8 | Penitent Strike | `PAYOFF_CP_PENITENT` | Counter-tempo: if attacker takes damage first, retaliatory pick at 1.4×. The church rewards suffering. | 3 | 20s |
| 9 | Confessional | `PAYOFF_CP_CONFESSIONAL` | Intel payoff: attacker can see target's exact armor values and HP % for 10s. Knowledge is the church's weapon. | 2 | 15s |
| 10 | Cathedral Slam | `PAYOFF_CP_CATHEDRAL` | Transformed charged: OffBalance 10ds + AoE 3×2 minor damage. Devastation from above. | 3 | 25s |
| 11 | Holy Purpose | `PAYOFF_CP_HOLY_PURPOSE` | After killing undead target: attacker heals 10 HP. The church's blessing for faithful work. | 3 | 30s |
| 12 | Precision Extraction | `PAYOFF_CP_EXTRACTION` | Pick to wound: removes existing bandages/sutures from target's hit zone. Undoes their healing. Surgical cruelty. | 4 | 30s |

---

## 24. Holy Moonlight Sword — Arcane Greatsword ★ SPECIAL

**Identity:** Greatsword. Transformed R2s emit moonlight waves (ranged projectiles that cost ammo/bullets). L2 is a thrust with a flash at the end that causes AoE knockdown. Max 1 per round (unless admin). Already has projectile system, we limit projectile spam via internal ammo system rather than an actual item in the users inventory, ammo regenerates at fixed rate. `is_silver=TRUE`. The LEGENDARY weapon — gets 14 payoffs and they're all powerful.

**SPECIAL CASE:** Since max 1/round, payoffs can be significantly stronger than other weapons. This is the reward for acquiring the rarest weapon in the game.

**BB Reference:** Normal R1 1.00x–1.06x 4-hit. Transformed R2 1.20x + 2.00x wave (ranged). Charged transformed 1.40x + 2.80x wave. L2 1.50x thrust + 1.50x flash with AoE knockdown. Transformed leap 1.30x + 2.40x vertical wave. The moonlight defines the weapon.

| # | Payoff Name | Define | Effect | Tier | CD |
|---|---|---|---|---|---|
| 1 | Moonlight Wave | `PAYOFF_HMS_WAVE` | Fire moonlight wave: 1×3 line projectile at 1.0× finisher damage. Costs 1 ammo. Ranged finisher. | 3 | 20s |
| 2 | Lunar Cascade | `PAYOFF_HMS_CASCADE` | Enhanced wave: 1×5 line, 1.2× damage, pierces all targets in line. Costs 2 ammo. Devastating reach. | 4 | 30s |
| 3 | Blinding Radiance | `PAYOFF_HMS_RADIANCE` | L2 flash: all mobs within 2 tiles get flinch (eyes closed) + camera jerk. Holy light overwhelms. | 3 | 20s |
| 4 | Moonlit Shockwave | `PAYOFF_HMS_SHOCKWAVE` | L2 thrust AoE: knockback 2 tiles + OffBalance 10ds to all in 3×3 centered on target. Costs 1 ammo. | 4 | 30s |
| 5 | Silver Cleanse | `PAYOFF_HMS_CLEANSE` | +60% damage vs undead. Stacks with `is_silver`. The holy blade's true purpose revealed. | 3 | 20s |
| 6 | Arcane Resonance | `PAYOFF_HMS_RESONANCE` | Sword glows: next 3 attacks deal +20% damage. The moonlight charges over time. | 2 | 20s |
| 7 | Descending Moon | `PAYOFF_HMS_DESC_MOON` | Overhead slam AoE: 3×2 area + OffBalance 8ds to all. The greatsword crashes like a falling star. | 3 | 25s |
| 8 | Phase Slash | `PAYOFF_HMS_PHASE` | ★ LEGENDARY: Moonlight slash bypasses parry AND dodge. Cannot be defensively mitigated. Pure skill check on armor only. Costs 3 ammo. | 5 | 60s |
| 9 | Holy Storm | `PAYOFF_HMS_STORM` | 360° wave burst: all mobs within 2 tiles take 0.8× finisher damage + knockback 1 tile. Costs 2 ammo. | 4 | 45s |
| 10 | Guardian's Light | `PAYOFF_HMS_GUARDIAN` | After finisher, attacker gains 30% damage reduction for 5s + visible light aura. | 2 | 20s |
| 11 | Moonbeam | `PAYOFF_HMS_MOONBEAM` | Focused single-target projectile at range 3. Full finisher damage at range. Costs 1 ammo. | 3 | 20s |
| 12 | Lunar Eclipse | `PAYOFF_HMS_ECLIPSE` | Target's vision darkened: tunnel vision + reduced view range for 5s. Moonlight overwhelms then blinds. | 2 | 15s |
| 13 | Celestial Judgment | `PAYOFF_HMS_CELESTIAL` | Execute: +80% damage when target at ≤20% HP. The moonlight sword's ultimate verdict. | 4 | 30s |
| 14 | Symphony of the Night | `PAYOFF_HMS_SYMPHONY` | ★ LEGENDARY: All mobs within 3 tiles take full finisher damage + flinch + knockback + frighten. Costs ALL remaining ammo. One-use apocalyptic burst. | 5 | 120s |

---

## 25. Bloodletter — Self-Destruction

**Identity:** Mace (normal) to blood mace (transformed). TRANSFORMS BY STABBING THROUGH SELF. L2 ground slam + frenzy AoE affecting everything including the wielder. `transform_hp_cost=10` already exists. Self-harm IS the weapon's identity — every powerful move costs something.

**BB Reference:** Normal R1 4-hit combo with overhand slashes and sweeps. Transformed R1 5-hit with ground slams. Transform attack 1.30x — stabs through self to create the spikeball. L2 2.00x overhead ground slam + AoE frenzy (hurts EVERYONE including user). Mace of devotional self-destruction.

| # | Payoff Name | Define | Effect | Tier | CD |
|---|---|---|---|---|---|
| 1 | Blood Explosion | `PAYOFF_BLOOD_EXPLOSION` | Self-harm AoE: lose 20 `blood_volume`, all mobs within 2 tiles take massive brute scaled to blood spent. | 4 | 45s |
| 2 | Hemorrhage | `PAYOFF_HEMORRHAGE` | All existing bleed wounds on target worsen by +2 severity (`WOUND_SEVERITY`). Catastrophic bleed escalation. | 4 | 30s |
| 3 | Self-Transfusion | `PAYOFF_BL_TRANSFUSION` | Transform-through-self payoff: steal 10 HP from own pool → next 2 attacks at +30%. Blood fuels the weapon. | 3 | 20s |
| 4 | Frenzy Slam | `PAYOFF_BL_FRENZY_SLAM` | L2 AoE: 3×3 area. All targets (INCLUDING ATTACKER) take damage + camera jerk. Mutual devastation. | 4 | 30s |
| 5 | Blood Coating | `PAYOFF_BL_COATING` | Self-bleed 5 HP: weapon gains +20% damage for 10s. Blood-slick edge cuts deeper. | 2 | 15s |
| 6 | Sanguine Mist | `PAYOFF_BL_SANGUINE` | Blood spray: all mobs within 1 tile get flinch (eyes closed). Blood splashes in their face. | 1 | 12s |
| 7 | Crimson Tide | `PAYOFF_BL_CRIMSON_TIDE` | Drain 15% of target's current `blood_volume` instantly. Blood weapon drinks deep. | 3 | 25s |
| 8 | Desperate Strength | `PAYOFF_BL_DESPERATE` | When attacker below 30% HP: finisher at 2.0× damage. The dying man hits hardest. | 4 | 30s |
| 9 | Blood Offering | `PAYOFF_BL_OFFERING` | Self-harm 10 HP → next hit ignores armor class. Pain opens the path. | 3 | 25s |
| 10 | Mace Concussion | `PAYOFF_BL_CONCUSSION` | Normal mode: daze (reversed WASD) for 3s. Blunt trauma before the blood comes. | 2 | 15s |
| 11 | Gore Splash | `PAYOFF_BL_GORE` | Both target and attacker lose 5% current `blood_volume`. Mutual destruction. The Bloodletter takes from everyone. | 2 | 15s |
| 12 | Martyr's Gambit | `PAYOFF_BL_MARTYRS_GAMBIT` | Self-harm 20 HP → AoE 3×3: all targets stumble + frighten for 5s. Massive setup at massive cost. | 4 | 45s |

---

## 26. Parasite of Kos — Cosmic Leech

**Identity:** Bare tentacle fists. Backstep = VOMIT (pale fluid, poison). Transformed L2 is multi-hit arcane bomb (costs 2 bullets). Leap is headbutt. Requires Milkweed rune. Grotesque cosmic horror — the most alien weapon in the game. Leverages leech system.

**BB Reference:** Normal R1 3-hit tentacle strikes 1.00x–1.10x. Backstep R1 0.75x vomit (poison). Charged normal 1.35x+103 (multi-hit). Transformed R1 dual tentacle 1.05x–1.18x. L2 multi-hit (90+113+113+350) consuming 2 bullets. Transformed leap headbutt + tongue strike. Transform attack spawns parasites as short-range projectile (no bullet cost).

| # | Payoff Name | Define | Effect | Tier | CD |
|---|---|---|---|---|---|
| 1 | Budding | `PAYOFF_BUDDING` | 3×1 spew in front: covers target in 2+ leeches (ignores unleechable). Leech infestation. | 3 | 25s |
| 2 | Vomit | `PAYOFF_VOMIT` | 3×2 spew: tox damage (20) + mood debuff to all targets. Bile and horror. | 3 | 30s |
| 3 | Headbutt | `PAYOFF_HEADBUTT` | Ram head into target: 1.5× brute + attach 1 leech. Skull meets face. | 2 | 20s |
| 4 | Parasite Burst | `PAYOFF_KP_BURST` | L2 AoE: 3×3 area of massive damage. Costs special resource. The arcane detonation. | 4 | 35s |
| 5 | Tentacle Bind | `PAYOFF_KP_BIND` | Tentacles wrap target: immobilize 1.5s + attach 1 leech during wrap. Held and fed upon. | 3 | 25s |
| 6 | Bile Spray | `PAYOFF_KP_BILE` | Backstep spew: 1×3 line of tox damage + 30% chance target vomits (brief incapacitation). | 2 | 15s |
| 7 | Cosmic Madness | `PAYOFF_KP_MADNESS` | Daze (reversed WASD) + tunnel vision for 3s. Reality bends around the parasite's influence. | 4 | 30s |
| 8 | Parasitic Drain | `PAYOFF_KP_DRAIN` | Activate all leeches on target: each heals attacker for 5 HP. More leeches = more healing. | 3 | 25s |
| 9 | Spawn | `PAYOFF_KP_SPAWN` | If leeched target dies: leeches jump to nearest mob within 2 tiles. Infestation spreads. | 3 | 30s |
| 10 | Alien Grasp | `PAYOFF_KP_ALIEN_GRASP` | Tentacles swap target's hands + force eyes closed. Confused and blind. | 2 | 15s |
| 11 | Reality Warp | `PAYOFF_KP_REALITY_WARP` | Camera jerk + reversed WASD for 2s. Brief but deeply disorienting. | 1 | 12s |
| 12 | Cosmic Avalanche | `PAYOFF_KP_AVALANCHE` | ★ LEGENDARY: 4×4 AoE. All mobs take damage + 2 leeches + frighten + stumble. Costs significant resource. Mother Kos's wrath. | 5 | 120s |

---

## 27. Hunter Torch — Funny

**Identity:** It's a torch. On fire. Not a real weapon, but in the right hands, an instrument of humiliation and mob justice. Fewer payoffs than proper trickweapons — it IS a torch.

| # | Payoff Name | Define | Effect | Tier | CD |
|---|---|---|---|---|---|
| 1 | Mob Mentality | `PAYOFF_MOB_MENTALITY` | ★ LEGENDARY (diff 5, 10-input). Target screams torch voice lines involuntarily for 60s using 23 existing voice OGGs. Random line every 10-50s + on attack/defend. Humiliation + position reveal. | 5 | 120s |
| 2 | Brand | `PAYOFF_HT_BRAND` | Torch thrust to face: flinch (eyes closed) + minor burn damage. Branded. | 2 | 15s |
| 3 | Torch Thrust | `PAYOFF_HT_THRUST` | Simple thrust: apply 1 fire stack via `adjust_fire_stacks()`. Direct ignition. | 1 | 12s |
| 4 | Smoke Screen | `PAYOFF_HT_SMOKE` | Wave torch aggressively: camera jerk + flinch from smoke. | 1 | 10s |
| 5 | Arson | `PAYOFF_HT_ARSON` | Set target's current armor piece on fire: 2 fire stacks on the armor piece. Gear damage over time. | 3 | 25s |
| 6 | Rally Cry | `PAYOFF_HT_RALLY` | Frighten: mood debuff from torch-mob energy. The collective madness. | 1 | 10s |
| 7 | Blazing Overhead | `PAYOFF_HT_BLAZING` | Slam torch down: minor burn to target + anyone within 1 tile from ember spray. | 2 | 15s |
| 8 | Pyre | `PAYOFF_HT_PYRE` | If target already has fire stacks: +30% finisher damage. Stoking what's already burning. | 2 | 15s |

---

## Cross-Reference: Generic Template → Weapon Usage

This table maps each generic payoff template to its weapon-specific incarnations, showing how the templates were distilled into unique identity:

| Generic Template | Weapons Using (as unique version) |
|---|---|
| Stumble | Saw Cleaver (Tendon Cut), Saw Spear (Raking Cut), Threaded Cane (Trip Wire), Beasthunter Saif (Ankle Reaper), Beast Cutter (Chain Trip), Beast Claws (Hamstring), Blade of Mercy (—), Simon's Bowblade (Crippling Arrow) |
| Camera Jerk | Saw Cleaver (Crimson Splatter as AoE), Hunter Axe (Ground Pound), Kirkhammer (Quake Stomp AoE), Stake Driver (Sucker Punch), Chikage (Crimson Veil), Reiterpallasch (Suppressive Discharge), Tonitrus (Static Discharge), Amygdalan Arm (Ground Pound), Beast Claws (part of Bestial Roar) |
| Flinch (Eyes Closed) | Saw Cleaver (Jaw Breaker), Hunter Axe (Axe Pommel), Kirkhammer (Pommel Bash), Stake Driver (Sucker Punch), Rifle Spear (Gunshot Flinch), Reiterpallasch (Pistol Whip), Tonitrus (Arc Flash), Amygdalan Arm (Visceral Horror), Boom Hammer (Flash Ignition), Blade of Mercy (Blinding Speed), Beast Claws (Face Rake), Rakuyo (Dagger Flick), Whirligig (Sparks Fly), HMS (Blinding Radiance AoE), Bloodletter (Sanguine Mist AoE), Kos (part of Alien Grasp) |
| Guard Break | Kirkhammer (Plate Crusher), Tonitrus (EMP Pulse), Church Pick (Armor Puncture), Bloodletter (Blood Offering with self-cost), Logarius Wheel (Penitent Strike with self-cost) |
| Knockback | Saw Spear (Spear Wall), Hunter Axe (Crowd Clear), Kirkhammer (Hammer Down), Stake Driver (Blast Punt), Rifle Spear (Spear Wall), Boom Hammer (Hammer Blow), Beasthunter Saif (via Tactical Retreat), Burial Blade (Drag to Hell as pull), Whirligig (Mace Slam), HMS (Moonlit Shockwave AoE), Bloodletter (Frenzy Slam AoE) |
| Immobilize | Threaded Cane (Entangle), Rifle Spear (Anchoring Stab), Amygdalan Arm (Eldritch Grip mutual), Tonitrus (Stun Lock), Church Pick (Anchoring Pick), Whirligig (Grinding Halt), Simon's Bowblade (Pinning Shot), Kos Parasite (Tentacle Bind), Beast Cutter (Anchored In mutual) |
| Disarm | Threaded Cane (Disarming Lash), Reiterpallasch (Disarming Parry), Burial Blade (Wrist Reap) |
| Counter-Tempo | Saw Cleaver (Panic Response), Threaded Cane (Gentleman's Rebuke), Saw Spear (Counter-Thrust), Church Pick (Penitent Strike), Burial Blade (First Hunter's Technique), Rakuyo (Counter Dance on miss) |
| Execute Scaling | Hunter Axe (Execution Swing), Ludwig's (Final Judgement), Burial Blade (Reaper's Harvest), Blade of Mercy (Death By A Thousand), HMS (Celestial Judgment), Rifle Spear (Execution Thrust) |
| Dodge Buff | Blade of Mercy (Quicksilver), Rakuyo (Dancer's Grace), Beast Claws (Instinctive Dodge), Simon's Bowblade (Covering Fire) |
| Frighten | Threaded Cane (Whip Snap), Burial Blade (Grave Dust), Amygdalan Arm (Cosmic Dread+), Beast Cutter (Cracking Whip), Beast Claws (Bestial Roar), Church Pick (Sermon), Hunter Torch (Rally Cry), Logarius (Skull Procession) |
| Multi-hit | Logarius Wheel (Zealot's Frenzy), Rakuyo (Twin Fang), Blade of Mercy (Flurry Blitz), Beast Claws (Mauling Flurry), Chikage (Sakura Slash) |
| Peel Reduction | Saw Cleaver (Flay), Threaded Cane (Flaying Lash from range), Beast Cutter (Flensing Strike), Beast Claws (Rend), Whirligig (Serrated Ruin), Church Pick (Precision Extraction alt) |
| Self-Harm for Power | Chikage (Blood Price, Blood Blade, Blood Frenzy), Bloodletter (Blood Explosion, Blood Coating, Blood Offering, Martyr's Gambit), Logarius (Martyr's Offering, Penitent Strike) |
| False Opening / Bait | Reiterpallasch (En Garde), Beasthunter Saif (Retreating Counter), Rakuyo (Counter Dance) |
| Daze (Reversed WASD) | Kirkhammer (Skull Ring), Tonitrus (Galvanic Shock), Amygdalan Arm (Unsettling Twitch), Boom Hammer (Concussive Impact), Bloodletter (Mace Concussion), Kos Parasite (Cosmic Madness, Reality Warp) |
| Wound Severity +1 | Saw Spear (Puncture Wound), Rifle Spear (Bayonet Twist), Burial Blade (Curved Bite), Chikage (Hemorrhagic Slash), Church Pick (Serrated Hook), Whirligig (Flesh Ripper), Simon's Bowblade (Precision Shot) |
| AoE (3×1 or wider) | Saw Cleaver (Street Sweep), Saw Spear (Polearm Sweep), Hunter Axe (Cleave Through, Spinning Cleave), Threaded Cane (Crack the Whip), Kirkhammer (Seismic Impact), Ludwig's (Cleansing Sweep, Holy Shockwave), Beast Cutter (Chain Lash, Ground Slam), Amygdalan Arm (Tentacle Flail, Aberrant Slam), Burial Blade (Scythe Sweep, Reaping Arc), Whirligig (Buzzsaw Sweep, Sawblade Burst), HMS (Moonlight Wave, Holy Storm), Bloodletter (Blood Explosion, Frenzy Slam), Kos (Vomit, Parasite Burst, Cosmic Avalanche) |
| ClickCD Increase | Saw Cleaver (Bind and Tear), Threaded Cane (Cane Pommel), Blade of Mercy (Nerve Cut), Tonitrus (Voltage Spike), Logarius (Wheel Lock), Rifle Spear (Disabling Shot), Whirligig (Stalling Grind) |

---

## Payoff Totals

| Weapon | Unique Payoffs | Legendary? | Self-Harm? | AoE? |
|---|---|---|---|---|
| Saw Cleaver | 12 | — | — | ✓ |
| Saw Spear | 12 | — | — | ✓ |
| Hunter Axe | 12 | — | — | ✓ ✓ |
| Threaded Cane | 12 | — | — | ✓ |
| Kirkhammer | 12 | — | — | ✓ |
| Ludwig's Holy Blade | 12 | — | — | ✓ ✓ |
| Stake Driver | 12 | — | ✓ | ✓ |
| Rifle Spear | 12 | — | — | ✓ |
| Reiterpallasch | 12 | — | — | — |
| Tonitrus | 12 | — | — | ✓ |
| Beast Cutter ★ | **14** | — | — | ✓ ✓ |
| Amygdalan Arm | 12 | — | — | ✓ |
| Boom Hammer | 10 | — | — | ✓ |
| Beasthunter Saif | 12 | — | — | ✓ |
| Blade of Mercy | 12 | — | — | — |
| Burial Blade | 12 | — | — | ✓ ✓ |
| Chikage | 12 | — | ✓ ✓ ✓ | ✓ |
| Logarius' Wheel | 12 | — | ✓ ✓ | ✓ |
| Rakuyo | 12 | — | — | ✓ |
| Simon's Bowblade | 12 | — | — | — |
| Whirligig Saw | 12 | — | — | ✓ |
| Beast Claws | 12 | — | — | ✓ |
| Church Pick | 12 | — | — | ✓ |
| Holy Moonlight Sword ★ | **14** | ✓ ✓ | — | ✓ ✓ ✓ |
| Bloodletter | 12 | — | ✓ ✓ ✓ ✓ | ✓ ✓ |
| Kos Parasite | 12 | ✓ | — | ✓ ✓ ✓ |
| Hunter Torch | 8 | ✓ | — | ✓ |
| **TOTALS** | **315** | **4 legendary** | **10 self-harm weapons** | **varies** |

---

## Implementation Notes

### New Proc Requirements
Most weapon payoffs dispatch to existing generic template procs with custom parameters. The following weapons require **net-new proc code** beyond parameterizing existing templates:

- **Saw Lock / Serrated Snare / Crimson Tide / Exsanguinate** — Percentage-of-current blood drain mechanics (shared proc, different params)
- **Beast Cutter: Punishing Reach** — Reactive trigger on target movement away from attacker
- **Beasthunter Saif: Closing Lunge / Tactical Retreat / Disengaging Slash** — Attacker position manipulation (move self N tiles)
- **Blade of Mercy: Evasion Strike / Flowing Combo** — Conditional bonuses based on attacker's recent combat state
- **Rakuyo: Counter Dance / Evasive Riposte / Dueling Mastery** — Reactive triggers on target miss / attacker dodge
- **Simon's Bowblade: Mark Target / Sword Finisher** — Cross-form synergy (debuff from one form, exploit from other)
- **Whirligig: Pizza Cutter / Rev Up / Stalling Grind** — Integration with `saw_grind_tick` continuous damage system
- **HMS: Moonlight Wave / Lunar Cascade / Moonbeam** — Projectile finisher integration with existing projectile system
- **HMS: Phase Slash** — Parry/dodge bypass mechanic
- **Kos: Parasitic Drain** — Activate existing leeches for healing
- **Kos: Spawn** — Leech transfer on death
- **Tonitrus: Lightning Rod / Conducted Strike** — Conditional damage bonuses (metal armor check, wet check)
- **Church Pick: Confessional** — Intel reveal (show armor values)
- **Church Pick: Precision Extraction** — Remove bandages/sutures from target zone
- **Burial Blade: Phantom Step** — Temporary transparency + silent movement

### Shared Parameterized Procs (reuse generic backend)
These generic template procs cover the majority of payoffs with different parameters:
- `proc/payoff_stumble(target, duration)` — Covers all stumbling walk variants
- `proc/payoff_flinch(target)` — Force eyes closed
- `proc/payoff_camera_jerk(target, offset)` — Viewport snap
- `proc/payoff_frighten(target, duration)` — Mood debuff
- `proc/payoff_knockback(target, user, tiles)` — Push via `throw_at`
- `proc/payoff_pull(target, user, tiles)` — Pull via `throw_at`
- `proc/payoff_immobilize(target, duration)` — Brief `Immobilize()`
- `proc/payoff_offbalance(target, duration_ds)` — `OffBalance()`
- `proc/payoff_guard_break(target, duration)` — Armor class negated
- `proc/payoff_clickcd_debuff(target, percent, duration)` — Increase clickCD
- `proc/payoff_disarm(target, user)` — Modified disarm attempt
- `proc/payoff_swap_hands(target)` — Force hand swap
- `proc/payoff_daze(target, duration)` — Reverse WASD
- `proc/payoff_armor_damage(target, zone, percent)` — Reduce armor integrity %
- `proc/payoff_peel_reduce(target, zone, amount)` — Reduce peel threshold
- `proc/payoff_wound_escalate(target, zone, severity_increase)` — Wound severity +N
- `proc/payoff_aoe_damage(user, range, damage_mult, shape)` — Area damage
- `proc/payoff_execute_bonus(target, hp_threshold, max_bonus)` — Execute scaling
- `proc/payoff_counter_tempo(user, window, damage_mult)` — Reactive damage buff
- `proc/payoff_dodge_buff(user, percent, duration)` — Passive dodge bonus
- `proc/payoff_speed_buff(user, cd_reduction, attacks)` — ClickCD reduction
- `proc/payoff_slow(target, percent, duration)` — Movement speed debuff
- `proc/payoff_tunnel_vision(target, duration)` — Reduced view + chat disable
- `proc/payoff_multi_hit(target, user, extra_hits, damage_mult)` — Multi-hit finisher
- `proc/payoff_bleed_percent(target, percent_per_tick, duration)` — % blood drain
