# Developer setup (Mac)

What each teammate needs installed to build and run Kabadiwala Connect.
Versions below are what we use; newer patch versions are fine.

| Tool | Why we need it | Install |
|---|---|---|
| Homebrew | Installs everything else | https://brew.sh |
| Java 17 | Android builds need it | `brew install openjdk@17` |
| Flutter (stable, 3.47+) | The app framework (includes Dart) | `brew install --cask flutter` |
| Android command-line tools | Android SDK manager | `brew install --cask android-commandlinetools` |
| Android SDK 36 + build tools | Compile the APK | see step 3 below |
| Firebase CLI | Log in to Firebase, used by FlutterFire | `npm install -g firebase-tools` (needs Node) |
| FlutterFire CLI | Connects the app to our Firebase project | `dart pub global activate flutterfire_cli` |
| Python 3 + venv | Seed-data and analysis scripts | already on most Macs / `brew install python` |
| Xcode Command Line Tools | `flutter test` compiles a little Mac code | `xcode-select --install` |

## Steps

1. Install the tools in the table above.
2. Add these lines to the end of `~/.zshrc`, then open a new terminal:
   ```
   export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
   export ANDROID_HOME="/opt/homebrew/share/android-commandlinetools"
   export ANDROID_SDK_ROOT="$ANDROID_HOME"
   export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$HOME/.pub-cache/bin:$PATH"
   ```
3. Accept the Android SDK licence and install the SDK:
   ```
   sdkmanager --licenses
   sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0"
   flutter config --android-sdk "$ANDROID_HOME"
   ```
4. Check everything: `flutter doctor` (Android toolchain should have a tick;
   Xcode/Chrome warnings are fine — we only build for Android).
5. Python scripts:
   ```
   python3 -m venv .venv
   .venv/bin/pip install -r scripts/requirements.txt
   ```
6. Get the app's packages and run checks:
   ```
   cd app
   flutter pub get
   flutter analyze
   flutter test
   ```

## Running on a phone

1. On the Android phone: Settings → About phone → tap "Build number" 7 times.
2. Settings → Developer options → turn on "USB debugging".
3. Plug in with a USB cable, tap "Allow" on the phone.
4. `adb devices` should list the phone. Then `cd app && flutter run`.

## Troubleshooting
- **First build fails with `ConnectException: Operation timed out` while
  "Downloading gradle-…-bin.zip".** Some Indian ISPs can't reach one of GitHub's
  download servers. Download Gradle with curl instead (it picks a working server):
  ```
  cd ~/.gradle/wrapper/dists/gradle-9.3.1-bin/*/
  curl -fL -o gradle-9.3.1-bin.zip https://services.gradle.org/distributions/gradle-9.3.1-bin.zip
  ```
  then run the build again.
- **`flutter test` fails with `'CarbonCore/Folders.h' file not found`.** Your Xcode
  Command Line Tools are damaged. Reinstall them:
  `sudo rm -rf /Library/Developer/CommandLineTools` then `xcode-select --install`.

## Notes
- Android 7 (API 24) is the oldest version we support. Flutter no longer
  supports Android 6.
- Never commit `scripts/serviceAccount.json` (it is in `.gitignore`).
