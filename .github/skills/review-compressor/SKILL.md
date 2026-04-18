---
name: review-compressor
description: 'Compress long review findings into terse, high-signal summaries without losing severity, file references, or actionability. Use for code review findings, audit notes, regression writeups, risk summaries, and any request to be brief, tighten findings, or shorten a review.'
argument-hint: 'brief|ultra|findings-only|exec'
---

# Review Compressor

Turn long review material into short, dense output that preserves what matters: severity, location, risk, and next action.

## When to Use

- Long code review or audit findings need compression
- User asks for terse summary, shorter review, or high-signal recap
- Findings exist, but narrative is too long or repetitive
- Need executive summary without losing the decisive issues

## Compression Goals

- Findings first
- Highest severity first
- Preserve exact file references and key technical claim
- Remove repetition, throat-clearing, and low-signal framing
- Keep next action only when it materially changes priority

## Procedure

1. Identify source shape: code review, audit, regression analysis, architecture critique, or general findings list.
2. Extract only decisive points:
   - bug or risk
   - severity
   - affected file or subsystem
   - why it matters
3. Merge duplicates or near-duplicates into one stronger finding.
4. Rewrite each surviving point into one compact standalone statement.
5. Strip low-signal content:
   - greetings and softeners
   - repeated background
   - obvious restatements of user context
   - long overviews before findings
6. Add residual risk or testing gaps only if they meaningfully affect trust in the result.
7. If there are no findings, say so directly and mention only meaningful remaining risk.

## Modes

- `brief`: 3-6 tight findings or short paragraph summary
- `ultra`: minimum words; findings only
- `findings-only`: no recap, no praise, no extra context
- `exec`: one short paragraph or a few bullets for decision-makers

## Review Rules

- Lead with findings, not overview
- Order by severity or impact, not discovery order
- One finding per bullet or sentence
- Keep causal claim intact: issue -> consequence
- Preserve file references exactly when present
- Do not drop uncertainty if confidence is limited
- Do not inflate minor nits into headline findings

## Output Shapes

### Findings-Focused

1. Critical finding.
2. Next finding.
3. Remaining risk or test gap if needed.

### No Findings

No findings. Residual risk: <short note if real>.

### Executive

Top risk is <issue>. Next risk is <issue>. Main unknown is <gap>.

## Quality Check

Before finalizing, verify:

- strongest issue still present
- severity ordering still correct
- file references not lost
- repeated points merged
- output materially shorter than source
- no important caveat removed
