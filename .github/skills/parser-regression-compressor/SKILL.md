---
name: parser-regression-compressor
description: 'Compress long parser corpus failures into terse, high-signal findings without losing fixture names, grammar rules, CST drift, or next action. Use for Tree-sitter corpus failures, parse regressions, conflict logs, golden tree diffs, incremental-parse failures, and grammar triage summaries.'
argument-hint: 'brief|ultra|findings-only|fixture-focused'
---

# Parser Regression Compressor

Turn long parser failure output into short, dense findings that preserve fixture, failure mode, grammar surface, and next fix target.

## When to Use

- Tree-sitter corpus output too long or noisy
- Golden tree diff needs short actionable summary
- Conflict triage log buried in parser noise
- Incremental-parse regression needs clear findings
- User asks for terse parser review or short grammar failure recap

## Compression Goals

- Findings first
- Group by failing fixture or grammar risk
- Preserve exact fixture names, rule names, and syntax slices
- Keep CST drift, conflict type, or incremental instability explicit
- Remove parser noise, duplicated traces, and low-signal scaffolding

## Procedure

1. Identify source shape: corpus failure, golden tree diff, grammar conflict output, incremental-parse regression, or mixed parser triage notes.
2. Extract only decisive points:
   - failing fixture or syntax slice
   - failure mode
   - affected grammar rule, conflict, or CST node
   - why downstream tooling or parser stability cares
3. Merge duplicates:
   - same root cause across many fixtures -> one grouped finding
   - same CST drift repeated in many diff lines -> one finding
4. Rewrite each surviving point into one compact standalone statement.
5. Strip low-signal content:
   - repeated parser stack noise
   - unchanged tree sections
   - duplicated diff context
   - long log framing before actual failure
6. Keep next action only if it sharpens fix direction:
   - precedence issue
   - alias drift
   - recovery break
   - scanner suspicion
   - missing fixture split
7. If no real regression remains, say so directly and note only meaningful residual parser risk.

## Modes

- `brief`: 3-6 tight parser findings or short paragraph summary
- `ultra`: minimum words; findings only
- `findings-only`: no recap, no extra context, no softeners
- `fixture-focused`: group output by failing fixture or corpus case

## Parser Rules

- Lead with regression, not overview
- Order by parser correctness risk or corpus blast radius
- One finding per bullet or sentence
- Preserve exact fixture names when present
- Preserve exact rule/conflict names when present
- Keep causal claim intact: grammar change -> parser effect
- Do not hide uncertainty when root cause only suspected
- Do not promote harmless diff noise into primary finding

## Output Shapes

### Findings-Focused

1. Fixture or rule failure.
2. Next parser risk.
3. Remaining coverage gap or residual parser risk if needed.

### Fixture-Focused

1. `fixture_name`: short failure and likely cause.
2. `fixture_name`: next failure and impact.

### No Findings

No real regression. Residual parser risk: <short note if real>.

## Quality Check

Before finalizing, verify:

- strongest parser regression still present
- fixture and rule names not lost
- duplicate failures merged
- CST drift still explicit where important
- output materially shorter than source
- important ambiguity or recovery caveat not removed
