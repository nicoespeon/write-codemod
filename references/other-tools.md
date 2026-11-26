# When ast-grep isn't the right tool

ast-grep's strength is also its limit. Rules are YAML, fixes are text templates, and each file is processed alone, with no types and no data flow. Switch tools when a transformation needs one of these:

| The transformation needs… | Example | Reach for |
| --- | --- | --- |
| To know what a symbol **is** | Is this `z` Zod's, or a local variable? Does `.merge()` run on a Zod schema? | ts-morph (type checker), Codemod JSSG semantic analysis |
| **Other files** | Rename an exported symbol in every file that imports it | ts-morph, Codemod JSSG multi-file |
| **Several dependent edits** | Remove an import specifier, add another, then rewrite its call sites | ts-morph, jscodeshift, JSSG |
| **Conditional logic** a regex can't express | Pick the output based on the rest of a method chain | any programmatic tool |
| **Code embedded in other files** | `<script>` blocks in `.vue`/`.astro` files | extract the block, transform it, splice it back |

Don't switch the whole codemod for one hard row. Keep ast-grep for the simple 80%, write the few hard transformations elsewhere, or mark them **manual** and leave them to the agent after the run.

## ts-morph

A wrapper around the TypeScript compiler API: types, symbols, find-references, and edits that are re-printed for you. [ts-morph.com](https://ts-morph.com/)

Worked example: [nicoespeon/zod-v3-to-v4](https://github.com/nicoespeon/zod-v3-to-v4), the community codemod linked from the [Zod v4 changelog](https://zod.dev/v4/changelog):

- One `src/convert-*.ts` file per group of transformations, chained by a single `migrate.ts`.
- One fixture pair per scenario: `test/__scenarios__/<feature>.<detail>.input.ts` → `.output.ts`, grouped in `describe` blocks named after the changelog sections.
- The runner formats both sides with Prettier before comparing, so formatting never causes false failures.
- Every fixture includes a non-Zod look-alike that must stay untouched: the `valid` cases of ast-grep, written as a fixture.
- Mutations iterate nodes bottom-up and check `node.wasForgotten()`, so an earlier edit can't leave a stale node behind.

## jscodeshift

The classic JavaScript codemod runner, built on recast, which keeps the original formatting of the code it doesn't touch. Most published React codemods use it ([reactjs/react-codemod](https://github.com/reactjs/react-codemod)). Tests follow the same before/after shape: `__testfixtures__/<name>.input.js` / `.output.js` with `defineTest`. [facebook/jscodeshift](https://github.com/facebook/jscodeshift)

## Codemod JSSG

ast-grep driven from TypeScript instead of YAML, from [Codemod](https://codemod.com). It adds semantic analysis (definitions and references), multi-file edits, workflows and a public registry. Tests are folders with `input` and `expected` files, run by `npx codemod jssg test`. [JSSG docs](https://docs.codemod.com/community/jssg), [testing](https://docs.codemod.com/community/jssg/testing).

To **publish** the codemod to the Codemod registry, use their own [`sdk-migration` skill](https://github.com/codemod/codemod/blob/main/skills/sdk-migration/SKILL.md), which `npx codemod ai` installs along with an MCP server. It follows a similar plan → fixtures → green loop, built around their CLI and an account. Keep this skill's checkpoint: the human reviews the fixtures, not just the plan.

## Whatever the tool, keep the process

The tool changes, the discipline doesn't: fixtures a human can read (`input` / `expected`), must-not-touch cases next to must-change ones, the human checkpoint before implementation, red before green, and every bug turned into a test.
