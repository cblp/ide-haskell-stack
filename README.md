# ide-haskell-stack package

The `ide-haskell-stack` package provides a build backend for `ide-haskell`
package based on `stack`.

## Keybindings

ide-haskell-stack comes with little pre-specified keybindings, so you will need to specify your own, if you want those.

You can edit Atom keybindings by opening 'Edit → Open Your Keymap'. Here is a template for all commands, provided by ide-haskell-stack:

```cson
'atom-workspace':
  '': 'ide-haskell-stack:build'
  '': 'ide-haskell-stack:clean'
  '': 'ide-haskell-stack:test'
```
