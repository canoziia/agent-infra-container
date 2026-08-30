FROM ghcr.io/nixos/nix:latest

ENV NIX_CONFIG="experimental-features = nix-command flakes" \
    PATH="/nix/var/nix/profiles/runtime/bin:/usr/local/bin:/root/.nix-profile/bin:/usr/bin:/bin" \
    HOME=/home/pi \
    USER=pi \
    LOGNAME=pi \
    DISPLAY=:0 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

COPY flake.nix flake.lock runtime.nix /usr/share/agent-infra-container/nix/
RUN cd /usr/share/agent-infra-container/nix \
 && HOME=/root nix profile add .#runtimeEnv --profile /nix/var/nix/profiles/runtime \
 && setup="$(nix build .#setup --no-link --print-out-paths)" \
 && "$setup/bin/agent-infra-container-setup" \
 && nix-store --gc \
 && rm -rf /root/.cache/nix /root/.local/state/nix

WORKDIR /home/pi
CMD ["/nix/var/nix/profiles/runtime/bin/bash"]
