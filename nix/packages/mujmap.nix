{
  inputs,
  pkgs,
  ...
}: let
  craneLib = inputs.crane.mkLib pkgs;
  lib = pkgs.lib;

  mdFilter = path: _type: builtins.match ".*md$" path != null;
  mdOrCargo = path: type:
    (mdFilter path type) || (craneLib.filterCargoSources path type);

  src = lib.cleanSourceWith {
    src = ./../../.;
    filter = mdOrCargo;
    name = "source";
  };

  common-args = {
    inherit src;
    strictDeps = true;

    propagatedBuildInputs = [pkgs.notmuch];
  };

  cargoArtifacts = craneLib.buildDepsOnly common-args;

  mujmap = craneLib.buildPackage (common-args
    // {
      inherit cargoArtifacts;

      passthru.tests = {
        mujmap-clippy = craneLib.cargoClippy (common-args
          // {
            inherit cargoArtifacts;
            cargoClippyExtraArgs = "--all-targets -- --deny warnings";
          });

        mujmap-fmt = craneLib.cargoFmt {
          inherit src;
        };
      };
    });
in
  mujmap
