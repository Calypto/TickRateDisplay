![EnterServer](https://github.com/Calypto/TickRateDisplay/blob/main/ServerDetails.png?raw=true)

## TickRateDisplay
UT2004 mutator that shows the server's tick rate (Hz) and tick period (ms) in the server details, and also lets clients type `mutate tickrate` in the console to receive real time data on the server's tick rate, useful for profiling server performance.

Admins can also use `admin mutate tickratelog [ 0/off/false | 1/on/true ]` (use only one of) to disable/enable logging the tick rate to the server log. This is useful for short-term testing if you have the server console window open and do not wish to launch the game. Do not leave this enabled if you rotate logs, as it logs every single tick and will result in massive files, and also degraded server performance.

The last admin command is `admin tickratedetails [ 0/off/false/hide | 1/on/true/show ]` (use only one of) to hide/show the server details entry.

### Installation
Add `TickRateDisplay.MutTRD` to the server's command line and mutators. Do not add it to ServerPackages, it is server-side only. The mutator is configurable via webadmin, but only the `set` command will update the settings in real time.

Unfortunately DeltaTime appears to be skewed and does not return the correct tick rate. Instead, we use DeltaTimeOffset to adjust DeltaTime to match our expectation. An offset of 1.1 appears to work in most instances, however you will have to verify this yourself. Spam `admin getcurrenttickrate` to determine what the server is actually running at, then type `mutate tickrate` to get the skewed tick rate and solve for X (DeltaTimeOffset).

Formula: IncorrectTickRate * X = ExpectedTickRate  
X = DeltaTimeOffset
