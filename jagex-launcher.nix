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
      cat << 'EOF' > shim.c
      #define _GNU_SOURCE
      #include <stdio.h>
      #include <stdlib.h>
      #include <string.h>
      #include <dlfcn.h>
      #include <spawn.h>
      #include <unistd.h>
      #include <fcntl.h>

      static int (*real_execve)(const char *, char *const[], char *const[]) = NULL;
      static int (*real_execvp)(const char *, char *const[]) = NULL;
      static int (*real_execv)(const char *, char *const[]) = NULL;

      static void redirect_and_exec(const char *redirect_bin, char *const argv[]) {
          // Redirect standard output and error to /dev/null so Electron's IPC pipe
          // closes instantly. This tells Electron "launch complete, minimize launcher now".
          int devnull = open("/dev/null", O_WRONLY);
          if (devnull != -1) {
              dup2(devnull, STDOUT_FILENO);
              dup2(devnull, STDERR_FILENO);
              close(devnull);
          }

          // Replace process with target binary directly so Electron tracks the EXACT PID
          execv(redirect_bin, argv);
      }

      static const char *check_redirect(const char *path, char *const argv[]) {
          const char *redirect = getenv("REDIRECT_BINARY");
          if (path && redirect && strstr(path, "RuneLite.AppImage") != NULL) {
              redirect_and_exec(redirect, argv);
          }
          return path;
      }

      int execve(const char *filename, char *const argv[], char *const envp[]) {
          if (!real_execve) real_execve = dlsym(RTLD_NEXT, "execve");
          return real_execve(check_redirect(filename, argv), argv, envp);
      }

      int execvp(const char *file, char *const argv[]) {
          if (!real_execvp) real_execvp = dlsym(RTLD_NEXT, "execvp");
          return real_execvp(check_redirect(file, argv), argv);
      }

      int execv(const char *path, char *const argv[]) {
          if (!real_execv) real_execv = dlsym(RTLD_NEXT, "execv");
          return real_execv(check_redirect(path, argv), argv);
      }
      EOF

      gcc -shared -fPIC -O2 shim.c -o $out -ldl
    '';

  # Pinned using web archive to avoid breaking changes
  # https://rs-launcher-updates.runescape.com/production/linux/x64/latest/jagex-launcher-beta-linux-x86_64.AppImage
  src = fetchurl {
    url = "https://web.archive.org/web/20260730021847/https://rs-launcher-updates.runescape.com/production/linux/x64/latest/jagex-launcher-beta-linux-x86_64.AppImage";
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
