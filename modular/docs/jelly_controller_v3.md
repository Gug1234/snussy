# Jelly Controller V3 Design

## Goal

Expand the jelly controller system from a stable V2 relationship loop into a richer, negotiated, maintainable feature set.

V3 is aimed at three practical outcomes:
- turn shell or doppel control into a true shared interaction loop instead of a small set of one-shot actions
- improve matching and consent flows so the system supports directed interest, invitations, and explicit negotiation
- move the implementation out of ad hoc item growth and into a controller-specific architecture that can keep evolving safely

V3 assumes the current V2 foundation already exists:
- per-jelly application flow
- wearer-side permissions and dismissal
- hidden shell and slime-double controller lifecycle
- suspend, reconnect, death, and forced-removal hardening
- controller-side shared TGUI surface
- admin audit logging and VV repair tooling

## Non-Goals For V3

These stay out of scope unless the core V3 loop is already stable:
- unrestricted remote control over the wearer's body or every intimacy subsystem
- combat-capable or free-roaming controller forms
- replacing all intimate accessory UI with a controller-exclusive interface framework
- cross-round persistence of controller relationships, reputations, or memories
- a generalized possession framework for unrelated items or species

## V3 Product Thesis

V1 proved the role could exist.

V2 made it safe, legible, and resilient.

V3 should make it feel collaborative.

That means:
1. the controller should be able to make meaningful requests instead of only broadcasting feelings or manifesting
2. the wearer should be able to accept, deny, or defer those requests in a clear interface
3. discovery and matching should support mutual intent, not just browsing open applications
4. the code should finally have a dedicated controller-management home instead of continuing to expand inside the jelly item itself

## Primary V3 Scope

### 1. Negotiated Request Loop

V2 gives the controller a stable interface, but most actions are still unilateral flavor emission.

V3 should add a real negotiated request system between controller and wearer.

Examples of V3 request types:
- request manifestation
- request slot repositioning
- request attention or soothing
- request privacy or temporary speech mute changes
- request release or dismissal when the controller wants out

Recommended behavior:
- controller sends a structured request
- wearer sees the request in the jelly panel with explicit accept or deny actions
- request expiry is visible to both sides
- accepted requests call one authority proc each
- denied requests are logged in a lightweight shared activity history

This keeps consent explicit while making the relationship feel interactive instead of mostly declarative.

Current V3 slice note:
- the first implementation slice should start with shell-side requests for manifestation, stimulation, and repositioning rather than trying to gate every controller action at once
- wearer-facing requests should have a hard opt-in override toggle for players who explicitly want the controller to bypass per-action approval and act directly through the jelly
- the override should bypass only the new request gate, not the broader permission toggles that still let the wearer mute speech, emotes, or manifestation entirely

### 2. Invitation And Mutual Matching

Per-jelly applications are good enough for V2, but V3 should support mutual selection more directly.

V3 should explore:
- wearer-initiated invitations to currently opted-in candidates
- candidate-side shortlist or favorite jellies
- visibility filters so candidates can browse by wearer summary or jelly state
- explicit invite acceptance rather than silent role offers
- optional limited multi-application support if single-target flow feels too restrictive in playtests

The design goal is not mass matchmaking.

It is to let both sides signal intent more precisely without weakening the consent model.

