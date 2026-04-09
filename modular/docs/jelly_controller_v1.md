# Jelly Controller V1 Design

## Goal

Add a consent-first path for another player to permanently inhabit a strange jelly.

V1 is intentionally scoped to the foundations:
- opt-in preference for jelly controller content
- persisted applicant profile text
- explicit volunteer queue instead of unsolicited ghost-role popups
- wearer-side review and approval flow
- controller mind transfer into a dedicated jelly shell
- controller projection into the slime double
- voluntary in-round body abandonment with repeated confirmation

## Non-Goals For V1

These stay out of scope unless the current pass is fully stable:
- automatic roundstart or random jelly-role polling
- direct control of every existing NPC jelly behavior
- wearer-facing force-action UI beyond the current foundation hooks
- broad refactors of unrelated ERP or ghost-role systems

## Consent Model

The system must remain explicit at every step.

1. A player opts into jelly controller content in ERP preferences.
2. That player fills out a jelly controller profile.
3. The player joins the volunteer queue themselves.
4. A jelly wearer reviews volunteers and previews the applicant profile.
5. The wearer explicitly accepts or declines a candidate.
6. The candidate gets a final confirmation prompt.
7. Living candidates get stronger warnings because their body and job slot are being surrendered.

V1 does not send ambient ghost-role popups. This avoids surprising uninvolved players and matches the requested consent bar.

## Candidate States

V1 supports two candidate sources.

### Ghost / lobby candidate
- observer or new-player mob
- transfers cleanly into the jelly controller shell
- no body cleanup required

### Living in-round candidate
- human with a client and mind
- must explicitly confirm body abandonment
- drops worn and held items
- frees the occupied job slot
- old body is deleted after transfer succeeds

## Architecture

### Jelly profile and queue
- add a new `/datum/jelly_prefs`
- store profile text in savefiles through `/datum/preferences`
- keep a `GLOB.jelly_controller_queue` of volunteer clients

Required stored fields for V1:
- opt-in toggle
- display name
- pronouns
- descriptive flavor text
- OOC notes

### Controller shell
A bound controller needs a stable living mob while the jelly is worn.

V1 uses a dedicated hidden shell mob that:
- holds the controller's mind while the jelly is in item mode
- grants verbs for speaking or emoting through the jelly
- acts as the return point when the controller leaves the slime double

### Doppel surface
The existing doppelganger remains the active manifested form.

V1 extends it so it can be controlled by either:
- the bonded wearer during self-projection
- the permanent third-party jelly controller

When the controller returns from the doppel, control goes back to the hidden shell instead of a normal body.

## Wearer Review Flow

1. Wearer opens the strange jelly controls.
2. Wearer chooses to review jelly volunteers.
3. Game shows the current queue.
4. Wearer selects a volunteer.
5. Game shows the volunteer's preview card.
6. Wearer accepts or declines.
7. If accepted, the candidate receives a final confirmation.
8. On success, the jelly binds that controller.

## In-Round Transfer Rules

Living volunteer transfer must be intentionally hard to trigger.

V1 uses:
- explicit volunteer queueing by the candidate
- wearer acceptance first
- a direct confirmation prompt to the candidate
- a second irreversible warning before body abandonment

Cleanup after successful transfer:
- drop held items
- unequip worn items where practical
- free job slot counts
- delete the original body

## Initial Verbs / Capabilities

While worn, the controller shell should support:
- speak through the jelly
- emote through the jelly
- manifest into the slime double when available

While manifested as the doppel, the controller keeps the current limitations:
- short leash to wearer
- no ordinary gear use
- no normal combat role

## Open Questions

These are intentionally deferred until V1 is stable.

- how much wearer-directed force or body guidance should the controller get
- whether the wearer should be able to dismiss or mute a bound controller
- whether queueing should allow per-jelly applications instead of a shared volunteer pool
- whether opted-in ghosts should later receive targeted, wearer-initiated invites

## Current Implementation Notes

This document should be updated whenever scope or invariants change.

Forward plan:
- see `modular/docs/jelly_controller_v2.md` for the next-stage design pass focused on per-jelly applications, permissions, and lifecycle hardening

Current landed foundation:
1. preference and profile plumbing
2. volunteer queue and preview
3. wearer approval action on strange jelly
4. hidden controller shell and controller binding
5. living-body abandonment cleanup
6. controller return path back into the hidden shell after doppel use

Current verification status:
- file-scoped DM and TGUI diagnostics for the new jelly controller path are clean
- repo-wide frontend build is still red in unrelated files and should not be used as the signal for this feature
- the BYOND build script regenerated output artifacts, but its terminal output did not print a trustworthy final summary

Immediate follow-up targets:
1. playtest the full volunteer -> accept -> bind -> manifest -> return lifecycle
2. harden edge cases around stale queue entries and disconnect cleanup
3. decide whether the next pass should focus on body-abandon cleanup polish or wearer/controller interaction depth
