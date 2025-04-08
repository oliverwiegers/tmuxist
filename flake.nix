{
  description = "tmuxist - Self contained tmux poweruser config. Including remote awereness for nesting.";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixpkgs-unstable";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };

        plugins = import ./plugins.nix {inherit pkgs;};
        dependencies = import ./dependencies.nix {inherit pkgs;};

        pluginConfig = pkgs.lib.concatMapStringsSep "\n" (plugin: "run-shell ${plugin.rtp}") plugins;

        # Replace plugin config for installation using git with plugin config using this flake.
        tmuxConfig =
          builtins.replaceStrings
          ["# NIX PLUGIN CONFIG PLACEHOLDER" "run-shell ~/"]
          [pluginConfig "# run-shell ~/"]
          (builtins.readFile ./tmux/.tmux.conf);
        tmuxConfigPath = pkgs.writeText "tmux.conf" tmuxConfig;

        tmuxWrapped = pkgs.tmux.overrideAttrs (oldAttrs: {
          buildInputs = (oldAttrs.buildInputs or []) ++ [pkgs.makeWrapper];

          postInstall =
            (oldAttrs.postInstall or "")
            + ''
              wrapProgram $out/bin/tmux \
                  --add-flags "-f ${tmuxConfigPath}" \
                  --prefix PATH : "${pkgs.lib.makeBinPath dependencies}"
            '';
        });
      in rec {
        # Use wrapper to add plugins and custom configuration.
        packages.tmux = tmuxWrapped;

        apps.tmux = {
          type = "app";
          program = "${defaultPackage}/bin/tmux";
        };

        defaultApp = apps.tmux;
        defaultPackage = packages.tmux;

        formatter = pkgs.alejandra;

        devShells = {
          default = pkgs.mkShell {
            NIX_CONFIG = "extra-experimental-features = nix-command flakes";
            nativeBuildInputs = with pkgs; [
              git
              pre-commit
              ruby
            ];
          };
        };
      }
    );
}
