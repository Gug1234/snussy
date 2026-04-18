---
name: dm-byond-parser-triage
description: 'Triage DM/BYOND parser failures with stable fixture naming conventions, corpus grouping, and high-signal grammar diagnosis. Use for Tree-sitter DM/BYOND parse failures, grammar conflicts, CST drift, proc/type-path ambiguities, golden tree regressions, and fixture naming cleanup.'
argument-hint: 'What DM/BYOND syntax slice, parser failure, or fixture set needs triage?'
---

# DM/BYOND Parser Triage

Triage DM/BYOND parser failures into small, named, reproducible corpus cases that make grammar fixes obvious and regression review cheap.

## When to Use

- DM/BYOND Tree-sitter grammar fails on real syntax
- Conflict output unclear or too broad
- Golden tree drift needs root-cause isolation
- Corpus fixtures named badly or grouped inconsistently
- Proc paths, type paths, blocks, operators, or recovery behavior need stable triage

## Goals

- Reduce one big parser failure into a few sharp DM/BYOND cases
- Name fixtures so failure class obvious from filename alone
- Keep corpus grouped by syntax family, not random discovery order
- Distinguish grammar bug, CST drift, recovery issue, and fixture noise
- Make future regressions easy to spot and route

## Fixture Naming Conventions

Use lowercase kebab-case. Keep names short, semantic, and stable.

Pattern:

`<family>-<construct>-<variant>-<expectation>`

Examples:

- `expr-typepath-basic-accept`
- `expr-proccall-nested-accept`
- `stmt-if-else-chain-accept`
- `decl-proc-typed-arg-accept`
- `decl-var-typepath-init-accept`
- `path-absolute-proc-ref-accept`
- `path-relative-type-ambiguity-conflict`
- `recover-missing-rparen-error`
- `recover-bad-indent-tail-error`
- `regress-proc-body-dedent-tree`
- `incremental-binary-op-edit-stable`

## Family Prefixes

- `expr` for expressions
- `stmt` for statements
- `decl` for declarations
- `path` for DM/BYOND path syntax
- `proc` for proc signatures or proc bodies when proc-specific detail matters
- `type` for type definitions and inheritance forms
- `recover` for malformed input and error recovery
- `regress` for locked historical bugs
- `incremental` for local-edit stability checks

## Expectation Suffixes

- `accept` parses cleanly
- `conflict` captures ambiguity or precedence pressure
- `error` exercises recovery behavior
- `tree` locks intended CST shape
- `stable` checks incremental parse stability

## Corpus Folder Placement

Keep directories aligned with fixture family prefix. Do not scatter related syntax across unrelated folders.

Recommended layout:

- `expr/` for `expr-*`
- `stmt/` for `stmt-*`
- `decl/` for `decl-*`
- `path/` for `path-*`
- `proc/` for `proc-*`
- `type/` for `type-*`
- `recover/` for `recover-*`
- `regress/` for `regress-*`
- `incremental/` for `incremental-*`

Placement rule:

- directory chosen by family prefix
- filename still uses full fixture name
- sibling variants stay in same directory
- do not mix acceptance and recovery cases in one catch-all folder

Examples:

- `expr/expr-typepath-basic-accept`
- `decl/decl-proc-typed-arg-accept`
- `path/path-relative-type-ambiguity-conflict`
- `recover/recover-missing-rparen-error`
- `incremental/incremental-binary-op-edit-stable`

### Subfolder Convention For Large Corpora

When one family folder grows broad, split by construct cluster under the family directory.

Pattern:

`<family>/<construct-cluster>/<family>-<construct>-<variant>-<expectation>`

Examples:

- `expr/typepath/expr-typepath-basic-accept`
- `expr/proccall/expr-proccall-nested-accept`
- `expr/operator/expr-binary-plus-precedence-conflict`
- `stmt/block/stmt-block-dedent-tail-accept`
- `stmt/control-flow/stmt-if-else-chain-accept`
- `decl/proc/decl-proc-typed-arg-accept`
- `decl/var/decl-var-typepath-init-accept`
- `path/type/path-relative-type-ambiguity-conflict`
- `path/proc/path-absolute-proc-ref-accept`
- `recover/delimiter/recover-missing-rparen-error`
- `recover/block/recover-bad-indent-tail-error`

Subfolder rule:

- first directory = syntax family
- second directory = stable construct cluster
- filename still keeps full family-prefixed fixture name
- create subfolders only when they reduce clutter, not for one isolated file
- keep sibling constructs together so grep and review stay cheap

## Procedure

1. Identify failure class.
   - grammar conflict
   - wrong tree shape
   - parse rejection
   - bad recovery
   - incremental instability

2. Reduce to smallest DM/BYOND sample.
   - remove unrelated declarations
   - keep only tokens needed to trigger failure
   - preserve real DM/BYOND syntax, not invented pseudo-code

3. Assign syntax family.
   - expression
   - statement
   - declaration
   - path
   - proc
   - type
   - recovery
   - regression
   - incremental

4. Name fixture with convention.
   - family first
   - construct second
   - variant third
   - expectation last
   - rename noisy historical cases if meaning unclear

5. Place fixture in matching corpus directory.
   - directory chosen from family prefix
   - add construct subfolder when family bucket grows large
   - keep same-family fixtures together
   - move legacy misplaced fixtures when practical

6. Split mixed failures.
   - one fixture per primary risk
   - if one case proves conflict plus recovery plus CST drift, split it
   - keep sibling fixtures only when they prove different parser outcomes

7. Record intended parser outcome.
   - should accept or error
   - intended winning parse
   - intended CST nodes or fields
   - whether incremental stability matters

8. Check blast radius.
   - does failure touch proc declarations?
   - type paths?
   - operator precedence?
   - indent or block termination?
   - recovery around delimiters?

9. Finalize triage summary.
   - root cause class
   - minimal fixtures to add or rename
   - expected tree or failure behavior
   - next grammar area to inspect

## Decision Rules

- If sample only differs by identifier spelling, do not add second fixture.
- If ambiguity depends on precedence, add paired winner/loser fixtures.
- If tree shape matters to downstream tooling, add `tree` suffix even when parse accepts.
- If bug only appears after local edit, add `incremental-*` fixture, not normal acceptance fixture.
- If malformed DM/BYOND input breaks recovery near delimiter or block edge, use `recover-*` fixture.
- If old fixture name hides meaning, rename it before adding more siblings.
- If fixture family and directory disagree, fix placement first unless strong repo convention says otherwise.
- If one directory becomes a dump for unrelated constructs, split by family before adding more cases.
- If one family directory starts mixing many constructs, split into stable construct subfolders like `expr/typepath/` or `stmt/block/`.

## Output Shape

Return:
1. Failure class
2. Minimal fixture set
3. Fixture names
4. Expected parser outcome
5. Next grammar area to inspect

## Quality Check

Before finishing, verify:

- each fixture has one primary purpose
- name tells syntax family and expectation
- directory matches syntax family
- subfolder matches construct cluster when family bucket is large
- DM/BYOND construct obvious from fixture name
- acceptance, conflict, recovery, and incremental cases not mixed
- intended CST or failure behavior explicit
- duplicate noisy fixtures removed or renamed
