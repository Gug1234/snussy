#!/usr/bin/env python3
"""Generate sex_action_defaults.json — visceral, hand-crafted text per race.
Revenant = dullahan (physical undead, cold flesh, detachable head)."""
import json

def P(p_s,p_p,p_f,t_s,t_p,t_f,o_s,o_p,o_f):
    return {"performer":{"on_start":p_s,"on_perform":p_p,"on_finish":p_f},
            "target":{"on_start":t_s,"on_perform":t_p,"on_finish":t_f},
            "observer":{"on_start":o_s,"on_perform":o_p,"on_finish":o_f}}

with open("modular/code/datums/sexcon/strings/sex_action_defaults.json","r",encoding="utf-8") as f:
    existing = json.load(f)
humanoid = existing["humanoid"]

ACTIONS = list(humanoid.keys())  # all 28 action paths
RACE_DATA = {}  # race_name -> {action_path -> pso dict}


# ========== ANTHRO ==========
ant = {}
ant["/datum/sex_action/vaginal_sex"] = P(
    "[USER]'s [USIZE] [UCOCK] spreads [TARGET]'s [TVAG] apart, sinking inch by aching inch into slick heat.",
    "[USER] [FORCE] ruts [TARGET], fur bristling with each feral thrust.",
    "[USER]'s [USHAFT] slides free with a wet pop, slick and twitching.",
    "[TARGET]'s walls stretch taut around [USER]'s [USIZE] [USHAFT], a whimper caught in [TTHEIR] throat.",
    "[TARGET]'s cunt clenches and milks [USER]'s [UCOCK] with each bestial rut.",
    "[TARGET]'s folds clench around nothing as [USER] pulls free, dripping.",
    "[USER] buries [THEIR] [UCOCK] in [TARGET]'s [TVAG], fur pressed flush against skin.",
    "[USER] [FORCE] ruts into [TARGET] with feral intensity.",
    "[USER] pulls free of [TARGET], [USHAFT] glistening.")
ant["/datum/sex_action/vaginal_sex/double"] = P(
    "[USER] spreads [TARGET]'s [TVAG] wide with both shafts, stuffing [TTHEIR] cunt to the brim.",
    "[USER] [FORCE] double-stuffs [TARGET]'s cunt, both cocks grinding together inside.",
    "[USER] drags both slick cocks free, leaving [TARGET] gaping and trembling.",
    "[TARGET]'s [TVAG] is spread obscenely around [USER]'s twin shafts, stretched to [TTHEIR] limit.",
    "[TARGET]'s walls spasm helplessly around both of [USER]'s cocks.",
    "[TARGET]'s ruined cunt twitches as both cocks slide free.",
    "[USER] hilts both shafts into [TARGET]'s [TVAG].",
    "[USER] [FORCE] double-ruts [TARGET], both cocks pumping in tandem.",
    "[USER] pulls both slick cocks from [TARGET].")
ant["/datum/sex_action/anal_sex"] = P(
    "[USER]'s [UCOCK] presses against [TARGET]'s rim before sinking in, fur tickling skin.",
    "[USER] [FORCE] ruts [TARGET]'s ass, paws gripping [TTHEIR] hips hard enough to bruise.",
    "[USER]'s [USHAFT] slides free of [TARGET]'s ass with a wet sound.",
    "[TARGET]'s rim stretches around [USER]'s [USHAFT], burning as it spreads.",
    "[TARGET]'s guts clench around [USER]'s throbbing [USHAFT] with each punishing thrust.",
    "[TARGET]'s ass clenches shut as [USER]'s [UCOCK] pops free.",
    "[USER] mounts [TARGET] from behind, sinking in deep.",
    "[USER] [FORCE] ruts [TARGET]'s ass, fur matted with sweat.",
    "[USER] pulls out of [TARGET]'s rear, dripping.")
ant["/datum/sex_action/anal_sex/double"] = P(
    "[USER] forces both cocks into [TARGET]'s ass, stretching [THEM] around twin shafts.",
    "[USER] [FORCE] double-ruts [TARGET]'s ass, both cocks grinding mercilessly.",
    "[USER] drags both cocks free, leaving [TARGET]'s hole wrecked and twitching.",
    "[TARGET]'s rim is spread obscenely around [USER]'s twin cocks, guts bulging.",
    "[TARGET] squirms helplessly on both of [USER]'s shafts, stuffed to bursting.",
    "[TARGET]'s gaping hole clenches around nothing as [USER] withdraws.",
    "[USER] stuffs both cocks into [TARGET]'s rear.",
    "[USER] [FORCE] double-ruts [TARGET]'s ass with bestial fervor.",
    "[USER] pulls both shafts from [TARGET]'s wrecked hole.")
ant["/datum/sex_action/slit_sex"] = P(
    "[USER]'s [USIZE] [UCOCK] parts [TARGET]'s slit, the wet heat swallowing [THEIR] length whole.",
    "[USER] [FORCE] ruts [TARGET]'s slit, paws kneading into [TTHEIR] thighs.",
    "[USER]'s [USHAFT] slips free of [TARGET]'s slit, trailing a string of slick.",
    "[TARGET]'s slit spreads around [USER]'s [USIZE] [USHAFT], squeezing tight.",
    "[TARGET]'s slit milks [USER]'s [UCOCK], walls fluttering with each thrust.",
    "[TARGET]'s slit clenches as [USER]'s [USHAFT] pops free, leaving [THEM] empty.",
    "[USER] slides [THEIR] [USIZE] [UCOCK] into [TARGET]'s slit, burying deep.",
    "[USER] [FORCE] ruts [TARGET]'s slit with desperate urgency.",
    "[USER] pulls free of [TARGET]'s slit.")
ant["/datum/sex_action/slit_sex/double"] = P(
    "[USER] stuffs both cocks into [TARGET]'s slit, spreading it obscenely wide.",
    "[USER] [FORCE] double-stuffs [TARGET]'s slit, both shafts stretching it taut.",
    "[USER] drags both cocks free, [TARGET]'s slit left gaping and quivering.",
    "[TARGET]'s slit is pried apart by [USER]'s twin shafts, each one [USIZE].",
    "[TARGET]'s slit spasms around both of [USER]'s cocks, stretched paper-thin.",
    "[TARGET]'s slit twitches uselessly as both cocks pop free.",
    "[USER] forces both cocks into [TARGET]'s slit.",
    "[USER] [FORCE] double-ruts [TARGET]'s slit.",
    "[USER] withdraws both shafts from [TARGET]'s slit.")
