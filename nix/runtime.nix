{
  pkgs,
  inputs,
  system,
}:

let
  nixIndex = inputs.nix-index-database.packages.${system}.nix-index-with-db;

  cuaDriver = pkgs.callPackage ./cua-driver.nix { };

  fontPackages = with pkgs; [
    dejavu_fonts
    liberation_ttf
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  fontConfig = pkgs.makeFontsConf {
    fontDirectories = fontPackages;
    includes = [ "${pkgs.fontconfig.out}/etc/fonts/conf.d" ];
  };

  fontEnv = pkgs.buildEnv {
    name = "agent-infra-container-fonts";
    paths = fontPackages;
    pathsToLink = [ "/share/fonts" ];
  };

  starshipConfig = (pkgs.formats.toml { }).generate "starship.toml" {
    add_newline = true;
    character = {
      success_symbol = "[\\$](bold green) ";
      error_symbol = "[\\$](bold red) ";
    };
  };

  bashrc = pkgs.writeText "bashrc" ''
    export STARSHIP_CONFIG=/etc/starship.toml
    eval "$(starship init bash)"
    source ${nixIndex}/etc/profile.d/command-not-found.sh
  '';

  profile = pkgs.writeText "profile" ''
    case $- in *i*) . /etc/bashrc ;; esac
  '';

  loginDefs = pkgs.writeText "login.defs" ''
    ENV_PATH PATH=/nix/var/nix/profiles/runtime/bin:/usr/local/bin:/root/.nix-profile/bin:/usr/bin:/bin
    ENV_SUPATH PATH=/nix/var/nix/profiles/runtime/bin:/usr/local/bin:/root/.nix-profile/bin:/usr/bin:/bin
    ALWAYS_SET_PATH yes
  '';

  pam = pkgs.writeText "pam-container" ''
    auth sufficient pam_rootok.so
    account required pam_permit.so
    session required pam_permit.so
  '';

  sudoers = pkgs.writeText "sudoers" ''
    Defaults secure_path="/nix/var/nix/profiles/runtime/bin:/usr/local/bin:/root/.nix-profile/bin:/usr/bin:/bin"
    root ALL=(ALL:ALL) ALL
  '';

  setup = pkgs.writeShellScriptBin "agent-infra-container-setup" ''
    set -eu

    install -Dm644 ${profile} /etc/profile
    install -Dm644 ${bashrc} /etc/bashrc
    install -Dm644 ${loginDefs} /etc/login.defs
    install -Dm644 ${fontConfig} /etc/fonts/fonts.conf
    install -Dm644 ${starshipConfig} /etc/starship.toml
    install -Dm644 ${pam} /etc/pam.d/su
    install -Dm644 ${pam} /etc/pam.d/sudo
    install -Dm440 ${sudoers} /etc/sudoers

    rm /bin/sh /usr/bin/env
    rmdir /bin /usr/bin
    ln -s /nix/var/nix/profiles/runtime/bin /usr/bin
    ln -s /nix/var/nix/profiles/runtime/bin /usr/sbin
    ln -s usr/bin /bin
    ln -s usr/sbin /sbin

    mkdir -p -m 700 /root
  '';
in
{
  runtimeEnv = pkgs.buildEnv {
    name = "agent-infra-container-runtime";
    pathsToLink = [
      "/bin"
      # D-Bus uses XDG_DATA_DIRS to discover the AT-SPI bus and registry.
      "/share/dbus-1"
      # Fontconfig scans this stable profile path rather than per-package store paths.
      "/share/fonts"
    ];
    ignoreCollisions = true;
    paths = with pkgs; [
      at-spi2-core
      bashInteractive
      chromium
      cloudflared
      cmake
      cuaDriver
      coreutils
      curl
      dbus
      diffutils
      direnv
      dnsutils
      ethtool
      file
      fluxbox
      fontconfig
      fontEnv
      gawk
      gcc
      gdu
      gh
      git
      gnumake
      gnupg
      gnused
      go
      inetutils
      inputs.nix-index-database.packages.${system}.nix-index-with-db
      iperf3
      iproute2
      jq
      lbzip2
      lsof
      net-tools
      nexttrace
      nixd
      nixfmt
      nodejs_latest
      novnc
      openssl
      patch
      pixi
      pkg-config
      procps
      psmisc
      python3Packages.supervisor
      reptyr
      ripgrep
      rsync
      shadow.su
      starship
      sudo
      tcpdump
      texliveFull
      tmux
      unzip
      vim
      wget
      which
      x11vnc
      xvfb
      xvfb-run
      yq-go
    ];
  };

  inherit setup cuaDriver;
}
