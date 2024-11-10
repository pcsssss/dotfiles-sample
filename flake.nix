{
  description = "Example Darwin system flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager}:
  let
    user = "yourusername";
    hostnames = {
      m1 = "MacBook-Pro";
    };
    mkDarwinConfig = { system, hostname }: nix-darwin.lib.darwinSystem {
      inherit system;
      modules = [
        ({ pkgs, ... }: {
          # System paths
          environment.systemPath = [
            "/opt/homebrew/bin"
            "/opt/homebrew/sbin"
          ];
          # System packages
          environment.systemPackages = with pkgs; [
            vim jq htop black kubectl k9s s3cmd lazydocker lazygit starship python312
            zoxide fzf direnv mas nodejs curl git gitflow
          ];
          services.nix-daemon.enable = true;
          nix.settings.experimental-features = "nix-command flakes";
          programs.zsh = {
            enable = true;
            shellInit = ''
              export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
              export ZDOTDIR=~/Projects/dotfiles/configs
              eval "$(direnv hook zsh)"
              eval "$(zoxide init --cmd cd zsh)"
              eval "$(starship init zsh)"

              # NVM setup
              export NVM_DIR="$HOME/.nvm"
              [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
              [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

              function cd () {
                  builtin cd "$@" && ls
              }
              
              alias ldd=lazydocker
            '';
          };

          # Dock configuration
          system.defaults.dock = {
            autohide = true;
            orientation = "right";
            tilesize = 36;
            mru-spaces = false;
          };

          # Finder
          system.defaults.finder = {
            AppleShowAllFiles = true;
            FXPreferredViewStyle = "Nlsv";
            QuitMenuItem = true;
            ShowPathbar = true;
            FXDefaultSearchScope = "SCcf";
            AppleShowAllExtensions = true;
            CreateDesktop = false;
          };

          # Trackpad configuration
          system.defaults.trackpad = {
            Clicking = true;
            TrackpadRightClick = true;
            TrackpadThreeFingerDrag = false;
            ActuationStrength = 1; # Firmness level (0 is lightest, 2 is heaviest)
            FirstClickThreshold = 1; # Sensitivity (0 is lightest, 3 is heaviest)
            SecondClickThreshold = 1; # Sensitivity for secondary click
          };

          # Keyboard configuration
          system.defaults.NSGlobalDomain = {
            InitialKeyRepeat = 15; # Normal minimum is 15 (225 ms)
            KeyRepeat = 2; # Normal minimum is 2 (30 ms)
            ApplePressAndHoldEnabled = false; # Disable press-and-hold for keys in favor of key repeat
            "com.apple.keyboard.fnState" = true;
          };

          system.keyboard = {
            enableKeyMapping = true;
            remapCapsLockToEscape = false;
            swapLeftCommandAndLeftAlt = false;
          };


          # Menu bar configuration
          system.defaults = {
            menuExtraClock = {
              Show24Hour = true;
              ShowDate = 0;
            };
          };

          # Homebrew configuration
          homebrew = {
            enable = true;
            onActivation = {
              autoUpdate = true;
              cleanup = "zap";
            };
            taps = [
              "koekeishiya/formulae"
            ];
            casks = [
              "karabiner-elements"
              "cursor"
              "spotify"
              "discord"
              "insomnia"
              "vlc"
              "brave-browser"
              "raycast"
              "whatsapp"
              "docker"
              "macvim"
              "transmission"
              "google-chrome"
              "notion"
              "inkscape"
              "ukelele"
              # Add other casks here
            ];
            brews = [
              "cheat"
              "wget"
              "ffmpeg"
              # Add formulae here if needed
            ];
            masApps = {
              "WireGuard" = 1451685025;
              # Add other App Store apps here
            };
          };

          # Karabiner Elements autostart configuration
          launchd.user.agents.karabiner-elements = {
            path = [ "/usr/bin" ];
            serviceConfig = {
              Label = "org.pqrs.karabiner.karabiner_console_user_server";
              ProgramArguments = [
                "/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_console_user_server"
              ];
              ProcessType = "Background";
              RunAtLoad = true;
            };
          };

          system.configurationRevision = self.rev or self.dirtyRev or null;
          system.stateVersion = 4;
          nixpkgs.hostPlatform = system;
        })
        home-manager.darwinModules.home-manager {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
          };
          home-manager.users.${user} = { pkgs, ... }: {
            home.stateVersion = "23.11";
            home.homeDirectory = pkgs.lib.mkForce "/Users/${user}";

            home.activation = {
              installNvm = home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
                if [ ! -d "$HOME/.nvm" ]; then
                  # Download the NVM installation script
                  ${pkgs.curl}/bin/curl -o /tmp/nvm-install.sh https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh

                  # Set the necessary environment variables
                  export PATH="${pkgs.git}/bin:$PATH"
                  export HOME="$HOME"

                  # Run the installation script
                  ${pkgs.bash}/bin/bash /tmp/nvm-install.sh

                  # Clean up
                  rm /tmp/nvm-install.sh

                  echo "NVM installed. Please restart your terminal or run 'source ~/.zshrc' to start using it."
                else
                  echo "NVM is already installed."
                fi
              '';
            };
            
            # Karabiner Elements configuration
            home.file.".config/karabiner/karabiner.json".text = builtins.toJSON {
              global = {
                check_for_updates_on_startup = true;
                show_in_menu_bar = true;
                show_profile_name_in_menu_bar = false;
              };
              profiles = [
                {
                  name = "Default profile";
                  selected = true;
                  simple_modifications = [
                    {
                      from = { key_code = "caps_lock"; };
                      to = [ { key_code = "escape"; } ];
                    }
                    {
                      from = { key_code = "escape"; };
                      to = [ { key_code = "caps_lock"; } ];
                    }
                    {
                      from = { key_code = "right_option"; };
                      to = [ { key_code = "right_command"; } ];
                    }
                    {
                      from = { key_code = "right_command"; };
                      to = [ { key_code = "right_option"; } ];
                    }
                  ];
                  complex_modifications = {
                    rules = [
                      {
                        description = "Left option + hjkl to arrow keys";
                        manipulators = [
                          {
                            type = "basic";
                            from = {
                              key_code = "h";
                              modifiers = { 
                                mandatory = ["left_option"];
                                optional = ["any"];
                              };
                            };
                            to = [{ key_code = "left_arrow"; }];
                          }
                          {
                            type = "basic";
                            from = {
                              key_code = "j";
                              modifiers = { 
                                mandatory = ["left_option"];
                                optional = ["any"];
                              };
                            };
                            to = [{ key_code = "down_arrow"; }];
                          }
                          {
                            type = "basic";
                            from = {
                              key_code = "k";
                              modifiers = { 
                                mandatory = ["left_option"];
                                optional = ["any"];
                              };
                            };
                            to = [{ key_code = "up_arrow"; }];
                          }
                          {
                            type = "basic";
                            from = {
                              key_code = "l";
                              modifiers = { 
                                mandatory = ["left_option"];
                                optional = ["any"];
                              };
                            };
                            to = [{ key_code = "right_arrow"; }];
                          }
                        ];
                      }
                    ];
                  };
                }
              ];
            };

            home.file.".config/raycast/config.json".text = builtins.toJSON {
              hotkey = {
                modifier = "cmd";
                key = "space";
              };
              # Add other Raycast configurations here if needed
              accesstoken = "aaaaaaaaaaaaa-aaaaa-aaaaaaaaaaaaaaaaaaaaaaa";
              token = "aaaaaaaaaaaaa-aaaaa-aaaaaaaaaaaaaaaaaaaaaaa";
            };

            programs.direnv = {
              enable = true;
              nix-direnv.enable = true;
            };

            programs.fzf = {
              enable = true;
              enableZshIntegration = true;
            };

            programs.zoxide = {
              enable = true;
              enableZshIntegration = true;
            };

            programs.zsh = {
              enable = true;
              initExtra = ''
                # Any additional zsh configuration can go here
              '';
            };
          };
        }
      ];
    };
  in {
    darwinConfigurations = {
      ${hostnames.m1} = mkDarwinConfig {
        system = "aarch64-darwin";
        hostname = hostnames.m1;
      };
    };
  };
}
