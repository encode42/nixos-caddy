{
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) elemAt removePrefix splitString;

  info = import ./info.nix;
  dist = fetchFromGitHub info.dist;

  caddy-version =  removePrefix "v" info.version;
  cloudflare-version-string = splitString "-" (removePrefix "v" info.cfVersion);
  cloudflare-version = elemAt cloudflare-version-string 0;

  ddns-version-string = splitString "-" (removePrefix "v" info.ddnsVersion);
  ddns-version = elemAt ddns-version-string 0 + "+" + elemAt ddns-version-string 2;

  snake-version-string = splitString "-" (removePrefix "v" info.snakeVersion);
  snake-version = elemAt snake-version-string 0;

  cloudflare-ip-version-string = splitString "-" (removePrefix "v" info.cfiVersion);
  cloudflare-ip-version = elemAt cloudflare-ip-version-string 0 + "+" + elemAt cloudflare-ip-version-string 2;
in
  buildGoModule {
    pname = "caddy-with-plugins";
    version = caddy-version + "-" + cloudflare-version + "-" + ddns-version + "-" + snake-version + "-" + cloudflare-ip-version;

    src = ../caddy-src;

    runVend = true;
    inherit (info) vendorHash;

    # Everything past this point is from Nixpkgs
    ldflags = [
      "-s"
      "-w"
    ];

    preInstall = ''
      export CGO_ENABLED=1
    '';

    buildInputs = [
      pkgs.dbus
      pkgs.python3
    ];

    nativeBuildInputs = [
      pkgs.pkg-config
      installShellFiles
    ];

    postInstall = ''
      install -Dm644 ${dist}/init/caddy.service ${dist}/init/caddy-api.service -t $out/lib/systemd/system

      substituteInPlace $out/lib/systemd/system/caddy.service --replace "/usr/bin/caddy" "$out/bin/caddy"
      substituteInPlace $out/lib/systemd/system/caddy-api.service --replace "/usr/bin/caddy" "$out/bin/caddy"

      $out/bin/caddy manpage --directory manpages
      installManPage manpages/*

      installShellCompletion --cmd caddy \
        --bash <($out/bin/caddy completion bash) \
        --fish <($out/bin/caddy completion fish) \
        --zsh <($out/bin/caddy completion zsh)
    '';

    meta = with lib; {
      homepage = "https://caddyserver.com";
      description = "Fast and extensible multi-platform HTTP/1-2-3 web server with automatic HTTPS";
      license = licenses.asl20;
      mainProgram = "caddy";
    };
  }
