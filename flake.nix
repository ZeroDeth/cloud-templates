{
  description = "Nix flake dev environments";

  outputs = { self }: {
    templates = rec {
      aws = {
        path = ./aws;
        description = "Amazon Web Services development environment";
      };

      azure = {
        path = ./azure;
        description = "Microsoft Azure development environment";
      };

      gcp = {
        path = ./gcp;
        description = "Google Cloud development environment";
      };

      digitalocean = {
        path = ./digitalocean;
        description = "Digital Ocean development environment";
      };

      linode = {
        path = ./linode;
        description = "Linode development environment";
      };
    };
  };
}
