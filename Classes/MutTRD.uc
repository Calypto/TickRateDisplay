// By Anonymous/Calypto, 2025
// https://github.com/Calypto/TickRateDisplay/

class MutTRD extends Mutator
	config;

// Import needed for ServerResponseLine
#exec OBJ LOAD FILE=Engine.u

var float LastDeltaTime;

//var float LastTickTime;
var float InstantaneousTickRate;
var float InstantaneousMilliseconds;

var float CurrentTickRate;
var float CurrentMilliseconds;

var config bool bEnableLogging;
var config bool bShowInServerDetails;
var config float DeltaTimeOffset;

// Variable to track when to update server details
var float NextServerDetailsUpdate;

// Array to store server details
struct DetailSetting
{
	var string Setting;
	var string Value;
};
var array<DetailSetting> MyDetails;

// Array to track players with active tick rate display
struct TickRateClient
{
	var PlayerController Controller;
};
var array<TickRateClient> ActiveClients;

function PostBeginPlay()
{
	local DetailSetting NewSetting;

	Super.PostBeginPlay();

	//LastTickTime = Level.TimeSeconds;
	CurrentTickRate = 0;
	CurrentMilliseconds = 0;
	InstantaneousTickRate = 0;
	InstantaneousMilliseconds = 0;
	NextServerDetailsUpdate = 0;

	NewSetting.Setting = "Server Tick Rate";
	NewSetting.Value = FormatTickRate(CurrentTickRate) $ " / " $ FormatMilliseconds(CurrentMilliseconds);
	MyDetails[0] = NewSetting;
}

function string FormatTickRate(float TickRate)
{
	return string(TickRate) $ " Hz";
}

function string FormatMilliseconds(float Ms)
{
	return string(Ms) $ " ms";
}

// Function to update display values and notify clients
function UpdateDisplayValues()
{
	local int i;
	
	// Update the display values
	CurrentTickRate = InstantaneousTickRate;
	CurrentMilliseconds = InstantaneousMilliseconds;
	
	// Update the server details only once per second
	if (Level.TimeSeconds >= NextServerDetailsUpdate)
	{
		MyDetails[0].Setting = "Server Tick Rate";
		MyDetails[0].Value = FormatTickRate(CurrentTickRate) $ " / " $ FormatMilliseconds(CurrentMilliseconds);

		NextServerDetailsUpdate = Level.TimeSeconds + 1.0;
	}

	if (bEnableLogging)
	{
		Log(FormatTickRate(CurrentTickRate) $ " / " $ FormatMilliseconds(CurrentMilliseconds));
	}
	
	// Update any active clients
	for (i = 0; i < ActiveClients.Length; i++)
	{
		if (ActiveClients[i].Controller != None)
		{
			ActiveClients[i].Controller.ClientMessage(FormatTickRate(CurrentTickRate) $ " / " $ FormatMilliseconds(CurrentMilliseconds));
		}
	}
}

/*
DeltaTime is skewed and does not return the correct tick rate. DeltaTimeOffset of 1.1 should return the correct
tick rate. Spam 'admin getcurrenttickrate' to determine what the server is actually running at,
then type 'mutate tickrate' and solve for X (DeltaTimeOffset).

Formula: IncorrectTickRate * X = ExpectedTickRate
X = DeltaTimeOffset
*/
function Tick(float DeltaTime)
{
	Super.Tick(DeltaTime);

	if (DeltaTime > 0)
	{
		InstantaneousTickRate = 1.0 / DeltaTime * DeltaTimeOffset;
		InstantaneousMilliseconds = DeltaTime * 1000.0 / DeltaTimeOffset;
	}

	//LastTickTime = Level.TimeSeconds;

	// Update the display every tick
	UpdateDisplayValues();
}

// Function to add server details to the server browser
function GetServerDetails(out GameInfo.ServerResponseLine ServerState)
{
	local int i, j;

	Super.GetServerDetails(ServerState);

	if (bShowInServerDetails)
	{
		// Get current length of server info array
		j = ServerState.ServerInfo.Length;
		
		// Add each of our custom details to the server info
		for(i = 0; i < MyDetails.Length; i++)
		{
			ServerState.ServerInfo.Length = j + 1;
			ServerState.ServerInfo[j].Key = MyDetails[i].Setting;
			ServerState.ServerInfo[j++].Value = MyDetails[i].Value;
		}
	}
}

