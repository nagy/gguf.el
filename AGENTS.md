# AGENTS.md

Nix flake repo (flake-parts). Validate changes with:

```bash
nix flake check && nix build && nix fmt
```

- `flake.nix` — builds the `gguf` Emacs package via `melpaBuild`.
- Package `version` comes from `self.lastModifiedDate`: the flake passes
  `self` into `outputs` and derives `0-unstable-YYYY-MM-DD` from the
  source tree date (epoch fallback for non-git sources).  No manual
  version bumps.
- New files must be `git add`ed or they are invisible to `nix build`.
- Formatting: `nix fmt` (treefmt + nixfmt). Never run formatters standalone.
- Byte-compilation warnings fail the build (`turnCompilationWarningToError`).
- Package shells out to external `ggufmeta` binary — not baked into the store.
