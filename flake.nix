{
  description = "Major mode for viewing GGUF file metadata (Emacs package)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      # One nixpkgs closure, no duplicates.
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      flake-parts,
      nixpkgs,
      treefmt-nix,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } ({
      # treefmt-nix flakeModule wires up `formatter' and a formatting check.
      imports = [ inputs.treefmt-nix.flakeModule ];

      # Emacs packages are pure Elisp: no ELF binaries, so evaluate on
      # every Linux arch (and darwin if the deps exist there).
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      perSystem =
        {
          system,
          pkgs,
          lib,
          config,
          ...
        }:
        let
          inherit (pkgs.emacsPackages) melpaBuild;
        in
        {
          # One formatter config for the whole repo, driven by `nix fmt';
          # the module also adds a formatting check to `nix flake check'.
          treefmt = {
            projectRootFile = "flake.nix";
            programs.nixfmt.enable = true;
          };

          packages.gguf = melpaBuild {
            pname = "gguf";
            # Nix rejects versions Nixpkgs cannot parse. Convention for
            # unreleased packages: <upstream-version>-unstable-<YYYY-MM-DD>,
            # where the date is the last commit touching the source.
            version = "0.1.0-unstable-2026-08-15";

            src = lib.cleanSource ./.;

            # The package shells out to the external `ggufmeta' binary, which
            # is intentionally NOT baked into the store: users install it (or
            # point `gguf-program' at it) themselves. It must be on `exec-path'.

            # Byte-compilation warnings fail the build. Keep it on: it is
            # the cheapest lint the package will ever get. Silence only
            # genuinely noisy third-party warnings, never your own code.
            turnCompilationWarningToError = true;

            meta = {
              description = "Major mode for viewing GGUF file metadata";
              longDescription = ''
                A major mode for displaying metadata from GGUF (GPT-Generated
                Unified Format) model files using the external ggufmeta binary.
                When visiting a .gguf file, the raw file content is never loaded
                into memory — only the metadata output is shown.
              '';
              # Read the license from the file header — Elisp packages
              # conventionally declare it after ";;; Code:".
              license = lib.licenses.agpl3Plus;
              homepage = "https://github.com/nagy/gguf.el";
              maintainers = with lib.maintainers; [ nagy ];
              platforms = lib.platforms.unix;
            };
          };

          packages.default = config.packages.gguf;

          devShells.default = pkgs.mkShell {
            # Mirror whatever the package needs at runtime when hacking on
            # it: the external CLI, a real Emacs for interactive testing, etc.
            # packages = [ ggufmetaBin ];
          };
        };
    });
}
