{
  description = "Prebuilt/cached packages (ffmpeg-with-vmaf, etc.)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs = { self, nixpkgs, ... }:
  let
    systems = [ "x86_64-linux" "aarch64-darwin" ];
    forAllSystems = f:
      builtins.listToAttrs (map (system: { name = system; value = f system; }) systems);
  in
  {
    packages = forAllSystems (system:
      let
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      in
      {
        ffmpeg-with-vmaf = import ./pkgs/ffmpeg-with-vmaf.nix { inherit pkgs; };

        # Optional: a roll-up "default" with your favorite tools
        default = pkgs.symlinkJoin {
          name = "prebuilt-tools";
          paths = [
            self.packages.${system}.ffmpeg-with-vmaf
          ];
        };
      });

    devShells = forAllSystems (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        default = pkgs.mkShell { packages = [ pkgs.cachix ]; };
      });
  }
}

