{
  description = "Google Cloud DevOps with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-22.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    }:

    let
      name = "todos";
      goVersion = 19;
      # An overlay to set the Go version
      goOverlay = self: super: {
        go = super."go_1_${toString goVersion}";
      };
      overlays = [ goOverlay ];
    in
    # The package and Docker image are only intended to be built on amd64 Linux
    flake-utils.lib.eachSystem [ "x86_64-linux" ]
      (system:
      let
        pkgs = import nixpkgs { inherit overlays system; };
      in
      {
        packages = rec {
          default = todos;

          todos = pkgs.buildGoModule {
            name = "todos";
            src = ../.;
            subPackages = [ "cmd/todos" ];
            vendorSha256 = "sha256-fwJTg/HqDAI12mF1u/BlnG52yaAlaIMzsILDDZuETrI=";
          };

          docker =
            # A layered image means better caching and less bandwidth
            pkgs.dockerTools.buildLayeredImage {
              name = "lucperkins/todos";
              config = {
                Cmd = [ "${self.packages.${system}.todos}/bin/todos" ];
                ExposedPorts."8080/tcp" = { };
              };
              maxLayers = 120;
            };
        };
      }) //
    # The shell environment is intended for all systems
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit overlays system;
      };
    in
    {
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs;
          [
            figlet              # Output text as big ASCII art text
            lolcat              # Make console output raibow colored

            # Platform-non-specific Go (for local development)
            go

            # Docker CLI
            docker

            # Kubernetes
            kubectl
            kubectx

            # Terraform
            terraform
            tflint

            # Google Cloud
            # Ref: https://github.com/michielboekhoff/nixos-conf/blob/37d2a6f7b4d5c266346b270f5da5db82613eb945/hosts/kyoshi/default.nix#L19
            (google-cloud-sdk.withExtraComponents [google-cloud-sdk.components.gke-gcloud-auth-plugin google-cloud-sdk.components.cloud-build-local])
          ];

          shellHook = ''
            figlet "GCP DEV!" | lolcat --freq 0.5
            echo "Go `${pkgs.go}/bin/go version`"
            echo "Google Cloud `${pkgs.google-cloud-sdk}/bin/gcloud version`"
            echo "Terraform `${pkgs.terraform}/bin/terraform version`"
            echo "Docker `${pkgs.docker}/bin/docker --version`"
            echo "Kubernetes `${pkgs.kubectl}/bin/kubectl version --short`"
          '';
      };
    });
}
