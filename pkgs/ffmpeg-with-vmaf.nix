{ pkgs }:
pkgs.ffmpeg-full.overrideAttrs (old: {
  #
  buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.libvmaf ];
  configureFlags = (builtins.filter (f: f != "--disable-libvmaf") (old.configureFlags or [ ])) ++ [
    "--enable-libvmaf"
  ];
})
