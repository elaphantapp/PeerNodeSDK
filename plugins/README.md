# MicroService

- Moments https://github.com/zuohuahua/Moments
- MicroService.PersonalStorage https://github.com/elaphantapp/MicroService.PersonalStorage
- MicroService.ChatGroup https://github.com/elaphantapp/MicroService.ChatGroup
- MicroService.HashAddressMapping https://github.com/elaphantapp/MicroService.HashAddressMapping
- MicroService.Manager https://github.com/elaphantapp/MicroService.Manager
- MicroService.Feedback https://github.com/elaphantapp/PeerNodeSDK/tree/master/plugins/MicroService.Feedback

## How to build

Download one or more repo to PeerNodeSDK's plugins directory, and run `scripts/build.sh`.
Target libraries are in build/sysroot/{Darwin,Linux}/x86_64/lib/PeerNodePlugins.

## How to load

Such as: ./build/sysroot/Linux/x86_64/bin/PeerNodeLauncher.sh -name build/sysroot/Linux/x86_64/lib/PeerNodePlugins/libChatGroupService.so -path /tmp/PeerNode/ -key 4138db5bd521d810dbd5863bda6f18af8dbaa8382fd6a5260ee09cf05d2dc276

