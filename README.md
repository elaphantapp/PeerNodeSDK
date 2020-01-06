# PeerNodeSDK

## Build the project
run `./scripts/build.sh`

## Troubleshooting
- for error `setenv-android.sh: line 11: ANDROID_NDK_HOME: unbound variable`
then do `export ANDROID_NDK_HOME=/Users/???/Library/Android/sdk/ndk-bundle`

- for error
```
ld: warning: directory not found for option '-L../build/sysroot/iOS/x86_64/lib'
ld: library not found for -lElastos.SDK.Keypair.C
```
then do `build the project using Generic iOS device rather than simulator`