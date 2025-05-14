{
  description = "Naeve knowledge-base management system";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    utils.url = "github:numtide/flake-utils/";
    fenix.url = "github:nix-community/fenix";
    crane.url = "github:ipetkov/crane";
  };

  outputs = {
    crane,
    fenix,
    nixpkgs,
    utils,
    ...
  }:
    utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};

      inherit (pkgs) lib;

      craneLib = crane.mkLib pkgs;

      toolchain = fenix.packages.${system}.stable.toolchain;

      reqs = with pkgs; [
        expat
        fontconfig
        freetype
        freetype.dev
        libGL
        pkg-config
        xorg.libX11
        xorg.libXcursor
        xorg.libXi
        xorg.libXrandr
        wayland
        libxkbcommon
      ];

      commonArgs = {
        src = craneLib.cleanCargoSource ./.;
        nativeBuildInputs = with pkgs; [makeWrapper];
        strictDeps = true;
      };
    in {
      formatter = pkgs.alejandra;

      devShells.default = pkgs.mkShell {
        name = "naeve dev";
        packages = [toolchain];

        LD_LIBRARY_PATH = "${lib.makeLibraryPath reqs}";
      };

      packages.default = craneLib.buildPackage {
        inherit (commonArgs) src nativeBuildInputs strictDeps;

        cargoArtifacts = craneLib.buildDepsOnly commonArgs;

        postInstall = ''
          wrapProgram $out/bin/naeve --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath reqs}
        '';
      };
    });
}
