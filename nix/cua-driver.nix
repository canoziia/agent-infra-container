{ pkgs, lib }:
# Cua Driver (https://github.com/trycua/cua) — cross-platform computer-use
# automation driver. There is no nixpkgs package, so we fetch the official
# prebuilt release from GitHub Releases and patch its interpreter/RPATH so it
# runs against the Nix store inside the container.
#
# Version pinned here; update together with the per-arch hashes below when
# bumping. Asset hashes come from the GitHub release (asset `digest`).
let
  version = "0.25.0";

  arch =
    if pkgs.stdenv.hostPlatform.isx86_64 then
      "linux-x86_64"
    else if pkgs.stdenv.hostPlatform.isAarch64 then
      "linux-arm64"
    else
      throw "cua-driver: unsupported platform ${pkgs.stdenv.hostPlatform.system}";

  srcHash =
    if pkgs.stdenv.hostPlatform.isx86_64 then
      "11kdy5y8x4xknblq9hphmr6adw5193slp84s6shcigihg0m16s3l"
    else if pkgs.stdenv.hostPlatform.isAarch64 then
      "1kqk4cz5jmnvr1nd275vb7lbwhd50b5vlrb440qja6xzimn6lmg8"
    else
      throw "cua-driver: no hash for ${arch}";

  licenseFile = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/trycua/cua/cua-driver-rs-v${version}/LICENSE.md";
    hash = "sha256-wHeSkMHUeDFpqj2/tV/rUF5WPvigBLv1UpjO/8+9qNk=";
  };

  # The prebuilt executables are dynamically linked (foreign, non-Nix-built),
  # so we add these store paths to their RPATH.
  runtimeLibs = with pkgs; [
    glibc
    gcc-unwrapped.lib
    libx11
    libxi
    libxkbcommon
  ];
in
pkgs.stdenv.mkDerivation {
  pname = "cua-driver";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://github.com/trycua/cua/releases/download/cua-driver-rs-v${version}/cua-driver-rs-${version}-${arch}-binary.tar.gz";
    sha256 = srcHash;
  };

  nativeBuildInputs = [ pkgs.patchelf ];
  buildInputs = runtimeLibs;

  sourceRoot = ".";

  installPhase = ''
    install -Dm755 cua-driver $out/bin/cua-driver
    install -Dm755 cua-cursor-theme $out/bin/cua-cursor-theme
    install -Dm644 ${licenseFile} $out/share/licenses/cua-driver/LICENSE.md

    for executable in $out/bin/cua-driver $out/bin/cua-cursor-theme; do
      patchelf \
        --set-interpreter "$(cat ${pkgs.stdenv.cc}/nix-support/dynamic-linker)" \
        --set-rpath "${lib.makeLibraryPath runtimeLibs}" \
        "$executable"
    done
  '';

  meta = with lib; {
    description = "Cua cross-platform computer-use automation driver (prebuilt Linux binary)";
    homepage = "https://github.com/trycua/cua";
    license = licenses.mit;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
