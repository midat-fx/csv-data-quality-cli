# Schema DSL

`csvq validate <file> --schema <schema>` checks a CSV against a small,
line-oriented schema. One rule per line; blank lines and lines starting with
`#` are ignored.

## Grammar

    col:<name> type:<int|float|bool|date|string> [required] [unique] [min:<n>] [max:<n>] [regex:<re>]

Tokens are whitespace-separated. `col:` is required and names a column by its
header. All other tokens are optional and may appear in any order.

| Token        | Meaning                                                        |
|--------------|----------------------------------------------------------------|
| `type:`      | Expected type. `float` also accepts integers; `string` accepts anything. |
| `required`   | The value must be non-empty.                                   |
| `unique`     | The value must not repeat within the column.                   |
| `min:` `max:`| Numeric bounds (applied when the value parses as a number).    |
| `regex:`     | The value must match this ERE. May not contain whitespace.     |

Types: `int` (`-?\d+`), `float` (decimal or scientific), `bool`
(`true`/`false`, any case), `date` (`YYYY-MM-DD`), `string` (anything).

## Example

```
# people.schema
col:id    type:int required unique min:1
col:email type:string required regex:^[^@]+@[^@]+$
col:age   type:int required min:18 max:120
```

Validating a file with a bad email, an under-age row, a missing age and a
repeated id:

```
$ csvq validate people.csv --schema people.schema
CSV SCHEMA VALIDATION
=====================
File:   people.csv
Schema: people.schema
Rules:  3   Data rows: 4

  row 2: column 'email' value 'bad-email' fails regex ^[^@]+@[^@]+$
  row 2: column 'age' value 17 < min 18
  row 3: column 'age' is required but empty
  row 4: column 'id' value '1' is not unique

FAIL: 4 violation(s)
$ echo $?
1
```

## Limitations

- Regex values cannot contain spaces (tokens are whitespace-split).
- Cross-column and cross-file constraints are not supported yet
  (see the roadmap in CHANGELOG.md).
