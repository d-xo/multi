{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    foundry.url = "github:shazow/foundry.nix/monthly";
    solc = {
      url = "github:hellwolf/solc.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = ins: ins.flake-utils.lib.eachDefaultSystem(system: let
    pkgs = import ins.nixpkgs {
      inherit system;
      overlays = [
        ins.solc.overlay
        ins.foundry.overlay
      ];
    };
    solc = (ins.solc.mkDefault pkgs pkgs.solc_0_8_27);
  in {
    devShells.default = pkgs.mkShell {
      DAPP_SOLC="${solc}/bin/solc";
      buildInputs = [
        pkgs.foundry-bin
        solc
      ];
    };
  });
}
