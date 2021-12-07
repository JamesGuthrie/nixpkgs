{ lib, stdenv, fetchFromGitHub, gcc, gnumake, cargo, rustPlatform, rustfmt, postgresql, openssl, libkrb5, libiconv }:

# # To enable on NixOS:
# config.services.postgresql = {
#   extraPlugins = [ pkgs.promscale_extension ];
#   extraConfig = "shared_preload_libraries = 'timescaledb'";
# }

stdenv.mkDerivation rec {
  pname = "promscale_extension";
  version = "0.3.0";

  buildInputs = [
    gcc
    gnumake
    cargo
    postgresql
    rustfmt
    openssl
    libkrb5
    libiconv
  ];

  src = fetchFromGitHub {
    owner  = "timescale";
    repo   = "promscale_extension";
    # some branches are named like tags which confuses git
    rev    = "refs/tags/${version}";
    sha256 = "sha256-nxvyfdx/cGQ1tejNxI5EXf2u4BZLSIL18dIxVcmfp0Y";
  };

  cargoDeps = rustPlatform.fetchCargoTarball {
    inherit src;
    hash = "sha256-SaJvN0A8PiWqwKG5NIeMsDc1BIwtMbPxlPW0+BQJfKg=";
  };

  nativeBuildInputs = (with rustPlatform; [ cargoSetupHook rust.cargo rust.rustc ]);

  configurePhase = ''
    runHook preConfigure

    export PGX_HOME=$(mktemp -d) # Workaround because PGX insists on having a PGX_HOME

    runHook postConfigure
  '';

  buildFlags = [
    "PG_CONFIG=${postgresql}/bin/pg_config"
    "PGX_PG_CONFIG_PATH=${postgresql}/bin/pg_config"
  ];

  installFlags = [
    "DESTDIR=$out"
  ];

  meta = with lib; {
    description = "Boosts promscale";
    homepage    = "https://www.timescale.com/";
    changelog   = "https://github.com/timescale/timescaledb/raw/${version}/CHANGELOG.md";
    maintainers = with maintainers; [ volth marsam ];
    platforms   = postgresql.meta.platforms;
    license     = licenses.asl20;
    broken      = versionOlder postgresql.version "12";
  };
}
