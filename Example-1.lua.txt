--[[
	Contoh pemakaian EWEHUB (by Asep)

	Kalau di-hosting online, developer lain cukup menulis:
		local EWEHUB = loadstring(game:HttpGet("URL_RAW_KAMU/Library.lua"))()

	Kalau dipakai sebagai ModuleScript di dalam game:
		local EWEHUB = require(game.ReplicatedStorage.EWEHUB.Library)

	File ini mencontohkan cara memakai SEMUA fitur library:
	Window, Tab, Toggle, Slider, Dropdown, Button, Textbox,
	Config system, Notify, dan info pemain di tab Settings.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- local EWEHUB = loadstring(game:HttpGet("URL_RAW_KAMU/Library.lua"))()
local EWEHUB = require(script.Parent.Library) -- ganti sesuai lokasi module kamu

-- (opsional) reskin tema sebelum membuat window
-- EWEHUB:SetTheme({ Accent = Color3.fromRGB(0, 255, 170) })

local Window = EWEHUB:CreateWindow({
	Name = "EWEHUB",
	ToggleKey = Enum.KeyCode.RightControl, -- tekan untuk show/hide UI
})

----------------------------------------------------------------
-- TAB MAIN
----------------------------------------------------------------
local MainTab = Window:CreateTab({ Name = "Main", Icon = "🏠" })

MainTab:CreateLabel("FITUR UTAMA")

MainTab:CreateToggle({
	Name = "Contoh Toggle",
	Flag = "ExampleToggle",
	Default = false,
	Callback = function(value)
		EWEHUB:Notify({
			Title = "Toggle",
			Content = "Contoh Toggle sekarang: " .. tostring(value),
			Duration = 3,
		})
	end,
})

MainTab:CreateSlider({
	Name = "Contoh Slider",
	Flag = "ExampleSlider",
	Min = 0, Max = 100, Default = 50,
	Callback = function(value)
		print("Slider Contoh:", value)
	end,
})

MainTab:CreateDropdown({
	Name = "Contoh Dropdown",
	Flag = "ExampleDropdown",
	Options = { "Opsi 1", "Opsi 2", "Opsi 3" },
	Default = "Opsi 1",
	Callback = function(value)
		print("Dropdown Contoh:", value)
	end,
})

MainTab:CreateButton({
	Name = "Kirim Notifikasi",
	Callback = function()
		EWEHUB:Notify({
			Title = "EWEHUB",
			Content = "Halo! Ini contoh notifikasi dari Asep.",
			Duration = 4,
		})
	end,
})

----------------------------------------------------------------
-- TAB CONFIG
----------------------------------------------------------------
local ConfigTab = Window:CreateTab({ Name = "Config", Icon = "💾" })
ConfigTab:CreateLabel("MANAJEMEN KONFIGURASI")

local configNameBox = ConfigTab:CreateTextbox({ Name = "Nama Config", Placeholder = "Masukkan nama config..." })

local configDropdown
local function RefreshConfigList()
	if configDropdown then
		configDropdown.SetOptions(EWEHUB.SafeIO.ListConfigs())
	end
end

local overwriteHolder
local function ShowOverwriteConfirm(name)
	if overwriteHolder then overwriteHolder:Destroy() end

	overwriteHolder = Instance.new("Frame")
	overwriteHolder.Size = UDim2.new(1, 0, 0, 60)
	overwriteHolder.BackgroundColor3 = EWEHUB.Theme.Panel
	overwriteHolder.Parent = ConfigTab.Page

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = overwriteHolder

	local label = Instance.new("TextLabel")
	label.Text = ("Config '%s' sudah ada. Timpa?"):format(name)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 13
	label.TextColor3 = EWEHUB.Theme.Text
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0, 10, 0, 6)
	label.Size = UDim2.new(1, -20, 0, 18)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = overwriteHolder

	local function makeBtn(text, x, color)
		local b = Instance.new("TextButton")
		b.Text = text
		b.Font = Enum.Font.GothamBold
		b.TextSize = 12
		b.TextColor3 = EWEHUB.Theme.Text
		b.BackgroundColor3 = color
		b.Size = UDim2.new(0, 100, 0, 24)
		b.Position = UDim2.new(0, x, 1, -30)
		b.AutoButtonColor = false
		b.Parent = overwriteHolder
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = b
		return b
	end

	local confirmBtn = makeBtn("Ya, Timpa", 10, EWEHUB.Theme.Danger)
	local cancelBtn = makeBtn("Batal", 118, EWEHUB.Theme.Stroke)

	confirmBtn.MouseButton1Click:Connect(function()
		EWEHUB.SafeIO.SaveConfig(name, EWEHUB.Flags)
		RefreshConfigList()
		overwriteHolder:Destroy()
		overwriteHolder = nil
	end)
	cancelBtn.MouseButton1Click:Connect(function()
		overwriteHolder:Destroy()
		overwriteHolder = nil
	end)
end

ConfigTab:CreateButton({
	Name = "Save Config",
	Callback = function()
		local name = configNameBox.Get()
		if name == "" then return end
		local exists = table.find(EWEHUB.SafeIO.ListConfigs(), name) ~= nil
		if exists then
			ShowOverwriteConfirm(name)
		else
			EWEHUB.SafeIO.SaveConfig(name, EWEHUB.Flags)
			RefreshConfigList()
			EWEHUB:Notify({ Title = "Config", Content = "Config '" .. name .. "' disimpan.", Duration = 3 })
		end
	end,
})

configDropdown = ConfigTab:CreateDropdown({
	Name = "Daftar Config",
	Options = EWEHUB.SafeIO.ListConfigs(),
})

ConfigTab:CreateButton({
	Name = "Load Config",
	Callback = function()
		local name = configDropdown.Get()
		if not name then return end
		local data = EWEHUB.SafeIO.LoadConfig(name)
		if data then
			for flagName, value in pairs(data) do
				local setter = EWEHUB.ConfigCallbacks[flagName]
				if setter then setter(value) end
			end
			EWEHUB:Notify({ Title = "Config", Content = "Config '" .. name .. "' dimuat.", Duration = 3 })
		end
	end,
})

ConfigTab:CreateButton({
	Name = "Edit / Rename Config",
	Callback = function()
		local oldName = configDropdown.Get()
		local newName = configNameBox.Get()
		if not oldName or newName == "" then return end
		if EWEHUB.SafeIO.RenameConfig(oldName, newName) then
			RefreshConfigList()
			configDropdown.Set(newName)
		end
	end,
})

ConfigTab:CreateButton({
	Name = "Delete Config",
	Callback = function()
		local name = configDropdown.Get()
		if not name then return end
		EWEHUB.SafeIO.DeleteConfig(name)
		configDropdown.Set(nil)
		RefreshConfigList()
	end,
})

----------------------------------------------------------------
-- TAB SETTINGS (info pemain)
----------------------------------------------------------------
local SettingsTab = Window:CreateTab({ Name = "Settings", Icon = "👤" })

local function AddInfoRow(parent, label, value)
	local Row = Instance.new("Frame")
	Row.Size = UDim2.new(1, 0, 0, 16)
	Row.BackgroundTransparency = 1
	Row.Parent = parent

	local L = Instance.new("TextLabel")
	L.Text = label
	L.Font = Enum.Font.Gotham
	L.TextSize = 12
	L.TextColor3 = EWEHUB.Theme.SubText
	L.BackgroundTransparency = 1
	L.TextXAlignment = Enum.TextXAlignment.Left
	L.Size = UDim2.new(0.5, 0, 1, 0)
	L.Parent = Row

	local V = Instance.new("TextLabel")
	V.Text = value
	V.Font = Enum.Font.GothamMedium
	V.TextSize = 12
	V.TextColor3 = EWEHUB.Theme.Text
	V.BackgroundTransparency = 1
	V.TextXAlignment = Enum.TextXAlignment.Right
	V.Size = UDim2.new(0.5, 0, 1, 0)
	V.Parent = Row
end

local ProfileCard = Instance.new("Frame")
ProfileCard.Size = UDim2.new(1, 0, 0, 220)
ProfileCard.BackgroundColor3 = EWEHUB.Theme.Panel
ProfileCard.Parent = SettingsTab.Page
local pcCorner = Instance.new("UICorner") pcCorner.CornerRadius = UDim.new(0, 10) pcCorner.Parent = ProfileCard
local pcStroke = Instance.new("UIStroke") pcStroke.Color = EWEHUB.Theme.Stroke pcStroke.Parent = ProfileCard

local Avatar = Instance.new("ImageLabel")
Avatar.Size = UDim2.new(0, 80, 0, 80)
Avatar.Position = UDim2.new(0.5, -40, 0, 16)
Avatar.BackgroundColor3 = EWEHUB.Theme.PanelLight
Avatar.Parent = ProfileCard
local avCorner = Instance.new("UICorner") avCorner.CornerRadius = UDim.new(0, 40) avCorner.Parent = Avatar
local avStroke = Instance.new("UIStroke") avStroke.Color = EWEHUB.Theme.Accent avStroke.Thickness = 2 avStroke.Parent = Avatar

task.spawn(function()
	local ok, content = pcall(function()
		return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
	end)
	if ok then Avatar.Image = content end
end)

local nameLabel = Instance.new("TextLabel")
nameLabel.Text = "@" .. LocalPlayer.Name
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextSize = 15
nameLabel.TextColor3 = EWEHUB.Theme.Text
nameLabel.BackgroundTransparency = 1
nameLabel.Position = UDim2.new(0, 0, 0, 100)
nameLabel.Size = UDim2.new(1, 0, 0, 18)
nameLabel.Parent = ProfileCard

local displayLabel = Instance.new("TextLabel")
displayLabel.Text = LocalPlayer.DisplayName
displayLabel.Font = Enum.Font.Gotham
displayLabel.TextSize = 13
displayLabel.TextColor3 = EWEHUB.Theme.SubText
displayLabel.BackgroundTransparency = 1
displayLabel.Position = UDim2.new(0, 0, 0, 120)
displayLabel.Size = UDim2.new(1, 0, 0, 16)
displayLabel.Parent = ProfileCard

local InfoList = Instance.new("Frame")
InfoList.Position = UDim2.new(0, 16, 0, 145)
InfoList.Size = UDim2.new(1, -32, 0, 60)
InfoList.BackgroundTransparency = 1
InfoList.Parent = ProfileCard
local ilLayout = Instance.new("UIListLayout")
ilLayout.Padding = UDim.new(0, 2)
ilLayout.SortOrder = Enum.SortOrder.LayoutOrder
ilLayout.Parent = InfoList

AddInfoRow(InfoList, "UserId", tostring(LocalPlayer.UserId))
AddInfoRow(InfoList, "Umur Akun", LocalPlayer.AccountAge .. " hari")
AddInfoRow(InfoList, "Platform", (UserInputService.TouchEnabled and not UserInputService.MouseEnabled) and "Mobile" or "PC")
AddInfoRow(InfoList, "Versi UI", "EWEHUB v" .. EWEHUB.Version .. " by " .. EWEHUB.Author)

local CopyBtn = Instance.new("TextButton")
CopyBtn.Text = "Copy UserId"
CopyBtn.Font = Enum.Font.GothamBold
CopyBtn.TextSize = 13
CopyBtn.TextColor3 = EWEHUB.Theme.Text
CopyBtn.BackgroundColor3 = EWEHUB.Theme.AccentDark
CopyBtn.Size = UDim2.new(1, -32, 0, 30)
CopyBtn.Position = UDim2.new(0, 16, 1, -40)
CopyBtn.AutoButtonColor = false
CopyBtn.Parent = ProfileCard
local cbCorner = Instance.new("UICorner") cbCorner.CornerRadius = UDim.new(0, 8) cbCorner.Parent = CopyBtn

CopyBtn.MouseButton1Click:Connect(function()
	local ok = pcall(function() setclipboard(tostring(LocalPlayer.UserId)) end)
	local originalText = CopyBtn.Text
	CopyBtn.Text = ok and "Copied!" or "Tidak didukung"
	task.delay(1, function() CopyBtn.Text = originalText end)
end)

EWEHUB:Notify({
	Title = "EWEHUB",
	Content = "Library berhasil dimuat. Selamat datang!",
	Duration = 4,
})
