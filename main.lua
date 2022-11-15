shared.TheConquerorsAPI = {
    Enabled = false;
} 

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService("Players");
local Teams = game:GetService("Teams")

local LocalPlayer = Players.LocalPlayer

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local Dump = loadstring(game:HttpGet('https://raw.githubusercontent.com/strawbberrys/LuaScripts/main/TableDumper.lua'))()

local Map = workspace:FindFirstChild("Map");
local Geometry = Map:FindFirstChild("Map");

local TeamsInstance = workspace:FindFirstChild("Teams");
local TeamSettings = workspace:FindFirstChild("TeamSettings")

local EnergyCrystals = Map:FindFirstChild("EnergyCrystals");
local OilSpots = Map:FindFirstChild("OilSpots");

local RemoteFunctionsNames = {
    jjjllji = "BuyRotatingLootBox",
    IIilIII = "BuyLootBox"
}

local Remotes, RemoteFunctions = {}, {}

local Classes = {};

local UnitMovementQueue = {
    ["Waypointed"] = {

    };
    ["UnWaypointed"] = {

    };
};

shared.TheConquerorsAPI["Enabled"] = true;

task.spawn(function()
    while shared.TheConquerorsAPI["Enabled"] do
        for Index, Value in pairs(UnitMovementQueue.Waypointed) do
            local RequestData = {
                ["isAWaypoint"] = true,
                ["iIjjII"] = Value;
                ["Position"] = table.create(#Value, Index);
            }
        
            Remotes.MoveUnits:FireServer(RequestData)
            
            if not shared.TheConquerorsAPI["Enabled"] then
                break
            end
            
            UnitMovementQueue.Waypointed[Index] = nil;
        end

        for Index, Value in pairs(UnitMovementQueue.UnWaypointed) do
            local RequestData = {
                ["isAWaypoint"] = false,
                ["iIjjII"] = Value;
                ["Position"] = table.create(#Value, Index);
            }
        
            Remotes.MoveUnits:FireServer(RequestData)
            
            if not shared.TheConquerorsAPI["Enabled"] then
                break
            end
            
            UnitMovementQueue.UnWaypointed[Index] = nil;
        end
            
        task.wait(0.5)
    end
end)

local function AddToQueue(Unit, Position, IsAWaypoint)
    if IsAWaypoint then
        if not UnitMovementQueue.Waypointed[Position] then
            UnitMovementQueue.Waypointed[Position] = {}
        end

        table.insert(UnitMovementQueue.Waypointed[Position], Unit)
    else
        if not UnitMovementQueue.UnWaypointed[Position] then
            UnitMovementQueue.UnWaypointed[Position] = {}
        end

        table.insert(UnitMovementQueue.UnWaypointed[Position], Unit)
    end
end

local Unit = {} 
local UnitCache = {}

local UnitDynamicProperties = {
    ["CFrame"] = function(self)
        return self.Instance:GetPivot();
    end;
};

function Unit:__index(Index)
    local Stats = rawget(self, "Torso");
    local Stat = Stats:FindFirstChild(Index);
    
    return rawget(self, Index) or (Stat and #Stat:GetChildren() == 0 and Stat.Value) or UnitDynamicProperties[Index] and UnitDynamicProperties[Index](self); 
end

function Unit.new(UnitOBJ)
    local self = UnitCache[UnitOBJ] or setmetatable({}, Unit)
    
    UnitCache[UnitOBJ] = self;
    
    local Torso = UnitOBJ:FindFirstChild("Torso");
    
    self.Type = UnitOBJ.Name;
    self.Instance = UnitOBJ;
    self.Torso = Torso;
    self.InternalSignals = {
        Destroying = UnitOBJ.Destroying:Connect(function()
            UnitCache[UnitOBJ]:Disconnect();
        end)
    };
    
    return self;
end

function Unit:MoveTo(Goal, IsWaypoint) --(Goal: Vector3 [Destination You Want To Move To], IsWaypoint: boolean [If the destination will be followed after the last one is done]) -> (nil)
    print(Goal, IsWaypoint)
    return AddToQueue(self.Instance, Goal, IsWaypoint)
end

function Unit:Destroy()
    return Remotes.Destroy:FireServer(self.Instance);
end

function Unit:Destroy()
    UnitCache[self.Instance] = nil;
    self.InternalSignals["Destroying"]:Disconnect();
    Remotes.Destroy:FireServer(self.Instance);
end

Classes.Unit = Unit;

local Team = {} 
local TeamCache = {};

local TeamDynamicProperties = {
    ["Owner"] = function(self)
        return self:GetPlayers()[1];
    end;
    ["Color"] = function(self)
        return self.Instance.TeamColor;
    end;
    ["Units"] = function(self)
        return self:GetAllUnits();
    end;
    ["Buildings"] = function(self)
        return self:GetAllBuildings();
    end;
    ["UnitsResearched"] = function(self)
        local UnitsResearched = self.Stats:FindFirstChild("UnitsResearched")
        local Result = {}
        
        for Index, Unit in pairs(UnitsResearched:GetChildren()) do
            table.insert(Result, Unit.Name);
        end
        
        return Result
    end;
    ["Research"] = function(self)
        return self:GetResearchTable();
    end;
    ["Researched"] = function(self)
        local Research = self.Research;
        local Result = {}
        
        for Index, Value in pairs(Research:GetChildren()) do
            local Done = Value:FindFirstChild("Done");
            
            if Done and Done.Value then
                table.insert(Result, Value.Name);
            end
        end
        
        return Result
    end;
    ["Researching"] = function(self)
        local Research = self.Research;
        local Result = {}
        for Index, Value in pairs(Research:GetChildren()) do
            local Progress = Value:FindFirstChild("Progress");
            local Done = Value:FindFirstChild("Done")
            
            if Progress and Progress.Value > 0 and not Done.Value then
                print(Value.Name)
                table.insert(Result, Value.Name)
            end
        end
        
        return Result
    end;
    ["AvailiableResearch"] = function(self)
        local Research = self.Research;
        local Result = {}
        
        for Index, Value in pairs(Research:GetChildren()) do
            local AvailiableNow = Value:FindFirstChild("AvailiableNow");
            
            if AvailiableNow and AvailiableNow.Value then
                table.insert(Result, AvailiableNow.Name);
            end
        end
        
        return Result;
    end;
    ["Name"] = function(self)
        return tostring(self.Instance.TeamColor)
    end
}

function Team:__index(Index)
    local Stats = rawget(self, "Stats");
    local Stat = Stats:FindFirstChild(Index);

    return rawget(Team, Index) or (Stat and Stat.Value) or TeamDynamicProperties[Index] and TeamDynamicProperties[Index](self); 
end

function Team.new(TeamOBJ)
    local self = TeamCache[TeamOBJ] or setmetatable({}, Team);

    TeamCache[TeamOBJ] = self;
    
    local ColorName = tostring(TeamOBJ.TeamColor)
    
    self.Color = TeamOBJ.TeamColor
    self.Instance = TeamOBJ;
    self.WorkspaceInstance = TeamsInstance:FindFirstChild(ColorName);
    self.Stats = TeamSettings:FindFirstChild(ColorName);
    self.InternalSignals = {
        ["Destroying"] = TeamOBJ.Destroying:Connect(function()
            TeamCache[TeamOBJ] = nil;
        end)
    };
    
    return self;
end

function Team:GetAllUnits()
    local Result = {};

    for _, Unit in pairs(self.WorkspaceInstance:GetChildren()) do
        if not Unit:FindFirstChild("PyramidCollisionPart") then
            table.insert(Result, Classes.Unit.new(Unit))
        end
    end

    return Result;
end

function Team:GetResearchTable()
    for Index, Value in pairs(self.Stats:GetChildren()) do
        if Value:FindFirstChild("Juggernaut") then
            return Value
        end
    end
end

function Team:Destroy()
    TeamCache[self.Instance] = nil;
    self.InternalSignals["Destroying"]:Disconnect();
    Remotes.Destroy:FireServer(self.Instance);
end

function Team:IsAlliedWith(Team)
    local Allies = self.Stats:FindFirstChild("Allies");
    
    return Allies:FindFirstChild(Team.Name)
end

Classes.Team = Team;

local function GetLocalTeam()
    return Team.new(LocalPlayer.Team)
end

local function GetAllTeams()
    local Result = {}
    
    for Index, Team in pairs(Teams:GetChildren()) do
        table.insert(Result, Team.new(Team));
    end
    
    return Result
end

local function GetAllActiveTeams() 
    local Result = {}
    
    for Index, Player in pairs(Players:GetPlayers()) do
        table.insert(Result, Team.new(Player.Team));
    end
    
    return Result
end

local getconstants = debug.getconstants;
local getconstant = debug.getconstant;
local getupvalue = debug.getupvalue;

local function filtergc(con, return_one) 
    local r = {};
    for i,v in pairs(getgc()) do
        if type(v) == "function" and not is_synapse_function(v) and islclosure(v) then
            local m = 0;
            for _, v2 in pairs(getconstants(v)) do
                if table.find(con, v2) then
                    m = m + 1;
                end;
            end;

            if m >= #con then
                r[#r+1] = v;
            end;
        end;
    end;

    return return_one and r[1] or r;
end;

local Reg = {};
local MoveUnitsF = filtergc({"Position", "isAWaypoint", "isAFormation", "afterFormationPositions" })[2]
local Build = filtergc({"VIPPlaceBuilding", "Parent"})[2];
local SetHover = filtergc({"ClearAllChildren", "InvokeServer", "Heartbeat", "wait"}, true);
local Research = filtergc({"Cash", "Value", "Cost", "Purchased", "FireServer", 0.35 })[1]
local DeployUnit = filtergc({"Can't make this, it's not researched", "Command Center" }, true);

Reg = getupvalue(MoveUnitsF, 1);
Remotes.MoveUnits = Reg[getconstant(MoveUnitsF, 1)];
Remotes.Build = Reg[getconstant(Build, 1)];
Remotes.SetHover = getupvalue(SetHover, 1)[getconstant(SetHover, 2)];
Remotes.Research = getupvalue(Research, 6)[getconstant(Research, 10)];
Remotes.DeployUnit = getupvalue(DeployUnit, 5)[getconstant(DeployUnit, 21)]

for i,v in getgc() do
    if type(v) == "function" and not is_synapse_function(v) and debug.info(v, "l") == 3336 then
        local p = getproto(v, 4);
        Remotes.SetSkin = Reg[getconstant(p, 1)];
        break;
    end;
end;

local TeamAPI = {
    GetLocalTeam = GetLocalTeam;
    GetAllTeams = GetAllTeams;
    GetAllActiveTeams = GetAllActiveTeams;
};

local ConquerorsAPI = {
    Remotes = Remotes;
    RemoteFunctions = RemoteFunctions;
    TeamAPI = TeamAPI;
}

return ConquerorsAPI
