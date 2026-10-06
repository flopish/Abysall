local Environment = {
	Results = {}
}

local RootEnvironment = getfenv(0)
local BrokenFeatures = {
	Volcano = { "run_on_actor", "oth" },
	Opiumware = { "gethiddenproperty" },
	Solara = { "require" },
	Xeno = { "require" },
}

local Capabilities = {
	"getgenv",
	"getrenv",
	"getgc",
	"identifyexecutor",
	"request",
	"cloneref",
	"gethui",
	"getcallbackvalue",
	"getinstances",
	"getnilinstances",
	"fireproximityprompt",
	"fireclickdetector",
	"firetouchinterest",
	"clonefunction",
	"newcclosure",
	"hookfunction",
	"restorefunction",
	"isfunctionhooked",
	"isexecutorclosure",
	"getnamecallmethod",
	"hookmetamethod",
	"getrawmetatable",
	"setrawmetatable",
	"isreadonly",
	"setreadonly",
	"Drawing.new",
	"Drawing.Fonts",
	"writefile",
	"isfile",
	"readfile",
	"appendfile",
	"loadfile",
	"delfile",
	"makefolder",
	"delfolder",
	"listfiles",
	"getcustomasset",
	"gethiddenproperty",
	"sethiddenproperty",
	"getthreadidentity",
	"setthreadidentity",
	"isnetworkowner",
	"firesignal",
	"replicatesignal",
	"getconnections",
	"require",
}

local CapabilityAliases = {
	["Drawing.new"] = "Drawing_New",
	["Drawing.Fonts"] = "Drawing_Fonts",
}

local ExecutorName = RootEnvironment.identifyexecutor and RootEnvironment.identifyexecutor() or "Unknown"
local BrokenList = BrokenFeatures[ExecutorName]
local Available = 0

local function ResolveGlobal(Path)
	local Value = RootEnvironment
	for Name in string.gmatch(Path, "[^.]+") do
		if Value == nil then
			return nil
		end
		Value = Value[Name]
	end
	return Value
end

for _, Name in ipairs(Capabilities) do
	local IsKnownBroken = BrokenList and table.find(BrokenList, Name)
	local Value = not IsKnownBroken and ResolveGlobal(Name)
	if Value then
		Environment[CapabilityAliases[Name] or Name] = Value
		table.insert(Environment.Results, "✅ " .. Name .. " available")
		Available += 1
	else
		local Reason = IsKnownBroken and "unsupported by this executor" or "function is nil"
		table.insert(Environment.Results, "❌ " .. Name .. " unavailable: " .. Reason)
	end
end

Environment.PrintResults = function()
	print("Capability Check Result")
	for _, Result in ipairs(Environment.Results) do
		print(Result)
	end
	print("Executor - " .. tostring(ExecutorName))
	print(("Capabilities Available: %d/%d"):format(Available, #Capabilities))
end

return Environment
