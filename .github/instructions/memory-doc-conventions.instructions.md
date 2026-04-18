---
description: "Use when creating or updating living memory docs, master context indexes, subsystem notes, or agent-facing markdown conventions. Covers where `_memory.md`, `.github/MASTER_CONTEXT.md`, and local folder docs should live."
---
# Memory Doc Conventions

- Put the canonical master context index at `.github/MASTER_CONTEXT.md`.
- Put additive living memory notes in the nearest subsystem-level `_memory.md`.
- Put stable folder guidance in colocated markdown maintained by Markdown Manager.
- Prefer an existing `README.md` for folder guidance when it already serves that purpose.
- If a folder has no suitable local doc, create `_context.md` beside that folder rather than adding more detail to the master index.
- Use Memory Scribe for `_memory.md` updates.
- Use Memory Summarizer for `.github/MASTER_CONTEXT.md` updates and cross-folder rollups.
- Use Markdown Manager for the richer local folder docs that the master index points to.
- Keep `.github/MASTER_CONTEXT.md` brief and navigational.
- Keep `_memory.md` additive and historical when old context still explains current behavior.