// Function to check if a player controller is already in the ActiveClients array
function int FindClientIndex(PlayerController PC)
{
	local int i;
	
	for (i = 0; i < ActiveClients.Length; i++)
	{
		if (ActiveClients[i].Controller == PC)
		{
			return i;
		}
	}
	
	return -1;
}

// Handle mutate commands
function Mutate(string MutateString, PlayerController Sender)
{
	local int ClientIndex;
	local TickRateClient NewClient;
	local string Command, Value;
	local int SplitPos;
	
	// Split the command if it contains a space
	SplitPos = InStr(MutateString, " ");
	if (SplitPos >= 0)
	{
		Command = Left(MutateString, SplitPos);
		Value = Mid(MutateString, SplitPos + 1);
	}
	else
	{
		Command = MutateString;
		Value = "";
	}
	
	// Check for tickrate command
	if (Command ~= "tickrate")
	{
		// Check if this player is already in our active clients array
		ClientIndex = FindClientIndex(Sender);
		
		if (ClientIndex >= 0)
		{
			// Remove from active clients (toggle off)
			ActiveClients.Remove(ClientIndex, 1);
			Sender.ClientMessage("Tick rate display disabled");
		}
		else
		{
			// Add to active clients (toggle on)
			NewClient.Controller = Sender;
			ActiveClients[ActiveClients.Length] = NewClient;
			
			// Send first update immediately
			Sender.ClientMessage("Server tick rate: " $ FormatTickRate(CurrentTickRate) $ " / " $ FormatMilliseconds(CurrentMilliseconds));
		}
	}
	
	// Call parent method to handle other mutate commands
	Super.Mutate(MutateString, Sender);
}

// Make sure the mutator stays relevant for net games
function bool IsRelevant(Actor Other, out byte bSuperRelevant)
{
	if (Super.IsRelevant(Other, bSuperRelevant))
		return true;
	
	return true;
}

// Called when a player disconnects
function NotifyLogout(Controller Exiting)
{
	local int ClientIndex;
	local PlayerController PC;
	
	// Cast to PlayerController
	PC = PlayerController(Exiting);
	
	// If this is a player that was in our active clients list, remove them
	if (PC != None)
	{
		ClientIndex = FindClientIndex(PC);
		if (ClientIndex >= 0)
		{
			ActiveClients.Remove(ClientIndex, 1);
		}
	}
	
	Super.NotifyLogout(Exiting);
}

static function FillPlayInfo(PlayInfo PlayInfo)
{
	Super.FillPlayInfo(PlayInfo);

	PlayInfo.AddSetting("Tick Rate Display", "bEnableLogging", "Enable logging", 0, 1, "Check", , , True);
	PlayInfo.AddSetting("Tick Rate Display", "bShowInServerDetails", "Show tick rate in server details", 0, 1, "Check", , , True);
	//PlayInfo.AddSetting("Tick Rate Display", "DeltaTimeOffset", "DeltaTime offset", 0, 1, "Text", "8;0:10");
}

static event string GetDescriptionText(string PropName)
{
	switch (PropName)
	{
		case "bEnableLogging":
			return "If enabled, each tick will be logged to the server log. Do not use this outside short-term testing.";
		case "bShowInServerDetails":
			return "If enabled, tick rate will be visible in server browser details.";
		//case "DeltaTimeOffset":
			//return "Adjustment value to correct DeltaTime's offset. Uses 1.1 by default, which should be correct in most cases.";
		default:
			return Super.GetDescriptionText(PropName);
	}
}

defaultproperties
{
	GroupName=""
	FriendlyName="Tick Rate Display"
	Description="Displays the server's tick rate in hertz and tick period in milliseconds, and allows profiling via 'mutate tickrate'.||https://github.com/Calypto/TickRateDisplay/"
	
	bEnableLogging=False
	bShowInServerDetails=True
	DeltaTimeOffset=1.1
	
	bAlwaysRelevant=True
	RemoteRole=ROLE_SimulatedProxy
	
	bNetNotify=True
}