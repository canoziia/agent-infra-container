FROM ghcr.io/nixos/nix:latest

ENV NIX_CONFIG="experimental-features = nix-command flakes" \
    PATH="/nix/var/nix/profiles/runtime/bin:/usr/local/bin:/root/.nix-profile/bin:/usr/bin:/bin" \
    HOME=/root \
    USER=root \
    LOGNAME=root \
    SHELL=/nix/var/nix/profiles/runtime/bin/bash \
    DISPLAY=:0 \
    NIX_LD=/nix/var/nix/profiles/runtime/share/nix-ld/lib/ld.so \
    NIX_LD_LIBRARY_PATH=/nix/var/nix/profiles/runtime/share/nix-ld/lib \
    XDG_DATA_DIRS=/nix/var/nix/profiles/runtime/share:/usr/local/share:/usr/share \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

COPY flake.nix flake.lock runtime.nix cua-driver.nix /usr/share/agent-infra-container/nix/
RUN cd /usr/share/agent-infra-container/nix \
 && HOME=/root nix profile add .#runtimeEnv --profile /nix/var/nix/profiles/runtime \
 && setup="$(nix build .#setup --no-link --print-out-paths)" \
 && "$setup/bin/agent-infra-container-setup" \
 && nix-store --gc \
 && rm -rf /root/.cache/nix /root/.local/state/nix

WORKDIR /root
CMD ["/nix/var/nix/profiles/runtime/bin/bash"]
