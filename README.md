# write-codemod

An agent skill that makes your coding agent write a **codemod** for a migration instead of migrating your code file by file.

> Where we're going, we don't need tokens.

Asking an agent to migrate a codebase costs tokens on every file, every run, every repo, and the result is hard to trust. Asking it to write the codemod costs tokens once. You get a deterministic program that runs in seconds for zero tokens, that you can review, test and run again on the next codebase.

The skill drives the agent **test-first**:

1. **Study** the changelog or migration guide (and optionally your codebase), then list the transformations.
2. **Write the tests** as before/after fixtures, plus the code that must *not* change.
3. **You review the tests** before any implementation exists.
4. **Implement** with [ast-grep](https://ast-grep.github.io) until the tests pass. The suite is a ratchet: every bug found later becomes a failing test first.
5. **Run** the codemod, then let the agent handle the last 20% it can't.

The key skill is testing both ways. `invalid` cases catch false negatives, code the codemod missed. `valid` cases catch false positives, code it should never have touched.

## Install

Requires [ast-grep](https://ast-grep.github.io/guide/quick-start.html) (tested with 0.40.5 and 0.51.3).

For Claude Code:

```bash
git clone https://github.com/nicoespeon/write-codemod.git ~/.claude/skills/write-codemod
```

Then ask your agent something like:

> Write a codemod for the React 19 upgrade guide: https://react.dev/blog/2024/04/25/react-19-upgrade-guide

## What's inside

- [SKILL.md](SKILL.md): the process, with the human checkpoint.
- [references/ast-grep-cheatsheet.md](references/ast-grep-cheatsheet.md): commands, rule syntax and the gotchas that fail silently.
- [references/test-format.md](references/test-format.md): `valid`/`invalid` cases, before/after fixtures, snapshots.
- [references/other-tools.md](references/other-tools.md): when to use ts-morph, jscodeshift or Codemod's JSSG instead.
- [example/](example/): a small project that runs: the React 19 `useRef()` → `useRef(undefined)` rule, with its tests and fixtures. Run `ast-grep test && ./check-fixtures.sh` inside it.

## Resources

**ast-grep**

- [Documentation](https://ast-grep.github.io) and [playground](https://ast-grep.github.io/playground.html): paste code, see the AST, try a rule.
- [Testing rules](https://ast-grep.github.io/guide/test-rule.html) and the [rule reference](https://ast-grep.github.io/reference/rule.html)
- [Using ast-grep with AI tools](https://ast-grep.github.io/advanced/prompting.html), with the official [ast-grep agent skill](https://github.com/ast-grep/agent-skill) for writing rules. It complements this one, which covers the codemod process.
- [*Mastering ast-grep*](https://leanpub.com/ast-grep), the book by ast-grep's author, Herrington Darkholme

**Codemod.com**

- [What are codemods?](https://codemod.com/blog/what-are-codemods)
- [Quickstart](https://docs.codemod.com/community/oss-quickstart): build, test and publish a codemod with your agent
- [JSSG](https://docs.codemod.com/community/jssg), ast-grep driven from TypeScript, and the post [Announcing JavaScript ast-grep](https://codemod.com/blog/jssg)
- [Writing codemods like a pro](https://codemod.com/blog/writing-codemods-like-a-pro)

**Worked example**

- [nicoespeon/zod-v3-to-v4](https://github.com/nicoespeon/zod-v3-to-v4): a real migration codemod (ts-morph) with one before/after fixture pair per transformation

**Further reading**

- [Refactoring with Codemods to Automate API Changes](https://martinfowler.com/articles/codemods-api-refactoring.html), on martinfowler.com

## License

[MIT](LICENSE)
