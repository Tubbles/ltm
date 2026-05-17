# ltm

In-process Lua text transforms over multi-cursor selections for the
[micro](https://github.com/zyedidia/micro) editor. A faster successor
to invoking a shell-based tool once per cursor.

## Ops

One micro command `ltm` with 14 sub-ops dispatched on the first
positional arg.

```
> ltm eval                       evaluate each cursor's selection as a Lua expression
> ltm seq FIRST STEP [-z | -p]   generate FIRST, FIRST+STEP, ... one per cursor
> ltm dec2hex                    convert each selection from decimal to hex
> ltm dec2oct
> ltm dec2bin
> ltm hex2dec
> ltm hex2oct
> ltm hex2bin
> ltm oct2dec
> ltm oct2hex
> ltm oct2bin
> ltm bin2dec
> ltm bin2hex
> ltm bin2oct
```

## Behavior

- Per cursor: selection text is the input; the result replaces the
  selection, or is inserted at the cursor position if there was no
  selection. Edits are applied in buffer-position descending order
  so they stay valid under any cursor ordering returned by micro.
- `eval` uses pure Lua. The `math` table is flattened into the
  expression scope, so `sqrt(2)`, `pi`, `floor(3.7)` work bare.
  Other globals (`tostring`, `string.format`, ...) remain reachable
  namespaced. Errors in the expression replace the selection with
  the error message text.
- `seq` always emits one value per cursor. `-z` zero-pads (sign
  aware), `-p` space-pads. Padding width is computed from the full
  generated sequence.
- The 12 base shortcuts treat the selection as a single value. Empty
  selections are skipped. Selections that aren't valid in the
  from-base are replaced with the literal string `"nil"`. The
  prefixes `0x`, `0o`, `0b` (case-insensitive) are stripped only
  when they match the from-base.

## Install

Clone into micro's plugin directory:

```
git clone https://github.com/Tubbles/ltm.git ~/.config/micro/plug/ltm
```

Micro picks it up at next launch. See `> help ltm` (from micro's
command prompt) for the full reference.

## Tests

```
busted spec/
```

The pure modules (`util`, `seq`, `convert`, `eval`, `dispatch`) all
have spec coverage. The micro adapter (`ltm.lua`) is the only file
that touches micro's plugin API and is verified by manual smoke in
the editor.

## License

AGPL-3.0-or-later. See `LICENSE`.
