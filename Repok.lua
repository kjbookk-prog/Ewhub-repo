--//========================================================--
--// EWEHUB UNIVERSAL LOADER
--// Version : 1.0.0
--// Author  : EWEHUB
--//========================================================--

repeat task.wait() until game:IsLoaded()

--========================================================--
-- SERVICES
--========================================================--

local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService        = game:GetService("HttpService")
local CoreGui            = game:GetService("CoreGui")
local RunService         = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

--========================================================--
-- CONFIG
--========================================================--

local Config = {
	Name = "EWEHUB Loader",
	Version = "1.0.0",
	Debug = true,

	FadeTime = 0.25,
	ScaleTime = 0.35,
	ProgressSpeed = 0.35,
	DestroyDelay = 0.15,

	UISize = Vector2.new(285, 145),
	CornerRadius = UDim.new(0, 14),
	StrokeThickness = 1,
	DisplayOrder = 999999,

	EnableLogger = true,
	RegistryURL = "",
	DefaultScript = "",
	AllowRemoteRegistry = false,
}

--========================================================--
-- THEME
--========================================================--

local Theme = {
	Background = Color3.fromRGB(17, 17, 17),
	Surface = Color3.fromRGB(24, 24, 24),
	Border = Color3.fromRGB(40, 40, 40),
	Accent = Color3.fromRGB(0, 255, 150),
	Success = Color3.fromRGB(0, 255, 120),
	Error = Color3.fromRGB(255, 70, 70),
	Warning = Color3.fromRGB(255, 185, 0),
	Text = Color3.fromRGB(255, 255, 255),
	SubText = Color3.fromRGB(170, 170, 170),
}

--========================================================--
-- LOGGER
--========================================================--

local Logger = {}

local function log(prefix, ...)
	if not Config.EnableLogger then
		return
	end
	print(("[EWEHUB][%s]"):format(prefix), ...)
end

function Logger:Info(...)
	log("INFO", ...)
end

function Logger:Success(...)
	log("SUCCESS", ...)
end

function Logger:Warn(...)
	warn("[EWEHUB][WARN]", ...)
end

function Logger:Error(...)
	warn("[EWEHUB][ERROR]", ...)
end

--========================================================--
-- MAID
--========================================================--

local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({
		Tasks = {}
	}, Maid)
end

function Maid:Give(Task)
	table.insert(self.Tasks, Task)
	return Task
end

function Maid:Cleanup()
	for _, Task in ipairs(self.Tasks) do
		pcall(function()
			if typeof(Task) == "RBXScriptConnection" then
				Task:Disconnect()
			elseif typeof(Task) == "Instance" then
				Task:Destroy()
			elseif type(Task) == "function" then
				Task()
			end
		end)
	end
	table.clear(self.Tasks)
end

local Cleaner = Maid.new()

--========================================================--
-- UTILITIES
--========================================================--

local Utility = {}

function Utility:Create(ClassName, Properties)
	local Obj = Instance.new(ClassName)
	for Property, Value in pairs(Properties) do
		Obj[Property] = Value
	end
	return Obj
end

function Utility:Tween(Object, Info, Properties)
	local Tw = TweenService:Create(Object, Info, Properties)
	Tw:Play()
	return Tw
end

function Utility:SafeCall(Func, ...)
	local Ok, Result = pcall(Func, ...)
	if not Ok then
		Logger:Error(Result)
	end
	return Ok, Result
end

function Utility:FormatNumber(Number)
	local Left, Num, Right = tostring(Number):match("^([^%d]*%d)(%d*)(.-)$")
	return Left .. (Num:reverse():gsub("(%d%d%d)", "%1,"):reverse()) .. Right
end

--========================================================--
-- GAME REGISTRY
--========================================================--

local GameRegistry = {
	-- [UniverseId] = {
	--     Name = "Game Name",
	--     Script = "https://raw.githubusercontent.com/...",
	--     Enabled = true
	-- }
}

--========================================================--
-- GAME DETECTOR
--========================================================--

local GameDetector = {}

function GameDetector:Get()
	local UniverseId = game.GameId
	local PlaceId = game.PlaceId

	local Result = {
		UniverseId = UniverseId,
		PlaceId = PlaceId,
		Name = "Unknown Game",
		Supported = false,
		Registry = nil,
	}

	local Entry = GameRegistry[UniverseId]
	if Entry and Entry.Enabled then
		Result.Supported = true
		Result.Registry = Entry
		Result.Name = Entry.Name or "Supported Game"
	end

	local Ok, Info = pcall(function()
		return MarketplaceService:GetProductInfo(PlaceId)
	end)

	if Ok and Info and Info.Name and Result.Name == "Unknown Game" then
		Result.Name = Info.Name
	end

	return Result
