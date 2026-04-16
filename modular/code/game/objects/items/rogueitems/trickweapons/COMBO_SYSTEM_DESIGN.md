# Trickweapon Combo System v3 -- Architecture Design Document

> **Last updated:** April 15, 2026 -- Added Combo Payoff System, Standardized Intent HUD Icons, Difficulty Tier 5 (Legendary).

---

## Philosophy

Trickweapons are **high-skill-ceiling weapons** that reward mastery through **true combo sequences**. Random button mashing -- ANY random button mashing, even varied inputs -- produces **floor damage**. Only executing defined combo sequences yields bonuses.

This is a martial-arts-style combo system: the weapon defines exactly which attack sequences are valid combos, what the finisher bonus is, and how difficult the execution is. Every combo is intentionally designed per weapon based on Bloodborne source data.

**Key design principles:**
- **30 unique comboable attacks per weapon.** Zero shared intents between weapons.
- **Each weapon is hand-crafted** with unique character, combos, and sound profiles.
- **R1 chains ARE the simplest combo** -- still flavorful with progressive sounds and scaling. The floor is random mashing that doesn't complete any defined sequence.
- **Grip variants (1H vs 2H) are truly unique intents**, not stat overrides. Players have greater manipulation than Bloodborne through wielded/unwielded states.
- **Specials remain untouched** on strong intent RMB -- a separate system entirely.
- **Lunges are purpose-built** on jump intent + MMB, with gap-closing propulsion and commitment risk.

---

## Attack Taxonomy (30 per weapon)

Every trick weapon defines exactly 30 unique attack intents:

| Category | Count | Form x Grip | Input | Intent Namespace Example |
|---|---|---|---|---|
| **Regular 1H** | 4 | Base unwielded | LMB (HUD-selected) | `/datum/intent/sawcleaver/base/slash` |
| **Regular 2H** | 4 | Base wielded | LMB (HUD-selected) | `/datum/intent/sawcleaver/base/grip_slash` |
| **Regular Tfm 1H** | 4 | Transformed unwielded | LMB (HUD-selected) | `/datum/intent/sawcleaver/tfm/sweep` |
| **Regular Tfm 2H** | 4 | Transformed wielded | LMB (HUD-selected) | `/datum/intent/sawcleaver/tfm/grip_sweep` |
| **Transform attacks** | 2 | Cross-form | Hold Space + LMB | `/datum/intent/sawcleaver/xfm/extend` |
| **Running attacks** | 4 | All form x grip | Run intent + LMB | `/datum/intent/sawcleaver/run/base_cut` |
| **Running transform** | 2 | Cross-form | Run + Hold Space + LMB | `/datum/intent/sawcleaver/runxfm/extend` |
| **Lunge attacks** | 4 | All form x grip | Jump intent + MMB on mob | `/datum/intent/sawcleaver/lunge/base_cut` |
| **Specials** | 2 | One per form | Strong intent RMB | (separate `/datum/special_intent/` system) |
| **Total** | **30** | | | |

**Regular intents** (16 total, 4 per form x grip) appear in the HUD and cycle via scroll wheel. They are:
1. **Light** (R1 chain) -- BCLASS_CUT, `combo_max` > 0, multi-hit chain with progressive sounds/damfactors
2. **Heavy** (R2) -- BCLASS_STAB or BCLASS_CHOP, single high-damage hit
3. **Blunt** (strike) -- BCLASS_BLUNT, for armor/stun situations
4. **Charged** (charged R2) -- BCLASS_CUT/CHOP with `chargetime > 0`, highest single-hit damage

**Extra intents** (12 total -- running/transform/lunge) are NOT in the HUD. They are auto-selected by `resolve_attack_intent()` based on player state, and lazily instantiated by `find_intent_on_weapon()` into `cached_extra_intents`.

---

## Standardized Intent HUD Icons

### Problem

Currently, each weapon shows its unique attack names in the HUD (e.g., "Quick Cut", "Serrated Thrust", "Cleaver Sweep"). This means players must memorize which named attack maps to which functional role on EVERY weapon they use. A combo recipe like "R1 → R1 → R2" requires knowing "Quick Cut is R1 and Serrated Thrust is R2 on Saw Cleaver" but "Thread Slash is R1 and Piercing Stab is R2 on Threaded Cane."

This doesn't scale across 26 weapons. Combo HUD readability requires universal shorthand.

### Solution: Uniform Slot Icons

All 4 HUD intent slots use the **same icon set** across every trickweapon. The slot position determines the functional role:

| HUD Slot | Icon Label | Role | Description |
|---|---|---|---|
| **Slot 1** | **R1** / Light | Light chain | The weapon's fast repeating attack. Always `combo_max > 0`. |
| **Slot 2** | **R2** / Heavy | Heavy single | The weapon's heavy single-hit attack. Higher damfactor, no chain. |
| **Slot 3** | **Strike** / Blunt | Blunt/impact | The weapon's blunt attack. Always `BCLASS_BLUNT`. |
| **Slot 4** | **Charged** / Power | Charged heavy | The weapon's charged attack. Always `chargetime > 0`. |

**The underlying attacks are still 100% unique per weapon.** Saw Cleaver's R1 is a quick horizontal cut. Threaded Cane's R1 is a precise downward strike. Kirkhammer's R1 is a swift sword slash. They look different, sound different, have different damfactors and blade classes. But the ICON is the same and the SLOT is the same.

### Why This Matters for Combos

Combo recipes become universally readable:
- "R1 → R1 → R2" means "light, light, heavy" on EVERY weapon
- "R1 → R1 → Transform → tR1" means the same cross-form combo on every weapon
- A player who masters Saw Cleaver combos can immediately READ (not necessarily execute identically) any other weapon's combo list

The combo HUD display (planned) can show combo sequences using these universal icons instead of weapon-specific attack names.

### Grip and Form Variants

When 2H gripped, the same 4 slots show the gripped versions with a subtle grip indicator overlay. When transformed, the transform form's 4 slots appear in the same positions:

| HUD Slot | Base 1H | Base 2H | Tfm 1H | Tfm 2H |
|---|---|---|---|---|
| Slot 1 | R1 | R1 (grip) | tR1 | tR1 (grip) |
| Slot 2 | R2 | R2 (grip) | tR2 | tR2 (grip) |
| Slot 3 | Strike | Strike (grip) | tStrike | tStrike (grip) |
| Slot 4 | Charged | Charged (grip) | tCharged | tCharged (grip) |

### Icon Asset Requirements

One DMI file with standardized intent icons:
- `r1` / `r1_grip` / `tr1` / `tr1_grip` — Light attack icons
- `r2` / `r2_grip` / `tr2` / `tr2_grip` — Heavy attack icons
- `strike` / `strike_grip` / `tstrike` / `tstrike_grip` — Blunt attack icons
- `charged` / `charged_grip` / `tcharged` / `tcharged_grip` — Charged attack icons
- Each needs an `_active` variant for the currently selected slot

Total: 32 icon states (16 types × 2 active/inactive).

### Implementation Note

This is a HUD display change only. Each `/datum/intent` gets a new `var/hud_icon_state` that's standardized to one of 16 values (slot × grip × form). The intent's `name` var remains descriptive ("Quick Cut", "Serrated Thrust") for tooltips and examine text. Only the icon in the combat HUD changes.

---

## Core Mechanic: Ring Buffer + Sequence Matching

### The Ring Buffer

Every attack appends its `combo_id` string to a ring buffer on the weapon:

```
combo_buffer = ["sc_b_slash", "sc_b_slash", "sc_b_thrust"]
                 ^ oldest                      ^ newest (just hit)
```

- Max length: `combo_buffer_max` (default 8). Oldest entries are trimmed via `.Cut(1, 2)`.
- ALL attack types feed into the buffer: regular, running, transform, lunge.
- Buffer persists across intent switches, form changes, and grip changes.

### Sequence Matching

After each attack, `check_combo_match()` scans `defined_combos` and checks if the **tail** of the buffer matches any combo's full sequence. Longest match wins (greedy).

```
Buffer:  [sc_b_slash, sc_b_slash, sc_b_thrust]
                                   |
                                   v
Combo "Saw Splice": [sc_b_slash, sc_b_thrust]         <- MATCH (tail 2 entries)
Combo "Deep Splice": [sc_b_slash, sc_b_slash, sc_b_thrust]  <- MATCH (tail 3, LONGER, wins)
```

**On match:** The completing hit gets the finisher bonus (damage mult + speed mult + optional sound). Buffer is cleared after consuming the combo.

**No match:** Floor damage. The intent's raw `damfactor` applies, no bonuses. This is what random mashing gets.

### Same-Intent Chains (R1 Chains)

