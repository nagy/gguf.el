# ggufmeta.el

An Emacs major mode for viewing metadata from GGUF (GPT-Generated
Unified Format) model files.

## Requirements

- Emacs 29.1 or later
- The `ggufmeta` binary installed somewhere in `PATH`

The `ggufmeta` binary must accept a single file argument and print a
human-readable description of the GGUF file to stdout.

## Installation

If you use `use-package`:

```elisp
(use-package ggufmeta
  :load-path "/path/to/ggufmeta.el"
  :config
  (setq ggufmeta-program "ggufmeta"))
```

Or manually:

```elisp
(add-to-list 'load-path "/path/to/ggufmeta.el")
(require 'ggufmeta)
```

## Usage

### Opening a GGUF file

**Via `auto-mode-alist`:** simply visit any `.gguf` file — the mode
activates automatically and displays the metadata.

**Via `M-x`:** run `M-x ggufmeta-open` and select the GGUF file to
inspect.  A dedicated `*ggufmeta: <name>*` buffer is shown.

### Keybindings

| Key | Command              | Description                     |
|-----|----------------------|---------------------------------|
| `g` | `ggufmeta-refresh`   | Re-run `ggufmeta` on the file   |
| `q` | `quit-window`        | Dismiss the metadata buffer     |
| `n` | `next-line`          | Move to next line               |
| `p` | `previous-line`      | Move to previous line           |
| `RET` | `ggufmeta-show-help` | Open help for `ggufmeta-mode`   |

### Customization

- `ggufmeta-program` — name or path of the `ggufmeta` executable
  (default: `"ggufmeta"`)
- `ggufmeta-auto-update` — if non-nil (the default), automatically
  populate the buffer when visiting a `.gguf` file

## License

GPLv3 or later.
