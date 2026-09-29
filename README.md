# agent-infra-container

Nix-based **base image** for agent runtime containers.

This repository provides tools, libraries, and a browser-ready fontconfig setup
with Latin, CJK, and color-emoji fonts. It does not start desktop, VNC, MCP, or
application services. Derived runtime images own process
supervision, network exposure, authentication, and lifecycle policy.

The main consumer is
[`darknightlab/pi-web-container`](https://github.com/darknightlab/pi-web-container),
which starts Xvfb/Fluxbox and its application services with Supervisor.

## Prebuilt Linux binary support

The image includes [`nix-ld`](https://github.com/nix-community/nix-ld) to run
unpatched, dynamically linked Linux binaries downloaded by third-party tools.
It installs nix-ld at the architecture's standard ELF interpreter path and sets
`NIX_LD` and `NIX_LD_LIBRARY_PATH` in the Docker environment. Compatibility
libraries follow the default library set from the NixOS nix-ld module and are
kept in the runtime profile so image garbage collection preserves them.

This supports native-architecture glibc binaries, not every Linux binary or
cross-architecture execution. Additional application-specific libraries may
still be needed. Nix-packaged interpreters such as Python and Node use their
own store linker, so nix-ld does not automatically fix their native extension
library lookup. Avoid setting `LD_LIBRARY_PATH` globally, as it can interfere
with Nix-packaged programs.

## Interactive shells

The image sets `SHELL` to its runtime Bash and initializes Starship from
`/etc/bashrc`, which Nixpkgs Bash reads for interactive non-login shells.
Login shells initialize it through `/etc/profile`. Pi Web uses `SHELL` to
launch a login shell, and Pixi's interactive Bash subshells load `/etc/bashrc`.
Noninteractive commands do not initialize prompt hooks. No user `.bashrc`
is required, and persistent home directories are not overwritten.

Derived images inherit these shell defaults and the `NIX_LD` variables. After
changing this base image, rebuild derived images with `--pull` after publishing
the updated base, then recreate their containers; restarting an existing
container does not install the changes.

## Included Cua support

The runtime environment includes
[`cua-driver`](https://github.com/trycua/cua), allowing a derived image with a
running Linux X11 session to expose Cua Driver as an MCP stdio server.

The prebuilt Cua release is packaged by `nix/cua-driver.nix`. The derivation:

- pins the release version and hashes for x86_64 and aarch64 Linux;
- patches the foreign ELF interpreter and RPATH for the Nix store;
- installs both `cua-driver` and its required `cua-cursor-theme` sidecar;
- provides D-Bus and AT-SPI packages and activation files for derived X11
  runtimes that need semantic accessibility trees.

This base image intentionally does not run `cua-driver mcp` or
`cua-driver serve`. A derived image should start `cua-driver mcp` from its agent
MCP configuration so the process inherits that image's `DISPLAY` and session
environment.

## Build

Build the Nix runtime environment:

```bash
cd nix
nix build .#runtimeEnv
```

Build the Docker image from the repository root:

```bash
docker build -t agent-infra-container ./nix
```

Build and inspect Cua Driver independently:

```bash
cd nix
nix build .#cuaDriver
./result/bin/cua-driver --version
./result/bin/cua-driver cursor-theme list --json
```

## Runtime ownership

A derived image is responsible for all of the following:

- starting and supervising Xvfb and the window manager;
- creating any D-Bus/AT-SPI session needed for semantic accessibility tools;
- registering `cua-driver mcp` with its agent;
- applying an appropriate Cua capability/permission policy;
- securing VNC/noVNC or other remote-access endpoints;
- handling health checks, logs, signals, and shutdown.

Do not add service startup commands or network listeners to this base image.
