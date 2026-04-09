# Jelly Controller V2 Design

## Goal

Expand the strange jelly controller system from a functional v1 foundation into a stable, expressive, consent-preserving role loop.

V2 is aimed at three practical outcomes:
- make controller matching feel intentional instead of queue-like
- give both wearer and controller clearer, richer interaction tools while the jelly is worn
- harden lifecycle edge cases so bound controllers survive real round conditions cleanly

V2 assumes the current v1 foundation already exists:
- jelly controller opt-in preference
- volunteer profile card
- wearer-side volunteer review
- hidden controller shell while worn
- doppel manifestation and return-to-shell path
- voluntary living-body abandonment

## Non-Goals For V2

These stay out of scope unless the core V2 loop is already stable:
- full replacement of existing ghost-role infrastructure
- a combat-capable slime class or free-roaming antagonist-style role
- a broad rewrite of intimate accessory UI outside jelly-specific needs
- cross-round persistence of controller bonds
- automatic random assignment of controllers to jellies

## V2 Product Thesis

V1 proves that a player can inhabit a jelly safely and consensually.

V2 should make that role feel like an actual relationship surface instead of a technical possession state.

That means:
1. the wearer should choose from targeted, understandable applications instead of a generic pool
2. the controller should have meaningful but bounded expressive agency
3. the wearer should have explicit control over access, boundaries, and dismissal
4. disconnects, destruction, unequips, and re-manifestation should leave the system in a predictable state

## Primary V2 Scope

### 1. Per-Jelly Application Flow

V1 uses a shared global volunteer queue.

That works as scaffolding, but it is weak at the roleplay layer because it asks wearers to browse a general-purpose pool instead of receiving interest that is specific to their own jelly.

V2 should move toward a per-jelly application model:
- a wearer explicitly opens their jelly for applications
- opted-in candidates browse currently available jellies
- candidates submit an application to one jelly at a time
- the wearer reviews pending applicants for that jelly only
- accepted candidates are removed from other pending lists automatically

Benefits:
- stronger consent framing on both sides
- less ambiguity about who is volunteering for whom
- easier future expansion into targeted invitations without random popups

### 2. Wearer / Controller Permission Model

V1 gives the controller a shell, speech, emote, and doppel manifestation.

V2 should formalize permissions into explicit tiers.

Suggested permission groups:
- speak: can voice words through the jelly
- emote: can send descriptive sensation or affect
- guide: can suggest or trigger wearer-facing prompts/actions through approved interfaces
- manifest: can enter the slime doppel when available
- persist: remains bound during temporary interruptions unless explicitly dismissed

Suggested wearer controls:
- mute controller speech temporarily
- mute controller emotes temporarily
- block manifestation
- dismiss controller voluntarily
- lock the jelly from receiving new applications while occupied

This should be policy-driven rather than hard-coded per verb so future expansion does not create another permission rewrite.

### 3. Controller Interaction Surface While Worn

The hidden shell currently works, but it is still a thin transport layer.

V2 should give the controller a clearer worn-mode play surface:
- dedicated verbs or TGUI controls for speech and emotes
- short preset action categories for jelly intent
- explicit cooldowns where needed
- wearer-visible attribution for controller-originated actions

The key constraint is that item-mode interaction should remain expressive without turning into unrestricted remote control.

V2 should prefer structured actions over arbitrary forced behavior.

Examples of acceptable V2 interaction depth:
- request attention
- ask to be moved to another supported slot
- ask to manifest
- send affectionate, needy, jealous, or possessive flavor through curated actions

Examples explicitly not required for V2:
- full arbitrary command over the wearer's body
- unrestricted action injection into every intimacy system

### 4. Lifecycle Hardening

This is the highest-value technical part of V2.

The current system needs a cleaner state model for:
- candidate disconnect before acceptance
- wearer disconnect while a controller is bound
- controller disconnect while shell-bound
- controller disconnect while manifested in the doppel
- jelly deletion or forced removal during transfer windows
- wearer death, gibbing, or transformation while carrying a bound controller

V2 should define a strict controller state machine:
- unbound
- applicant
- offered
- shell-bound
- manifested
- suspended
- released

Every transition should have one authority proc and one cleanup path.

This matters more than adding fancy verbs. Without it, round-state bugs will dominate support cost.

### 5. Body-Abandonment Polish

V1 handles the irreversible transfer, but it should be tightened for parity with other round-exit flows.

V2 should review:
- inventory dropping behavior for odd equipment cases
- job slot cleanup for special roles and advclasses
- body deletion timing relative to mind transfer success
- admin logging and player-facing warnings
- whether a final ghost fallback should happen if shell creation fails mid-transfer

This is not new feature work so much as making the dangerous path trustworthy.

### 6. Better Visibility And Auditability

This role is intimate, consent-sensitive, and unusual enough that V2 should improve visibility for both players and admins.

Desired additions:
- clear wearer-side status text for current controller state
- clear controller-side status text for wearer state and manifestation availability
- admin logs for application, acceptance, rejection, body abandonment, manifestation, dismissal, and forced release
- optional examine or debug breadcrumbs that explain why an action is unavailable

## Consent Model For V2

V2 keeps the same consent bar as V1 and tightens where needed.

Rules:
1. no unsolicited random erotic-role assignment
2. the wearer always sees exactly who is applying
3. the candidate always knows whose jelly they are applying to
4. acceptance stays two-sided and explicit
5. irreversible living transfer remains double-confirmed
6. wearer moderation controls exist after binding, not just before it

