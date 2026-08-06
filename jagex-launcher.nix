{ lib
, appimageTools
, fetchurl
, libredirect
, runelite
, gcc
, clientPkg ? runelite
, pname ? "jagex-launcher"
, runCommand
}:

let
  version = "0.1.1";
  clientBinary = "${clientPkg}/bin/${clientPkg.meta.mainProgram or clientPkg.pname or clientPkg.name}";

  execRedirectShim = runCommand "exec-redirect-shim.so" { buildInputs = [ gcc ]; } ''
    gcc -shared -fPIC -O2 ${./shim.c} -o $out -ldl
  '';

  src = fetchurl {
    url = "https://rs-launcher-updates.runescape.com/production/linux/x64/releases/${version}/jagex-launcher-beta-linux-x86_64.AppImage";
    hash = "sha256-VUWfxwvnVTjfsA8lXYGBG6SYKQDbzhZQqrgApiz7lIE=";
  };

  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs = pkgs: with pkgs; [
    glib
    nss
    nspr
    openssl
    curl
    libsecret
    libnotify
    udev
    systemd
    xdg-utils
  ];

  profile = ''
    export TARGET_APPIMAGE="$HOME/.local/share/Jagex Launcher/games/runelite/RuneLite.AppImage"
    export REDIRECT_BINARY="${clientBinary}"
    export LD_PRELOAD="${execRedirectShim}''${LD_PRELOAD:+:$LD_PRELOAD}"
    export APPDIR="${appimageContents}"
    export SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt"
  '';

  extraInstallCommands = ''
    mkdir -p $out/share/applications $out/share/icons/hicolor/512x512/apps
    cp ${appimageContents}/jagex-launcher.desktop $out/share/applications/${pname}.desktop
    cp ${appimageContents}/jagex-launcher.png $out/share/icons/hicolor/512x512/apps/${pname}.png

    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace-fail "Exec=AppRun" "Exec=$out/bin/${pname}"
  '';

  meta = {
    description = "Official launcher for Jagex games (RuneScape and Old School RuneScape)";
    homepage = "https://www.runescape.com/launcher";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    maintainers = with lib.maintainers; [ kurtmorris ];
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
