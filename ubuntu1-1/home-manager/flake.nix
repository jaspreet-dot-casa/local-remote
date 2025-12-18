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
      # Function to create Home Manager configuration for a specific user
      mkHomeConfiguration = { system, username, homeDirectory }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          modules = [ 
            ./home.nix 
            {
              # Override username and homeDirectory
              home.username = username;
              home.homeDirectory = homeDirectory;
            }
          ];
        };
    in {
      homeConfigurations = {
        # Default configuration (x86_64-linux for Ubuntu servers)
        ubuntu = mkHomeConfiguration {
          system = "x86_64-linux";
          username = "ubuntu";  # Default Ubuntu user
          homeDirectory = "/home/ubuntu";
        };
        
        # ARM configuration (for testing on Apple Silicon or ARM servers)
        ubuntu-aarch64 = mkHomeConfiguration {
          system = "aarch64-linux";
          username = "ubuntu";
          homeDirectory = "/home/ubuntu";
        };
        
        # Test user configuration (for Docker testing)
        testuser = mkHomeConfiguration {
          system = "aarch64-linux";
          username = "testuser";
          homeDirectory = "/home/testuser";
        };
        
        testuser-x86 = mkHomeConfiguration {
          system = "x86_64-linux";
          username = "testuser";
          homeDirectory = "/home/testuser";
        };
      };
    };
}
