{ pkgs, config, ... }:

let
  rustVersion = "1.98.1";
  emscriptenVersion = "6.0.9";
in
{
  packages = with pkgs; [
    cacert
    corepack
    git
    pkg-config
    rustup
  ];

  languages.javascript = {
    enable = true;
    package = pkgs.nodejs_24;
  };

  languages.python = {
    enable = true;
    package = pkgs.python3;
  };

  env = {
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    COREPACK_HOME = "${config.env.DEVENV_STATE}/corepack";
    RUSTUP_HOME = "${config.env.DEVENV_STATE}/rustup";
    CARGO_HOME = "${config.env.DEVENV_STATE}/cargo";
    EMSDK = "${config.env.DEVENV_STATE}/emsdk";
    EM_CONFIG = "${config.env.DEVENV_STATE}/emsdk/.emscripten";
    PYTHON = "${pkgs.python3}/bin/python3";
    PNPM_HOME = "${config.env.DEVENV_STATE}/pnpm/bin";
    npm_config_store_dir = "${config.env.DEVENV_STATE}/pnpm/store";
    npm_config_cache = "${config.env.DEVENV_STATE}/npm/cache";
    XDG_CACHE_HOME = "${config.env.DEVENV_STATE}/cache";
  };

  enterShell = ''
    export PATH="$DEVENV_STATE/bin:$PNPM_HOME:$PATH"
  '';

  tasks."ovrley:toolchains".exec = ''
    set -e
    mkdir -p "$DEVENV_STATE/bin"
    corepack enable --install-directory "$DEVENV_STATE/bin"
    export PATH="$DEVENV_STATE/bin:$PATH"

    rustup toolchain install 1.95.0 --profile minimal --component rustfmt
    rustup default 1.95.0
    rustup toolchain install ${rustVersion} --profile minimal \
      --target wasm32-unknown-emscripten \
      --target wasm32-unknown-unknown

    if [ ! -d "$EMSDK/.git" ]; then
      git clone https://github.com/emscripten-core/emsdk.git "$EMSDK"
    fi
    "$EMSDK/emsdk" install ${emscriptenVersion}
    "$EMSDK/emsdk" activate ${emscriptenVersion}
  '';

  tasks."ovrley:install" = {
    after = [ "ovrley:toolchains" ];
    exec = ''
      corepack pnpm install --frozen-lockfile
    '';
  };
}