Current V3 slice note:
- the second implementation slice adds wearer-initiated invitations to opted-in candidates from the global jelly controller queue
- the wearer picks a candidate through a server-side input dialog that filters GLOB.jelly_controller_queue, excluding candidates who already have pending invitations or active applications for this jelly
- each invitation is stored as an associative list entry on the strange jelly keyed by a sequentially incrementing invitation id
- invitation fields: id, candidate_ckey, candidate_name, sent_at world.time, expires_at (sent_at + 120 SECONDS)
- invitations are capped at 3 concurrent per jelly; expired or invalid invitations are pruned on access
- candidate notification uses INVOKE_ASYNC to run an askuser prompt with 120 second timeout, matching the existing offer_controller_role_to_candidate flow
- if the candidate accepts, the invitation is consumed and the standard binding flow runs (offer_controller_role_to_candidate with the wearer's jelly prefs)
- if the candidate declines or the prompt times out, the invitation is removed and the wearer sees a status update in the activity log
- the wearer can cancel a pending invitation from the TGUI panel before the candidate responds
- all invitations are cleared when a controller binds (alongside clearing applications)
- invitations are cleared in Destroy to prevent dangling references
- candidate-side shortlist and visibility filters are deferred to a future slice

### 3. Controller And Wearer Activity History

V2 added admin auditability, but the player-facing relationship still lacks memory.

V3 should add a lightweight shared activity history visible to the wearer and controller.

Suggested entries:
- applications and invitations
- bind and release events
- manifestation or return events
- request accepted or denied outcomes
- major permission changes
- interruption or suspension events

This should stay in-round only for now.

The purpose is transparency and shared context, not permanent progression.

Current V3 slice note:
- the second implementation slice adds a controller_activity_log list on the strange jelly, separate from the existing mood_log (which tracks emotional events)
- activity log fields: time (formatted as MM:SS from world.time), actor (wearer, controller, admin, or system), event (bind, release, manifest, return, request, permission, suspension, invitation, dismissal, direct_control), summary (human-readable string), severity (normal, important, or warning)
- the log is capped at 40 entries; oldest entries are trimmed when the cap is exceeded
- activity entries are added at every lifecycle event: bind, release, manifest, return from doppelganger, suspension, reconnect, resume, permission change, dismissal, request queued, request accepted, request denied, direct control enabled, direct control restored, application submitted, invitation sent, invitation cancelled, invitation accepted, invitation declined, invitation timed out
- each call specifies actor_side so the UI can color-code entries by perspective (wearer blue, controller purple, admin orange, system gray)
- severity levels are used for visual emphasis: normal for routine events, important for binding status changes and dismissals, warning for suspensions
- the TGUI component (ControllerActivityLog) shows the most recent 5 entries collapsed with an expand toggle to show all, matching the MoodLog visual pattern
- the activity log is emitted through ui_data as controller_activity_log for all three view paths (strange jelly, non-strange jelly fallback, non-jelly fallback)
- observer and admin visibility of the activity log is deferred to a future slice

### 4. Dedicated Controller Manager Datum

By V3, this is no longer optional.

The strange jelly currently owns too much controller state directly.

V3 should extract a dedicated controller-management datum responsible for:
- application and invitation ownership
- active controller identity and lifecycle state
- request queue ownership
- permission state
- shell and doppel references
- audit and repair helpers
- UI serialization for controller-specific views

The jelly item should remain the physical anchor and intimacy integration point, but not the dumping ground for every controller concern.

### 5. Controller-Specific UI Separation

V2 correctly reuses the wearer interface so the feature can ship.

V3 should decide whether the controller experience has grown large enough to deserve its own interface datum or window shape.

This does not require throwing away the current shared panel immediately.

A reasonable V3 target is:
- keep one conceptual interaction model
- separate wearer-management sections from controller-action sections more cleanly
- support controller-only panels when the wearer is unavailable
- reduce hidden-shell dependence on verbs entirely

### 6. Playtest-Driven Recovery Refinement

V2 finally added admin repair and auditing.

V3 should use that breathing room to refine real observed failures rather than guessing at them.

Targets:
- identify repeat repair cases from admin use
- decide which repair outcomes should become automatic self-healing
- document known safe intervention paths for admins
- reduce noisy audit events while preserving actionable ones

V3 should treat admin tooling as a source of truth about where the design is still brittle.

## Consent Model For V3

V3 must preserve the same hard consent guarantees as V2.

Rules:
1. controllers can request, but not silently force, wearer-facing outcomes that exceed existing permissions
2. invitations must be explicit and opt-in on both sides
3. all request outcomes should be visible to the involved players
4. dismissal and release remain explicit escape valves
5. living-body abandonment remains heavily confirmed and never hidden behind a new UX layer
6. if the wearer enables a direct-control toggle, that toggle must itself be explicit, reversible, and legible in the UI so the controller is bypassing approval by consent rather than by surprise

V3 should deepen mutual play, not weaken boundaries.

## UI / UX Direction

### Wearer side

The wearer panel should evolve from a management screen into a relationship dashboard.

Wearer-visible V3 sections:
- active controller state
- pending requests
- invitations and applicants
- permissions and moderation tools
- recent shared activity

### Candidate side

The candidate flow should gain explicit invite and shortlist support.

Candidate-visible V3 sections:
- outgoing applications
- incoming invitations
- short bio or state summary for open jellies
- clear signal about why a jelly is unavailable

### Controller side

The controller panel should treat shell and doppel as two modes of the same role rather than two different surfaces.

Controller-visible V3 sections:
- current mode and interruption state
- request composer
- manifestation and return controls
- recent request outcomes and activity history
- wearer availability or interruption reason

## Architecture Direction

### Manager datum responsibilities

V3 should introduce a controller manager datum attached to the strange jelly.

Minimum responsibility split:
- jelly item keeps physical slot logic, wearer integration, and intimacy-specific effects
- controller manager keeps controller state, shell or doppel ownership, request queues, invites, and audits

### Request queue model

Recommended request fields:
- unique request id
- request type
- controller ckey snapshot
- creation time
- expiration time
- current status: pending, accepted, denied, expired, canceled
- optional short payload such as target slot or action subtype

### Activity history model

Recommended activity fields:
- timestamp
- actor side: wearer, controller, admin, system
- event type
- human-readable summary
- optional severity or highlight level

### Recovery model

V3 should preserve the V2 authority-proc discipline.

Recommended recovery rule:
- every automated or admin repair path should either restore a valid controller state or release cleanly
- no repair path should leave a half-bound shell with stale references

## Suggested Implementation Order

1. extract a controller manager datum with no behavior change
2. move existing lifecycle, permission, and audit helpers into that datum
3. add negotiated request objects and wearer approval flow
4. add invitation support and candidate-side mutual matching improvements
5. add shared activity history to the wearer and controller UI
6. decide whether controller UI now deserves a separate window or datum
7. run repeated playtests focused on request spam, denial flow, and recovery tooling

## Validation Plan

V3 should be validated with scenario-based testing and focused playtests, not only compile success.

Minimum manual scenarios:
1. controller submits a manifestation request, wearer accepts it, and the state stays correct
2. controller submits a reposition request, wearer denies it, and both sides see a clear outcome
3. wearer sends an invitation to a candidate, the candidate accepts, and binding still respects all current confirmations
4. controller disconnects while a request is pending and the request resolves cleanly after reconnect
5. admin repair is used on a deliberately corrupted shell or doppel link and produces a valid final state
6. multiple requests in quick succession remain legible and do not flood either side

## Open Questions

- should V3 keep single-target applications once invitations exist, or is that constraint no longer worth the friction
- should denied controller requests have a cooldown to prevent spam loops
- should the activity history be visible to observers, admins only, or only the wearer and controller
- should some wearer-approved requests execute immediately while others stay as prompts for a second confirmation
- is the controller manager datum enough, or does V3 also justify a dedicated request datum hierarchy from the start

## Exit Criteria

V3 is successful when:
- the controller and wearer can negotiate actions through explicit requests instead of relying mostly on flavor emissions
- matching supports invitations or other mutual-intent signals without weakening consent
- admins can identify and repair broken states quickly, but need to do so less often than in V2 playtests
- the code is organized so future jelly-controller work no longer requires expanding one giant item file
- future work can focus on content depth and social texture instead of infrastructure rescue

## Current Planning Notes

This document assumes V2 is feature-complete enough that its remaining work is mostly playtest iteration.

Forward plan:
- keep V2 focused on verification, playtest feedback, and recovery cleanup that emerges from real use
- start V3 only once the current controller loop is stable enough that structural refactors will not hide basic bugs

## Implementation Status

### V1 scope

| Goal | Status | Notes |
|------|--------|-------|
| Permanent controller binding | Done | Mind transfers to hidden shell mob; living body deleted on accept with two-phase confirm |
| Item-mode control while worn | Done | Shell anchored inside jelly; all actions gate on is_worn + wearer availability; auto-suspend on disconnect, resume on reconnect |
| Public jelly speech | Done | visible_message: "[jelly] voices [name]'s words: ..." — public to room |
| Private jelly speech | Done | to_chat to wearer only: "[jelly] murmurs [name]'s words inwardly: ..." — only wearer and controller see it |
| Trigger jelly actions from controller | Done | Stimulate, reposition, manifest, preset actions — all via TGUI or shell verbs; routes through request queue or direct-control bypass |
| Doppel handoff to same controller | Done | Controller shell mind transfers into doppel on manifest; separate from wearer-projected doppel; both paths exist, mutually exclusive |
| Basic wearer forcing (emote/short speech) | Not started | Controller can make the jelly itself speak or emote but cannot force output from the wearer's body |
| Consent toggles | Done | Four toggles: speech, emote, manifest, direct-control bypass — all wearer-controlled, all default-safe |

### V2 scope

| Goal | Status | Notes |
|------|--------|-------|
| Full "speak through wearer" presets | Not started | 6 preset actions exist but emit jelly flavor text, not wearer-voice output |
| Forced posture / trembling / kneeling | Not started | No posture system or forced animation states |
| Controller-managed cocoon behavior | Partial | Doppel auto-spawns on cocoon entry and passive feeding exists; controller cannot pilot doppel during cocoon or command cocoon stages |
| Ghost takeover of abandoned controllers | Done | release_bound_controller ghostizes the shell mind then deletes shell mob; reconnection path exists via handle_controller_shell_login |
| Better observer-facing presence and formatting | Partial | Speech and emotes are publicly visible with jelly attribution; no distinct player-identity signal or chat styling for observers |

### V3 scope

| Goal | Status | Notes |
|------|--------|-------|
| Negotiated request loop | Done | Request queue with accept/deny/expire for manifest, stimulate, reposition; direct-control bypass toggle |
| Invitation and mutual matching | Done | Wearer-initiated invitations with askuser prompt, 120s expiry, 3 concurrent cap; candidate-side shortlist deferred |
| Controller and wearer activity history | Done | Rolling 40-entry log with actor color-coding, severity levels, lifecycle event coverage |
| Dedicated controller manager datum | Not started | State still lives on the jelly item directly |
| Controller-specific UI separation | Not started | Shared TGUI panel with conditional sections |
| Playtest-driven recovery refinement | Not started | Admin repair exists from V2 but no playtest-driven iteration yet |

### Implementation shape

| Step | Status | Notes |
|------|--------|-------|
| Controller datum bound to jelly | Done | /mob/living/jelly_controller_shell anchored inside jelly, state mirrored on both |
| Route actions through controller ownership | Done | All jelly actions check controller state, permissions, wearer availability |
| Jelly chat and wearer-forced output | Partial | Jelly chat (public and private) done; wearer-forced output not started |
| Convert doppel to controller-piloted shell | Done | Both wearer-projected and controller-piloted flows exist as separate paths |
| Gate coercive features behind permissions | Done | Four permission toggles, request queue, direct-control bypass |
| Emotional meters as unlock/state drivers | Partial | Bond level gates doppel (level 3) and voluntary cocoon (level 2); need/jealousy/resentment are display-only, do not gate controller actions |