end

--========================================================--
-- LOADER UI
--========================================================--

local LoaderUI = {
	Gui = nil,
	Main = nil,
	Shadow = nil,
	Title = nil,
	Status = nil,
	Detail = nil,
	Bar = nil,
	Progress = nil,
	Icon = nil,
	Scale = nil,
}

function LoaderUI:Create()
	if self.Gui then
		self.Gui:Destroy()
	end

	local Gui = Utility:Create("ScreenGui", {
		Name = "EWEHUB_Loader",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = Config.DisplayOrder,
		Parent = CoreGui,
	})
	self.Gui = Gui

	local Shadow = Utility:Create("ImageLabel", {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, Config.UISize.X + 40, 0, Config.UISize.Y + 40),
		BackgroundTransparency = 1,
		Image = "rbxassetid://1316045217",
		ImageTransparency = 0.75,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(10, 10, 118, 118),
		ZIndex = 1,
		Parent = Gui,
	})
	self.Shadow = Shadow

	local Main = Utility:Create("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(Config.UISize.X, Config.UISize.Y),
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = Gui,
	})
	self.Main = Main

	Utility:Create("UICorner", {
		CornerRadius = Config.CornerRadius,
		Parent = Main,
	})

	Utility:Create("UIStroke", {
		Color = Theme.Border,
		Thickness = Config.StrokeThickness,
		Transparency = 0.35,
		Parent = Main,
	})

	local Scale = Utility:Create("UIScale", {
		Scale = 0.85,
		Parent = Main,
	})
	self.Scale = Scale

	local Title = Utility:Create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(15, 10),
		Size = UDim2.new(1, -50, 0, 20),
		Font = Enum.Font.GothamBold,
		Text = Config.Name,
		TextColor3 = Theme.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTransparency = 1,
		ZIndex = 3,
		Parent = Main,
	})
	self.Title = Title

	local Icon = Utility:Create("TextLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -15, 0, 10),
		Size = UDim2.fromOffset(22, 22),
		Font = Enum.Font.GothamBold,
		Text = "●",
		TextColor3 = Theme.Accent,
		TextScaled = true,
		TextTransparency = 1,
		ZIndex = 3,
		Parent = Main,
	})
	self.Icon = Icon

	local Status = Utility:Create("TextLabel", {
		Name = "Status",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(15, 38),
		Size = UDim2.new(1, -30, 0, 18),
		Font = Enum.Font.Gotham,
		Text = "Initializing...",
		TextColor3 = Theme.SubText,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTransparency = 1,
		ZIndex = 3,
		Parent = Main,
	})
	self.Status = Status

	local Detail = Utility:Create("TextLabel", {
		Name = "Detail",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(15, 61),
		Size = UDim2.new(1, -30, 0, 38),
		Font = Enum.Font.Gotham,
		Text = "Universe : -\nPlace : -",
		TextColor3 = Theme.SubText,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextTransparency = 1,
		ZIndex = 3,
		Parent = Main,
	})
	self.Detail = Detail

	local BarBG = Utility:Create("Frame", {
		Name = "BarBG",
		Position = UDim2.fromOffset(15, 113),
		Size = UDim2.new(1, -30, 0, 8),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = Main,
	})
	Utility:Create("UICorner", {
		CornerRadius = UDim.new(1, 0),
		Parent = BarBG,
	})

	local Progress = Utility:Create("Frame", {
		Name = "Progress",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = BarBG,
	})
	self.Progress = Progress

	Utility:Create("UICorner", {
		CornerRadius = UDim.new(1, 0),
		Parent = Progress,
	})

	self:ResetState()
	return self
end

function LoaderUI:ResetState()
	if not self.Main then
		return
	end
	self.Main.BackgroundTransparency = 1
	self.Title.TextTransparency = 1
	self.Status.TextTransparency = 1
	self.Detail.TextTransparency = 1
	self.Icon.TextTransparency = 1
	self.Progress.Size = UDim2.fromScale(0, 1)
	self.Icon.Text = "●"
	self.Icon.TextColor3 = Theme.Accent
	self.Scale.Scale = 0.85
end

