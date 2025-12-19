# Auto-generated machine-specific configuration - TEMPLATE
# ========================================================
# This is a TEMPLATE file that gets processed by generate-user-config.sh
# The actual user-config.nix is generated from this template and git-ignored
#
# DO NOT EDIT user-config.nix directly - edit this template instead
# DO NOT COMMIT user-config.nix - it is machine-specific and gitignored
#
# Template placeholders (replaced by generate-user-config.sh):
#   jaspreetsingh        - Replaced with actual username (e.g., "tagpro")
#   /Users/jaspreetsingh  - Replaced with actual home directory (e.g., "/home/tagpro")
#   Jaspreet Singh   - Replaced with git user name (e.g., "Jaspreet Singh")
#   6873201+tagpro@users.noreply.github.com  - Replaced with git user email (e.g., "user@example.com")
#   Jaspreets-MacBook-Pro.local        - Replaced with actual hostname
#   aarch64-linux      - Replaced with nix system identifier (x86_64-linux, aarch64-linux)
#   arm64            - Replaced with architecture (x86_64, arm64)
#   Unknown OS         - Replaced with OS pretty name
#   25.1.0          - Replaced with kernel version
#   2025-12-19 02:08:31 UTC - Replaced with generation timestamp
#
# Generated: 2025-12-19 02:08:31 UTC
#
# Machine Information:
#   Hostname: Jaspreets-MacBook-Pro.local
#   System: aarch64-linux
#   Architecture: arm64
#   OS: Unknown OS
#   Kernel: 25.1.0
#
# User Information:
#   Username: jaspreetsingh
#   Home: /Users/jaspreetsingh

{
  # User configuration
  home.username = "jaspreetsingh";
  home.homeDirectory = "/Users/jaspreetsingh";
  
  # Git configuration
  programs.git = {
    userName = "Jaspreet Singh";
    userEmail = "6873201+tagpro@users.noreply.github.com";
  };
}
