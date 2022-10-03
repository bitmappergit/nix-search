{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.05;
    flake-utils.url = github:numtide/flake-utils;
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        haskellPackages = pkgs.haskell.packages.ghc924.override {
          overrides = self: super: {
            hpack = super.hpack_0_35_0;
          };
        };
      in rec {
        packages = {
          nix-search = haskellPackages.callCabal2nix "nix-search" ./. {};
          default = packages.nix-search;
        };

        devShell = haskellPackages.shellFor {
          packages = pkgs: [ packages.nix-search ];
          
          withHoogle = true;
          
          buildInputs = [
            pkgs.haskell.compiler.ghc924
            haskellPackages.cabal-install
            haskellPackages.cabal2nix
            haskellPackages.haskell-language-server
          ];
        };
      }
    );
}
