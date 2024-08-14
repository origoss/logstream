{
  description = "Basic development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    pre-commit-hooks,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        logstream = pkgs.stdenv.mkDerivation {
          name = "logstream";
          src = pkgs.lib.fileset.toSource {
            root = ./.;
            fileset =
              pkgs.lib.fileset.fileFilter (
                file:
                  file.hasExt "zig" || file.hasExt "zon"
              )
              ./.;
          };
          XDG_CACHE_HOME = ".cache"; # https://github.com/ziglang/zig/issues/6810
          doCheck = true;
          buildInputs = with pkgs; [zig];
          buildPhase = ''
            ls -Ra
            zig build --release=safe
          '';
          checkPhase = ''
            zig build test
          '';
          installPhase = ''
            mkdir -p $out/bin
            cp zig-out/bin/logstream $out/bin
          '';
        };
        docker-image = pkgs.dockerTools.buildLayeredImage {
          name = "logstream";
          tag = "latest";
          contents = [logstream];
          config = {
            EntryPoint = ["${logstream}/bin/logstream"];
          };
        };
        pre-commit-checks = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            alejandra.enable = true;
            detect-private-keys.enable = true;
            end-of-file-fixer.enable = true;
            flake-checker.enable = true;
            statix.enable = true;
            trim-trailing-whitespace.enable = true;
            unit-tests = {
              enable = true;
              name = "Unit tests";
              pass_filenames = false;
              entry = "${pkgs.zig}/bin/zig build test";
              files = "\\.zig$";
            };
          };
        };
      in {
        packages = {
          inherit docker-image;
          default = logstream;
        };
        devShells.default = pkgs.mkShell {
          shellHook = ''
            ${pre-commit-checks.shellHook}
          '';
          packages = with pkgs; [
            zig
          ];
        };
        apps.default = {
          type = "app";
          program = "${logstream}/bin/logstream";
        };
      }
    );
}
