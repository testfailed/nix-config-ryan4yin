# just is a command runner, Justfile is very similar to Makefile, but simpler.

# use nushell for shell commands
set shell := ["nu", "-c"]

############################################################################
#
#  Nix commands related to the local machine
#
############################################################################

i3 mode="default":
  use utils.nu *; \
  nixos-switch ai-i3 {{mode}}

hypr mode="default":
  use utils.nu *; \
  nixos-switch ai-hyprland {{mode}}


s-i3 mode="default":
  use utils.nu *; \
  nixos-switch shoukei-i3 {{mode}}


s-hypr mode="default":
  use utils.nu *; \
  nixos-switch shoukei-hyprland {{mode}}

# Run eval tests
test:
  nix eval .#evalTests --show-trace --print-build-logs --verbose

# update all the flake inputs
up:
  nix flake update

# Update specific input
# Usage: just upp nixpkgs
upp input:
  nix flake lock --update-input {{input}}

# List all generations of the system profile
history:
  nix profile history --profile /nix/var/nix/profiles/system

# Open a nix shell with the flake
repl:
  nix repl -f flake:nixpkgs

# remove all generations older than 7 days
clean:
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

# Garbage collect all unused nix store entries
gc:
  # garbage collect all unused nix store entries
  sudo nix store gc --debug
  sudo nix-collect-garbage --delete-old

# Remove all reflog entries and prune unreachable objects
gitgc:
  git reflog expire --expire-unreachable=now --all
  git gc --prune=now

############################################################################
#
#  Darwin related commands, harmonica is my macbook pro's hostname
#
############################################################################

darwin-set-proxy:
  sudo python3 scripts/darwin_set_proxy.py
  sleep 1sec

darwin-rollback:
  use utils.nu *; \
  darwin-rollback

# Deploy to harmonica(macOS host)
ha mode="default":
  use utils.nu *; \
  darwin-build "harmonica" {{mode}}; \
  darwin-switch "harmonica" {{mode}}

# Depoly to fern(macOS host)
fe mode="default": darwin-set-proxy
  use utils.nu *; \
  darwin-build "fern" {{mode}}; \
  darwin-switch "fern" {{mode}}

# Reload yabai and skhd(macOS)
yabai-reload:
  launchctl kickstart -k "gui/502/org.nixos.yabai";
  launchctl kickstart -k "gui/502/org.nixos.skhd"; 

############################################################################
#
#  Homelab - Virtual Machines running on Kubevirt
#
############################################################################

# Remote deployment via colmena
col tag:
  colmena apply --on '@{{tag}}' --verbose --show-trace

# Build and upload a vm image
upload-vm name mode="default":
  use utils.nu *; \
  upload-vm {{name}} {{mode}}

# Deploy all the KubeVirt nodes(Physical machines running KubeVirt)
lab:
  colmena apply --on '@virt-*' --verbose --show-trace

# Deploy all the VMs running on KubeVirt
vm:
  colmena apply --on '@homelab-*' --verbose --show-trace

aqua:
  colmena apply --on '@aqua' --verbose --show-trace
  # some config changes require a restart of the dae service
  ssh root@aquamarine "sudo systemctl stop dae; sleep 1; sudo systemctl start dae"

ruby:
  colmena apply --on '@ruby' --verbose --show-trace

ruby-local mode="default":
  use utils.nu *; \
  nixos-switch ruby {{mode}}

kana:
  colmena apply --on '@kana' --verbose --show-trace

############################################################################
#
# Kubernetes related commands
#
############################################################################

k3s:
  colmena apply --on '@k3s-*' --verbose --show-trace

master:
  colmena apply --on '@k3s-prod-1-master-*' --verbose --show-trace

worker:
  colmena apply --on '@k3s-prod-1-worker-*' --verbose --show-trace

k3s-test:
  colmena apply --on '@k3s-test-*' --verbose --show-trace

############################################################################
#
#  RISC-V related commands
#
############################################################################

riscv:
  colmena apply --on '@riscv' --verbose --show-trace

nozomi:
  colmena apply --on '@nozomi' --verbose --show-trace

yukina:
  colmena apply --on '@yukina' --verbose --show-trace

############################################################################
#
# Aarch64 related commands
#
############################################################################

aarch:
  colmena apply --on '@aarch' --build-on-target --verbose --show-trace

suzu:
  colmena apply --on '@suzu' --build-on-target --verbose --show-trace

suzu-local mode="default":
  use utils.nu *; \
  nixos-switch suzu {{mode}}

rakushun:
  colmena apply --on '@rakushun' --build-on-target --verbose --show-trace

rakushun-local mode="default":
  use utils.nu *; \
  nixos-switch rakushun {{mode}}

############################################################################
#
#  Misc, other useful commands
#
############################################################################

fmt:
  # format the nix files in this repo
  nix fmt

path:
   $env.PATH | split row ":"

nvim-test:
  rm -rf $"($env.HOME)/.config/astronvim/lua/user"
  rsync -avz --copy-links --chmod=D2755,F744 home/base/desktop/editors/neovim/astronvim_user/ $"($env.HOME)/.config/astronvim/lua/user"

nvim-clean:
  rm -rf $"($env.HOME)/.config/astronvim/lua/user"

# =================================================
# Emacs related commands
# =================================================

emacs-plist-path := "~/Library/LaunchAgents/org.nix-community.home.emacs.plist"

reload-emacs-cmd := if os() == "macos" {
    "launchctl unload " + emacs-plist-path
    + "\n"
    + "launchctl load " + emacs-plist-path
    + "\n"
    + "tail -f ~/Library/Logs/emacs-daemon.stderr.log"
  } else {
    "systemctl --user restart emacs.service"
    + "\n"
    + "systemctl --user status emacs.service"
  }

emacs-test:
  rm -rf $"($env.HOME)/.config/doom"
  rsync -avz --copy-links --chmod=D2755,F744 home/base/desktop/editors/emacs/doom/ $"($env.HOME)/.config/doom"
  doom clean
  doom sync

emacs-clean:
  rm -rf $"($env.HOME)/.config/doom/"

emacs-purge:
  doom purge
  doom clean
  doom sync

emacs-reload:
  doom sync
  {{reload-emacs-cmd}}


# =================================================
#
# Kubernetes related commands
#
# =================================================


del-failed:
   kubectl delete pod --all-namespaces --field-selector="status.phase==Failed"
