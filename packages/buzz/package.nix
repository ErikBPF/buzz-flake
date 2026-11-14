{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  gtk3,
  webkitgtk_4_1,
}: let
  version = "0.5.30";
in
  stdenv.mkDerivation {
    pname = "buzz";
    inherit version;

    src = fetchurl {
      url = "https://github.com/block/buzz/releases/download/desktop-v${version}/Buzz_${version}_amd64.deb";
      hash = "sha256-GDTk25iWN6gA5IHUjqLQp0PTHWK8udA2HKjSU4KDJNY=";
    };

    nativeBuildInputs = [dpkg autoPatchelfHook makeWrapper];
    buildInputs = [alsa-lib gtk3 webkitgtk_4_1];

    unpackPhase = "dpkg-deb -x $src .";
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r usr/* $out/
      wrapProgram $out/bin/buzz-desktop --prefix XDG_DATA_DIRS : "$out/share"
      runHook postInstall
    '';

    meta = {
      description = "Workspace where humans and agents build together";
      homepage = "https://github.com/block/buzz";
      license = lib.licenses.asl20;
      mainProgram = "buzz-desktop";
      platforms = ["x86_64-linux"];
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    };
  }