ant["/datum/sex_action/throat_sex"] = P(
    "[USER] grips [TARGET]'s head with both paws and shoves [THEIR] [USIZE] [UCOCK] down [TTHEIR] throat.",
    "[USER] [FORCE] throat-fucks [TARGET], paws tangled in [TTHEIR] hair, musk overwhelming.",
    "[USER] pulls [THEIR] [USHAFT] free, a rope of drool connecting tip to [TARGET]'s lips.",
    "[TARGET]'s throat bulges visibly around [USER]'s [USIZE] [USHAFT], gagging wetly.",
    "[TARGET] gags and sputters around [USER]'s [UCOCK], drool running down [TTHEIR] chin.",
    "[TARGET] gasps for air as [USER]'s spit-slick [USHAFT] slides free.",
    "[USER] shoves [THEIR] [USIZE] [UCOCK] down [TARGET]'s throat.",
    "[USER] [FORCE] throat-fucks [TARGET], paws gripping tight.",
    "[USER] pulls free of [TARGET]'s throat.")
ant["/datum/sex_action/throat_sex/double"] = P(
    "[USER] pries [TARGET]'s jaw open and stuffs both cocks down [TTHEIR] throat!",
    "[USER] [FORCE] double throat-fucks [TARGET], jaw stretched painfully wide.",
    "[USER] pulls both spit-slick shafts free, drool pooling on the floor.",
    "[TARGET]'s jaw is forced wide around [USER]'s twin shafts, choking!",
    "[TARGET] chokes and gurgles on both of [USER]'s cocks, tears streaming.",
    "[TARGET] sputters and gasps as both cocks withdraw.",
    "[USER] stuffs both shafts into [TARGET]'s mouth.",
    "[USER] [FORCE] double throat-fucks [TARGET], muzzle flush to face.",
    "[USER] pulls both drool-slick cocks from [TARGET]'s mouth.")
ant["/datum/sex_action/double_penetration_sex"] = P(
    "[USER] sinks both cocks into [TARGET]'s holes, filling [THEM] completely.",
    "[USER] [FORCE] double-penetrates [TARGET], both holes stuffed by furred shafts.",
    "[USER] pulls both cocks free, leaving [TARGET] gaping from both ends.",
    "[TARGET]'s holes stretch around [USER]'s twin shafts, every inch of [THEM] stuffed.",
    "[TARGET] squirms between [USER]'s twin cocks, impaled and helpless.",
    "[TARGET] gasps as both cocks slide free, holes left gaping.",
    "[USER] double-penetrates [TARGET], burying both shafts.",
    "[USER] [FORCE] thrusts into both of [TARGET]'s holes.",
    "[USER] pulls out of [TARGET].")
ant["/datum/sex_action/vaginal_ride_sex"] = P(
    "[USER] straddles [TARGET] and drops [THEIR] hips, [UVAG] swallowing [TARGET]'s [TSIZE] [TCOCK] whole.",
    "[USER] [FORCE] rides [TARGET]'s [TCOCK], furred thighs clamped tight around [THEM].",
    "[USER] lifts off with a shudder, [TARGET]'s [TSHAFT] slipping free of [THEIR] soaked cunt.",
    "[TARGET]'s [TSIZE] [TCOCK] is swallowed by [USER]'s furred hips dropping down.",
    "[TARGET]'s [TSHAFT] throbs inside [USER]'s [UVAG], squeezed by furred walls.",
    "[TARGET]'s [TCOCK] slips free as [USER] lifts off, slick with wetness.",
    "[USER] mounts [TARGET]'s [TSIZE] [TCOCK], dropping [THEIR] hips down.",
    "[USER] [FORCE] rides [TARGET], fur bouncing with each thrust.",
    "[USER] dismounts [TARGET].")
ant["/datum/sex_action/anal_ride_sex"] = P(
    "[USER] drops [THEIR] ass onto [TARGET]'s [TSIZE] [TCOCK], taking it to the base with a grunt.",
    "[USER] [FORCE] bounces on [TARGET]'s [TCOCK], tail swishing with each drop.",
    "[USER] lifts off with a wet pop, [TARGET]'s [TSHAFT] slipping free.",
    "[TARGET]'s [TSIZE] [TCOCK] is squeezed by [USER]'s tight rear as [THEY] drop down.",
    "[TARGET]'s [TSHAFT] throbs inside [USER]'s ass, gripped like a vice.",
    "[TARGET]'s [TCOCK] slips free as [USER] lifts off, glistening.",
    "[USER] sits on [TARGET]'s [TSIZE] [TCOCK], tail hiked high.",
    "[USER] [FORCE] bounces on [TARGET]'s [TCOCK].",
    "[USER] lifts off of [TARGET].")
ant["/datum/sex_action/blowjob"] = P(
    "[USER] takes [TARGET]'s [TSIZE] [TCOCK] into [THEIR] muzzle, tongue coiling around the [TSHAFT].",
    "[USER] [FORCE] sucks [TARGET]'s [TCOCK], muzzle bobbing, tongue working the underside.",
    "[USER]'s muzzle pops off [TARGET]'s [TCOCK] with a wet smack.",
    "[TARGET]'s [TSIZE] [TCOCK] disappears into [USER]'s warm muzzle.",
    "[TARGET]'s [TSHAFT] throbs against [USER]'s rough tongue.",
    "[TARGET]'s [TCOCK] pops free, slick with spit.",
    "[USER] takes [TARGET]'s [TSIZE] [TCOCK] in [THEIR] muzzle.",
    "[USER] [FORCE] sucks [TARGET]'s [TCOCK], muzzle bobbing.",
    "[USER] pulls off [TARGET]'s [TCOCK].")
ant["/datum/sex_action/cunnilingus"] = P(
    "[USER] buries [THEIR] muzzle in [TARGET]'s [TVAG], rough tongue lapping hungrily!",
    "[USER] [FORCE] eats [TARGET] out, rough tongue dragging across every fold.",
    "[USER] pulls [THEIR] muzzle free, whiskers damp with [TARGET]'s slick.",
    "[TARGET]'s [TVAG] is pressed against [USER]'s rough, bestial tongue!",
    "[TARGET]'s folds quiver against the sandpaper drag of [USER]'s tongue.",
    "[TARGET] whimpers as [USER]'s tongue withdraws, leaving [THEM] aching.",
    "[USER] buries [THEIR] muzzle between [TARGET]'s thighs.",
    "[USER] [FORCE] eats [TARGET] out with feral enthusiasm.",
    "[USER] pulls away from [TARGET], muzzle slick.")