function LoaderUI:SetStatus(Text)
	if self.Status then
		self.Status.Text = Text
	end
end

function LoaderUI:SetDetail(UniverseId, PlaceId)
	if self.Detail then
		self.Detail.Text = ("Universe : %s\nPlace : %s"):format(UniverseId, PlaceId)
	end
end

function LoaderUI:SetProgress(Value)
	Value = math.clamp(Value, 0, 100)
	if self.Progress then
		Utility:Tween(self.Progress, TweenInfo.new(Config.ProgressSpeed, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(Value / 100, 1)
		})
	end
end

function LoaderUI:FadeIn()
	if not self.Main then
		return
	end

	Utility:Tween(self.Scale, TweenInfo.new(Config.ScaleTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Scale = 1
	})
	Utility:Tween(self.Main, TweenInfo.new(Config.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0
	})
	Utility:Tween(self.Shadow, TweenInfo.new(Config.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		ImageTransparency = 0.65
	})
	Utility:Tween(self.Title, TweenInfo.new(Config.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0
	})
	Utility:Tween(self.Status, TweenInfo.new(Config.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0
	})
	Utility:Tween(self.Detail, TweenInfo.new(Config.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0
	})
	Utility:Tween(self.Icon, TweenInfo.new(Config.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0
	})
end

function LoaderUI:Success()
	if not self.Icon then
		return
	end
	self.Icon.Text = "✓"
	self.Icon.TextColor3 = Theme.Success
	local Scale = self.Icon:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", self.Icon)
	Scale.Scale = 0.4
	Utility:Tween(Scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1
	})
end

function LoaderUI:Error()
	if not self.Icon then
		return
	end
	self.Icon.Text = "✕"
	self.Icon.TextColor3 = Theme.Error
	local Scale = self.Icon:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", self.Icon)
	Scale.Scale = 0.4
	Utility:Tween(Scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1
	})
end

function LoaderUI:Close()
	if not self.Main then
		return
	end

	Utility:Tween(self.Scale, TweenInfo.new(Config.ScaleTime, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
		Scale = 0.85
	})
	Utility:Tween(self.Main, TweenInfo.new(Config.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 1
	})
	Utility:Tween(self.Shadow, TweenInfo.new(Config.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		ImageTransparency = 1
	})
	Utility:Tween(self.Title, TweenInfo.new(Config.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1
	})
	Utility:Tween(self.Status, TweenInfo.new(Config.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1
	})
	Utility:Tween(self.Detail, TweenInfo.new(Config.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1
	})
	Utility:Tween(self.Icon, TweenInfo.new(Config.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1
	})

	task.wait(Config.DestroyDelay)
	Cleaner:Cleanup()
	if self.Gui then
		self.Gui:Destroy()
	end
end

--========================================================--
-- MAIN
--========================================================--

local Main = {}

function Main:Run()
	Logger:Info("Starting loader...")

	local Data = GameDetector:Get()
	LoaderUI:Create()
	LoaderUI:FadeIn()

	LoaderUI:SetDetail(Data.UniverseId, Data.PlaceId)

	LoaderUI:SetStatus("Detecting Game...")
	LoaderUI:SetProgress(25)
	task.wait(0.35)

	LoaderUI:SetStatus("Checking Game Support...")
	LoaderUI:SetProgress(60)
	task.wait(0.35)

	LoaderUI:SetStatus("Verifying Database...")
	LoaderUI:SetProgress(85)
	task.wait(0.35)

	if Data.Supported then
		Logger:Success("Game supported:", Data.Name)
		LoaderUI:SetProgress(100)
		LoaderUI:SetStatus("✔ Game Supported")
		LoaderUI:Success()
		task.wait(1.5)
		LoaderUI:Close()

		if Data.Registry and Data.Registry.Script ~= "" then
			local Ok, Err = pcall(function()
				loadstring(game:HttpGet(Data.Registry.Script))()
			end)
			if not Ok then
				Logger:Error(Err)
			end
		elseif Config.DefaultScript ~= "" then
			local Ok, Err = pcall(function()
				loadstring(game:HttpGet(Config.DefaultScript))()
			end)
			if not Ok then
				Logger:Error(Err)
			end
		end
	else
		Logger:Warn("Game not supported:", Data.UniverseId)
		LoaderUI:SetProgress(100)
		LoaderUI:SetStatus("✖ Game Not Supported")
		LoaderUI:Error()
		task.wait(2)
		LoaderUI:Close()
	end
end

Main:Run()
