# ast-grep cheatsheet for codemods

Every snippet below was run against ast-grep 0.40.5 and 0.51.3. Full reference: [rule config](https://ast-grep.github.io/reference/yaml.html), [rule object](https://ast-grep.github.io/reference/rule.html).

## Commands

```bash
ast-grep run -p 'useRef($$$)' --lang tsx src/              # search with a pattern
ast-grep run -p '<X a="b" />' --lang tsx --debug-query=ast  # dump the AST of a snippet: node kinds and fields
ast-grep run -p 'a=$X' --lang tsx --debug-query=pattern     # see how ast-grep parsed YOUR pattern
ast-grep scan -r rules/my-rule.yml src/                     # preview one rule
ast-grep scan --update-all src/                             # apply every rule from sgconfig.yml
ast-grep test --skip-snapshot-tests                         # match/no-match contract
ast-grep test --update-all                                  # write snapshots once green
```

When a rule surprises you, paste the code and the rule into the [playground](https://ast-grep.github.io/playground.html) and look at the AST tab.

## Rule anatomy

```yaml
id: use-ref-argument          # same id in rule-tests/<id>-test.yml
language: Tsx
message: React 19 requires an argument for useRef
severity: hint
rule:                         # sibling keys are ANDed
  kind: arguments
  regex: ^\(\s*\)$
  inside:
    kind: call_expression
    has:
      field: function
      regex: ^(React\.)?useRef$
fix: (undefined)
```

## Matching

This file doesn't cover matching syntax: `pattern`, `kind`, `regex`, `inside`/`has`, `all`/`any`/`not`, metavariables, `constraints`, `utils`. Use the official [ast-grep skill](https://github.com/ast-grep/agent-skill) if it's installed, or the [rule reference](https://ast-grep.github.io/reference/rule.html).

## Fixing

```yaml
# Rewrite an import source, and only the import source
rule:
  kind: string
  regex: ^["']react-dom/test-utils["']$
  inside:
    kind: import_statement
fix: '"react"'
```

- `fix` is a **text template**, not an AST: metavariables get pasted in, and relative indentation is kept ([rewrite guide](https://ast-grep.github.io/guide/rewrite-code.html)). A metavariable that didn't bind becomes an empty string.
- Replace the smallest node you can (`()` → `(undefined)` instead of the whole call). The diff stays smaller and the formatting stays intact.
- To delete a node together with its trailing comma, use `fix: { template: "", expandEnd: { regex: "," } }`. It leaves stray whitespace behind, so run the formatter afterwards.
- To compute new text from a metavariable (replace, substring, case conversion), use [`transform`](https://ast-grep.github.io/guide/rewrite/transform.html).

## Gotchas (each one fails silently)

1. **`stopBy` defaults to `neighbor`.** `inside`/`has` only look one level up or down. Add `stopBy: end` to search all ancestors or descendants.
2. **Patterns are parsed without context.** `variant=$X` parses as an `assignment_expression`, so it never matches a JSX attribute. Match with `kind` + `has`/`regex`, or give the pattern context: `pattern: { context: '<X variant=$V />', selector: jsx_attribute }`.
3. **Metavariables captured in `pattern.context` can't be used in `fix`** (`Undefined meta var`). Match structurally instead.
4. **`kind` and `pattern` must describe the same node.** `kind: public_field_definition` + `pattern: $NAME = $VALUE` matches nothing.
5. **A pattern must parse as a single node.** `from "./foo"` is rejected. Match the `string` inside an `import_statement` instead.
6. **`language: Tsx` skips `.ts` files.** Add `languageGlobs: { tsx: ["*.ts"] }` to `sgconfig.yml` (as in the example) or write a `TypeScript` twin of the rule.
7. **JSX has two shapes:** `<A />` is a `jsx_self_closing_element`; `<A>x</A>` is a `jsx_element` with a `jsx_opening_element`. Cover both with `any`.
8. **Nested matches apply one level per run.** `a.strict().strict()` needs two `scan --update-all` runs. Run until nothing changes, or write the rule to match the innermost node.
9. **`ast-grep test` doesn't check `fix` output** unless snapshots exist. Before snapshots, `check-fixtures.sh` is what verifies the output.

## Limits: when to stop and switch

ast-grep sees one file at a time, has no types, and can't follow data flow. If a transformation depends on what a symbol *is* (its type, where it's declared, its import in another file), see [other-tools.md](other-tools.md).