ant["/datum/sex_action/rimming"] = P(
    "[USER] spreads [TARGET]'s cheeks and presses [THEIR] rough tongue against [TTHEIR] hole!",
    "[USER] [FORCE] rims [TARGET], rough tongue probing deep.",
    "[USER] pulls [THEIR] tongue free, leaving [TARGET]'s rim twitching.",
    "[TARGET]'s hole twitches against the sandpaper texture of [USER]'s tongue!",
    "[TARGET]'s rear clenches around [USER]'s rough tongue, shuddering.",
    "[TARGET] shivers as [USER]'s tongue withdraws, hole left slick.",
    "[USER] buries [THEIR] muzzle in [TARGET]'s rear.",
    "[USER] [FORCE] rims [TARGET] with bestial enthusiasm.",
    "[USER] pulls away from [TARGET]'s rear.")

ant["/datum/sex_action/handjob"] = P(
    "[USER] wraps [THEIR] padded paw around [TARGET]'s [TSIZE] [TCOCK], paw-pads pressing into the [TSHAFT].",
    "[USER] [FORCE] strokes [TARGET]'s [TCOCK] with a padded grip, fur tickling sensitive skin.",
    "[USER] releases [TARGET]'s [TCOCK], paw-pads peeling away with a wet sound.",
    "[TARGET]'s [TSIZE] [TCOCK] twitches in [USER]'s warm, padded grip.",
    "[TARGET]'s [TSHAFT] throbs against [USER]'s soft paw-pads, pre leaking.",
    "[TARGET]'s [TCOCK] springs free as [USER]'s paw lets go.",
    "[USER] wraps [THEIR] paw around [TARGET]'s [TSIZE] [TCOCK].",
    "[USER] [FORCE] paw-jobs [TARGET]'s [TCOCK].",
    "[USER] releases [TARGET]'s [TCOCK].")
ant["/datum/sex_action/fingering"] = P(
    "[USER] slips [THEIR] clawed fingers into [TARGET]'s [TVAG], careful of [THEIR] nails!",
    "[USER] [FORCE] fingers [TARGET]'s cunt, clawed digits curling against [TTHEIR] walls.",
    "[USER] pulls [THEIR] slick claws from [TARGET]'s cunt, digits glistening.",
    "[TARGET]'s [TVAG] clenches around [USER]'s clawed fingers, feeling every ridge!",
    "[TARGET]'s walls grip [USER]'s fingers, the faint scratch of claws sending shivers up [TTHEIR] spine.",
    "[TARGET]'s cunt twitches as [USER]'s clawed fingers withdraw, dripping.",
    "[USER] fingers [TARGET]'s [TVAG] with careful claws.",
    "[USER] [FORCE] fingers [TARGET], claws curling inside.",
    "[USER] pulls [THEIR] claws from [TARGET].")
ant["/datum/sex_action/anal_fingering"] = P(
    "[USER] presses a clawed finger against [TARGET]'s rim, easing it inside!",
    "[USER] [FORCE] fingers [TARGET]'s ass, clawed digits probing deep.",
    "[USER] pulls [THEIR] claws free of [TARGET]'s ass, slick with lube.",
    "[TARGET]'s hole clenches around [USER]'s clawed finger, burning as it spreads!",
    "[TARGET]'s rear squeezes [USER]'s clawed fingers, the faint scrape making [THEM] whimper.",
    "[TARGET]'s hole twitches as [USER]'s claws withdraw.",
    "[USER] fingers [TARGET]'s rear with clawed digits.",
    "[USER] [FORCE] fingers [TARGET]'s ass with careful claws.",
    "[USER] pulls [THEIR] claws from [TARGET]'s rear.")
ant["/datum/sex_action/footjob"] = P(
    "[USER] presses [THEIR] paw against [TARGET]'s [TSIZE] [TCOCK], toe-beans squishing against the [TSHAFT].",
    "[USER] [FORCE] rubs [TARGET]'s [TCOCK] with [THEIR] paw, pads kneading the [TSHAFT].",
    "[USER] pulls [THEIR] paw away, paw-pads damp with pre.",
    "[TARGET]'s [TSIZE] [TCOCK] twitches under [USER]'s warm paw, beans pressing into skin.",
    "[TARGET]'s [TSHAFT] throbs against [USER]'s soft paw-pads.",
    "[TARGET]'s [TCOCK] springs free as [USER]'s paw lifts away.",
    "[USER] presses [THEIR] paw against [TARGET]'s [TSIZE] [TCOCK].",
    "[USER] [FORCE] gives [TARGET] a paw-job.",
    "[USER] pulls [THEIR] paw away from [TARGET].")
ant["/datum/sex_action/foot_lick"] = P(
    "[USER] drags [THEIR] rough tongue along [TARGET]'s foot, tasting salt and skin!",
    "[USER] [FORCE] licks [TARGET]'s foot, rough tongue dragging across [TTHEIR] sole.",
    "[USER] pulls [THEIR] tongue away, a string of spit connecting them.",
    "[TARGET]'s toes curl as [USER]'s rough, bestial tongue drags across [TTHEIR] sole!",
    "[TARGET]'s foot twitches against [USER]'s sandpaper tongue.",
    "[TARGET] shivers as [USER]'s tongue withdraws, sole left damp.",
    "[USER] licks [TARGET]'s foot with [THEIR] rough tongue.",
    "[USER] [FORCE] laps at [TARGET]'s foot.",
    "[USER] stops licking [TARGET]'s foot.")
ant["/datum/sex_action/facesitting"] = P(
    "[USER] drops [THEIR] furred hips onto [TARGET]'s face, smothering [THEM] in musk!",
    "[USER] [FORCE] grinds [THEIR] furred crotch on [TARGET]'s face, musk suffocating.",
    "[USER] lifts [THEIR] hips off [TARGET]'s face, leaving [THEM] gasping.",
    "[TARGET]'s face is smothered in [USER]'s warm, musky fur!",
    "[TARGET] can barely breathe under [USER]'s weight, face damp with sweat and musk.",
    "[TARGET] gulps air as [USER] lifts off, face matted with [USER]'s scent.",
    "[USER] sits on [TARGET]'s face, fur flush against skin.",
    "[USER] [FORCE] grinds on [TARGET]'s face, smothering [THEM].",
    "[USER] lifts off [TARGET]'s face.")