The biggest V2 consent improvement is contextual matching.
Per-jelly applications are materially better than a generic queue because intent is visible and directed.

## UI / UX Direction

### Wearer side

The strange jelly panel should evolve from a status page into a role-management panel.

Wearer-visible sections for V2:
- current controller status
- pending applicants
- permission toggles
- manifestation permissions
- dismissal actions

### Candidate side

The current jelly preferences popup should remain the place for profile editing.

V2 should add a separate browse/apply surface:
- list of currently application-open jellies
- wearer-facing summary and jelly status where appropriate
- single active application or a small capped number of concurrent applications
- withdraw application action

### Controller side

Bound controllers should have a consistent interface regardless of whether they are in shell-mode or doppel-mode.

V2 should aim for one conceptual controller panel with state-dependent actions.

## Architecture Direction

### Matching data

V1 stores a global volunteer queue.

V2 should add jelly-local applicant storage, likely on the strange jelly datum itself or in a dedicated controller-manager datum attached to it.

Recommended shape:
- applicant ckey
- application timestamp
- candidate state snapshot
- preview data reference
- optional short application note

Using jelly-local state makes cleanup much simpler when the item is deleted or rebound.

### Controller manager datum

V2 likely justifies a dedicated management datum instead of continuing to grow the jelly item directly.

Suggested responsibilities:
- application list ownership
- permission state
- shell ownership
- controller state transitions
- disconnect / reconnect handling
- admin logging helpers

This reduces the chance that `intimate_jelly.dm` becomes the dumping ground for every future controller feature.

### Signal and cleanup strategy

V2 should continue reusing existing hooks where possible, but cleanup ownership needs to be centralized.

Recommended rule:
- one proc to bind
- one proc to manifest
- one proc to return
- one proc to suspend
- one proc to release

All other code should call those procs instead of mutating shell or doppel fields directly.

## Suggested Implementation Order

1. formalize controller state and cleanup ownership
2. add wearer-side permissions and dismissal controls
3. replace the shared queue with per-jelly applications
4. add controller-facing worn-mode action surface
5. improve disconnect / reconnect handling
6. polish living-transfer cleanup and admin logging
7. playtest the full round lifecycle repeatedly before any V3 ambitions

## Validation Plan

V2 should be validated with scenario-based testing rather than only file-scoped diagnostics.

Minimum manual scenarios:
1. ghost applies to one jelly, gets accepted, binds, manifests, returns, and is dismissed cleanly
2. living player applies, abandons body, binds, manifests, returns, and survives wearer re-equip cycles
3. controller disconnects while shell-bound and reconnects
4. controller disconnects while manifested and reconnects
5. wearer disconnects or dies while a controller is bound
6. jelly is deleted or forcibly removed while occupied
7. pending application is invalidated by disconnect or opt-out change

## Open Questions

- should applications be single-target only, or can one candidate apply to multiple open jellies at once
- should wearer permission changes be reversible instantly or locked while manifested
- should the controller be able to request slot transfers directly or only ask via wearer prompt
- should dismissal send the controller to ghost immediately or support a temporary suspended return window
- does V2 need a lightweight admin verb for forced unbind and cleanup repair

## Exit Criteria

V2 is successful when:
- matching is directed and no longer feels like browsing a global ERP queue
- the wearer can manage an already-bound controller safely
- the controller has richer worn-mode expression without becoming an unrestricted body-puppeteer
- disconnects and deletion paths stop being scary edge cases
- the system feels stable enough that future work can focus on content depth rather than recovery bugs

## Current Implementation Notes

Initial V2 slice landed:
- formal controller state helpers on the strange jelly
- wearer-side permission toggles for controller speech, emotes, and manifestation
- wearer-side dismissal action for a bound controller
- safer release flow that recalls a manifested controller to the hidden shell before release

Second V2 slice landed:
- per-jelly application state on the strange jelly itself
- wearer-side open or close control for targeted controller applications
- candidate-side browse, apply, and withdraw flow from the jelly preference popup
- wearer-side applicant review now pulls from jelly-local pending applications instead of the shared queue

Third V2 slice landed:
- controller disconnects now transition into a suspended state instead of silently collapsing back into ambiguous shell or doppel ownership
- shell and doppel reconnects restore the correct controller lifecycle state and notify the wearer when the controller resumes
- shell-bound controllers now have curated preset worn-mode actions for attention, affection, jealousy, possessiveness, manifestation requests, and repositioning requests

Fourth V2 slice landed:
- wearer disconnect now suspends the controller cleanly and recalls any manifested controller back to the hidden shell until the wearer returns
- wearer death, deletion, transformation, and forced jelly removal now release the controller through one predictable cleanup path instead of leaving a stale bound shell behind
- shell and slime-double controllers can now open the same jelly interface and use a controller-specific TGUI surface instead of relying only on verbs

Fifth V2 slice landed:
- meaningful controller lifecycle transitions now also write to admin-facing audit logs instead of only the gameplay log
- the strange jelly now exposes VV repair, audit, and force-release actions for broken controller bindings and recovery edge cases
- acceptance, body abandonment, manifestation, return, dismissal, suspension, and forced cleanup paths now leave clearer breadcrumbs for admin investigation

Still pending from the larger V2 plan:
- playtest and iterate on any recovery cases the new admin tooling exposes in live use

Forward plan:
- see `modular/docs/jelly_controller_v3.md` for the next-stage design pass focused on negotiated request loops, invitations, activity history, and extracting a dedicated controller manager datum
