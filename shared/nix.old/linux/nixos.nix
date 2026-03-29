{pkgs, ...}: {
  # Basic Linux-specific config
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  environment.systemPackages = [
    pkgs.android-studio
    pkgs.bitwarden-desktop
    pkgs.blender
    pkgs.colima # container daemon (for docker) `colima start`
    pkgs.discord
    pkgs.deno
    pkgs.docker
    pkgs.docker-compose
    pkgs.figma-linux
    pkgs.firefox
    pkgs.github-desktop
    pkgs.postgresql
    pkgs.libpq
    pkgs.python3Full # latest py3
    pkgs.mongosh # mongodb cli tool
    pkgs.obsidian
    pkgs.redis
    pkgs.spotify
    pkgs.ungoogled-chromium
    pkgs.vlc
    pkgs.warp-terminal
    pkgs.zed-editor
    pkgs.zulu
  ];

  # Use the version you initially installed with... Once set, you shouldn't change this value even when you upgrade your system. It's meant to stay at the version you initially installed with.
  system.stateVersion = "23.11";

  nixpkgs.hostPlatform = "x86_64-linux"; # or aarch64-linux
}