ant["/datum/sex_action/frotting"] = P(
    "[USER] presses [THEIR] [USIZE] [UCOCK] against [TARGET]'s [TSIZE] [TSHAFT], furred hips flush.",
    "[USER] [FORCE] frots against [TARGET], both cocks grinding slickly together.",
    "[USER] pulls [THEIR] [USHAFT] away, a strand of pre connecting their tips.",
    "[TARGET]'s [TSIZE] [TCOCK] twitches against [USER]'s [USHAFT], fur tickling skin.",
    "[TARGET]'s [TSHAFT] throbs against [USER]'s [UCOCK], pre mixing between them.",
    "[TARGET]'s [TCOCK] springs free as [USER] pulls away.",
    "[USER] presses [THEIR] [USIZE] [UCOCK] against [TARGET]'s [TSIZE] [TCOCK].",
    "[USER] [FORCE] frots against [TARGET], shafts grinding.",
    "[USER] pulls away from [TARGET].")
ant["/datum/sex_action/grinding"] = P(
    "[USER] grinds [THEIR] [UVAG] against [TARGET]'s [TVAG], wet heat meeting wet heat!",
    "[USER] [FORCE] grinds against [TARGET], both cunts sliding slickly together.",
    "[USER] pulls away, a string of mixed slick connecting them.",
    "[TARGET]'s [TVAG] presses against [USER]'s furred mound, heat radiating!",
    "[TARGET]'s cunt slides wetly against [USER]'s, both sets of lips tangled.",
    "[TARGET] whimpers as [USER] pulls away, leaving [THEM] aching and damp.",
    "[USER] grinds against [TARGET], furred hips rolling.",
    "[USER] [FORCE] grinds against [TARGET].",
    "[USER] pulls away from [TARGET].")
ant["/datum/sex_action/grind_body"] = P(
    "[USER] presses [THEIR] furred body against [TARGET], fur prickling against skin!",
    "[USER] [FORCE] rubs against [TARGET], warm fur dragging across [TTHEIR] body.",
    "[USER] pulls away, leaving [TARGET]'s skin tingling from the fur.",
    "[TARGET] feels [USER]'s warm, furred body press against [THEM], musk filling [TTHEIR] nose!",
    "[TARGET] shivers as [USER]'s fur drags across [TTHEIR] skin, the warmth intoxicating.",
    "[TARGET] feels the warmth fade as [USER] pulls away.",
    "[USER] grinds [THEIR] furred body against [TARGET].",
    "[USER] [FORCE] rubs against [TARGET], fur bristling.",
    "[USER] pulls away from [TARGET].")
ant["/datum/sex_action/spanking"] = P(
    "[USER] raises [THEIR] paw and brings it down on [TARGET]'s rear with a sharp crack!",
    "[USER] [FORCE] spanks [TARGET]'s ass, padded paw leaving red marks through [TTHEIR] skin.",
    "[USER] rests [THEIR] paw on [TARGET]'s reddened rear, kneading gently.",
    "[TARGET]'s rear stings from [USER]'s padded slap, a yelp escaping [TTHEIR] lips!",
    "[TARGET]'s butt burns from [USER]'s paw-strikes, skin turning crimson.",
    "[TARGET]'s rear throbs as [USER] stops, handprints visible.",
    "[USER] spanks [TARGET] with a padded paw.",
    "[USER] [FORCE] spanks [TARGET]'s butt, paw cracking.",
    "[USER] stops spanking [TARGET].")
ant["/datum/sex_action/force_titjob"] = P(
    "[USER] pushes [THEIR] [USIZE] [UCOCK] between [TARGET]'s [TBREASTTYPE], fur tickling [TTHEIR] skin.",
    "[USER] [FORCE] tit-fucks [TARGET], furred hips pumping between [TTHEIR] [TCUPSIZE] breasts.",
    "[USER] pulls [THEIR] [USHAFT] from [TARGET]'s cleavage, tip glistening with pre.",
    "[TARGET]'s [TBREASTTYPE] are spread by [USER]'s furred [UCOCK].",
    "[TARGET]'s [TCUPSIZE] breasts squeeze [USER]'s [USHAFT], fur bristling between them.",
    "[TARGET]'s breasts spring apart as [USER] pulls free.",
    "[USER] pushes [THEIR] [UCOCK] between [TARGET]'s [TCUPSIZE] breasts.",
    "[USER] [FORCE] tit-fucks [TARGET], furred hips pumping.",
    "[USER] pulls free of [TARGET]'s breasts.")
ant["/datum/sex_action/knot_grinding"] = P(
    "[USER] grinds [THEIR] swollen knot against [TARGET]'s entrance, pushing insistently!",
    "[USER] [FORCE] grinds [THEIR] knot into [TARGET], the fat bulge stretching [THEM] wider with each push.",
    "[USER]'s knot pops free with a wet schlop, leaving [TARGET] gaping.",
    "[TARGET] feels [USER]'s swollen knot pressing against [TTHEIR] entrance, threatening to pop inside!",
    "[TARGET] stretches around [USER]'s fat knot, a moan forced from [TTHEIR] lips.",
    "[TARGET] gasps as [USER]'s knot pops free with a wet sound, leaving [THEM] empty.",
    "[USER] grinds [THEIR] knot against [TARGET].",
    "[USER] [FORCE] knot-fucks [TARGET], the bulge popping in and out.",
    "[USER] pulls [THEIR] knot from [TARGET].")
ant["/datum/sex_action/masturbate"] = P(
    "[USER] wraps [THEIR] paw around [THEIR] own [USIZE] [UCOCK] and begins stroking.",
    "[USER] [FORCE] strokes [THEIR] [UCOCK], paw-pads working the [USHAFT] with practiced ease.",
    "[USER] releases [THEIR] [USHAFT], shaft twitching and slick.",
    "[TARGET] watches [USER] stroke [THEIR] [USIZE] [UCOCK] with [THEIR] own paw.",
    "[TARGET] watches [USER] [FORCE] pleasure [THEM]self, tongue lolling.",
    "[TARGET] watches as [USER] stops, [UCOCK] left twitching.",
    "[USER] begins stroking [THEIR] [USIZE] [UCOCK].",
    "[USER] [FORCE] paw-strokes [THEIR] own [UCOCK].",
    "[USER] stops masturbating.")
