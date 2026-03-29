{
  config,
  pkgs,
  ...
}: {
  imports = [../home.nix];
  home.username = "$U_CTX";
  home.homeDirectory = "/Users/$U_CTX";
}
