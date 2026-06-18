{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
  emacs ? pkgs.emacs,
  emacsPackages ? emacs.pkgs,
  melpaBuild ? emacsPackages.melpaBuild,
}:

melpaBuild {
  pname = "gguf";
  version = "0.1.0";
  src = lib.cleanSource ./.;

  turnCompilationWarningToError = true;

  meta = {
    description = "Major mode for viewing GGUF file metadata";
    longDescription = ''
      A major mode for displaying metadata from GGUF (GPT-Generated
      Unified Format) model files using the external ggufmeta binary.
      When visiting a .gguf file, the raw file content is never loaded
      into memory — only the metadata output is shown.
    '';
    license = lib.licenses.agpl3Plus;
    homepage = "https://example.com/gguf";
    maintainers = with lib.maintainers; [ nagy ];
    platforms = lib.platforms.unix;
  };
}
