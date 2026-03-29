{
  pkgs,
  config,
  ...
}: let
  user = "$U_CTX";
  userHome = "/Users/${user}";
in {
  system.build.applications = pkgs.lib.mkForce (
    pkgs.buildEnv {
      name = "applications";
      paths = config.environment.systemPackages;
      pathsToLink = "/Applications";
    }
  );

  environment = {
    variables = {
      JAVA_HOME = "/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home";
      ANDROID_HOME = "/Users/${user}/Library/Android/sdk";
      PNPM_HOME = "/Users/${user}/Library/pnpm";
    };
    
    # List packages installed in system profile. To search by name, run:
    # $ nix-env -qaP | grep wget
    systemPackages = [
      pkgs.cocoapods
    ];
    
    systemPath = [
      "/opt/homebrew/bin"
      "/run/current-system/sw/bin"
    ];
    
    shellAliases = {
      gaa = "git add --all";
      gcm = "git commit -m";
      gps = "git push";
      gpl = "git pull";
      gco = "git checkout";
      gcb = "git checkout -b";
      gbr = "git branch";
      glg = "git log --pretty=format:'%C(yellow)%h %Cred%ad %Cblue%an%Cgreen%d %Creset%s' --graph --date=short";
    };
  };
  

  # Homebrew
  system.activationScripts.preUserActivation.text = ''
    export PATH="/opt/homebrew/bin:$PATH"

    if ! command -v brew >/dev/null 2>&1; then
      echo "Installing Homebrew..."
      NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    eval "$(/opt/homebrew/bin/brew shellenv)"
  '';

  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";
    onActivation.autoUpdate = false;
    onActivation.upgrade = false;
    onActivation.extraFlags = [
      "--verbose"
      "--file=${userHome}/.dotfiles/config/homebrew/Brewfile"
    ];
    global = {
      brewfile = true;
      lockfiles = false;
    };
  };

  # System settings:
  system.defaults = {
    # Hide Dock:
    dock.autohide = true;
    # Apps in Dock:
    dock.persistent-apps = [
      "/System/Applications/Mail.app"
      "/System/Applications/Calendar.app"
      "/Applications/monday.com.app"
      "${userHome}/Applications/Obsidian.app"
      "${userHome}/Applications/Discord.app"
      "${userHome}/Applications/Google Chrome.app"
      "/Applications/Zen Browser.app"
      "${userHome}/Applications/Spotify.app"
      "${userHome}/Applications/Docker.app"
      "${userHome}/Applications/Warp.app"
      "${userHome}/Applications/Zed.app"
      "${userHome}/Applications/Blender.app"
      "${userHome}/Applications/Figma.app"
    ];
    # Default Finder to column view:
    finder.FXPreferredViewStyle = "clmv";
    # Disable guest login:
    loginwindow.GuestEnabled = false;
    # Use 24-hour time:
    NSGlobalDomain.AppleICUForce24HourTime = true;
    NSGlobalDomain.AppleInterfaceStyle = "Dark";
    NSGlobalDomain.KeyRepeat = 2;
  };

  # Shell
  programs.zsh.enable = true; # default shell on macOS 15 Sequoia
  
  # programs.fish.enable = true;

  # Enable Services
  services = {
    postgresql = {
      enable = false;
      package = pkgs.postgresql;
      dataDir = "${userHome}/.postgres";
      enableTCPIP = true;
      authentication = pkgs.lib.mkForce ''
        local all all trust
        host all all 127.0.0.1/32 trust
        host all all ::1/128 trust
      '';
    };
    redis = {
        enable = true;
        port = 6379;
    };
  };

  # Set Group ID as set on install
  ids.gids.nixbld = 30000;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
