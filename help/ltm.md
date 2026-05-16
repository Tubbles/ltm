# ltm

In-process Lua text transforms over multi-cursor selections. Invoke
through the command prompt (`Ctrl-E`).

## Synopsis

```
> ltm eval
> ltm seq FIRST STEP [-z | -p]
> ltm dec2hex | ltm dec2oct | ltm dec2bin
> ltm hex2dec | ltm hex2oct | ltm hex2bin
> ltm oct2dec | ltm oct2hex | ltm oct2bin
> ltm bin2dec | ltm bin2hex | ltm bin2oct
```

Press `Tab` after `ltm ` to see op names. Press `Tab` after
`ltm seq FIRST STEP ` to see padding flags.

## Per-cursor model

Each invocation operates on every cursor in the current pane.
Selections are read first, then transformed, then applied as a
sorted batch so that edit positions remain valid regardless of the
order `GetCursors()` returned the cursors in.

For each cursor:

- A selection is the input. Its result replaces the selection.
- No selection means empty input. For `seq`, a value is inserted at
  the cursor position. For `eval` and the 12 base conversions, the
  cursor is skipped silently.

## ltm eval

Evaluate each cursor's selection as a Lua expression. Replaces the
selection with the result.

`eval` runs pure Lua. The entire `math` table is exposed as bare
globals, so `sqrt(2)`, `pi`, `floor(3.7)`, `sin`, `log`, and so on
work without the `math.` prefix. Other Lua globals
(`tostring`, `tonumber`, `string`, `table`, ...) remain reachable
through their usual names.

Examples (each cursor selects its own expression):

```
1+3            -> 4
2^10           -> 1024
sqrt(16)       -> 4
abs(-7)        -> 7
math.pi        -> 3.1415926535898
floor(3.7)     -> 3
string.format("%x", 255) -> ff
```

Errors in the expression (parse, runtime, division of nil, ...)
replace the selection with the Lua error message text. One
`Ctrl-Z` undoes the edit.

**No Python compatibility shims.** `**`, `//`, `True`, `False`,
`None`, ternary `if-else`, f-strings, list comprehensions, and
bitwise operators are not supported. Use `^` for exponent and
`math.floor(a/b)` for floor division.

## ltm seq

Generate an arithmetic sequence, one value per cursor. The cursor
count drives the sequence length; there's no explicit COUNT
argument.

```
> ltm seq FIRST STEP [-z | -p]
```

- `FIRST` and `STEP` are numbers (integer or decimal).
- `-z` zero-pads, sign-aware (so `-1` to width 3 is `-01`, not
  `0-1`).
- `-p` space-pads (left-justifies values).
- Without a flag, values are emitted as-is.

Padding width is computed across the full N-element sequence so
outputs line up regardless of which cursors get the longer values.

Examples:

```
3 cursors, > ltm seq 0 1          -> 0, 1, 2
3 cursors, > ltm seq 10 -1        -> 10, 9, 8
3 cursors, > ltm seq 0 0.5        -> 0, 0.5, 1
11 cursors, > ltm seq 0 1 -z      -> 00, 01, ..., 09, 10
11 cursors, > ltm seq -5 1 -z     -> -5, -4, ..., -1, 00, 01, ..., 05
```

## ltm dec2hex (and 11 friends)

Convert each cursor's selection from one base to another:

```
> ltm dec2hex   decimal  -> hexadecimal
> ltm dec2oct   decimal  -> octal
> ltm dec2bin   decimal  -> binary
> ltm hex2dec   hex      -> decimal
> ltm hex2oct   hex      -> octal
> ltm hex2bin   hex      -> binary
> ltm oct2dec   octal    -> decimal
> ltm oct2hex   octal    -> hexadecimal
> ltm oct2bin   octal    -> binary
> ltm bin2dec   binary   -> decimal
> ltm bin2hex   binary   -> hexadecimal
> ltm bin2oct   binary   -> octal
```

The selection is treated as a single value (not line-split). Empty
selections are skipped. Whitespace is trimmed automatically.
Negative numbers are accepted. Output uses lowercase digits.

A selection that isn't a valid number in the from-base becomes the
literal string `nil`.

### Base prefixes

`0x`, `0o`, `0b` (case-insensitive) are recognised only when they
match the from-base. The sign is captured before the prefix check
so `-0xff` peels correctly.

```
> ltm hex2dec on "0xff"   -> 255    (prefix matches base 16, stripped)
> ltm hex2dec on "0XFF"   -> 255    (case-insensitive)
> ltm hex2dec on "-0xff"  -> -255
> ltm bin2dec on "0b101"  -> 5
> ltm oct2dec on "0o77"   -> 63
> ltm bin2dec on "0xff"   -> nil    (0x is not a binary prefix)
> ltm dec2hex on "0x10"   -> nil    (base 10 has no prefix)
> ltm hex2dec on "0bff"   -> 3071   (0b is not stripped at base 16,
                                      and 0bff is valid hex)
```
