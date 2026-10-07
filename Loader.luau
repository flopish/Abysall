local GlobalEnvironment = getgenv()
local BaseUrl = "https://raw.githubusercontent.com/flopish/Abysall/refs/heads/main/"
local GameList = {
    [2440500124] = "Doors"
}

local function Log(Message)
    print("[Abysall][Loader] " .. Message)
end

local function LoadModule(Path)
    local Url = BaseUrl .. Path
    Log("Fetching " .. Path)

    local FetchSuccess, Source = pcall(function()
        return game:HttpGet(Url)
    end)
    if not FetchSuccess then
        local Message = "HTTP fetch failed for " .. Path .. ": " .. tostring(Source)
        warn("[Abysall][Loader] " .. Message)
        if GlobalEnvironment.Abysall then
            GlobalEnvironment.Abysall.Loading = false
        end
        error(Message, 0)
    end

    if type(Source) ~= "string" or Source == "" then
        local Message = "HTTP fetch returned empty content for " .. Path
        warn("[Abysall][Loader] " .. Message)
        if GlobalEnvironment.Abysall then
            GlobalEnvironment.Abysall.Loading = false
        end
        error(Message, 0)
    end
    Log(("Fetched %s (%d bytes)"):format(Path, #Source))

    if type(loadstring) ~= "function" then
        local Message = "Compilation is unavailable: loadstring is not supported by this executor"
        warn("[Abysall][Loader] " .. Message)
        if GlobalEnvironment.Abysall then
            GlobalEnvironment.Abysall.Loading = false
        end
        error(Message, 0)
    end

    local CompileSuccess, Chunk, CompileError = pcall(loadstring, Source)
    if not CompileSuccess or not Chunk then
        if not CompileSuccess then
            CompileError = Chunk
        end
        local Message = "Compilation failed for " .. Path .. ": " .. tostring(CompileError)
        warn("[Abysall][Loader] " .. Message)
        if GlobalEnvironment.Abysall then
            GlobalEnvironment.Abysall.Loading = false
        end
        error(Message, 0)
    end

    Log("Executing " .. Path)
    local ExecuteSuccess, Result = pcall(Chunk)
    if not ExecuteSuccess then
        local Message = "Execution failed for " .. Path .. ": " .. tostring(Result)
        warn("[Abysall][Loader] " .. Message)
        if GlobalEnvironment.Abysall then
            GlobalEnvironment.Abysall.Loading = false
        end
        error(Message, 0)
    end

    Log("Loaded " .. Path)
    return Result
end

if type(GlobalEnvironment.Abysall) == "table" then
    Log("Resetting previous Abysall instance for clean reload")
end

local Abysall = {
    Legit = true,
    Loading = true
}
GlobalEnvironment.Abysall = Abysall
Abysall.LoadModule = LoadModule

Log(("Starting load (GameId=%s, PlaceId=%s)"):format(tostring(game.GameId), tostring(game.PlaceId)))

Abysall.Environment = LoadModule("Components/Environment.luau")
Abysall.ESPLibrary = LoadModule("Components/ESP.luau")

local function CloneReference(Object)
    if Abysall.Environment and Abysall.Environment.cloneref then
        return Abysall.Environment.cloneref(Object)
    end
    return Object
end

local Services = setmetatable({}, {
    __index = function(_, Name)
        return CloneReference(game:GetService(Name))
    end
})

local function LoadUserData()
    Abysall.TotalExecutions = 0
    Abysall.UILibrary = "Obsidian"

    local Environment = Abysall.Environment
    if not (Environment.writefile and Environment.readfile and Environment.isfile) then
        Log("User data persistence unavailable; using defaults")
        return
    end

    local Success, DataOrError = pcall(function()
        local Path = "Abysall/UserData.json"
        if Environment.makefolder and Environment.isfolder and not Environment.isfolder("Abysall") then
            Environment.makefolder("Abysall")
        end
        if not Environment.isfile(Path) then
            Environment.writefile(Path, Services.HttpService:JSONEncode({
                TotalExecutions = 0,
                UILibrary = "Obsidian"
            }))
        end

        local Decoded = Services.HttpService:JSONDecode(Environment.readfile(Path))
        assert(type(Decoded) == "table", "User data JSON must contain an object")
        Decoded.TotalExecutions = (tonumber(Decoded.TotalExecutions) or 0) + 1
        Decoded.UILibrary = Decoded.UILibrary or "Obsidian"

        Environment.writefile(Path, Services.HttpService:JSONEncode(Decoded))
        return Decoded
    end)

    if Success then
        Abysall.TotalExecutions = DataOrError.TotalExecutions
        Abysall.UILibrary = DataOrError.UILibrary
        Log(("User data loaded (execution %s)"):format(tostring(Abysall.TotalExecutions)))
    else
        warn("[Abysall][Loader] User data persistence failed; continuing with defaults: " .. tostring(DataOrError))
    end
end

LoadUserData()

Abysall.Interface = LoadModule("Components/Interface.luau")
Abysall.Analytics = LoadModule("Components/Analytics.luau")

local CurrentGame = GameList[game.GameId]
if CurrentGame then
    Log("Selected game loader: " .. CurrentGame)
    LoadModule("Games/" .. CurrentGame .. "/Loader.luau")
else
    Log("No game-specific loader matched; selecting Universal")
    LoadModule("Games/Universal/Loader.luau")
end

Abysall.Loading = false
Abysall.Loaded = true
Log("Startup completed successfully")