ant["/datum/sex_action/self_finger"] = P(
    "[USER] reaches between [THEIR] furred thighs and slips clawed fingers into [THEIR] own [UVAG].",
    "[USER] [FORCE] fingers [THEIR] own cunt, clawed digits curling inside, tail twitching.",
    "[USER] pulls [THEIR] slick claws free, panting.",
    "[TARGET] watches [USER] finger [THEIR] [UVAG] with clawed digits, tail swishing.",
    "[TARGET] watches [USER] [FORCE] finger [THEIR] own cunt, claws dripping.",
    "[TARGET] watches as [USER] stops, claws glistening.",
    "[USER] begins fingering [THEIR] [UVAG] with clawed digits.",
    "[USER] [FORCE] fingers [THEIR] own cunt.",
    "[USER] stops fingering [THEM]self.")
RACE_DATA["anthro"] = ant


# ========== HELPER: clone anthro with find/replace for body-part theming ==========
def retheme(base, replacements):
    """Deep-copy a preset dict, applying text replacements for race theming."""
    out = {}
    for action_path, pso in base.items():
        entry = {}
        for perspective, phases in pso.items():
            ph = {}
            for phase, txt in phases.items():
                t = txt
                for old, new in replacements:
                    t = t.replace(old, new)
                ph[phase] = t
            entry[perspective] = ph
        out[action_path] = entry
    return out



# ========== TAURIC ==========
# Four-legged beast body, humanoid torso. Emphasis on weight, hooves, barrel chest.
tau = retheme(ant, [
    ("paw", "hoof"), ("paws", "hooves"), ("paw-pads", "calloused palm"),
    ("padded", "rough"), ("beans", "sole"), ("toe-beans", "hoof"),
    ("muzzle", "mouth"), ("rough tongue", "tongue"), ("fur ", "hide "),
    ("furred", "hide-covered"), ("tail swishing", "tail flagging"),
    ("tail hiked high", "tail flagging behind [THEM]"),
    ("musk", "animal musk"), ("bestial", "brutish"),
])
# Override ride actions — taurics are hard to ride, text should reflect the size
tau["/datum/sex_action/vaginal_ride_sex"] = P(
    "[USER] backs [THEIR] massive hindquarters over [TARGET] and drops, [TSIZE] [TCOCK] disappearing into [THEIR] [UVAG].",
    "[USER] [FORCE] rocks [THEIR] enormous body back against [TARGET], each motion shaking the ground.",
    "[USER] lurches forward, [TARGET]'s [TSHAFT] slipping free with a wet sound, hooves clattering.",
    "[TARGET]'s [TSIZE] [TCOCK] is swallowed by [USER]'s immense body bearing down on [THEM].",
    "[TARGET] can barely breathe under [USER]'s weight, [TSHAFT] squeezed mercilessly.",
    "[TARGET]'s [TCOCK] pops free as [USER] shifts forward, slick and spent.",
    "[USER] backs onto [TARGET]'s [TSIZE] [TCOCK], massive body eclipsing [THEM].",
    "[USER] [FORCE] rocks back on [TARGET], the ground trembling.",
    "[USER] pulls forward off [TARGET].")
tau["/datum/sex_action/anal_ride_sex"] = P(
    "[USER] backs onto [TARGET]'s [TSIZE] [TCOCK], massive hindquarters swallowing [THEM] whole.",
    "[USER] [FORCE] rocks back against [TARGET], hooves scraping stone with each movement.",
    "[USER] lurches forward, [TARGET]'s [TSHAFT] popping free.",
    "[TARGET]'s [TSIZE] [TCOCK] vanishes into [USER]'s massive rear.",
    "[TARGET]'s [TSHAFT] throbs inside [USER], crushed by the beast's weight.",
    "[TARGET]'s [TCOCK] slips free as [USER] moves away.",
    "[USER] backs onto [TARGET]'s [TSIZE] [TCOCK], pinning [THEM] under [THEIR] bulk.",
    "[USER] [FORCE] grinds back on [TARGET].",
    "[USER] moves off [TARGET].")
RACE_DATA["tauric"] = tau


# ========== LAMIA ==========
# Snake from the waist down. Coils, scales, forked tongue, no legs.
lam = retheme(ant, [
    ("paw", "hand"), ("paws", "hands"), ("paw-pads", "palm"),
    ("padded", "scaled"), ("beans", "fingers"), ("toe-beans", "fingers"),
    ("muzzle", "mouth"), ("rough tongue", "forked tongue"),
    ("fur ", "scales "), ("furred", "scaled"), ("fur,", "scales,"),
    ("tail swishing", "tail coiling"), ("tail hiked high", "tail curling tight"),
    ("musk", "serpentine musk"), ("bestial", "serpentine"),
])
# Override footjob — lamias have no feet, use tail instead
lam["/datum/sex_action/footjob"] = P(
    "[USER] coils [THEIR] muscular tail around [TARGET]'s [TSIZE] [TCOCK], cool scales pressing against hot skin.",
    "[USER] [FORCE] squeezes [TARGET]'s [TCOCK] with [THEIR] tail, coils rippling along the [TSHAFT].",
    "[USER] uncoils [THEIR] tail, scales peeling away from [TARGET]'s slick [TCOCK].",
    "[TARGET]'s [TSIZE] [TCOCK] twitches in the crushing grip of [USER]'s scaled coils.",
    "[TARGET]'s [TSHAFT] throbs against [USER]'s squeezing tail, pre beading at the tip.",
    "[TARGET]'s [TCOCK] springs free as [USER]'s tail loosens.",
    "[USER] wraps [THEIR] tail around [TARGET]'s [TSIZE] [TCOCK].",
    "[USER] [FORCE] tail-strokes [TARGET]'s [TCOCK].",
    "[USER] releases [TARGET]'s [TCOCK] from [THEIR] coils.")
lam["/datum/sex_action/foot_lick"] = P(
    "[USER] drags [THEIR] forked tongue along the length of [TARGET]'s tail, tasting salt and scale.",
    "[USER] [FORCE] laps at [TARGET]'s body, forked tongue flickering across skin.",
    "[USER] pulls [THEIR] tongue away, a strand of spit glistening.",
    "[TARGET] shivers as [USER]'s forked tongue drags along [TTHEIR] skin.",
    "[TARGET]'s skin prickles under the wet, split tip of [USER]'s tongue.",
    "[TARGET] feels the cool air as [USER]'s tongue withdraws.",
    "[USER] licks [TARGET] with [THEIR] forked tongue.",
    "[USER] [FORCE] laps at [TARGET].",
    "[USER] stops licking [TARGET].")
