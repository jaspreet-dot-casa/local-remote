{
  description = "Home Manager configuration for Ubuntu server";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      # Support both x86_64 and aarch64 Linux systems
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ];
      
      mkHomeConfiguration = system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          modules = [ ./home.nix ];
        };
    in {
      homeConfigurations = {
        # Default configuration (x86_64-linux for Ubuntu servers)
        ubuntu = mkHomeConfiguration "x86_64-linux";
        
        # ARM configuration (for testing on Apple Silicon or ARM servers)
        ubuntu-aarch64 = mkHomeConfiguration "aarch64-linux";
      };
    };
}