When the same intent is repeated, `combo_index` advances through the intent's `combo_damfactors` and `combo_sounds` arrays. This provides:
- Progressive damage scaling (e.g., 1.0 -> 1.02 -> 1.04 -> 1.06 -> 1.09 for Saw Cleaver's 5-hit chain)
- Chain-specific sounds (1st hit, 2nd hit, etc.)

R1 chains ARE the simplest combo -- they're defined in `defined_combos` like everything else. For example, "Quick Chain" is 5x `sc_b_slash` with a 1.15x finisher on the 5th hit.

---

## Combo Definition Datum

```dm
/datum/trickweapon_combo
    var/name = "combo"              // Display name
    var/list/sequence               // Ordered list of combo_id strings
    var/finisher_dam_mult = 1.15    // Damage mult on the completing hit
    var/finisher_speed_mult = 1.0   // Clickcd mult on the completing hit (< 1 = faster recovery)
    var/list/finisher_sound         // Optional sound override for the finisher hit
    var/difficulty = 1              // 1=easy, 2=medium, 3=hard, 4=expert
```

Constructor: `New(_name, _sequence, _dam_mult, _speed_mult, _sound, _difficulty)`

Helper proc on the weapon:
```dm
/obj/item/rogueweapon/trickweapon/proc/add_combo(name, sequence, dam_mult, speed_mult, sound, difficulty)
```

### Difficulty Tiers

| Tier | Input Complexity | Typical Reward | Example |
|---|---|---|---|
| 1 (Easy) | Same intent repeated | 1.15x | Quick Chain (5x R1) |
| 2 (Medium) | Cross-intent within form | 1.2-1.3x + speed | Saw Splice (R1->R2), Rend Opener (R1->R1->xfm) |
| 3 (Hard) | Cross-form or lunge combo | 1.3-1.35x | Full Rend (R1->R1->xfm->tR1), Leaping Rend (lunge->xfm) |
| 4 (Expert) | Full form-cycle | 1.5x + speed | Reciprocating Rend (R1->xfm->tR1->unxfm->R1) |
| 5 (Legendary) | 8-10+ inputs, weapon-unique | Unique payoff effect | Mob Mentality (Hunter Torch, 10 inputs) |

---

## Intent Vars (on `/datum/intent`)

Each intent carries combo system metadata:

```dm
var/combo_id            // Unique string ID in the combo buffer (e.g., "sc_b_slash")
var/combo_category      // COMBO_CAT_LIGHT / HEAVY / THRUST / BLUNT (classification)
var/combo_max = 0       // Chain length for same-intent chaining (0 = no chain, e.g., charged R2)
var/list/combo_damfactors   // Per-chain-hit damage factors: list(1.0, 1.02, 1.04, ...)
var/list/combo_sounds       // Per-chain-hit swing sounds: list(list(snd1, snd2), list(snd3), ...)
```

---

## Weapon Vars (on `/obj/item/rogueweapon/trickweapon`)

### Core Combo Tracking

```dm
var/list/combo_buffer          // Ring buffer of combo_id strings
var/combo_buffer_max = 8       // Max buffer length
var/combo_index = 0            // Position in same-intent chain (0-indexed)
var/last_attack_time = 0       // world.time of last attack
var/last_intent_type           // Type path of last intent
var/datum/intent/last_intent_ref  // Cached last intent instance
var/datum/weakref/combo_target    // Weakref to combo target mob
var/list/defined_combos        // List of /datum/trickweapon_combo
```

### Zone Tracking

```dm
var/list/combo_zones_hit       // Parent zones hit this combo chain
var/combo_zone_bonus = 0       // Wound severity bonus from zone diversity
```

### Transform Attack Intents (Held Space + LMB)

```dm
var/list/transform_attack_intents           // 1H base->tfm type paths
var/list/transform_attack_gripped_intents   // 2H base->tfm type paths
var/list/untransform_attack_intents         // 1H tfm->base type paths
var/list/untransform_attack_gripped_intents // 2H tfm->base type paths
var/transform_key_held = FALSE              // Is Space currently held?
var/last_was_transform = FALSE              // Was last action a transform?
```

### Running Attack Intents (Run Intent + LMB, Auto-selected)

```dm
var/running_intent_base          // Type path: running attack for base 1H
var/running_intent_base_grip     // Type path: running attack for base 2H
var/running_intent_tfm           // Type path: running attack for tfm 1H
var/running_intent_tfm_grip      // Type path: running attack for tfm 2H
```

### Running Transform Attack Intents (Run + Held Space + LMB)

```dm
var/running_transform_intent     // Type path: running base->tfm transform attack
var/running_untransform_intent   // Type path: running tfm->base transform attack
```

### Lunge Attack Intents (Jump Intent + MMB on Mob)

```dm
var/lunge_intent_base            // Type path: lunge for base 1H
var/lunge_intent_base_grip       // Type path: lunge for base 2H
var/lunge_intent_tfm             // Type path: lunge for tfm 1H
var/lunge_intent_tfm_grip        // Type path: lunge for tfm 2H
```

### Internal State

```dm
var/list/cached_extra_intents    // Lazy cache: "[type_path]" -> instantiated datum
var/executing_lunge = FALSE      // Guard flag during lunge attack execution
```

---

## Attack Resolution Flow

### `resolve_attack_intent(user)` -- Priority System

When the player attacks, the weapon resolves which intent to actually use:

```
Priority 0: Lunge Bypass  (executing_lunge == TRUE)
    -> return used_intent as-is (already set by lunge_on_landing)

Priority 1: Running Transform Attack  (run intent + Space held + LMB)
    -> transform_weapon(), find running_transform/untransform_intent
    -> Fires transform attack sound, weapon changes form, attack executes

Priority 2: Transform Attack  (Space held + LMB, not running)
    -> transform_weapon(), find transform_attack_intents[1]
    -> Same as above but standing still

Priority 3: Running Attack  (run intent + LMB, no Space)
    -> find running_intent for current form x grip
    -> Auto-selected, player just attacks while running

Priority 4: Normal Attack  (default)
    -> user.used_intent (whatever the HUD shows)
```

### `find_intent_on_weapon(type_path, user)` -- Lazy Intent Cache

Running, transform, and lunge intents aren't in the HUD lists (`possible_item_intents` / `gripped_intents`), so they don't get instantiated by `update_a_intents()`. This proc:

1. Checks `user.possible_a_intents` first (for HUD intents that happen to match)
2. Falls back to `cached_extra_intents` -- an assoc list keyed by `"[type_path]"` -> datum instance
3. If cache miss, creates `new intent_type(user, src)` and stores it

Cache is cleared on `dropped()` to prevent stale mob references.

### `process_combo(target, user, intent)` -- Buffer Processing

Called by the `attack()` override after intent resolution:

1. **Timeout/target-switch check** -> full `reset_combo()` if window expired or target changed
2. **Same-intent chain tracking** -> advance `combo_index` through `combo_damfactors`/`combo_sounds`
3. **Buffer append** -> add `intent.combo_id` to ring buffer, trim to max
4. **Sequence matching** -> `check_combo_match()` finds longest matching combo
5. **Zone diversity** -> track unique parent zones via `check_zone()`, accumulate wound bonus
6. **Returns** `list(combo_sound, dam_mult, speed_mult)` for injection

### `attack(M, user)` -- Override

```
1. resolve_attack_intent()   -> get the correct intent
2. process_combo()           -> get combo bonuses
3. Cache original swingsound + damfactor on the intent
4. Inject combo values:  intent.damfactor *= dam_mult, intent.swingsound = combo_sound
5. Set user.used_intent = resolved intent (if different from HUD intent)
6. Call parent ..()          -> executes the actual attack with injected values
7. Restore originals        -> intent is back to normal for next hit
8. Apply speed mult         -> user.changeNext_move(reduced_cd) if combo gave speed bonus
```

---

## Lunge Attack System

### Input Chain

```
Player on jump intent -> MMB on living mob -> weapon in active hand
    -> COMSIG_MOB_MIDDLECLICKON fires
    -> on_owner_mmb() intercepts, returns COMSIG_MOB_CANCEL_CLICKON (blocks normal jump)
    -> INVOKE_ASYNC(execute_lunge)
```

### Execution

```dm
execute_lunge(user, target, lunge_intent):
    range = running ? LUNGE_RANGE_RUN (3) : LUNGE_RANGE (2)
    user.throw_at(target, range, speed=1, spin=FALSE, callback=lunge_on_landing)

lunge_on_landing(user, target, lunge_intent):
    if !adjacent(target):
        // MISSED -- penalty debuffs only, no damage
        user.OffBalance(LUNGE_OFFBALANCE)    // 20 ds
        user.Immobilize(LUNGE_IMMOBILIZE)    // 10 ds
        return
    // HIT -- execute attack with lunge intent
    executing_lunge = TRUE       // prevents resolve_attack_intent re-resolution
    user.used_intent = lunge_intent
    attack(target, user)         // goes through full combo processing
    user.used_intent = orig_intent
    executing_lunge = FALSE
    // Post-lunge debuffs (even on hit -- commitment cost)
    user.OffBalance(LUNGE_OFFBALANCE)
    user.Immobilize(LUNGE_IMMOBILIZE)
```

The lunge's `combo_id` feeds into the buffer like any other attack, enabling lunge-into-combo sequences (e.g., "Leaping Rend": lunge -> transform attack).

### Signal Registration

- `equipped()` -> `RegisterSignal(user, COMSIG_MOB_MIDDLECLICKON, on_owner_mmb)`
- `dropped()` -> `UnregisterSignal(user, COMSIG_MOB_MIDDLECLICKON)` + clear `cached_extra_intents`

---

## Transform Attack Input (Space Keybinding)

Handled in `keybinding_transform.dm`:

```
down(): transform_key_held = TRUE, start timer (TRANSFORM_HOLD_WINDOW = 4 ds)
up():   transform_key_held = FALSE (if timer hasn't fired yet)
Timer:  if transform_key_held still TRUE -> normal transform_weapon() (tap behavior)
LMB:    attack() sees transform_key_held -> resolve_attack_intent picks Priority 1 or 2
```

Transform attacks **change the weapon's form AND attack in one action**. The weapon transforms first (via `transform_weapon()`), then the attack executes with the cross-form transform attack intent.

---

## Combo Window and Reset

### Window Calculation

```dm
window = last_intent_ref.clickcd * COMBO_WINDOW_MULT  // default 2.0x
```

If no previous intent, uses the current intent's clickcd.

### Reset Conditions

| Condition | Effect |
|---|---|
| Timeout (window expires) | Full reset -- buffer, zones, index, tracking |
| Target switch (weakref mismatch) | Full reset |
| Weapon dropped | Full reset (via dropped()) |
| Death | Full reset (via dropped()) |
| Transform (Space tap, no attack) | `combo_index` resets to 0. Buffer/zones PRESERVED. |
| Grip change | Nothing resets -- free transition |
| Intent switch | `combo_index` resets to 0. Buffer/zones PRESERVED. |
| Combo match consumed | Buffer cleared after finisher hit |

---

## Zone Diversity Tracking

Tracks which parent zones have been hit in the current combo chain:

- Each attack, `check_zone(user.zone_selected)` collapses precise zones to 6 parent zones
- Each unique new zone adds `COMBO_ZONE_BONUS_PER` (0.05 = +5%) to `combo_zone_bonus`
- Bonus applies to wound severity (affects crit chance and wound stacking)
- Same-zone repeated = no penalty, just no bonus growth
- Resets with the full combo reset

---

## Sound Mapping

| Composite Pattern | System | Trigger |
|---|---|---|
| `r1_1st` -> `r1_5th` | Intent `combo_sounds` | Same-intent R1 chain progression |
| `r2` / `r2_charged` | Intent `swingsound` | Heavy/charged intent LMB |
| `r1-r2_followup` (+alts) | Combo `finisher_sound` | R1->R2 combo completion |
| `r2-r2_followup` | Combo `finisher_sound` | Heavy chain combo completion |
| `l1_transform_attack` (+alts) | Intent `swingsound` | Transform attack (hold Space+LMB) |
| `running_r1` / `running_r2` | Intent `swingsound` | Running attack intent |
| `running_r1_tr` / `running_r2_tr` | Intent `swingsound` | Running transform attack intent |
| `dodge_l1_transform` (+variants) | Intent `swingsound` | Running transform attack (alt sounds) |
| `backstep_r1` / `rolling_r1` | Intent `swingsound` | Lunge attack (repurposed for leap sounds) |
| `quickstep_r1` | Intent `swingsound` | Lunge attack (alt sounds) |
| Hit sounds (`*_hit*.ogg`) | Intent `hitsound` | Attack lands successfully |

**Sound selection priority in `get_combo_sound()`:**
1. Combo finisher sound (if a combo just completed)
2. Intent `combo_sounds[combo_index]` (if in a same-intent chain)
3. Intent `swingsound` (fallback)

---

## Saw Cleaver -- Reference Implementation

### 28 Unique Intents

All under `/datum/intent/sawcleaver/` namespace. BB motion values -> `damfactor` (MV / 100):

| Intent | combo_id | BB MV | damfactor | blade_class |
|---|---|---|---|---|
| **Base 1H** | | | | |
| Quick Cut (5-hit R1) | `sc_b_slash` | 100->109 | 1.0->1.09 | CUT |
| Serrated Thrust (R2) | `sc_b_thrust` | 120 | 1.2 | STAB |
| Saw Bash (blunt) | `sc_b_strike` | -- | BLUNT_DEFAULT | BLUNT |
| Ripping Slash (charged) | `sc_b_charged` | 190 | 1.9 | CUT |
| **Base 2H** | | | | |
| Power Cut (3-hit R1) | `sc_bg_slash` | -- | 1.05->1.12 | CUT |
| Driving Thrust (R2) | `sc_bg_thrust` | 125 | 1.25 | STAB |
| Crushing Bash (blunt) | `sc_bg_strike` | -- | BLUNT_DEFAULT | BLUNT |
| Goring Rip (charged) | `sc_bg_charged` | 190 | 1.9 | CUT |
| **Transformed 1H** | | | | |
| Cleaver Sweep (3-hit) | `sc_t_sweep` | 97->102 | 0.97->1.02 | CUT |
| Heavy Chop (R2) | `sc_t_chop` | 125 | 1.25 | CHOP |
| Pommel Strike (blunt) | `sc_t_strike` | -- | BLUNT_DEFAULT | BLUNT |
| Executioner's Cleave (charged) | `sc_t_charged` | 170 | 1.7 | CHOP |
| **Transformed 2H** | | | | |
| Great Sweep (3-hit) | `sc_tg_sweep` | -- | 1.0->1.08 | CUT |
| Brutal Chop (R2) | `sc_tg_chop` | 127 | 1.27 | CHOP |
| Handle Crush (blunt) | `sc_tg_strike` | -- | BLUNT_DEFAULT | BLUNT |
| Decapitating Cleave (charged) | `sc_tg_charged` | 170 | 1.7 | CHOP |
| **Transform Attacks** | | | | |
| Extending Slash | `sc_xfm_ext` | 130 | 1.3 | CUT |
| Retracting Cut | `sc_xfm_ret` | 130 | 1.3 | CUT |
| **Running** | | | | |
| Dashing Cut (base 1H) | `sc_run_b` | 109 | 1.09 | CUT |
| Charging Cut (base 2H) | `sc_run_bg` | 109 | 1.1 | CUT |
| Dashing Sweep (tfm 1H) | `sc_run_t` | 115 | 1.15 | CUT |
| Charging Sweep (tfm 2H) | `sc_run_tg` | 120 | 1.2 | CUT |
| **Running Transform** | | | | |
| Running Extend | `sc_rxfm_ext` | 130 | 1.3 | CUT |
| Running Retract | `sc_rxfm_ret` | 130 | 1.3 | CUT |
| **Lunge** | | | | |
| Leaping Cut (base 1H) | `sc_lng_b` | 140 | 1.4 | CUT |
| Plunging Cut (base 2H) | `sc_lng_bg` | 140 | 1.4 | CUT |
| Leaping Cleave (tfm 1H) | `sc_lng_t` | 130 | 1.3 | CHOP |
| Plunging Cleave (tfm 2H) | `sc_lng_tg` | 130 | 1.3 | CHOP |

### 14 Combos

| Combo | Sequence | Finisher | Speed | Diff |
|---|---|---|---|---|
| Quick Chain | 5x `sc_b_slash` | 1.15x | 1.0 | 1 |
| Saw Splice | slash -> thrust | 1.2x | 0.85 | 1 |
| Deep Splice | slash -> slash -> thrust | 1.25x | 0.8 | 2 |
| Rend Opener | slash -> slash -> xfm_ext | 1.3x | 1.0 | 2 |
| Full Rend | slash -> slash -> xfm_ext -> t_sweep | 1.35x | 0.85 | 3 |
| Cleaver Fury | 3x `sc_t_sweep` | 1.15x | 1.0 | 1 |
| Overhead Splice | sweep -> chop | 1.2x | 0.85 | 1 |
| Deep Overhead | sweep -> sweep -> chop | 1.25x | 0.8 | 2 |
| Snap Back | sweep -> xfm_ret -> b_slash | 1.3x | 0.85 | 2 |
| Reciprocating Rend | slash -> xfm_ext -> sweep -> xfm_ret -> slash | 1.5x | 0.75 | 4 |
| Butcher's Chain | bg_slash -> bg_thrust -> bg_charged | 1.3x | 1.0 | 2 |
| Great Cleave | 3x `sc_tg_sweep` | 1.15x | 1.0 | 1 |
| Running Opener | run_b -> xfm_ext | 1.25x | 1.0 | 2 |
| Leaping Rend | lng_b -> xfm_ext | 1.35x | 1.0 | 3 |

---

## Defines (in `_base.dm`)

```dm
#define COMBO_CAT_LIGHT   "light"
#define COMBO_CAT_HEAVY   "heavy"
#define COMBO_CAT_THRUST  "thrust"
#define COMBO_CAT_BLUNT   "blunt"

#define COMBO_WINDOW_MULT 2.0         // Window = last_intent.clickcd x this
#define COMBO_ZONE_BONUS_PER 0.05     // +5% wound severity per unique parent zone
#define TRANSFORM_HOLD_WINDOW 4       // 0.4s tap vs hold detection

#define LUNGE_RANGE 2                 // Lunge distance (tiles)
#define LUNGE_RANGE_RUN 3             // Lunge distance when running
#define LUNGE_OFFBALANCE 20           // OffBalance debuff duration (ds)
#define LUNGE_IMMOBILIZE 10           // Immobilize debuff duration (ds)
```

---

## Implementation Files

| File | Role |
|---|---|
| `code/game/objects/items/rogueweapons/intents.dm` | Base `/datum/intent` with `combo_id`, `combo_category`, `combo_sounds`, `combo_damfactors`, `combo_max` vars |
| `modular/.../trickweapons/_base.dm` | **All combo system logic**: combo datum, add_combo helper, ring buffer, process_combo, check_combo_match, get_combo_sound, reset_combo, resolve_attack_intent (4-priority), attack override, lunge system (signal hooks, throw_at, landing callback), find_intent_on_weapon (lazy cache), equipped/dropped signal management |
| `modular/.../trickweapons/keybinding_transform.dm` | Hold-to-prime: `down()` sets flag + timer, `up()` clears, timer falls back to normal transform |
| `modular/.../trickweapons/sawcleaver.dm` | **Reference weapon**: 28 unique intents, weapon definition with all v3 vars, 14 combo definitions in `Initialize()` |
| `modular/.../trickweapons/trickweapon_specials.dm` | Weapon specials -- **UNTOUCHED** by combo system, separate RMB path |
| `code/_onclick/item_attack.dm` | **NO CHANGES.** Combo system injects via the trickweapon `attack()` override, temporarily modifying intent vars before parent call. |

---

## Bonus Stacking Example

**Expert combo -- Reciprocating Rend (difficulty 4):**
```
R1 (sc_b_slash) -> R1 (sc_b_slash) -> xfm (sc_xfm_ext) -> tR1 (sc_t_sweep) -> unxfm (sc_xfm_ret) -> R1 (sc_b_slash)
```
Buffer after each hit:
```
[slash]
[slash, slash]
[slash, slash, xfm_ext]
[slash, slash, xfm_ext, t_sweep]
[slash, slash, xfm_ext, t_sweep, xfm_ret]
[slash, slash, xfm_ext, t_sweep, xfm_ret, slash]  <- matches Reciprocating Rend
```

Last hit = finisher: **1.5x damage + 0.75x clickcd recovery**.

Plus zones: if player targeted head, chest, arm, leg = 3 unique parent zones x 0.05 = **+15% wound severity**.

**Vs random masher:**
```
R1 (skull) -> R2 (skull) -> blunt (skull) -> charged (skull)
Buffer: [slash, thrust, strike, charged] -- matches NO defined combo
```
Each hit does its raw damfactor. Zero finisher bonus. Zero zone diversity. **Floor.**

---

## Data Source

All motion values, attack types, and combo chains are derived from `bloodborne_movesets_v2.xlsx` in the workspace root:
- **Sheet 1: Motion Values** -- Precise numeric damage multipliers per weapon per attack type (R1 chain, R2, Charged, Jump, Dash, Transform, Backstep)
- **Sheet 2: Wiki Attacks** -- Descriptive attack data from the Bloodborne wiki
- **Sheet 3: Fextralife Movesets** -- Move lists with damage percentages and stamina costs

Sound composites were extracted from Bloodborne audio files, composited per attack type, and deployed to `modular/sounds/trickweapons/<weapon>/`.

---

## Impact FX System -- Variable Hit Sounds + Visual Impact Effects

### Problem

The current combat system has **zero context-awareness for hit sounds or impact visuals**:
- Hit sound = `user.used_intent.hitsound` (always the same sound list regardless of target)
- Slashing plate armor sounds identical to slashing bare flesh
- No on-hit VFX exist at all -- only attacker-side weapon icon animations (`do_item_attack_animation`)
- Objects use a completely separate `play_attack_sound()` system
- Simple animals have no variable hit sounds
- Combo finishers have no audio/visual escalation on impact (only on swing)

### Architecture

The Impact FX system adds **target-aware hit sounds** and **visual impact effects** through the existing trickweapon `attack()` override. It uses the same temporary-mutation pattern already used for swing sounds and damfactor: inspect target before `..()`, swap `intent.hitsound`, restore after.

#### Integration Point

```
trickweapon attack() override:
    1. resolve_attack_intent()    -> get the correct intent
    2. process_combo()            -> get combo bonuses (sound, dam_mult, speed_mult)
    3. resolve_impact_fx()        -> NEW: select hit sound + VFX based on target & combo state
    4. Cache originals            -> swingsound, damfactor, AND hitsound
    5. Inject combo + impact values
    6. ..()                       -> parent attack chain executes with injected values
    7. Restore originals
    8. play_impact_vfx()          -> NEW: if hit landed (. == TRUE), show VFX at target
    9. Apply speed mult
```

This is non-invasive: **zero changes to `item_attack.dm` or `species.dm`**. Everything happens in `_base.dm`.

### Hit Sound Resolution -- Priority Chain

When determining what hit sound to play, the system checks these in order:

```
Priority 1: Combo finisher hit sound (combo.finisher_hitsound)
    -> Specific "big hit" sound for the finishing blow of a combo
    -> Loudest, most satisfying variant

Priority 2: Per-intent combo chain hit sound (intent.combo_hitsounds[combo_index])
    -> Progressive escalation through R1 chains (e.g., wet -> wetter -> meatiest)
    -> Falls through if not defined or combo_index == 0

Priority 3: Armor-reactive hit sound (target armor_class x blade_class)
    -> Human targets: check highest_ac_worn() to get armor tier
    -> Map blade_class -> damage category (slash/stab/blunt)
    -> Map armor_class -> armor tier (plate/chain/light)
    -> Select from existing sound/combat/hits/armor/ library
    -> ARMOR_CLASS_NONE -> weapon's flesh hitsound (intent.hitsound)

Priority 4: Target-type hit sound (simple animals, objects, turfs)
    -> Simple animals: weapon base hitsound (flesh sounds)
    -> Objects: material-based sound from existing onmetal/onwood/onstone/ libraries
    -> Turfs: same as objects

Priority 5: Intent base hitsound (fallback)
    -> Current default behavior, identical to vanilla
```

### Armor Sound Mapping

Using the existing `sound/combat/hits/armor/` library (23 files):

| Armor Class | + Slash (CUT/CHOP) | + Stab (STAB/PICK) | + Blunt |
|---|---|---|---|
| `ARMOR_CLASS_HEAVY` (3) | `plate_slashed` | `plate_stabbed` | `plate_blunt` |
| `ARMOR_CLASS_MEDIUM` (2) | `chain_slashed` | N/A* → `chain_slashed` | `chain_blunt` |
| `ARMOR_CLASS_LIGHT` (1) | `light_blunt`** | `light_stabbed` | `light_blunt` |
| `ARMOR_CLASS_NONE` (0) | weapon hitsound | weapon hitsound | weapon hitsound |

*No `chain_stabbed` files exist. Falls back to `chain_slashed`.
**No `light_slashed` files exist. Falls back to `light_blunt`.

Blade class -> Damage category mapping:
```
BCLASS_CUT, BCLASS_CHOP, BCLASS_LASHING -> "slash"
BCLASS_STAB, BCLASS_PICK, BCLASS_PIERCE -> "stab"
BCLASS_BLUNT, BCLASS_SMASH, BCLASS_PUNCH, BCLASS_PEEL -> "blunt"
```

### Armor Sound Mixing

When hitting armored targets, the system plays **both** the armor sound AND a quieter weapon flesh sound layered underneath. This gives each weapon a distinct "voice" even against plate:

```dm
// Primary: armor contact sound (loud)
playsound(target.loc, armor_sound, 100, FALSE, -1)
// Secondary: weapon flesh sound (quiet, muffled)
playsound(target.loc, intent.hitsound, 40, FALSE, -1)
```

For `ARMOR_CLASS_NONE`, only the weapon's flesh sound plays at full volume (current behavior).

### Visual Impact Effects

VFX are spawned at the target's location after a confirmed hit. The type and intensity scale with target armor and combo state.

#### VFX Categories

| VFX | When | Asset Source | Duration |
|---|---|---|---|
| **Blood Splash** | Flesh hit (no armor) | VFX Blood Batch 1, burst_splatter_001 | 3-5 frames |
| **Hit Spark** | Light/medium armor hit | directional_impact, hitsparkle lines | 3-4 frames |
| **Metal Clang** | Heavy armor hit | hitsparkle stars, retro impact effects | 3-5 frames |
| **Slash Arc** | Any cut/chop hit | 48x48 Shader Slash, Hack n Slash Slashes | 4-6 frames |
| **Dust Puff** | Blunt hit, lunge landing | Smoke sprites | 2-3 frames |

#### Combo Escalation

Combo finishers get enhanced VFX:

| Combo Tier | VFX Enhancement |
|---|---|
| No combo (floor) | Base VFX only |
| Easy (diff 1) | Base VFX |
| Medium (diff 2) | +10% size scale |
| Hard (diff 3) | +20% size scale, double overlay (layered) |
| Expert (diff 4) | +30% size, double overlay, brief screen flash |

### New Vars

On `/datum/trickweapon_combo`:
```dm
var/list/finisher_hitsound      // Hit sound override for the combo finisher
var/finisher_vfx_scale = 1.0    // VFX size multiplier for the finisher
```

On `/datum/intent` (optional per-intent overrides):
```dm
var/list/combo_hitsounds        // Per-chain-index hit sounds: list(list(snd), list(snd), ...)
var/list/armor_hitsound_slash   // Override armor hit for this intent (slash category)
var/list/armor_hitsound_stab    // Override armor hit for this intent (stab category)
var/list/armor_hitsound_blunt   // Override armor hit for this intent (blunt category)
```

On `/obj/item/rogueweapon/trickweapon`:
```dm
var/impact_fx_enabled = TRUE            // Master toggle
var/list/flesh_hitsound_override        // Weapon-level flesh sound override (all intents)
var/last_matched_combo                  // Cached combo result from process_combo for VFX use
```

### New Procs

On `/obj/item/rogueweapon/trickweapon`:

```dm
// Determine hit sound and VFX category based on target, intent, and combo state
proc/resolve_impact_fx(mob/living/target, mob/living/user, datum/intent/intent, datum/trickweapon_combo/combo)
    // Returns list(hitsound_list, vfx_category, vfx_scale)

// Map blade_class to damage category string
proc/get_blade_damage_category(blade_class)
    // Returns "slash", "stab", or "blunt"

// Get armor-reactive hit sound for a target
proc/get_armor_hitsound(mob/living/carbon/human/target, datum/intent/intent)
    // Returns list of sound files, or null for no-armor

// Spawn impact VFX at target location
proc/play_impact_vfx(mob/living/target, mob/living/user, vfx_category, vfx_scale)
    // Creates /obj/effect/temp_visual at target.loc
```

### Implementation Flow Example

**Player attacks armored human with Saw Cleaver R1->R1->R2 (Saw Splice combo, diff 1):**

1. `resolve_attack_intent()` -> R2 thrust intent
2. `process_combo()` -> combo matched "Saw Splice", dam_mult=1.2, speed=0.85
3. `resolve_impact_fx()`:
   - Target is human, `highest_ac_worn()` returns `ARMOR_CLASS_MEDIUM` (chain mail)
   - Blade class = `BCLASS_STAB`, maps to "stab"
   - No `chain_stabbed` -> falls back to `chain_slashed`
   - Combo has `finisher_hitsound` -> uses that instead
   - VFX = "hit_spark" (medium armor), scale = 1.0 (diff 1)
4. Inject: `intent.hitsound = combo.finisher_hitsound`, other combo values
5. `..()` -> attack executes, parent plays the injected hitsound
6. `play_impact_vfx()` -> spawns hit spark at target

**Player random-mashes different attacks on unarmored target:**

1. `resolve_attack_intent()` -> whatever HUD shows
2. `process_combo()` -> no combo match, dam_mult=1.0
3. `resolve_impact_fx()`:
   - Target is human, `highest_ac_worn()` returns `ARMOR_CLASS_NONE`
   - No armor -> weapon's base hitsound (flesh hit, unchanged from current)
   - VFX = "blood_splash" (no armor, flesh), scale = 1.0
4. No hitsound injection needed (same as current behavior)
5. `..()` -> attack executes normally
6. `play_impact_vfx()` -> spawns small blood splash

### VFX Technical Implementation

Impact VFX use the existing `/obj/effect/temp_visual` system with a **variety system** that mirrors how hitsounds work — each category has a list of variants, and a random one is picked on spawn.

#### Variety System

Each subtype defines a `var/list/variants` containing icon_state names. On spawn, `Initialize()` does `icon_state = pick(variants)` then `flick()`. If `variants` is null/empty, falls back to the default `icon_state` (backward compatible).

**DMI Naming Convention:** `[category]_[N]` — e.g. `blood_splash_1`, `blood_splash_2`, etc.

```dm
/obj/effect/temp_visual/impact_fx
    icon = 'modular/icons/effects/impact_fx.dmi'
    duration = 4
    layer = ABOVE_MOB_LAYER
    pixel_y = 8                   // Center on chest area
    var/list/variants             // Null = use default icon_state

/obj/effect/temp_visual/impact_fx/Initialize(mapload)
    . = ..()
    if(LAZYLEN(variants))
        icon_state = pick(variants)
    flick(icon_state, src)
```

#### Variant Counts Per Category (29 total states)

| Category | Variants | Source Assets | Duration |
|---|---|---|---|
| `blood_splash` | 9 (`blood_splash_1` – `_9`) | Hack n Slash Blood Batch 1 (9 GIFs) | 5 |
| `hit_spark` | 5 (`hit_spark_1` – `_5`) | Hack n Slash Hitsparkle Line series | 3 |
| `metal_clang` | 4 (`metal_clang_1` – `_4`) | Hack n Slash Hitsparkle Star series | 4 |
| `slash_arc` | 6 (`slash_arc_1` – `_6`) | Hack n Slash Slashes SimpleCombo/SimpleSmall | 3 |
| `dust_puff` | 5 (`dust_puff_1` – `_5`) | Hack n Slash SmokeFX Pro series | 5 |

> **Note:** `slash_arc` has 6 variants defined but is not currently assigned by `resolve_impact_fx()`. Reserved for future differentiation of slash vs stab on unarmored flesh targets.

#### Placeholder DMI Generator

`tools/gen_impact_vfx_dmi.py` generates a placeholder DMI with all 29 variant states as color-coded 32×32 frames. Run it to regenerate after adding/removing variants. The user replaces these with real sprites from the asset packs.

The DMI icon file (`impact_fx.dmi`) is created by the user from the sprite assets in:
- `D:\Hack n Slash Bundle Effects\` (Blood, Hitsparkle, Slashes, Smoke)
- `D:\Effect Asset Packs\` (Retro Impacts, Super Pixel Effects, VFX Blood Batch, 48x48 Slashes, Fire)

### Asset Library Summary

| Source Folder | Content | Best Use |
|---|---|---|
| `Hack n Slash\Blood\` | Blood splatter GIFs (small/med/large) | Flesh hits, dismemberment splashes |
| `Hack n Slash\Hitsparkle\` | Line + Star spark effects | Blade-on-armor sparks, stab impacts |
| `Hack n Slash\Slashes\` | Directional slash arcs (simple + combo) | Cut/chop swing trails, combo finisher slashes |
| `Hack n Slash\Smoke\` | Smoke puffs (62 spritesheet PNGs) | Lunge dust, blunt impact, dodge dust |
| `Effect Packs\Retro Impact Pack 1-5 (A-F)` | 30 retro impact spritesheets, each 6-8 frames | Star bursts, flares, ring shockwaves, crescent slashes, spike impacts -- MASSIVE variety |
| `Effect Packs\VFX Blood Batch 1` | 9 blood splash GIFs + spritesheets (3 layouts) | High-quality blood splatter on flesh hits |
| `Effect Packs\VFX Blood Concepts` | 8 concept FX-only PNGs (detailed gore splashes) | Reference for extreme hit splashes |
| `Effect Packs\Super Pixel Effects Gigapack` | Impacts (directional + symmetrical), Splatters, Smoke, Explosions, Lightning, Magic | Directional impacts for blade hits, burst splatters for big combo finishers |
| `Effect Packs\Super Pixel Effects Mini Pack 1` | Small red splatter, large brown impact shock | Quick flesh splatter, blunt concussion effect |
| `Effect Packs\48x48 Shader Slash` | 5 parts, 12 slashes each (60 total) -- shader-style colored arcs | Premium slash arcs for bladed weapons, combo escalation variants |
| `Effect Packs\48x48 Slash Free` | 12 simpler slash effects | Lighter slash arcs for basic hits |
| `Effect Packs\Pixel Fire Asset Pack v3.2` | Fire effects in 7 colors + smoke variants | Fire/arcane weapon specials, Tonitrus electric can be recolored |
| `Effect Packs\Shader Cylinder 64x96` | 5 parts -- cylinder/ring shockwave effects | Heavy blunt impact rings, charged attack release, expert combo finishers |
| `Effect Packs\Free\ (Parts 1-36)` | 36 parts of varied small FX effects on dark backgrounds | Miscellaneous particles, small sparkles, hit flares |
| `Effect Packs\Bullet Impact Explosion` | 5 colors (32x32 spritesheets) | Ranged impact effects, firearm trickweapon hits |

---

## Other Trickweapon Systems (Unchanged by v3)

These systems exist on `_base.dm` alongside the combo system but are separate:

- **Transformation system** -- `transform_weapon()` swaps all state vars between base/transformed forms. Includes spam detection (10 = warning, 30 = arm dismemberment).
- **Serrated damage** -- Signal-based bonus brute damage vs beasts/anthromorphs. Full bonus for werewolves/wildkin, half for halfkin/lamia/harpies.
- **Dual wielder bonuses** -- `dualwielder_force_bonus` / `dualwielder_wdefense_bonus` applied when holder has `TRAIT_DUALWIELDER`.
- **Anti-trickweapon defense** -- `anti_trickweapon_dodge_bonus` / `anti_trickweapon_parry_bonus` for weapons designed to counter other trickweapons.
- **Firearm hybrid** -- `consume_ammo()` / `intent_requires_ammo()` for gun-weapons (Reiterpallasch, Rifle Spear).
- **Weapon specials** -- Per-form `/datum/special_intent/` on strong intent RMB. Base special and transformed special cached and swapped on transform.

---

## Combo Payoff System -- Beyond Damage Multipliers

> **Status:** Design phase. All concepts and numbers pending vetting before implementation.
>
> **Additive:** This system layers ON TOP of the existing combo damage/speed multiplier system. Existing Saw Cleaver combos retain their current `finisher_dam_mult` and `finisher_speed_mult`. Payoffs are an ADDITIONAL effect that fires alongside the existing finisher bonus. A combo can have damage bonuses only, a payoff only, or both.

### Design Philosophy

The current combo system rewards mechanical execution with damage multipliers. This works, but damage alone doesn't break the dominant strategy of "spam the fastest attack that causes paralysis/bleed." Players optimize away from combos because one reliable attack repeated is safer than a complex sequence for marginally more damage.

**Combo payoffs solve this by making combos do things that raw damage can't.** A stumble, a weapon jar, a guard break — these create tactical openings that justify the risk of sequencing multiple attacks. The best payoffs **punish autopilot play and reward presence**: effects that a skilled player can mitigate but a button-masher cannot.

### How Players Die (Combat Meta Context)

Understanding the meta is critical for designing payoffs that matter:

| Death Vector | Mechanic | Dominant Attack Pattern |
|---|---|---|
| **Bleedout** | blood → 0 → O2 damage → death | Spam CUT attacks to stack bleeds |
| **Paralysis** | Skull crack / neck break → helpless | Spam BLUNT to head |
| **Burn** | Fire damage accumulation | Sustained fire source |
| **Toxin** | 200 total toxin kills | Poison application |
| **O2** | Suffocation (drowning, choking) | Grab + choke |
| **Decapitation** | CHOP to neck at wound threshold | CHOP to neck zone |

The problem: once a player identifies the fastest kill vector (usually bleedout via CUT spam or paralysis via BLUNT spam to skull), there's no reason to use other attacks. **Payoffs give reasons.**

### Integration with Existing Attack Override

```
trickweapon attack() override (UPDATED):
    1. resolve_attack_intent()
    2. process_combo()           -> returns combo match + dam_mult + speed_mult + PAYOFF INFO
    3. resolve_impact_fx()
    4. Cache originals
    5. Inject combo + impact values
    6. ..()                      -> parent attack executes
    7. Restore originals
    8. play_impact_vfx()
    9. Apply speed mult
   10. execute_payoff()          -> NEW: fire payoff effect if combo matched and hit landed
   11. apply_combo_cooldown()    -> NEW: put this combo on individual cooldown
```

Steps 10-11 are new. The payoff fires AFTER the finisher damage is confirmed (`. == TRUE` from parent). If the attack missed/was dodged/parried, no payoff fires.

### New Vars on `/datum/trickweapon_combo`

```dm
    var/payoff_type = null          // PAYOFF_* define string, or null for damage-only combo
    var/list/payoff_params = null   // Assoc list: param_name -> value (duration, severity, etc.)
    var/payoff_cooldown = 0         // Individual cooldown in deciseconds (0 = no cooldown)
    var/last_used = 0               // world.time of last successful payoff trigger
```

### New Procs on `/obj/item/rogueweapon/trickweapon`

```dm
// Execute the matched combo's payoff effect on the target
proc/execute_payoff(mob/living/target, mob/living/user, datum/trickweapon_combo/combo)
    if(!combo.payoff_type)
        return
    if(combo_on_cooldown(combo))
        filtered_balloon_alert(user, TRAIT_COMBAT_AWARE, "[combo.name] on cooldown")
        return
    // switch(combo.payoff_type) dispatches to individual payoff procs
    apply_combo_cooldown(combo)

// Check if a combo is currently on cooldown
proc/combo_on_cooldown(datum/trickweapon_combo/combo)
    return (combo.payoff_cooldown > 0) && (world.time < combo.last_used + combo.payoff_cooldown)

// Apply cooldown timestamp after successful payoff
proc/apply_combo_cooldown(datum/trickweapon_combo/combo)
    combo.last_used = world.time
```

### Extended `add_combo()` Helper

```dm
/obj/item/rogueweapon/trickweapon/proc/add_combo(name, sequence, dam_mult, speed_mult, sound, difficulty, payoff_type, payoff_params, payoff_cooldown)
```

New optional params: `payoff_type`, `payoff_params` (assoc list), `payoff_cooldown` (deciseconds). Existing calls without these params continue to work unchanged (damage-only combos).

---

### Core Foundation: Pressured → Visceral

The central combat loop that all combo payoffs feed into.

#### Pressured Status

| Property | Value |
|---|---|
| **Accumulator** | Hidden `pressure` var on `/mob/living` (0-100) |
| **Sources** | Combo finisher hits add pressure based on combo difficulty tier |
| **Threshold** | At 100, target becomes "Pressured" (visible status indicator) |
| **Decay** | Decays at ~5/second when not taking combo hits |
| **Duration** | Pressured state lasts 10 seconds, or until consumed by Visceral, payoff effect, or weapon special (see modular\code\game\objects\items\rogueitems\trickweapons\trickweapon_specials.dm for details) |
| **Indicator** | Visual overlay on target + combat-aware balloon alert to attacker |

Pressure accumulated per combo difficulty:

| Combo Diff | Pressure Added |
|---|---|
| 1 (Easy) | +15 |
| 2 (Medium) | +25 |
| 3 (Hard) | +35 |
| 4 (Expert) | +50 |
| 5 (Legendary) | +75 |

Non-combo hits (floor damage, random mashing) add **zero** pressure. This is THE incentive to combo.

#### Visceral Attack

When a target is Pressured, the attacker can perform a **Visceral Attack** — a high-damage execution move.
Attack is performed by RMB on strong intent while adjacent to the Pressured target. It consumes the Pressured status and resets pressure to 0. Untransformed specials are ALWAYS visceral finishers. The transformed special is reserved for more typical weapon special use, so it does not trigger visceral but can still be used while the target is Pressured and may even check for pressured when used. See modular\code\game\objects\items\rogueitems\trickweapons\trickweapon_specials.dm for details on how weapon specials interact with pressure/visceral.

| Property | Value |
|---|---|
| **Input** | RMB (strong intent) while adjacent to Pressured target |
| **Damage** | 2.5x the weapon's base force and 30% of current blood level. If blocked, dodged, or parried, we subtract 30% from targets current stamina. If connects but is blocked by armor, we subtract 30% from targets current armor integrity of the piece we hit. |
| **Effect** | Consumes Pressured status, resets pressure to 0 |
| **Animation** | Weapon-specific visceral flavortext + unique sound |
| **Cooldown** | 30-second personal cooldown |
| **Risk** | If Visceral misses (target dodges), attacker is locked in recovery (OffBalance 30ds) |

Visceral is the payoff for sustained combo pressure. It's not a one-combo kill — it takes multiple successful combos to build to threshold, then a deliberate execution input.

---

### Stacking Combo Cooldowns

#### Problem

Without cooldowns, the optimal strategy becomes "find the easiest combo with the best payoff and spam it." This is just one step above R1 spam.

#### Solution

Each combo has an individual `payoff_cooldown`. After a combo's payoff fires, that specific combo goes on cooldown. The DAMAGE multiplier still applies (executing the sequence still rewards you mechanically), but the payoff effect won't fire again until cooldown expires.

This forces players to **rotate through multiple combos** during a fight, using different payoffs situationally:
- Open with Guard Break combo → land a free hit through armor
- Follow with Stumble combo → prevent target from fleeing
- Target is now Pressured → Visceral execute

| Cooldown Tier | Duration | When |
|---|---|---|
| Short | 10-15s | Common/easy payoffs (Stumble, Camera Jerk, Foul Footing) |
| Medium | 20-30s | Moderate payoffs (Guard Break, Weapon Jar, Nerve Strike) |
| Long | 45-60s | Powerful payoffs (Joint Lock, Zone Lock, Fake Wound) |
| Extreme | 120s+ | Legendary payoffs (Mob Mentality) |

- payoff_cooldown also increases each time the combo is used by 10%, up to 20% if used twice in a row up to a max of 10 minutes. Cooldowns reset after sleeping. 

**Damage-only combos** (no payoff_type) have **no cooldown** and can be repeated: however,the damage multipliers will be reduced first by half after two consecutive uses (third use is half as effective) then to 0 when used a third time in a row. If players use a damage only combo a forth time in a row, the damage mult becomes inverse, lowering the damage of the attack to punish spamming a single move. Players always have a reason to combo even when payoff combos are on CD but shouldn't rely solely on just one damage only combo. (i.e. we don't want people just using R1-R1-R1-R1-R1-R1-R1-R1-R1-R1-R1 for the entire fight with no variation, but we also don't want to force them to use payoffs if they just want to do a pure damage build without the extra effects). Damage only combo cooldown does not reset after sleeping, but instead after 3 different combos of any type are used, to encourage combo variety. EVERY COMBO CAN BE USED AS A DAMAGE-ONLY COMBO, but only those with payoff_type will have the payoff effect and cooldown, when no payoff exists we default to damage-only behavior with no cooldown but with the stacking damage mult reduction to prevent spamming.

---

### Generic Payoff Catalog

These are reusable payoff procs that any weapon's combo can reference. Each is a standalone effect — the combo definition sets `payoff_type = PAYOFF_X` and optionally customizes `payoff_params`.

#### PAYOFF_VISOR_FLIP — Visor Flip

| Property | Value |
|---|---|
| **Effect** | Helmet Visor down → flip up. No visor → 30% current headgear integrity damage if not defended against. |
| **Duration** | Instant |
| **Counterplay** | Flip your visor back down (if you have one). Otherwise, just be mindful of your headgear integrity. |
| **Use Case** | Disorient target, expose them to follow-up headshots or just mess with their headgear durability. |
| **Pressure** | High (from combo difficulty + tactical opening) |
| **Suggested CD** | 30s (Long) |

#### PAYOFF_WIND — Wind
| Property | Value |
|---|---|
| **Effect** | Vision drop + 20% stamina drain increase for duration on hit. |
| **Duration** | 5 seconds |
| **Counterplay** | Block the attack |
| **Use Case** | Disorient target, increase their stamina management difficulty. |
| **Pressure** | Standard |
| **Suggested CD** | 15s (Short) |

#### PAYOFF_DAZE — Daze
| Property | Value |
|---|---|
| **Effect** | Reverse target's WASD movement |
| **Duration** | 5 seconds |
| **Counterplay** | Wait for effect to wear off or defend against the attack |
| **Use Case** | Disorient target, disrupt movement patterns |
| **Pressure** | Standard |
| **Suggested CD** | 20s (Medium) |

#### PAYOFF_FLINCH — Flinch
| Property | Value |
|---|---|
| **Effect** | 	Force target's eyes closed. Must click eye HUD button to reopen. |
| **Duration** | Instant, requires player interaction to reopen eyes |
| **Counterplay** | Click eye HUD button to reopen eyes |
| **Use Case** | Disorient target, interrupt actions |
| **Pressure** | Standard |
| **Suggested CD** | 20s (Medium) |

#### PAYOFF_LOOSE_GRIP — Loose Grip
| Property | Value |
|---|---|
| **Effect** | Force throw intent. Panic clicks may throw weapon |
| **Duration** | Instant |
| **Counterplay** | Turn off throw intent |
| **Use Case** | Disrupt target's weapon handling |
| **Pressure** | Standard |
| **Suggested CD** | 15s (Short) |

#### PAYOFF_CONFUSE_DEFENSE — Confuse Defense
| Property | Value |
|---|---|
| **Effect** | Swap passive defense: parry↔dodge |
| **Duration** | Instant |
| **Counterplay** | Swap back to original defense |
| **Use Case** | Disrupt target's defensive strategy |
| **Pressure** | Standard |
| **Suggested CD** | 15s (Short) |

#### PAYOFF_DISABLE_RMB — Disable RMB
| Property | Value |
|---|---|
| **Effect** | Disable right-click intents/abilities. For most cases, this prevents the use of certain abilities or actions tied to the right mouse button. For swift intent we just negate the CD decrease. For aimed intent we prevent both bait and negate the aimed intent passive benefits.|
| **Duration** | 5 seconds |
| **Counterplay** | Wait for effect to wear off or avoid using RMB abilities during the effect duration |
| **Use Case** | Disrupt target's ability usage, especially those reliant on RMB actions |
| **Pressure** | Standard |
| **Suggested CD** | 20s (Medium) |

#### PAYOFF_INCREASE_CD — Increase Cooldown
| Property | Value |
|---|---|
| **Effect** | +15-20% click CD on all target intents |
| **Duration** | 10 seconds |
| **Counterplay** | Wait for effect to wear off or defend against initial attack |
| **Use Case** | Decreases how fast the target can make attacks |
| **Pressure** | Standard |
| **Suggested CD** | 20s (Medium) |

#### PAYOFF_STUMBLE — Stumbling

| Property | Value |
|---|---|
| **Effect** | Target enters stumbling walk. Movement speed halved, cannot sprint. |
| **Duration** | 2-3 seconds (param: `duration`) |
| **Counterplay** | Can still attack, parry, dodge normally. Just can't run away. |
| **Use Case** | Prevent disengage. Punish hit-and-run. |
| **Pressure** | Standard (from combo difficulty) |
| **Suggested CD** | 12s (Short) |

#### PAYOFF_CAMERA_JERK — Camera Jerk

| Property | Value |
|---|---|
| **Effect** | Snap target's viewport toward attacker (96-128px offset via client.pixel_x/y), animate back to center over 0.5-1 sec. Cursor misalignment causes potential self-hits |
| **Duration** | 0.5-1 seconds |
| **Counterplay** | Brief, non-mechanical. Psychological disruption only. |
| **Use Case** | Can force the target to accidentally click themselves  |
| **Pressure** | Standard |
| **Suggested CD** | 8s (Short) |
| **Note** | Very funny, maybe we do this multiple times |

#### PAYOFF_FAKE_WOUND — Fake Wound
| Property | Value |
|---|---|
| **Effect** | Apply fake wound icon to random uninjured limb on target's medical HUD. If target tries to suture: they stab themselves (brute+pierce). Clears after 60 sec or after failed suture attempt
| **Duration** | 60 seconds or until target attempts to suture the fake wound |
| **Counterplay** | Don't suture the fake wound. It's a trap! |
| **Use Case** | Psychological warfare payoff. Can cause panic and self-harm if target isn't paying attention to their medical HUD. |
| **Pressure** | Standard |
| **Suggested CD** | 30s (Long) |
| **Note** | Funny |

#### PAYOFF_SPOOF_CRIT — Spoof Crit
| Property | Value |
|---|---|
| **Effect** | Fake arterial bleed hallucination — all visual/HUD warnings, zero actual bleed. We play the gamit of all bleed indicators—Sound of wound tearing, visual effects, progressive bleed status that lie and tell the player their stats are dropping, rapid drop of heart/blood level icon. Invisible status, clears after 20 secs |
| **Duration** | 20 seconds |
| **Counterplay** | Ignore visual/HUD warnings. It's a hallucination! |
| **Use Case** | Psychological warfare payoff. Can cause panic and self-harm if target isn't paying attention to their medical HUD. Can also coax target to yield thinking they're about to bleed out. |
| **Pressure** | Standard |
| **Suggested CD** | 60s (Very Long) |
| **Note** | Funny |

#### PAYOFF_FRIGHTEN — Frighten

| Property | Value |
|---|---|
| **Effect** | Target given a temporary mood debuff, which in turn can lower their fortune and thus their hit chance via the mood system. |
| **Duration** | 30 seconds |
| **Counterplay** | Can mitigate by using mood-enhancing items or fulfilling other conditions that improve mood. |
| **Use Case** | Apply pressure indirectly by lowering target's hit chance through mood manipulation. |
| **Pressure** | Standard |
| **Suggested CD** | 15s (Short) |
| **Note** | Targets the users fortune stat indirectly via the mood debuff |

#### PAYOFF_KNOCKBACK — Knockback
| Property | Value |
|---|---|
| **Effect** | Push target 1-2 tiles away. Wall collision = knockdown |
| **Duration** | Instant |
| **Counterplay** | Dodge or block to avoid being pushed. |
| **Use Case** | Control positioning and create opportunities for follow-up attacks. |
| **Pressure** | Standard |
| **Suggested CD** | 20s (Medium) |



#### PAYOFF_TRIP_UP — Trip Up

| Property | Value |
|---|---|
| **Effect** | Target put on run intent which can lead to a collision. |
| **Duration** | N/A, changes the target's movement behavior until they change intent or collide with an obstacle. |
| **Counterplay** | Swap intents |
| **Use Case** | Environmental awareness payoff. Devastating in cluttered terrain, useless in open fields. |
| **Pressure** | Standard; the collision knockdown adds separate bonus pressure |
| **Suggested CD** | 15s (Short) |
| **Note** | Leverages existing running collision mechanics (boulders, structures, mob tackles). |

#### PAYOFF_BLEED_BURST — Bleed Burst

| Property | Value |
|---|---|
| **Effect** | Reduce targets current blood level by 25% of the current blood level, not the max. Reduced effectives as target's blood level decreases. If blocked, dodge, or parried, we subtract 30% from targets current stamina. If connects but is blocked by armor, we subtract 30% from targets current armor integrity of the piece we hit. |
| **Duration** | Instant |
| **Counterplay** | Guard, dodge, or parry to mitigate effects. |
| **Use Case** | Blood = health, armor = second health bar, pressure = combo potential. |
| **Pressure** | Standard |
| **Suggested CD** | 25s (Medium) |

#### PAYOFF_GUARD_BREAK — Guard Break

| Property | Value |
|---|---|
| **Effect** | Target's armor class negated for the NEXT incoming hit (or 3 seconds, whichever first). |
| **Duration** | One hit or 3 seconds |
| **Counterplay** | Dodge/parry the follow-up. The break is announced visually. |
| **Use Case** | Counter heavy armor. Combo → Guard Break → clean stab through plate. |
| **Pressure** | Standard |
| **Suggested CD** | 20s (Medium) |

#### PAYOFF_DISORIENT — Disorient

| Property | Value |
|---|---|
| **Effect** | Target's left/right movement inputs swap for duration. |
| **Duration** | 2-3 seconds (param: `duration`) |
| **Counterplay** | Stand still and fight. Turning is the problem, not attacking. |
| **Use Case** | Punish retreat attempts. Devastating to runners, ignorable by aggressive fighters. |
| **Pressure** | Standard |
| **Suggested CD** | 20s (Medium) |

#### PAYOFF_WEAPON_JAR — Weapon Jar

| Property | Value |
|---|---|
| **Effect** | Procs modified version of /datum/intent/sword/disarm |
| **Duration** | Instant (weapon stays on ground until re-grabbed) |
| **Counterplay** | Re-grab immediately (~0.5s pickup). Otherwise contest dice rolls with wrestling skill and other disarm intent checks (minus those hook sword dependent) |
| **Use Case** | Disarming someone is very powerful, taking their weapon can easily end fights|
| **Pressure** | Standard |
| **Suggested CD** | 25s (Medium) |

#### PAYOFF_SWAP_HANDS — Swap Hands

| Property | Value |
|---|---|
| **Effect** | If target is wielding (2H), UNWIELD first. Then force-swap their active hand. |
| **Duration** | Instant (target must manually re-equip/re-wield) |
| **Counterplay** | Quick re-wield if you notice. Muscle memory test. |
| **Use Case** | Disrupt 2H users hard. They lose wield AND have weapon in wrong hand. |
| **Pressure** | Standard |
| **Suggested CD** | 20s (Medium) | 

#### PAYOFF_TUNNEL_VISION — Tunnel Vision

| Property | Value |
|---|---|
| **Effect** | Freeze target's chat/text input. Disable eye overlay (narrow visible area). Shrink view range. |
| **Duration** | 5-8 seconds (param: `duration`) |
| **Counterplay** | Can still fight and move normally. Can't coordinate with allies or see flankers. |
| **Use Case** | Information and coordination denial. Brutal in group fights. |
| **Pressure** | Standard |
| **Suggested CD** | 25s (Medium) |

#### PAYOFF_FAKE_Sunder — Fake Sunder

| Property | Value |
|---|---|
| **Effect** | ATTACKER gains visible fake sundered armor indicator, sound, and visual effects. If target attacks the seemingly sundered zone within window, attacker auto-counters at 1.5x damage with advantaged hit dice rolls. |
| **Duration** | 4 seconds or until trap triggers/expires |
| **Counterplay** | Don't take the bait. Attack a different zone. Or back off. |
| **Use Case** | Mind games. Trap that punishes aggressive responses to "weakness." |
| **Pressure** | Standard; counter-attack hit adds +20 extra pressure |
| **Suggested CD** | 30s (Long) |
| **Note** | Unique — payoff benefits the ATTACKER, not debuffs the target. |

#### PAYOFF_FOUL_FOOTING — Foul Footing

| Property | Value |
|---|---|
| **Effect** | 5 sec — each direction change has 40% chance for off-balance (not hard stun). Straight-line movement is safe |
| **Duration** | 5 seconds (param: `duration`) |
| **Counterplay** | Stand still, throw normal attacks (less accurately). Don't commit to lunges. |
| **Use Case** | Punish aggression without removing agency. You CAN fight back, just worse. |
| **Pressure** | Standard |
| **Suggested CD** | 15s (Short) |

#### PAYOFF_JAMMED_THUMB — Jammed Thumb
| Property | Value |
|---|---|
| **Effect** | 5 sec — target takes brute to weapon hand on every parry or attack|
| **Duration** | 5 seconds (param: `duration`) |
| **Counterplay** | Avoid parrying or attacking with the affected hand. |
| **Use Case** | Punish aggressive use of the weapon hand. |
| **Pressure** | Standard |
| **Suggested CD** | 20s (Medium) |

#### PAYOFF_FALSE_OPENING — False Opening

| Property | Value |
|---|---|
| **Effect** | Attacker enters "vulnerable" stance. If target attacks during window, attacker auto-dodges + free counter at 1.3x damage with advantaged hit dice rolls. If target doesn't bite, nothing happens. |
| **Duration** | 2 seconds |
| **Counterplay** | Don't attack the obvious opening. Wait it out. |
| **Use Case** | Mind games. Rewards patience, punishes panic. |
| **Pressure** | Counter-hit generates high pressure (+40) |
| **Suggested CD** | 25s (Medium) |

#### PAYOFF_COUNTER_TEMPO — Counter-Tempo

| Property | Value |
|---|---|
| **Effect** | If attacker takes a hit within 2 seconds, their NEXT attack deals 1.5x damage with advantaged hit dice rolls. |
| **Duration** | 2s window to take a hit, then 3s to use the buff |
| **Counterplay** | Don't attack the finisher user, or accept they'll hit back harder. |
| **Use Case** | Rewards staying aggressive after a combo instead of retreating. |
| **Pressure** | Buffed counter-attack adds +20 extra pressure |
| **Suggested CD** | 15s (Short) |

#### PAYOFF_CROWD_SCATTER — Crowd Scatter

| Property | Value |
|---|---|
| **Effect** | AoE pushback: all mobs within 1 tile of target pushed 1-2 tiles away. |
| **Duration** | Instant |
| **Counterplay** | Don't cluster. Space out in group fights. |
| **Use Case** | Anti-gangfight. Isolates your target. Creates 1v1 from a dogpile. |
| **Pressure** | Standard on primary; pushed mobs get +10 each |
| **Suggested CD** | 20s (Medium) |

#### PAYOFF_JOINT_LOCK — Joint Lock

| Property | Value |
|---|---|
| **Effect** | Disable one of target's arm limbs. Can't use items in that hand, can't wield 2H if offhand. Does not drop held items. |
| **Duration** | 3-5 seconds (param: `duration`) |
| **Counterplay** | Switch to offhand weapon. Use one-hand attacks. Wait it out. Grab weapon with free hand |
| **Use Case** | Surgical disruption of dual-wielders and shield users. Lock the shield arm or disable the fighter's primary weapon hand. |
| **Pressure** | Standard |
| **Suggested CD** | 30s (Long) |
| **Zone** | Targets arm matching `user.zone_selected` (left arm / right arm) |

#### PAYOFF_ZONE_LOCK — Zone Lock

| Property | Value |
|---|---|
| **Effect** | Target's zone selection locks to their current zone. Can't change target zones. |
| **Duration** | 5 seconds (param: `duration`) |
| **Counterplay** | Pre-set zone before getting locked. Or accept the constraint. |
| **Use Case** | Punish zone-dependent attackers. Locked on chest = can't snipe neck for decap. |
| **Pressure** | Standard |
| **Suggested CD** | 30s (Long) |

---

### Weapon-Specific Payoff Catalog

> **⚠ MOVED TO DEDICATED DOCUMENT:** The full per-weapon unique payoff catalog is now in **[WEAPON_PAYOFFS.md](WEAPON_PAYOFFS.md)**.
>
> **Philosophy change:** Generic payoffs are now **template mechanics only**. No weapon's combo should reference a generic define (`PAYOFF_STUMBLE`, etc.) directly. Every weapon gets 10–14 unique payoffs that are mechanically derived from the templates but themed to the weapon's Bloodborne identity with unique names, parameters, and layered effects. The generic payoff *procs* remain as shared backend code; weapon-specific defines dispatch to them with custom parameters.
>
> **315 total unique payoffs** across 27 weapons (4 legendary, 10 self-harm weapons). See WEAPON_PAYOFFS.md for the complete catalog with BB moveset references, implementation notes, and cross-reference tables.

#### ~~Saw Cleaver — Serrated Aggression~~ → See WEAPON_PAYOFFS.md

| Payoff | Define | Effect | Params | CD |
|---|---|---|---|---|
| **Serrated Rip** | `PAYOFF_SERRATED_RIP` | Bonus wound severity on targets with beast/anthromorph traits. Stacks with existing serrated damage system. | `severity_bonus`: +30% wound severity | 20s |
| **Saw Lock** | `PAYOFF_SAW_LOCK` | Next R1 chain inflicts percentage bloodloss based on current blood level (NOT MAX!!!), 10% each hit. Attacks must both: connect (not be blocked, parried, or dodged) and penetrate (not stopped by armor) If we dont penetrate through armor, attack current armor integrity instead, if it doesn't connect, we attack current stamina.| `percent_per_hit`: 10% of current blood amount (or armor integrity , or stamina amount), `duration`: length of next chain | 25s |

#### Saw Spear — Serrated Reach

> **NEW ENTRY** — Saw Spear exists in codebase but had no payoffs in the doc. Serrated both forms, transforms from sword to polearm (reach=2). Sister weapon to Saw Cleaver.

| Payoff | Define | Effect | Params | CD |
|---|---|---|---|---|
| **TBD** | — | Needs payoff design. Identity: serrated polearm — combines serrated bleed with reach advantage. Shares serrated family with Saw Cleaver but polearm transformed gives different combo routes. | — | — |

#### Hunter Axe — Aggressive Hooking

| Payoff | Define | Effect | Params | CD |
|---|---|---|---|---|
| **Tempo Surge** | `PAYOFF_TEMPO_SURGE` | Reduced clickCD on finisher hit. Next 2 attacks come out faster, rewarding aggressive follow-up. | `cd_reduction`: 30%, `attacks`: 2 | 20s |
| **Leg Hook** | `PAYOFF_LEG_HOOK` | Hook the back of target's leg with axe head. `throw_at` pull toward user + trip (brief OffBalance). | `pull`: 1 tile via `throw_at`, `offbalance`: 8ds | 25s |
| **Cleave Through** | `PAYOFF_CLEAVE_THROUGH` | Finisher hit cleaves in a 3x1 area. Hitting multiple targets applies damage to each. | `aoe_range`: 3x1 | 25s |
| **Spinning Cleave** | `PAYOFF_SPINNING_CLEAVE` | R2 finisher becomes a 360° spin attack around the user, hitting all adjacent targets. | `aoe_range`: 3x3 | 30s |

#### Threaded Cane — Range and Elegance

| Payoff | Define | Effect | Params | CD |
|---|---|---|---|---|
| **Lash Bind** | `PAYOFF_LASH_BIND` | Sticky Feet (heavy slowdown via `add_movespeed_modifier`) for 5 sec + pull target 1 tile toward attacker via `throw_at` | `duration`: 5s, `pull`: 1 tile | 20s |
| **Crack the Whip** | `PAYOFF_CRACK_WHIP` | Ranged 3x1 — 3x1 attack hits target and both adjacent tiles. | `aoe_range`: 3x1 | 15s |

#### Kirkhammer — Overwhelming Force

> **NOTE:** Use existing `throw_at` for knockback and existing structure knockdown mechanics. Don't reinvent the wheel.

| Payoff | Define | Effect | Params | CD |
|---|---|---|---|---|
| **Seismic Impact** | `PAYOFF_SEISMIC_IMPACT` | Ground slam staggers AoE in a 3x2 area in front of user. Short `OffBalance()` to those hit. Players in 3x1 range of user get damaged on top of stagger. | `aoe_range`: 3x2, `offbalance`: 10ds via `OffBalance()` | 25s |
| **Shove** | `PAYOFF_SHOVE` | If target is adjacent to wall/structure: bonus damage + forced push INTO wall via `throw_at`, triggering existing wall knockdown mechanics. | `bonus_mult`: 1.5 | 30s |

#### Ludwig's Holy Blade — Cascading Steel

| Payoff | Define | Effect | Params | CD |
|---|---|---|---|---|
| **Descending Cleave** | `PAYOFF_DESCENDING_CLEAVE` | Multi-hit finisher that targets 3 zones in sequence: head → chest → groin. Each hit rolls separately. Devastating if all connect. | `zones`: ["head", "chest", "groin"], `dmg_split`: [0.4, 0.35, 0.25] | 25s |
| **Holy Shockwave** | `PAYOFF_HOLY_SHOCKWAVE` | Greatsword slam AoE: 3x2 area in front of user. All targets in range take brute damage + brief OffBalance. `is_silver` bonus applies to undead in AoE. | `aoe_range`: 3x2, `offbalance`: 6ds | 30s |

#### Stake Driver — Explosive Commitment

| Payoff | Define | Effect | Params | CD |
|---|---|---|---|---|
| **Pile Bunker** | `PAYOFF_PILE_BUNKER` | Next transformation attack has 2× damage. Combo sets up the nuke. The setup→payoff IS the Stake Driver | `burst_mult`: 2 | 45s |
| **Blast Punt** | `PAYOFF_BLAST_PUNT` | Knockback target 2 tiles + apply 1 fire stack. | `knockback`: 2 tiles, `fire_stacks`: 1 | 25s |

#### Rifle Spear — Impale and Fire

| Payoff | Define | Effect | Params | CD |
|---|---|---|---|---|
| **Impale & Fire** | `PAYOFF_IMPALE_FIRE` | Pin target (brief immobilize) then auto-fire the spear's gun component. Overpen 1×3 line — primary: full damage, behind: 60%, furthest: 30% | `pin_dur`: 1s, `overpen_mults`: [1.0, 0.6, 0.3] | 25s |
| **Bayonet Twist** | `PAYOFF_BAYONET_TWIST` | Twist spear in wound. 15 sec: all wounds on that bodypart have severity increased by one tier. Aggravates existing damage | `wound_severity`: 1 level | 20s |

#### Reiterpallasch — Rapier Precision

| Payoff | Define | Effect | Params | CD |
|---|---|---|---|---|
| **Wrist Stab** | `PAYOFF_WRIST_STAB` | High-pen stab forced to target's weapon hand | `blade_class` BCLASS_PICK , `penfactor` 90 | 30s |
| **Point Blank** | `PAYOFF_POINT_BLANK` | Finisher seamlessly fires a bonus pistol shot at melee range. Free attack, costs ammo| `shots`: 1 | 20s |

#### Tonitrus — Electrical Devastation

> **STATUS: NEEDS REWORK.** Earlier brainstormed ideas preferred over Bolt Chain / Static Buildup. Burn damage causes extreme pain in-game and can end fights quickly — electric payoffs must be careful with BURN application. Circle back to earlier concepts.

| Payoff | Define | Effect | Params | CD |
|---|---|---|---|---|
| **TBD** | — | Revisit earlier brainstormed concepts. Must account for BURN pain severity. | — | — |

#### Beast Cutter — Rending Range

> **PRIORITY WEAPON** — Deserves extra unique payoffs and special attention.

| Payoff | Define | Effect | Params | CD |
|---|---|---|---|---|
| **Rending Pull** | `PAYOFF_RENDING_PULL` | Whip finisher drags target 1 tile toward attacker via `throw_at`. Closes distance on fleeing targets. | `pull_dist`: 1 tile via `throw_at` | 20s |
| **Serrated Snare** | `PAYOFF_SERRATED_SNARE` | Percentage-chunking bleed (like Saw Lock): drains % of target's current blood_volume per tick instead of flat wound. Also slows movement 20% while active. | `percent_per_tick`: 5% of current `blood_volume`, `slow`: 20% via `add_movespeed_modifier`, `duration`: 10s | 25s |
| **(Additional payoffs TBD)** | — | Beast Cutter should have more unique payoffs than most weapons. Brainstorm additional entries based on whip-form range control and serrated identity. | — | — |

#### Amygdalan Arm — Cosmic Horror

> **STATUS: NEEDS REWORK.** Current payoffs too generic. Reference Bloodborne source moveset for ideas. The weapon transforms from a blunt club into a long tentacle-arm — payoffs should lean into that grotesque cosmic horror identity.

| Payoff | Define | Effect | Params | CD |
|---|---|---|---|---|
| **TBD** | — | Redesign based on Bloodborne moveset. Tentacle reach, eldritch visual horror, cosmic dread. | — | — |

#### Boom Hammer — Ignition Burst

> **NOTE:** All trick weapon intents need ground-up rework. Boom Hammer doing BURN on every melee hit in transformed is too much. Lore: *"Crush the beasts, then burn them — the brute simplicity of the Boom Hammer was favored by hunters with an acute distaste for beasts."* It explodes; it doesn't leave trails.

| Payoff | Define | Effect | Params | CD |
|---|---|---|---|---|
| **Ignition Blast** | `PAYOFF_IGNITION_BLAST` | Finisher detonates fire AoE (3x2 area in front of user). All mobs in range take burn damage + fire stacks. Consumes the hammer's igniter charge. | `aoe_range`: 3x2, `fire_stacks`: 2 via `adjust_fire_stacks()` | 30s |

#### Beasthunter Saif — Gap Control

> **STATUS: NEEDS REWORK.** Reference Bloodborne source moveset. The Saif closes distance on base attacks and retreats on transformed — payoffs should amplify this aggressive/defensive gap control identity.

| Payoff | Define | Effect | Params | CD |
|---|---|---|---|---|
| **TBD** | — | Redesign around gap closer/disengager identity from Bloodborne moveset. | — | — |

#### Blade of Mercy — Speed Kills

> **STATUS: NEEDS REWORK.** Reference Bloodborne moveset. Blades of Mercy in BB was the quintessential speed/aggression weapon. Not true dual-wield in our codebase (single item representing dual state). Payoffs should reward rapid combo execution and relentless pressure.

| Payoff | Define | Effect | Params | CD |
|---|---|---|---|---|
| **TBD** | — | Redesign around speed, rapid attacks, CLICK_CD_RAPID, and aggression-rewarding mechanics. | — | — |

#### Burial Blade — Reaper's Craft

> **NOTE:** The Burial Blade is the granddaddy of all trick weapons in BB lore. Its power comes from the user's skill, not magic. Payoffs should reward clever play and weapon mastery, not arcane effects.

| Payoff | Define | Effect | Params | CD |
|---|---|---|---|---|
| **Reaper's Harvest** | `PAYOFF_REAPERS_HARVEST` | Bonus damage scaling with target's missing HP percentage. More hurt = more damage. Execute mechanic — rewards finishing wounded targets. | `max_bonus`: +50% at ≤25% HP | 25s |
| **Soul Rend** | `PAYOFF_SOUL_REND` | Drains target's stamina heavily via `stamina_add()`. Target exhausted — reduced defensive capability. | `stamina_drain`: 40 via `stamina_add()` | 25s |

#### Chikage — Blood Price

| Payoff | Define | Effect | Params | CD |
|---|---|---|---|---|
| **Blood Price** | `PAYOFF_BLOOD_PRICE` | Finisher damage scales with ATTACKER's missing HP. Risk/reward — you deal more damage the closer to death you are. | `max_bonus`: +80% at ≤20% HP | 20s |
| **Crimson Mist** | `PAYOFF_CRIMSON_MIST` | Blood AoE burst on finisher. All mobs within 1 tile of target take splash damage. Costs attacker HP to use. | `aoe_range`: 1, `self_cost`: 10 HP | 30s |

#### Logarius' Wheel — Fanatical Zeal

| Payoff | Define | Effect | Params | CD |
|---|---|---|---|---|
| **Zealot's Frenzy** | `PAYOFF_ZEALOTS_FRENZY` | Multi-hit finisher — the completing blow strikes 3 times rapidly instead of once. Each hit rolls damage separately. | `extra_hits`: 2 | 25s |
| **Martyr's Offering** | `PAYOFF_MARTYRS_OFFERING` | Sacrifice attacker HP for massive damage boost. Self-harm = more finisher damage. | `self_cost`: 15 HP, `bonus_mult`: 2.0 | 30s |

#### Rakuyo — Twin Dance

> **NOTE:** *"A trick sword that feeds not off blood, but instead demands great dexterity. Lady Maria was fond of this aspect."* Highest skill requirement in Bloodborne. Payoffs should greatly reward skill expression — the harder the combo, the bigger the reward. Multi-hits are a natural fit.

| Payoff | Define | Effect | Params | CD |
|---|---|---|---|---|
| **Twin Fang** | `PAYOFF_TWIN_FANG` | Finisher guarantees double-hit (two separate damage rolls). Second hit uses same intent but fresh dodge/parry check. Rewards landing difficult combos with devastating follow-through. | `second_hit_force_mult`: 0.8 | 20s |
| **Dancer's Grace** | `PAYOFF_DANCERS_GRACE` | Brief dodge bonus after finisher. +30% passive dodge for 3 seconds. Harder to punish after a combo. Rewards the dexterous fighting style. | `dodge_bonus`: 30%, `duration`: 3s | 20s |

#### Simon's Bowblade — Hybrid Marksman

> **STATUS: NEEDS REWORK.** Current bow implementation is unusual (long-range melee intents). Full rework needed to properly handle melee↔ranged form switching. Mark as needs re-evaluation closer to end of implementation priority.

| Payoff | Define | Effect | Params | CD |
|---|---|---|---|---|
| **TBD** | — | Redesign once bowblade form-switching is properly implemented. Payoffs should reward cross-form play. | — | — |

#### Whirligig Saw — Grinding Machine

> **STATUS: NEEDS SPECIAL ATTENTION.** The saw_grind_tick system already exists (0.5× force_dynamic per tick while held). 180° AoE concept is sound. Full rework needed for the grind-specific payoff.

| Payoff | Define | Effect | Params | CD |
|---|---|---|---|---|
| **Sawblade Burst** | `PAYOFF_SAWBLADE_BURST` | Finisher sends a burst of serrated damage in a 180° arc. All mobs in front of attacker within 1 tile take serrated damage. Uses existing `transformed_serrated` flag. | `arc`: 180°, `range`: 1 | 25s |
| **(Grind payoff TBD)** | — | Redesign the grind-mode payoff to integrate with existing `saw_grind_tick` system. | — | — |

#### Beast Claws — Feral Fury

> **NOTE:** Not truly dual-wielded (single item representing dual state via `dualwielder_force_bonus`). Payoffs should not assume two distinct weapons in hand. Check wiki for additional ideas.

| Payoff | Define | Effect | Params | CD |
|---|---|---|---|---|
| **Feral Frenzy** | `PAYOFF_FERAL_FRENZY` | Each successive hit in the completed combo retroactively increased attack speed. After finisher, next 3 attacks are 40% faster (reduced clickcd). | `cd_reduction`: 40%, `attacks`: 3 | 20s |
| **(Second payoff TBD)** | — | Bestial Howl was okay but needs refinement. Check BB wiki for Beast Claws moveset inspiration. | — | — |

#### Church Pick — Righteous Precision

> **CAUTION:** BCLASS_PICK bypasses nearly all armor crit protection lists and can one-shot through full plate on a lucky arterial crit. Use sparingly. `is_silver` already handles undead bonus — Righteous Verdict is redundant.

| Payoff | Define | Effect | Params | CD |
|---|---|---|---|---|
| **TBD** | — | Redesign. The pick's identity is precision through armor — payoffs should lean into targeted strikes, wound manipulation, or exploit BCLASS_PICK's penetration without making it even more lethal than it already is. `transformed_serrated=TRUE` for serrated synergy. | — | — |

#### Holy Moonlight Sword — Arcane Greatsword

> **SPECIAL CASE:** Max 1 per round (unless admin). Can afford to splurge on combo rewards. NO arcane damage type exists (only BRUTE/BURN/TOX/OXY/CLONE/STAMINA). Already has a projectile system (`burst_damage=25`, `projectile_cooldown=10s`). `is_silver=TRUE`. Needs special attention — give this weapon a truly unique and powerful payoff suite.

| Payoff | Define | Effect | Params | CD |
|---|---|---|---|---|
| **TBD** | — | Redesign with special attention. Leverage existing projectile system. Consider multi-hit, massive AoE, projectile enhancement, or unique mechanics befitting the rarest weapon. Use BRUTE or BURN — no arcane damage type. | — | — |

#### Bloodletter — Self-Destruction

> **NOTE:** General direction is good — self-harm for power is the Bloodletter identity. `transform_hp_cost=10` already exists. Check BB source for more ideas.

| Payoff | Define | Effect | Params | CD |
|---|---|---|---|---|
| **Blood Explosion** | `PAYOFF_BLOOD_EXPLOSION` | Self-harm AoE: attacker loses `blood_volume`, all mobs within 2 tiles take massive brute damage scaled to blood spent. More blood = more damage. | `self_cost`: 20 `blood_volume`, `aoe_range`: 2 | 45s |
| **Hemorrhage** | `PAYOFF_HEMORRHAGE` | All existing bleed wounds on target worsen by TWO severity tiers (`WOUND_SEVERITY` +2). Stronger Bleed Burst. | `tier_increase`: 2 via `WOUND_SEVERITY` system | 30s |

#### Parasite of Kos — Cosmic Leech

| Payoff | Define | Effect | Params | CD |
|---|---|---|---|---|
| **Budding** | `PAYOFF_BUDDING` | 3×1 spew in front of user. Covers target in 2+ leeches (ignore unleechable) | `aoe_range`: 3x1, `leeches`: 2 | 25s |
| **Vomit** | `PAYOFF_VOMIT` | 	3×2 spew — mild tox damage + mood debuff to targets. | `aoe_range`: 3x2, `tox_damage`: 20, `mood_debuff`: 1 | 30s |
|**Headbutt**| `PAYOFF_HEADBUTT` | Ram head into target — brute damage + attach a leech| `damfactor`: 1.5, `leeches`: 1 | 20s |

#### Hunter Torch — Funny

| Payoff | Define | Effect | Params | CD |
|---|---|---|---|---|
| **Mob Mentality** | `PAYOFF_MOB_MENTALITY` | **LEGENDARY (Diff 5, 10 inputs).** Target screams Hunter Torch voice lines involuntarily for 60 seconds. Uses the 23 existing torch voice OGG files. Random line every 10-50 seconds + on any attack or defensive action. Humiliation + position reveal. | `duration`: 60s, `interval`: 3-5s | 120s |

---

### Generic Payoff Summary Table

Quick reference for all generic payoffs with their define strings:

| # | Payoff Name | Define | Category | CD Tier |
|---|---|---|---|---|
| 1 | Stumbling | `PAYOFF_STUMBLE` | Movement denial | Short |
| 2 | Camera Jerk | `PAYOFF_CAMERA_JERK` | Screen disruption | Short |
| 3 | Frighten | `PAYOFF_FRIGHTEN` | Forced movement | Short |
| 4 | Trip Up | `PAYOFF_TRIP_UP` | Environmental | Short |
| 5 | Bleed Burst | `PAYOFF_BLEED_BURST` | Wound escalation | Medium |
| 6 | Guard Break | `PAYOFF_GUARD_BREAK` | Armor bypass | Medium |
| 7 | Disorient | `PAYOFF_DISORIENT` | Control inversion | Medium |
| 8 | Weapon Jar | `PAYOFF_WEAPON_JAR` | Disarm | Medium |
| 9 | Nerve Strike | `PAYOFF_NERVE_STRIKE` | Information denial | Medium |
| 10 | Swap Hands | `PAYOFF_SWAP_HANDS` | Equipment disruption | Medium |
| 11 | Tunnel Vision | `PAYOFF_TUNNEL_VISION` | Sense denial | Medium |
| 12 | Fake Wound | `PAYOFF_FAKE_WOUND` | Trap / mind games | Long |
| 13 | Foul Footing | `PAYOFF_FOUL_FOOTING` | Accuracy debuff | Short |
| 14 | False Opening | `PAYOFF_FALSE_OPENING` | Trap / counter | Medium |
| 15 | Counter-Tempo | `PAYOFF_COUNTER_TEMPO` | Reactive buff | Short |
| 16 | Crowd Scatter | `PAYOFF_CROWD_SCATTER` | AoE displacement | Medium |
| 17 | Joint Lock | `PAYOFF_JOINT_LOCK` | Limb disable | Long |
| 18 | Zone Lock | `PAYOFF_ZONE_LOCK` | Targeting denial | Long |

---

### Weapon-Specific Payoff Summary Table

> **See [WEAPON_PAYOFFS.md](WEAPON_PAYOFFS.md) for full details.** All 27 weapons now have complete unique payoff suites.

| # | Weapon | Payoffs | Legendary? | Identity Theme |
|---|---|---|---|---|
| 1 | Saw Cleaver | 12 | — | Serrated Aggression |
| 2 | Saw Spear | 12 | — | Serrated Reach |
| 3 | Hunter Axe | 12 | — | Aggressive Hooking |
| 4 | Threaded Cane | 12 | — | Range and Elegance |
| 5 | Kirkhammer | 12 | — | Overwhelming Force |
| 6 | Ludwig's Holy Blade | 12 | — | Cascading Steel |
| 7 | Stake Driver | 12 | — | Explosive Commitment |
| 8 | Rifle Spear | 12 | — | Impale and Fire |
| 9 | Reiterpallasch | 12 | — | Rapier Precision |
| 10 | Tonitrus | 12 | — | Voltaic Brutality |
| 11 | Beast Cutter ★ | **14** | — | Rending Range (PRIORITY) |
| 12 | Amygdalan Arm | 12 | — | Cosmic Horror |
| 13 | Boom Hammer | 10 | — | Ignition Burst |
| 14 | Beasthunter Saif | 12 | — | Gap Control |
| 15 | Blade of Mercy | 12 | — | Speed Kills |
| 16 | Burial Blade | 12 | — | Reaper's Craft |
| 17 | Chikage | 12 | — | Blood Price |
| 18 | Logarius' Wheel | 12 | — | Fanatical Zeal |
| 19 | Rakuyo | 12 | — | Twin Dance |
| 20 | Simon's Bowblade | 12 | — | Hybrid Marksman |
| 21 | Whirligig Saw | 12 | — | Grinding Machine |
| 22 | Beast Claws | 12 | — | Feral Fury |
| 23 | Church Pick | 12 | — | Righteous Precision |
| 24 | Holy Moonlight Sword ★ | **14** | ✓✓ | Arcane Greatsword (SPECIAL) |
| 25 | Bloodletter | 12 | — | Self-Destruction |
| 26 | Kos Parasite | 12 | ✓ | Cosmic Leech |
| 27 | Hunter Torch | 8 | ✓ | Funny |
| | **TOTALS** | **315** | **4** | |

---

### Payoff Assignment Guidelines

When assigning payoffs to specific combos on each weapon:

1. **Easy combos (diff 1-2)** should get either no payoff (damage-only, the current system) OR a low-impact payoff (Camera Jerk, Stumble, Foul Footing).
2. **Medium combos (diff 2-3)** get the weapon's generic payoff assignments (Guard Break, Weapon Jar, etc.).
3. **Hard combos (diff 3-4)** get the weapon's unique payoffs (weapon-specific catalog entries).
4. **Expert combos (diff 4)** get the weapon's BEST unique payoff, or the most powerful generic (Joint Lock, Zone Lock).
5. **Legendary combos (diff 5)** have one-of-a-kind payoffs (Mob Mentality). Only some weapons have these.

A weapon with 14 combos might assign payoffs like:
- 4 damage-only combos (R1 chains, simple cross-intent)
- 4 generic payoff combos (Stumble, Guard Break, etc.)
- 4 weapon-specific payoff combos (Serrated Rip, Saw Lock, etc.)
- 2 high-tier combos (expert generic or best weapon payoff)

This ensures every weapon has a progression: learn the simple combos for damage bonuses, master the complex ones for tactical payoffs.

---

### Implementation Priority

The payoff system should be implemented in this order:

1. **Phase 1: Core Foundation** — Pressured status, Visceral attack, combo cooldown tracking. These are the skeleton everything hangs on.
2. **Phase 2: Generic Payoff Procs** — Implement the 18 generic payoffs as modular procs in `_base.dm`. Each is `proc/payoff_[name](target, user, params)`.
3. **Phase 3: Combo Datum Extension** — Add `payoff_type`, `payoff_params`, `payoff_cooldown` to `/datum/trickweapon_combo`. Update `add_combo()` helper.
4. **Phase 4: Saw Cleaver Payoff Assignment** — Assign payoffs to the existing 14 Saw Cleaver combos as the reference implementation. Test and balance.
5. **Phase 5: Weapon-Specific Payoff Procs** — Implement the 52 weapon-specific payoffs (these can be done incrementally, weapon by weapon, as each weapon gets its v3 conversion).
6. **Phase 6: Legendary Combos** — Mob Mentality and any future legendaries. These require the most testing.

---

## Remaining Work

### Weapons Needing v3 Conversion (25 of 26)

Every weapon besides Saw Cleaver still uses placeholder/old intents. Each needs:
1. 28 unique intents under `/datum/intent/<weaponname>/` namespace
2. BB motion values -> damfactors from the spreadsheet
3. Sound composite mapping to all 28 intents
4. ~10-15 combo definitions based on BB combo routes + weapon character
5. All v3 vars set on the weapon definition (running/transform/lunge type paths)
6. **NEW:** Payoff assignments for combos (generic + weapon-specific)
7. **NEW:** Standardized `hud_icon_state` on all intents
8. **NEW:** Per weapon combo payoff flavor text feedback on completion (e.g. "The Saw Cleaver's serrated edge sends blood flying with a gruesome rip!")

### Standardized Intent Icons

- [ ] Create intent icon DMI with 32 icon states (16 types × active/inactive)
- [ ] Add `var/hud_icon_state` to `/datum/intent`
- [ ] Update HUD rendering to use `hud_icon_state` instead of per-intent custom icons
- [ ] Backfit Saw Cleaver's 16 regular intents with standardized icon states
- [ ] Document icon → slot mapping in each weapon's intent definitions

### Combo Payoff System

- [ ] **Phase 1:** Pressured status var on `/mob/living`, decay timer, threshold trigger, visual overlay
- [ ] **Phase 1:** Visceral attack input (RMB on Pressured target), damage calc, cooldown, whiff penalty
- [ ] **Phase 1:** Combo cooldown tracking (`payoff_cooldown`, `last_used` on combo datum)
- [ ] **Phase 2:** Generic payoff proc library (18 procs in `_base.dm`)
- [ ] **Phase 3:** Extend `/datum/trickweapon_combo` with `payoff_type`, `payoff_params`, `payoff_cooldown`
- [ ] **Phase 3:** Update `add_combo()` helper with optional payoff params
- [ ] **Phase 3:** `execute_payoff()` dispatcher in attack override (step 10)
- [ ] **Phase 4:** Assign payoffs to Saw Cleaver's 14 combos (reference implementation)
- [ ] **Phase 5:** Weapon-specific payoff procs (52 procs, built per-weapon during v3 conversion)
- [ ] **Phase 6:** Legendary combo implementations (Mob Mentality, future legendaries)

### Future Expansions

- **Combo HUD display** -- visual indicator of combo progress, finisher cues. Uses standardized intent icons for universal readability.
- **Special finisher enhancement** -- if a combo finisher intersects with special use, bonus effect
- **Pressure HUD** -- attacker-side pressure meter showing how close target is to Pressured state (combat-aware only)