lam["/datum/sex_action/facesitting"] = P(
    "[USER] coils around [TARGET]'s head, pulling [TTHEIR] face into [THEIR] crotch, scales pressing against skin.",
    "[USER] [FORCE] grinds against [TARGET]'s face, coils tightening around [TTHEIR] head.",
    "[USER] loosens [THEIR] coils, letting [TARGET] gasp for air.",
    "[TARGET]'s face is smothered in [USER]'s scaled coils, cool skin pressing against [TTHEIR] mouth.",
    "[TARGET] can barely breathe in the crushing grip of [USER]'s serpentine body.",
    "[TARGET] gulps air as [USER]'s coils loosen.",
    "[USER] coils around [TARGET]'s head, smothering [THEM].",
    "[USER] [FORCE] grinds on [TARGET]'s face, coils squeezing.",
    "[USER] loosens [THEIR] coils off [TARGET].")
RACE_DATA["lamia"] = lam


# ========== DRIDER ==========
# Spider lower body, humanoid torso. Spinnerets, chitin, multiple eyes, mandibles.
dri = retheme(ant, [
    ("paw", "chitinous hand"), ("paws", "chitinous hands"), ("paw-pads", "hard palm"),
    ("padded", "chitinous"), ("beans", "fingers"), ("toe-beans", "claw"),
    ("muzzle", "mandibles"), ("rough tongue", "thin tongue"),
    ("fur ", "chitin "), ("furred", "chitinous"), ("fur,", "chitin,"),
    ("tail swishing", "spinnerets twitching"), ("tail hiked high", "abdomen raised"),
    ("tail ", "abdomen "), ("musk", "acrid scent"), ("bestial", "arachnid"),
])
dri["/datum/sex_action/footjob"] = P(
    "[USER] presses a chitinous leg against [TARGET]'s [TSIZE] [TCOCK], the hard, segmented limb grinding against the [TSHAFT].",
    "[USER] [FORCE] strokes [TARGET]'s [TCOCK] between two of [THEIR] spider-legs, chitin clicking.",
    "[USER] lifts [THEIR] leg away, [TARGET]'s [TCOCK] left twitching.",
    "[TARGET]'s [TSIZE] [TCOCK] is trapped between [USER]'s hard, segmented legs.",
    "[TARGET]'s [TSHAFT] throbs against [USER]'s chitinous limbs.",
    "[TARGET]'s [TCOCK] springs free as [USER]'s legs part.",
    "[USER] presses [THEIR] spider-leg against [TARGET]'s [TSIZE] [TCOCK].",
    "[USER] [FORCE] grinds [THEIR] legs against [TARGET]'s [TCOCK].",
    "[USER] lifts [THEIR] legs away from [TARGET].")
RACE_DATA["drider"] = dri


# ========== HARPY ==========
# Feathered arms/wings, taloned feet, light hollow bones. Emphasis on feathers, preening, talons.
har = retheme(ant, [
    ("paw", "taloned foot"), ("paws", "talons"), ("paw-pads", "scaly sole"),
    ("padded", "taloned"), ("beans", "talons"), ("toe-beans", "talons"),
    ("muzzle", "beak"), ("rough tongue", "nimble tongue"),
    ("fur ", "plumage "), ("furred", "feathered"), ("fur,", "feathers,"),
    ("tail swishing", "tail-feathers fanning"), ("tail hiked high", "tail-feathers fanned"),
    ("musk", "warm, avian scent"), ("bestial", "avian"),
    ("clawed fingers", "wing-claws"), ("clawed digits", "wing-claws"),
    ("claws", "wing-claws"),
])
har["/datum/sex_action/handjob"] = P(
    "[USER] wraps [THEIR] wing-claws around [TARGET]'s [TSIZE] [TCOCK], feathered wrist brushing the [TSHAFT].",
    "[USER] [FORCE] strokes [TARGET]'s [TCOCK] with [THEIR] wing-claws, down-feathers tickling sensitive skin.",
    "[USER] releases [TARGET]'s [TCOCK], wing-claws uncurling.",
    "[TARGET]'s [TSIZE] [TCOCK] twitches in [USER]'s delicate, feathered grip.",
    "[TARGET]'s [TSHAFT] throbs against [USER]'s soft down-feathers, pre leaking.",
    "[TARGET]'s [TCOCK] springs free as [USER]'s wing-claws release.",
    "[USER] wraps [THEIR] wing-claws around [TARGET]'s [TSIZE] [TCOCK].",
    "[USER] [FORCE] wing-strokes [TARGET]'s [TCOCK].",
    "[USER] releases [TARGET]'s [TCOCK].")
RACE_DATA["harpy"] = har


# ========== MOTH ==========
# Fuzzy antennae, proboscis, large wings, soft fluff. Emphasis on softness, dust, flutter.
mot = retheme(ant, [
    ("paw", "fuzzy hand"), ("paws", "fuzzy hands"), ("paw-pads", "soft palm"),
    ("padded", "plush"), ("beans", "fingers"), ("toe-beans", "toes"),
    ("muzzle", "proboscis"), ("rough tongue", "thin proboscis"),
    ("fur ", "fluff "), ("furred", "fluffy"), ("fur,", "fluff,"),
    ("tail swishing", "antennae twitching"), ("tail hiked high", "wings fluttering"),
    ("tail ", "wings "), ("musk", "sweet dust"), ("bestial", "mothlike"),
    ("clawed", "soft"),
])
RACE_DATA["moth"] = mot


# ========== LIZARD ==========
# Scaled, clawed, thick tail, rough hide. Cold-blooded, methodical.
liz = retheme(ant, [
    ("paw", "clawed hand"), ("paws", "clawed hands"), ("paw-pads", "rough palm"),
    ("padded", "scaled"), ("beans", "claws"), ("toe-beans", "claws"),
    ("muzzle", "snout"), ("rough tongue", "forked tongue"),
    ("fur ", "scale "), ("furred", "scaled"), ("fur,", "scales,"),
    ("tail swishing", "thick tail lashing"), ("tail hiked high", "tail curled aside"),
    ("musk", "reptilian musk"), ("bestial", "reptilian"),
])
RACE_DATA["lizard"] = liz


