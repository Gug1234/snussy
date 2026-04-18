---
name: parser-corpus-testing
description: 'Build and maintain parser corpus tests for Tree-sitter style grammars. Use for parser fixtures, golden trees, DM/BYOND syntax examples, incremental-parse validation, regression coverage, and CST stability checks.'
argument-hint: 'What grammar change, syntax slice, or parser regression should the corpus cover?'
---

# Parser Corpus Testing

Create small, durable parser fixtures that catch grammar regressions, CST drift, and incremental-parse breakage before parser changes land.

## When to Use

- A Tree-sitter grammar gains a new syntax form
- A parser conflict is fixed and needs regression coverage
- A CST shape changes and downstream tooling depends on it
- A syntax ambiguity needs permanent fixture coverage
- Incremental parsing behavior needs validation, not just full reparse success

## Goals

- Cover real syntax, not invented toy cases
- Keep each fixture small and diagnostic
- Lock down golden tree shape where downstream consumers depend on it
- Catch both full-parse and incremental-parse regressions
- Separate intended grammar changes from accidental tree drift

## Procedure

1. Define the target slice.
   - What syntax or ambiguity changed?
   - What node shape, precedence, or recovery behavior must stay stable?
   - What failure would matter to downstream tooling?

2. Gather representative samples.
   - Use real DM/BYOND examples from the codebase when possible.
   - Include smallest positive case, boundary case, and ambiguous case.
   - Add malformed input only when recovery behavior matters.

3. Split fixture intent.
   - acceptance fixture: should parse cleanly
   - ambiguity fixture: should choose the intended structure
   - recovery fixture: should produce stable error-containing tree
   - regression fixture: should preserve a previously fixed behavior
   - incremental fixture: should remain stable across local edits

4. Lock the golden tree.
   - Record the concrete tree shape that downstream tooling expects.
   - Preserve meaningful node names, fields, aliases, and delimiters.
   - Do not bless unrelated drift just because the parser still succeeds.

5. Validate incremental behavior.
   - Edit near token boundaries, delimiters, nesting edges, and ambiguous operators.
   - Reparse after local edits and compare subtree stability.
   - Check that unchanged regions remain structurally stable where expected.

6. Review coverage quality.
   - Remove duplicate fixtures that prove nothing new.
   - Keep one fixture per risk unless another case changes the tree in a meaningful way.
   - Prefer a few sharp corpus cases over a large noisy set.

7. Final check.
   - golden trees reflect intended CST
   - edge cases covered
   - incremental-parse risk exercised
   - regression case named clearly
   - unrelated tree drift not accepted

## Decision Rules

- If one fixture fails for multiple reasons, split it.
- If a grammar fix changes intended CST shape, update the golden tree and note why.
- If a change only affects whitespace or trivia, avoid broad corpus churn unless trivia is semantically important.
- If recovery behavior is unstable, add malformed fixtures near the failing token, not just at file end.
- If an ambiguity depends on precedence, include sibling fixtures that prove the losing parse is still rejected.

## Output Shape

Return:
1. Covered syntax slice
2. Fixtures to add or update
3. Golden tree expectations
4. Incremental-parse checks
5. Remaining coverage gaps

## Quality Check

Before finishing, verify:

- each fixture proves one clear thing
- golden trees match intended CST, not incidental output
- incremental edits test local stability
- ambiguous forms include the correct winner
- malformed fixtures test recovery only where it matters
