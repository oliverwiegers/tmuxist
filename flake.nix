{
  description = ".tmuxist - Self contained tmux poweruser config. Including remote awereness for nesting.";

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

        tmuxConfig = pkgs.writeText "tmux.conf" (builtins.readFile ./tmux/.tmux.conf);

        plugins = import ./plugins.nix {inherit pkgs;};
        pluginsPath = pkgs.lib.makeBinPath plugins;

        tmux-unwrapped = pkgs.tmux.overrideAttrs (oldAttrs: {
          buildInputs = (oldAttrs.buildInputs or [ ]) ++ [ pkgs.makeWrapper ];

          postInstall = (oldAttrs.postInstall or "") + ''
            mkdir $out/libexec

            mv $out/bin/tmux $out/libexec/tmux-unwrapped

            makeWrapper $out/libexec/tmux-unwrapped $out/bin/tmux \
                --add-flags "-f ${tmuxConfig}"
                --prefix PATH : "${pluginsPath}"
          '';
        });
      in rec {
        formatter = pkgs.alejandra;

        defaultApp = apps.tmux;
        defaultPackage = packages.tmux;

        apps.tmux = {
          type = "app";
          program = "${defaultPackage}/bin/tmux";
        };

        # Use wrapper to add plugins and custom configuration.
        packages.tmux = tmux-unwrapped;
      }
    );
}