# ========== KOBOLD ==========
# Tiny, scrappy, scaled, big eyes, claws. Emphasis on small size, eagerness.
kob = retheme(ant, [
    ("paw", "tiny clawed hand"), ("paws", "small claws"), ("paw-pads", "rough little palm"),
    ("padded", "small"), ("beans", "claws"), ("toe-beans", "claws"),
    ("muzzle", "snout"), ("rough tongue", "quick tongue"),
    ("fur ", "scale "), ("furred", "scaled"), ("fur,", "scales,"),
    ("tail swishing", "thin tail whipping"), ("tail hiked high", "tail wagging"),
    ("musk", "musky scent"), ("bestial", "scrappy"),
])
RACE_DATA["kobold"] = kob


# ========== TIEFLING ==========
# Horns, spaded tail, infernal heat. Emphasis on heat, sulfur, wickedness.
tie = retheme(ant, [
    ("paw", "clawed hand"), ("paws", "clawed hands"), ("paw-pads", "hot palm"),
    ("padded", "warm"), ("beans", "fingers"), ("toe-beans", "toes"),
    ("muzzle", "mouth"), ("rough tongue", "long, dexterous tongue"),
    ("fur ", "skin "), ("furred", "fiendish"), ("fur,", "skin,"),
    ("tail swishing", "spaded tail flicking"), ("tail hiked high", "tail curling"),
    ("musk", "sulfurous heat"), ("bestial", "infernal"),
])
RACE_DATA["tiefling"] = tie


# ========== HALF-ORC ==========
# Tusked, muscular, thick green/grey skin. Brute strength, heavy breathing.
orc = retheme(ant, [
    ("paw", "meaty hand"), ("paws", "thick hands"), ("paw-pads", "calloused palm"),
    ("padded", "calloused"), ("beans", "fingers"), ("toe-beans", "toes"),
    ("muzzle", "tusked mouth"), ("rough tongue", "thick tongue"),
    ("fur ", "skin "), ("furred", "muscled"), ("fur,", "skin,"),
    ("tail swishing", "muscles tensing"), ("tail hiked high", "muscles flexing"),
    ("tail ", "body "), ("musk", "heavy sweat"), ("bestial", "brutish"),
    ("clawed", "thick"),
])
RACE_DATA["half-orc"] = orc


# ========== GOBLIN ==========
# Tiny, green, sharp teeth, nimble. Chaotic energy, quick movements.
gob = retheme(ant, [
    ("paw", "small green hand"), ("paws", "small hands"), ("paw-pads", "rough little palm"),
    ("padded", "wiry"), ("beans", "fingers"), ("toe-beans", "toes"),
    ("muzzle", "sharp-toothed mouth"), ("rough tongue", "quick tongue"),
    ("fur ", "skin "), ("furred", "green-skinned"), ("fur,", "skin,"),
    ("tail swishing", "ears twitching"), ("tail hiked high", "ears perked"),
    ("tail ", "ears "), ("musk", "goblin stink"), ("bestial", "feral"),
    ("clawed", "sharp-nailed"),
])
RACE_DATA["goblin"] = gob


# ========== DWARF ==========
# Stocky, bearded, thick-skinned. Emphasis on strength, endurance, rumbling voice.
dwf = retheme(ant, [
    ("paw", "thick hand"), ("paws", "rough hands"), ("paw-pads", "calloused palm"),
    ("padded", "calloused"), ("beans", "fingers"), ("toe-beans", "toes"),
    ("muzzle", "bearded mouth"), ("rough tongue", "thick tongue"),
    ("fur ", "beard "), ("furred", "hairy"), ("fur,", "body hair,"),
    ("tail swishing", "beard bristling"), ("tail hiked high", "muscles tensing"),
    ("tail ", "beard "), ("musk", "stone-and-ale scent"), ("bestial", "dwarven"),
    ("clawed", "thick"),
])
RACE_DATA["dwarf"] = dwf


# ========== ELF ==========
# Lithe, graceful, pointed ears, smooth skin. Ethereal beauty, deliberate movements.
elf = retheme(ant, [
    ("paw", "slender hand"), ("paws", "elegant hands"), ("paw-pads", "smooth palm"),
    ("padded", "graceful"), ("beans", "fingers"), ("toe-beans", "toes"),
    ("muzzle", "lips"), ("rough tongue", "deft tongue"),
    ("fur ", "skin "), ("furred", "smooth"), ("fur,", "skin,"),
    ("tail swishing", "ears twitching"), ("tail hiked high", "back arching"),
    ("tail ", "hair "), ("musk", "floral scent"), ("bestial", "elven"),
    ("clawed", "nimble"),
])
RACE_DATA["elf"] = elf


# ========== REVENANT (DULLAHAN) ==========
# Physical undead with detachable head. Cold flesh, no heartbeat, stiff joints.
# NOT ghosts — these are walking corpses with cold skin and dead weight.
rev = retheme(ant, [
    ("paw", "cold hand"), ("paws", "cold hands"), ("paw-pads", "frigid palm"),
    ("padded", "cold"), ("beans", "fingers"), ("toe-beans", "toes"),
    ("muzzle", "cold mouth"), ("rough tongue", "cold, stiff tongue"),
    ("fur ", "pallid skin "), ("furred", "cold-fleshed"), ("fur,", "dead skin,"),
    ("tail swishing", "head lolling"), ("tail hiked high", "severed neck exposed"),
    ("tail ", "detached head "), ("musk", "grave-cold scent"), ("bestial", "deathly"),
    ("clawed", "stiff"),
    ("bristling", "tensing"), ("matted with sweat", "cold and dry"),
])
# Override key actions for dullahan-specific flavor
rev["/datum/sex_action/vaginal_sex"] = P(
    "[USER]'s [USIZE] [UCOCK] sinks into [TARGET]'s [TVAG], the cold flesh drawing a gasp from [TTHEIR] lips.",
    "[USER] [FORCE] thrusts into [TARGET], dead weight driving each stroke, [THEIR] body moving with mechanical resolve.",
    "[USER]'s [USHAFT] slides free, cold and slick, leaving [TARGET] shivering.",
    "[TARGET]'s walls clench around [USER]'s frigid [USIZE] [USHAFT], the cold seeping deep into [TTHEIR] core.",
    "[TARGET]'s [TVAG] squeezes [USER]'s ice-cold [UCOCK], warmth leeching from [TTHEIR] body with each thrust.",
    "[TARGET]'s folds clench around nothing as [USER]'s cold [USHAFT] withdraws.",
    "[USER] buries [THEIR] [USIZE] [UCOCK] in [TARGET]'s [TVAG], cold flesh pressed flush.",
    "[USER] [FORCE] fucks [TARGET] with the tireless rhythm of the dead.",
    "[USER] pulls free of [TARGET], [USHAFT] cold and wet.")
