{
  config,
  pkgs,
  ...
}: {
  # Common/shared config files
  home.file = {
    ".dotfiles/config/kitty/kitty.conf".source = ../config/kitty/kitty.conf;
    ".dotfiles/config/prettier/.prettierrc".source = ../config/prettier/.prettierrc;
  };

  home.stateVersion = "23.11";
}
