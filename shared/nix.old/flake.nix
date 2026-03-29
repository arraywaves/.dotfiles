{
  description = "$U_CTX Nix Sys flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    # nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    mac-app-util.url = "github:hraban/mac-app-util";
    # home-manager = {
    #     url = "github:nix-community/home-manager";
    #     inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = inputs @ {
    self,
    nix-darwin,
    nixpkgs,
#    nix-homebrew,
    mac-app-util,
  }: let
    configuration = {
      pkgs,
      config,
      ...
    }: {
      # Allow closed-source packages
      nixpkgs.config.allowUnfree = true;

      # Common/shared packages
      environment.systemPackages = [
        pkgs.alejandra # nix formatter `nix fmt`
        pkgs.bat # Cat(1) clone with syntax highlighting `> bat filename`
        pkgs.bun
        pkgs.curl
        pkgs.eza # better ls
        pkgs.ffmpeg
        pkgs.fzf # fuzzy finder (excellent cli search)
        pkgs.gh # github cli
        pkgs.git
        pkgs.gitea
        pkgs.go
        # pkgs.home-manager
        pkgs.imagemagick
        pkgs.jq # JSON parser
        pkgs.nixd # required for nix formatting
        pkgs.nodejs_23 # v23
        pkgs.nodePackages.prettier
        pkgs.ollama
        pkgs.php
        pkgs.pnpm
        pkgs.ripgrep # faster grep (text search)
        pkgs.rustup
        pkgs.superfile
        pkgs.tree
        pkgs.tmux # terminal multiplexer
        pkgs.vscode
        pkgs.wasm-pack
        pkgs.watchman # file watcher required for expo
        pkgs.yt-dlp
      ];

      # Common/shared font management
      fonts.packages = [
        pkgs.inter
        pkgs.jetbrains-mono
        pkgs.noto-fonts
        pkgs.nerd-fonts.zed-mono
      ];

      # Necessary for using flakes
      nix.settings.experimental-features = "nix-command flakes";

      # Store Git commit hash (optional)
      system.configurationRevision = self.rev or self.dirtyRev or null;
    };
  in {
    # Nix system-specific configurations
    darwinConfigurations."macbook" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        ./darwin/macbook.nix
#         home-manager.darwinModules.home-manager
#         {
#             home-manager.useGlobalPkgs = true;
#             home-manager.useUserPackages = true;
#             home-manager.users.$U_CTX = import ./darwin/home.nix;
#         }
        mac-app-util.darwinModules.default
#        nix-homebrew.darwinModules.nix-homebrew
#        {
#          nix-homebrew = {
#            enable = true;
#            enableRosetta = true; # Apple Silicon only.
#            user = "$U_CTX";
#            autoMigrate = true; # If Homebrew is already installed
#            mutableTaps = true; # Imperative `brew tap` installs
#          };
#        }
      ];
    };
    nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
      modules = [
        configuration
        ./linux/nixos.nix
        # home-manager.nixosModules.home-manager
        # {
        #     home-manager.useGlobalPkgs = true;
        #     home-manager.useUserPackages = true;
        #     home-manager.users.$U_CTX = import ./linux/home.nix;
        # }
      ];
    };

    #Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."macbook".pkgs;
    nixosPackages = self.nixosConfigurations."nixos".pkgs;

    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
    formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.alejandra;
  };
}