rev["/datum/sex_action/throat_sex"] = P(
    "[USER] grips [TARGET]'s head with cold, rigid fingers and feeds [THEIR] [USIZE] [UCOCK] into [TTHEIR] throat.",
    "[USER] [FORCE] throat-fucks [TARGET], dead grip unyielding, [THEIR] cold [USHAFT] plunging deep.",
    "[USER] pulls [THEIR] frigid [USHAFT] free, drool freezing on the shaft.",
    "[TARGET]'s throat bulges around [USER]'s ice-cold [USIZE] [USHAFT], the chill making [THEM] gag.",
    "[TARGET] chokes on [USER]'s freezing [UCOCK], tears streaming from the cold.",
    "[TARGET] gasps as [USER]'s frigid [USHAFT] slides free, throat numb.",
    "[USER] shoves [THEIR] cold [USIZE] [UCOCK] down [TARGET]'s throat.",
    "[USER] [FORCE] throat-fucks [TARGET], grip like rigor mortis.",
    "[USER] pulls free of [TARGET]'s throat.")
rev["/datum/sex_action/facesitting"] = P(
    "[USER] drops [THEIR] cold hips onto [TARGET]'s face, dead weight pinning [THEM] down.",
    "[USER] [FORCE] grinds [THEIR] frigid crotch on [TARGET]'s face, the cold numbing [TTHEIR] skin.",
    "[USER] lifts [THEIR] hips, [TARGET]'s face left numb and cold.",
    "[TARGET]'s face is smothered by [USER]'s frigid body, the grave-cold seeping into [TTHEIR] skin.",
    "[TARGET] can barely feel [TTHEIR] own face under [USER]'s numbing weight.",
    "[TARGET] gasps as [USER] lifts off, skin tingling as warmth returns.",
    "[USER] sits on [TARGET]'s face, dead weight settling.",
    "[USER] [FORCE] grinds on [TARGET]'s face, cold flesh pressing.",
    "[USER] lifts off [TARGET]'s face.")
rev["/datum/sex_action/masturbate"] = P(
    "[USER] wraps [THEIR] cold fingers around [THEIR] own [USIZE] [UCOCK] and begins stroking with stiff, mechanical motions.",
    "[USER] [FORCE] strokes [THEIR] [UCOCK], cold hand working the [USHAFT] with grim determination.",
    "[USER] releases [THEIR] [USHAFT], fingers uncurling stiffly.",
    "[TARGET] watches [USER] stroke [THEIR] cold [USIZE] [UCOCK] with dead fingers.",
    "[TARGET] watches [USER] [FORCE] pleasure [THEM]self, the motions eerily steady.",
    "[TARGET] watches as [USER] stops, [UCOCK] left cold and twitching.",
    "[USER] begins stroking [THEIR] cold [USIZE] [UCOCK].",
    "[USER] [FORCE] strokes [THEIR] own [UCOCK] with dead hands.",
    "[USER] stops masturbating.")
RACE_DATA["revenant"] = rev


# ========== CONSTRUCT ==========
# Artificial body — metal, crystal, magic-animated. No organic sensation, servos, clicking.
con = retheme(ant, [
    ("paw", "metal hand"), ("paws", "metal hands"), ("paw-pads", "smooth plate"),
    ("padded", "articulated"), ("beans", "digits"), ("toe-beans", "digits"),
    ("muzzle", "faceplate"), ("rough tongue", "smooth metal tongue"),
    ("fur ", "plating "), ("furred", "metallic"), ("fur,", "plating,"),
    ("tail swishing", "servos whirring"), ("tail hiked high", "chassis angled"),
    ("tail ", "chassis "), ("musk", "ozone tang"), ("bestial", "mechanical"),
    ("clawed", "articulated"), ("bristling", "clicking"),
    ("matted with sweat", "streaked with lubricant"),
    ("panting", "venting heat"), ("sweat", "coolant"),
])
con["/datum/sex_action/masturbate"] = P(
    "[USER] wraps [THEIR] articulated fingers around [THEIR] own [USIZE] [UCOCK] and begins stroking, servos humming.",
    "[USER] [FORCE] strokes [THEIR] [UCOCK], metal digits clicking rhythmically against the [USHAFT].",
    "[USER] releases [THEIR] [USHAFT], fingers clicking open.",
    "[TARGET] watches [USER] stroke [THEIR] [USIZE] [UCOCK] with precise, mechanical motions.",
    "[TARGET] watches [USER] [FORCE] pleasure [THEM]self, each stroke exactly the same.",
    "[TARGET] watches as [USER] stops, [UCOCK] left humming faintly.",
    "[USER] begins stroking [THEIR] [USIZE] [UCOCK], servos whirring.",
    "[USER] [FORCE] strokes [THEIR] own [UCOCK] with mechanical precision.",
    "[USER] stops masturbating.")
RACE_DATA["construct"] = con


# ========== FILL MISSING ACTIONS ==========
# For any race that doesn't have a specific override for an action,
# fall back to the humanoid base text from the existing JSON.
for race_name, race_dict in RACE_DATA.items():
    for action_path in ACTIONS:
        if action_path not in race_dict:
            # Use the rethemed version if available (from retheme()), otherwise humanoid fallback
            pass  # retheme already copies all actions from anthro; this is a safety net

# ========== OUTPUT ==========
output = {"humanoid": existing["humanoid"]}  # preserve only humanoid base
for race_name, race_dict in RACE_DATA.items():
    # Ensure all 28 actions are present — fill gaps from humanoid
    full = {}
    for action_path in ACTIONS:
        if action_path in race_dict:
            full[action_path] = race_dict[action_path]
        else:
            full[action_path] = humanoid[action_path]
    output[race_name] = full

OUT_PATH = "modular/code/datums/sexcon/strings/sex_action_defaults.json"
with open(OUT_PATH, "w", encoding="utf-8") as f:
    json.dump(output, f, indent="\t", ensure_ascii=False)

# Stats
total_strings = 0
for race_name, race_dict in output.items():
    total_strings += len(race_dict) * 9  # 3 perspectives × 3 phases
print(f"Written {len(output)} presets × {len(ACTIONS)} actions = {len(output)*len(ACTIONS)} entries")
print(f"Total flavor strings: {total_strings}")
print(f"Output: {OUT_PATH}")
