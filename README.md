# gguf.el

An Emacs major mode for viewing metadata from GGUF (GPT-Generated
Unified Format) model files.

## Requirements

- Emacs 29.1 or later
- The `ggufmeta` binary installed somewhere in `PATH`

## How it works

When you visit a `.gguf` file, Emacs normally reads the entire file into
memory.  For multi-gigabyte GGUF model files this is wasteful since we
only need the metadata.

`gguf.el` avoids this by advising `insert-file-contents` at the
Emacs Lisp level.  When it detects a `.gguf` file, it injects a tiny
placeholder string (a few bytes) instead of reading the actual file.
The `gguf-mode` major mode then replaces this placeholder with the
metadata output from the `ggufmeta` binary.

The raw GGUF bytes are **never** loaded into an Emacs buffer.

The `ggufmeta` binary must accept a single file argument and print a
human-readable description of the GGUF file to stdout.

## Installation

If you use `use-package`:

```elisp
(use-package gguf
  :load-path "/path/to/gguf.el"
  :config
  (setq gguf-ggufmeta-program "ggufmeta"))
```

Or manually:

```elisp
(add-to-list 'load-path "/path/to/gguf.el")
(require 'gguf)
```

## Usage

### Opening a GGUF file

**Via `auto-mode-alist`:** simply visit any `.gguf` file — the mode
activates automatically and displays the metadata.

**Via `M-x`:** run `M-x gguf-open` and select the GGUF file to
inspect.  A dedicated `*gguf: <name>*` buffer is shown.

### Keybindings

| Key | Command          | Description                   |
|-----|------------------|-------------------------------|
| `g` | `gguf-refresh`   | Re-run `ggufmeta` on the file |
| `q` | `quit-window`    | Dismiss the metadata buffer   |
| `n` | `next-line`      | Move to next line             |
| `p` | `previous-line`  | Move to previous line         |
| `RET` | `gguf-show-help` | Open help for `gguf-mode`     |

### Customization

- `gguf-ggufmeta-program` — name or path of the `ggufmeta` executable
  (default: `"ggufmeta"`)
- `gguf-auto-update` — if non-nil (the default), automatically
  populate the buffer when visiting a `.gguf` file

## License

GPLv3 or later.
