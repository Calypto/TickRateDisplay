![Server Details](https://github.com/Calypto/TickRateDisplay/blob/main/ServerDetails.png?raw=true)

## TickRateDisplay
UT2004 mutator to show the server's tick rate (Hz) and tick period (ms) in the server details, and also lets clients type `mutate tickrate` in the console to profile each tick from the server's end, with zero averaging, unlike `getcurrenttickrate`.

### Installation
Add `TickRateDisplay.MutTRD` to the server's command line and mutators. Do not add it to ServerPackages as it is server-side only. The mutator is configurable via webadmin, but only the `set` command will update the settings in real time.

![Mutate Tickrate](https://github.com/Calypto/TickRateDisplay/blob/main/MutateTickrate.png?raw=true)
