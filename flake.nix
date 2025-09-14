{
  description = "Prebuilt/cached packages (ffmpeg-with-vmaf, etc.)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs =
    { self, nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forAllSystems =
        f:
        builtins.listToAttrs (
          map (system: {
            name = system;
            value = f system;
          }) systems
        );
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          ffmpeg-with-vmaf = pkgs.ffmpeg-full.overrideAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.libvmaf ];
            configureFlags = (builtins.filter (f: f != "--disable-libvmaf") (old.configureFlags or [ ])) ++ [
              "--enable-libvmaf"
            ];
          });

          # Optional: expose it as default
          default = self.packages.${system}.ffmpeg-with-vmaf;
        }
      ); # ← semicolon required

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell { packages = [ pkgs.cachix ]; };
        }
      ); # ← semicolon required
    };
}
