{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      # Import nixpkgs with the Android SDK license auto-accepted. This avoids
      # touching ~/.config/nixpkgs/config.nix; the license flag is wired through
      # the `android_sdk.accept_license` nixpkgs config option (see
      # nixpkgs pkgs/development/mobile/androidenv/license.nix).
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
        };

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f (pkgsFor system));

      # SDK root = $out/libexec/android-sdk (see nixpkgs cmdline-tools.nix)
      androidSdk =
        pkgs: extra:
        pkgs.androidenv.composeAndroidPackages (
          {
            cmdLineToolsVersion = "20.0";
            toolsVersion = "26.1.1";
            platformToolsVersion = "37.0.1";
            buildToolsVersions = [
              "35.0.0"
              "36.0.0"
              "36.1.0"
              "37.0.0"
            ];
            platformVersions = [
              "35"
              "36"
              "37.0"
            ];
            # Android Gradle Plugin defaults to CMake 3.22.1 for the native
            # builds that plugins such as `path_provider_android` (via `jni`)
            # trigger, and only accepts that exact version.
            includeCmake = true;
            cmakeVersions = [ "3.22.1" ];
            # Flutter's Gradle plugin provisions `flutter.ndkVersion` (28.2.13676358
            # in Flutter 3.47.4) through sdkmanager, which cannot write into this
            # read-only store path. Ship that exact NDK instead so the plugin finds
            # it already installed.
            includeNDK = true;
            ndkVersions = [ "28.2.13676358" ];
            includeSources = false;
            includeEmulator = false;
            includeSystemImages = false;
          }
          // extra
        );

      flutterDeps =
        pkgs: with pkgs; [
          flutter
          jdk21
          gradle
          android-tools
          unzip
          which
          curl
          git
          cacert
          xz
          openssh
        ];

      linuxDesktopDeps =
        pkgs:
        nixpkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux (with pkgs; [
          clang
          cmake
          ninja
          pkg-config
          gtk3
          xz
          libsecret
          libgcrypt
          libgpg-error
        ]);

      mkShell =
        pkgs: sdk: extraPackages:
        pkgs.mkShell {
          packages = flutterDeps pkgs ++ linuxDesktopDeps pkgs ++ extraPackages;
          ANDROID_HOME = "${sdk.androidsdk}/libexec/android-sdk";
          ANDROID_SDK_ROOT = "${sdk.androidsdk}/libexec/android-sdk";
          JAVA_HOME = "${pkgs.jdk21.home}";
          shellHook = ''
            export GRADLE_USER_HOME="''${GRADLE_USER_HOME:-$PWD/.gradle}"
            export ANDROID_USER_HOME="$PWD/.android"
            export ANDROID_AVD_HOME="$PWD/.android/avd"
            export PATH="$ANDROID_HOME/cmdline-tools/20.0/bin:$PATH"
            mkdir -p "$ANDROID_USER_HOME"
            # A host /usr/lib carrying an older glibc (2.42 vs the devshell's
            # 2.44) shadows the devshell one during linking, so clang resolves
            # libc/libm for shared libraries against the wrong version and the
            # Flutter Linux link fails with "undefined reference to
            # `sinh@GLIBC_2.44'". Put the devshell glibc first in the link
            # search path.
            if command -v cc >/dev/null 2>&1; then
              _termora_libc="$(cc -print-file-name=libc.so.6 2>/dev/null || true)"
              if [ -f "$_termora_libc" ]; then
                export LDFLAGS="-L$(dirname "$_termora_libc")''${LDFLAGS:+ $LDFLAGS}"
              fi
              unset _termora_libc
            fi
          '';
        };
    in
    {
      devShells = forAllSystems (pkgs: {
        default = mkShell pkgs (androidSdk pkgs { }) [ pkgs.just ];

        android-emulator = mkShell pkgs (androidSdk pkgs {
          includeEmulator = true;
          includeSystemImages = true;
          systemImageTypes = [ "google_apis_playstore" ];
          abiVersions = [ "x86_64" ];
        }) [ pkgs.just ];
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
    };
}
