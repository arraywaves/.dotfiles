# Nix Setup (macOS 15 Sequoia)

## A. Installation

**Step 1**
Run `NIX_FIRST_BUILD_UID="351" sh <(curl -L https://nixos.org/nix/install)` in a new terminal window.

`NIX_FIRST_BUILD_UID` is just a one-time environment variable for the installation - it tells Nix where to start numbering its build users. After installation, you won't need to use it again.

The `351` value isn't arbitrary - it's specifically chosen to avoid conflicts with macOS Sequoia's system users.

Open a new terminal window and run `nix-shell -p neofetch --run neofetch` to check it was successful. _Neofetch won't permanently install with `nix-shell`, it will temporarily modify the `$PATH` environment variable._

**Step 2**
Make a new config directory with `mkdir ~/.config/nix` (in the user folder but it can be wherever you want), `cd` into it. I used `~/.dotfiles/nix`

**Step 3**
Create `flake.nix` with `nix flake init -t nix-darwin --extra-experimental-features "nix-command flakes"`, experimental features are required.

**Step 4**
Configure the nix flake located at `~/.dotfiles/nix/flake.nix` or whichever path was specified before.

**Step 5**
Install nix-darwin with the flake configuration:
`nix run nix-darwin/master#darwin-rebuild --extra-experimental-features "nix-command flakes" -- switch --flake ~/.dotfiles/nix#macbook`

Future rebuilds can now just use `darwin-rebuild switch --flake ~/.dotfiles/nix#macbook`

Open a new terminal window and run `which darwin-rebuild` to check it was successful.

## B. Installing Packages

**Step 1**
The equivalent of Hombrew's `brew install [package-name]` is `nix-env -i [package-name]` but it's recommended to edit the config declaratively instead.

This array contains all of the packages to be installed with `darwin-rebuild`:

```nix
environment.systemPackages =
    [ pkgs.neovim
    ];
```

**Step 2**
Search for CLI packages with `nix search nixpkgs [package-name]` or go to `https://search.nixos.org/packages` and add them to the `environment.systemPackages` variable.

To install GUI packages there are 2 methods:

1. Check the nixpkgs repo at `https://github.com/NixOS/nixpkgs`, packages in here should be cross-platform and can be added to the `environment.systemPackages` list.
2.

**Step 3**
To install fonts, add font packages to the `fonts.packages` list:

```nix
	fonts.packages = [
	    pkgs.inter
	    pkgs.jetbrains-mono
	    pkgs.nerd-fonts.zed-mono
	    pkgs.nerd-fonts.noto
	];
```

**Step 4**
Cleanup old packages, check:

- `npm list -g depth=0`
- `pnpm list -g`
- `brew leaves`

**Step 5**
Transfer an existing, or add a new, Homebrew installation to Nix:

```nix
	inputs = {
	    //...
	    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
	};
	outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
        let configuration = { pkgs, config, ... }: {
        //...
        homebrew = {
            enable = true;
            brews = [
                # Search for Mac App Store IDs with `mas search [app_name]`:
                "mas"
            ];
            casks = [
                "hammerspoon"
                "firefox"
                "iina"
                "the-unarchiver"
                "zulu"
            ];
            # Add Mac App Store apps with `"App Name" = [id_number]`:
            masApps = {
                "Bitwarden" = 1352778147;
                "CotEditor" = 1024640650;
                "Xcode" = 497799835;
            };
            # Cleanup of any non-declared packages:
            onActivation.cleanup = "zap";
            onActivation.autoUpdate = true;
            onActivation.upgrade = true;
        };
    //...

	darwinConfigurations."macbook" = nix-darwin.lib.darwinSystem {
        modules = [
            configuration
            nix-homebrew.darwinModules.nix-homebrew
            {
                nix-homebrew = {
                    enable = true;
                    # Apple Silicon only.
                    enableRosetta = true;
                    # User owning the Homebrew prefix:
                    user = "$U_CTX";
                    # If Homebrew is already installed:
                    autoMigrate = true;
                };
            }
        ];
    };
```

Run `darwin-rebuild switch --flake ~/.dotfiles/nix#macbook` to install or update everything.

## System Settings

Check `https://mynixos.com/` or run `darwin-help` to find a list of parameters to change.

```nix
	# System settings:
	system.defaults = {
	    # Hide Dock:
	    dock.autohide = true;
	    # Apps in Dock:
	    # dock.persistent-apps = [
	        # "path/to/App.app"
	        # "${pkgs.obsidian}/Applications/Obsidian.app"
	    # ];
	    # Default Finder to column view:
	    finder.FXPreferredViewStyle = "clmv";
	    # Disable guest login:
	    loginwindow.GuestEnabled = false;
	    # Use 24-hour time:
	    NSGlobalDomain.AppleICUForce24HourTime = true;
	    NSGlobalDomain.AppleInterfaceStyle = "Dark";
	    NSGlobalDomain.KeyRepeat = 2;
	};
```
