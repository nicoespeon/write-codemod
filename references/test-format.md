# Test format

A codemod can go wrong in two ways, and the tests cover both:

| Failure | What happens | Caught by | ast-grep label |
| --- | --- | --- | --- |
| **False negative** | the codemod misses code it should migrate | `invalid` cases, fixtures | `[Missing]` |
| **False positive** | the codemod rewrites code it should leave alone | `valid` cases, fixtures | `[Noisy]` |
| **Wrong output** | it matches the right code but writes the wrong thing | fixtures, then snapshots | `[Wrong]` / diff |

Three layers. The human reviews the first two before any implementation exists.

## 1. Match contract: `rule-tests/<id>-test.yml`

```yaml
id: use-ref-argument          # must equal the rule's id
valid:                        # must NOT match
  - useRef(null)
  - useRef<HTMLDivElement>(null)
  - useRef(undefined)         # already migrated
  - other.useRef()            # same name, different object
  - useRefCallback()          # name that only starts the same
  - useState()                # sibling API with the same shape
invalid:                      # MUST match
  - useRef()
  - useRef<number>()
  - React.useRef()
  - React.useRef<HTMLInputElement>()
  - useRef( )
```

Use a block string for multi-line cases:

```yaml
invalid:
  - |
    const ref = useRef<
      HTMLDivElement
    >();
```

Where to find `valid` cases. Write at least one per line that applies:

- Code that is already migrated (so the codemod stays idempotent).
- The same method name on another object (`cache.useRef()`, `Object.merge`, `_.merge`).
- Names that share a prefix or suffix (`useRefCallback`).
- Sibling APIs with the same call shape.
- The same text inside strings, comments or types.
- Local variables or imports that shadow the library's name. ast-grep can't tell them apart: if this matters, the transformation is **partial**. Say so in `TRANSFORMATIONS.md`.

## 2. Output contract: `fixtures/<case>/input.*` and `expected.*`

One realistic file per case, close to the code the human will actually migrate. Mix the code that changes with code that must stay identical, and add comments that say which is which:

```tsx
// fixtures/use-ref-argument/input.tsx
export function Form() {
  const input = useRef<HTMLInputElement>();
  const count = React.useRef<number>();

  // Already migrated: left alone
  const div = useRef<HTMLDivElement>(null);

  // Not React's hook: left alone
  const store = cache.useRef();
}
```

```tsx
// fixtures/use-ref-argument/expected.tsx
export function Form() {
  const input = useRef<HTMLInputElement>(undefined);
  const count = React.useRef<number>(undefined);

  // Already migrated: left alone
  const div = useRef<HTMLDivElement>(null);

  // Not React's hook: left alone
  const store = cache.useRef();
}
```

`check-fixtures.sh` copies `fixtures/` to a temp folder, runs `ast-grep scan --update-all` on it once, and diffs each `input.*` against its `expected.*`. A fixture can exercise several rules, since all rules in `sgconfig.yml` run.

Write `expected` files the way the project's formatter would print them. If a rule leaves stray whitespace, fix the rule or run the formatter in the script; never weaken the expected file.

## 3. Lock: snapshots

Snapshots can't be written by hand (they hold byte offsets), so they come **after** green. Treat them as approval tests:

```bash
ast-grep test --update-all       # writes rule-tests/__snapshots__/<id>-snapshot.yml
```

```yaml
snapshots:
  useRef<number>():
    fixed: useRef<number>(undefined)   # read every `fixed:` line before committing
    labels: [...]
```

From then on, plain `ast-grep test` flags any change in output as `[Wrong]` with a diff. Update a snapshot only when the human agrees the new output is better.

## Red for the right reason

With the stub rule (`pattern: TODO_CODEMOD_STUB`), expect:

- `[Missing]` on every `invalid` case. A `[Noisy]` at this stage means the test file is wrong.
- `FAIL <case>` with a diff on every fixture.
- `Cannot parse` or `Configuration not found`: the setup is broken, not the rule. Fix that first: ids must match, `sgconfig.yml` needs `ruleDirs` and `testConfigs`.

## Every bug becomes a test

Bugs found while running the codemod on real code (step 5) go back into these files first: a new `invalid`/`valid` case or a new fixture. See it fail, then fix the rule.
