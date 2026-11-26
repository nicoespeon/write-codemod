---
name: write-codemod
description: Write a deterministic codemod for a library migration or breaking change, test-first, with ast-grep by default. The agent turns the changelog into before/after tests a human reviews, then writes the codemod until they pass. Use when asked to write a codemod, automate a migration or upgrade (React, Zod, a design system…), or turn a migration guide into code transformations. Prefer it over editing files one by one when the same change repeats across a codebase.
---

# Write a codemod

Don't migrate the code yourself. Write the program that migrates it. A codemod is deterministic, costs zero tokens to run, can be reviewed like any code and works again on the next codebase. You handle only what it can't: the last 20%.

The tests are the contract. The human reviews them before you write any implementation. Once they pass, they work as a ratchet: every bug you find later becomes a new failing case before it gets fixed.

Default tool: [ast-grep](https://ast-grep.github.io). Read [references/ast-grep-cheatsheet.md](references/ast-grep-cheatsheet.md) before writing a rule, and [references/test-format.md](references/test-format.md) before writing a test. For rule syntax, use the official [ast-grep skill](https://github.com/ast-grep/agent-skill) if it's installed, or the [rule reference](https://ast-grep.github.io/reference/rule.html). [example/](example/) is a small project that runs and passes.

## 0. Look for an existing codemod first

Running a codemod that already exists is cheaper than writing one. Check the library's migration guide and repository for an official codemod, and search the Codemod registry: `npx codemod search "<library> <from> <to>"`. If one covers part of the migration, preview its changes with a dry run, then apply it. Then write a codemod only for the transformations it misses.

## 1. Study the migration and list the transformations

1. Read the library's changelog or migration guide. Fetch it, don't recall it.
2. Optionally, survey the target codebase: `ast-grep run -p '<pattern>' --lang tsx <dir>` for each change. Count the occurrences and collect the real shapes (multi-line, aliased imports, chained calls).
3. Write `TRANSFORMATIONS.md` as a table with one row per transformation: id, before → after, link to the guide section, occurrences found, and **auto / partial / manual**.
4. Mark a transformation **manual** when it needs type information, other files, or a human decision. If that adds up to too much, pick another tool for that row instead of forcing ast-grep: see [references/other-tools.md](references/other-tools.md).

## 2. Write the tests first

Copy [example/](example/) as the starting project: it holds `sgconfig.yml`, `rules/`, `rule-tests/`, `fixtures/` and `check-fixtures.sh`. Then, for each automatable transformation, write:

- `rule-tests/<id>-test.yml`: `invalid` lists code the rule **must** match (missed code is a false negative). `valid` lists code it **must not** match (wrongly matched code is a false positive). Spend most of your effort on `valid`: look-alike APIs, code that is already migrated, other objects with the same method name, shadowed imports.
- `fixtures/<case>/input.tsx` + `expected.tsx`: a realistic file, mixing code that changes with code that must stay identical. This is the readable before/after.
- `rules/<id>.yml`: a stub that matches nothing (`pattern: TODO_CODEMOD_STUB`), so the tests fail on assertions and not on missing config.

Run both suites and check that they fail **for the right reason**: `[Missing]` on every `invalid` case and a diff on every fixture.

```bash
ast-grep test --skip-snapshot-tests
./check-fixtures.sh
```

## 3. Checkpoint: the human reviews the tests

**Stop here.** Show the human `TRANSFORMATIONS.md`, the test files, the fixtures and the red output. Ask:

- Is every `expected` file what you want?
- Is any shape from your codebase missing?
- Should any `valid` case actually be migrated, or the other way around?

Don't write rules until they approve. Apply their edits, then run the tests again to confirm they're still red. For a big migration, review in batches: do the first 1–3 transformations end to end so the human can check the format early.

## 4. Implement until green

- One rule per transformation, one file per rule, with the `id` matching the test file.
- Loop: dump the AST (`ast-grep run -p '<snippet>' --lang tsx --debug-query=ast`), write the rule, run both suites.
- Replace the smallest node that does the job, and let the project's formatter tidy up afterwards.
- **Never edit an approved test to make it pass.** If a case looks wrong, or ast-grep can't express it, stop and ask the human: they decide whether it moves to manual, changes tools, or the test changes.
- Once everything is green, lock the output: `ast-grep test --update-all`, then read every `fixed:` line in `rule-tests/__snapshots__/`. From now on, run `ast-grep test` without the skip flag.

## 5. Run it, then finish by hand

1. Start from a clean git tree. Run `ast-grep scan --config <codemod>/sgconfig.yml --update-all <src-dir>`, then the project's formatter, type-checker and tests. Point it at the source folder only: anything else it scans gets rewritten too, including your own fixtures.
2. For each failure, decide: **codemod bug** (add a failing case, fix the rule, go back to step 4) or **manual case** (fix it by hand). Fix bugs in the codemod, not in the output, so the next run gets them right.
3. Report what the codemod changed (files and rules), what you fixed by hand, and what's left in the manual list.
