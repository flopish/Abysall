if Abysall and type(Abysall.LoadModule) == "function" then
    if game.PlaceId ~= 6516141723 then
        Abysall.LoadModule("Games/Doors/Main.luau")
    else
        Abysall.LoadModule("Games/Doors/Lobby.luau")
    end
else
    local BaseUrl = "https://raw.githubusercontent.com/flopish/Abysall/refs/heads/main/"
    local Path = (game.PlaceId ~= 6516141723) and "Games/Doors/Main.luau" or "Games/Doors/Lobby.luau"
    local Source = game:HttpGet(BaseUrl .. Path)
    local Chunk, CompileErr = loadstring(Source)
    if not Chunk then
        error("[Abysall] Failed to compile " .. Path .. ": " .. tostring(CompileErr), 0)
    end
    Chunk()
end
