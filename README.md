## TickRateDisplay
UT2004 mutator that shows the server's tick rate (Hz) and tick period (ms) in the server details, and also lets clients type `mutate tickrate` in the console to receive real time data on the server's tick rate, useful for profiling server performance.

### Installation
Add `TickRateDisplay.MutTRD` to the server's command line and mutators. Do not add it to ServerPackages, it is server-side only. The mutator is configurable via webadmin, but only the `set` command will update the settings in real time.

Unfortunately DeltaTime appears to be skewed and does not return the correct tick rate. Instead, we use DeltaTimeOffset to adjust DeltaTime to match our expectation. Use 1.155 for Win7 and earlier, 1.1 for Modern Windows and Linux. On my Win10 install an offset of 1.1 gave correct values, but your mileage may vary. Spam `admin getcurrenttickrate` to determine what the server is actually running at, then type `mutate tickrate` to get the skewed tick rate and solve for X (DeltaTimeOffset).

Formula: IncorrectTickRate * X = ExpectedTickRate  
X = DeltaTimeOffset
