{
  config,
  pkgs,
  ...
}: {
  imports = [../home.nix];
  home.username = "$U_CTX";
  home.homeDirectory = "/home/$U_CTX";
}
