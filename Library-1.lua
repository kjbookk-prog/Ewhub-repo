--[[
	================================================================
	 EWEHUB
	 UI Library untuk Roblox — dibuat murni dengan Luau.
	 Dibuat oleh: Asep
	 Versi: 4.1.0

	 CATATAN PERUBAHAN v4.0.0:
	 1. Layout utama sekarang HORIZONTAL (lebih lebar, lebih pendek)
	    supaya tidak terlalu menutupi layar pemain.
	 2. Semua frame memakai rounded corner yang konsisten (desain modern).
	 3. ScreenGui memakai DisplayOrder tinggi supaya selalu di layer
	    paling atas dan tidak tertutup GUI lain.
	 4. Tambahan opening cutscene (fade in/out + skip) saat window
	    pertama kali dibuat.
	 5. Tambahan sistem Discord Join Notification (opsional, bisa
	    dimatikan lewat config).
	 6. Transisi tab & buka/tutup window lebih halus (custom easing).

	 CATATAN PERUBAHAN v4.1.0 (perbaikan dari laporan bug):
	 1. FIX: UI tidak bisa dipencet ketika bentrok dengan library lain
	    (mis. Rayfield). ScreenGui sekarang diparent ke gethui()/CoreGui
	    (kalau tersedia di executor) dan DisplayOrder dinaikkan ke nilai
	    maksimum, supaya selalu menerima input paling pertama.
	 2. FIX: sudut bawah window masih terlihat "kotak" (siku), padahal
	    parent-nya sudah dibuat rounded. Ini bug klasik Roblox: Frame
	    dengan ClipsDescendants hanya meng-clip ke bounding box persegi,
	    BUKAN ke bentuk melengkung UICorner. Sekarang TabList & ContentArea
	    (yang sebelumnya persegi polos) diberi UICorner sendiri supaya
	    sudutnya benar-benar melengkung mengikuti Main.
	 3. BARU: tab "⚙ Pengaturan" bawaan yang SELALU ada di paling ujung
	    (bawah) daftar tab, tidak bisa dihapus/diubah lewat API publik.
	    Isinya: foto profil (headshot) pemain, nama & UserId, HWID
	    (kalau executor mendukung gethwid/get_hwid), nama executor, dan
	    info versi library.

	 CARA MEMUAT (jika dihosting, mis. di GitHub raw):
	   local EWEHUB = loadstring(game:HttpGet("URL_RAW_KAMU"))()

	 CARA MEMUAT (sebagai ModuleScript di dalam game):
	   local EWEHUB = require(path.to.Library)
	 ================================================================
]]

local TweenService     = game:GetService("TweenService")
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

--============================================================
-- EWEHUB CORE TABLE
--============================================================
local EWEHUB = {}
EWEHUB.__index = EWEHUB

EWEHUB.Version  = "4.1.0"
EWEHUB.Author   = "Asep"
EWEHUB.Windows  = {}
EWEHUB.Flags    = {}
EWEHUB.ConfigCallbacks = {}

-- ScreenGui semua elemen library selalu memakai DisplayOrder ini
-- supaya tetap berada di layer teratas, di atas GUI game/library lain.
-- Dipakai nilai maksimum Int32 supaya menang lawan library manapun
-- yang juga mencoba pakai DisplayOrder tinggi (mis. Rayfield).
EWEHUB.DisplayOrder = 2147483647

EWEHUB.Theme = {
	Background   = Color3.fromRGB(14, 14, 14),
	Panel        = Color3.fromRGB(20, 20, 20),
	PanelLight   = Color3.fromRGB(26, 26, 26),
	Stroke       = Color3.fromRGB(38, 38, 38),
	Accent       = Color3.fromRGB(0, 255, 140),
	AccentDark   = Color3.fromRGB(0, 140, 80),
	Text         = Color3.fromRGB(235, 235, 235),
	SubText      = Color3.fromRGB(145, 145, 145),
	Danger       = Color3.fromRGB(255, 80, 80),
	-- Radius sudut default — dipakai supaya semua elemen konsisten "tumpul"
	CornerRadius = 14,
}

local FastTween   = TweenInfo.new(0.16, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local MediumTween = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local SlowTween   = TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local SoftTween   = TweenInfo.new(0.35, Enum.EasingStyle.Sine,  Enum.EasingDirection.InOut)

--============================================================
-- UTIL
--============================================================
local function Tween(obj, info, props)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function New(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do inst[k] = v end
	for _, child in ipairs(children or {}) do child.Parent = inst end
	return inst
end

local function Corner(radius)
	return New("UICorner", { CornerRadius = UDim.new(0, radius or EWEHUB.Theme.CornerRadius) })
end

local function Stroke(color, thickness)
	return New("UIStroke", {
		Color = color or EWEHUB.Theme.Stroke,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function Padding(a, b, c, d)
	return New("UIPadding", {
		PaddingTop = UDim.new(0, a or 0),
		PaddingRight = UDim.new(0, b or a or 0),
		PaddingBottom = UDim.new(0, c or a or 0),
		PaddingLeft = UDim.new(0, d or b or a or 0),
	})
end

local function IsMobile()
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

--============================================================
-- Cari parent GUI teraman & paling atas yang tersedia di executor.
-- Ini penyebab paling umum kenapa UI "tidak bisa dipencet": kalau
-- ScreenGui cuma diparent ke PlayerGui biasa, library lain (mis.
-- Rayfield) yang diparent ke gethui()/CoreGui akan selalu berada
-- SATU LAYER LEBIH ATAS dan mencuri semua input, walaupun secara
-- visual/DisplayOrder kita sudah lebih tinggi.
--============================================================
local function GetGuiParent()
	if typeof(gethui) == "function" then
		local ok, hui = pcall(gethui)
		if ok and hui then return hui end
	end
	local ok2, coreGui = pcall(function() return game:GetService("CoreGui") end)
	if ok2 and coreGui then
		-- pastikan kita benar-benar boleh nulis ke CoreGui (beberapa executor melarang)
		local ok3 = pcall(function()
			local test = Instance.new("Folder")
			test.Name = "__EWEHUB_test"
			test.Parent = coreGui
			test:Destroy()
		end)
		if ok3 then return coreGui end
	end
	return PlayerGui
end

local GuiParent = GetGuiParent()

-- Membuat ScreenGui baru yang selalu diposisikan di layer paling atas.
-- parentOverride opsional — dipakai kalau ada window yang mau memaksa
-- parent tertentu (mis. ForcePlayerGui = true di config CreateWindow).
local function NewTopScreenGui(name, parentOverride)
	return New("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = EWEHUB.DisplayOrder,
		Parent = parentOverride or GuiParent,
	})
end

--============================================================
-- PENYIMPANAN CONFIG (aman untuk executor maupun Studio)
--============================================================
local SafeIO = {}
local MemoryStore = {}
local HasFileSystem = (typeof(writefile) == "function") and (typeof(readfile) == "function")

if HasFileSystem and typeof(isfolder) == "function" and typeof(makefolder) == "function" then
	if not isfolder("EWEHUB") then makefolder("EWEHUB") end
	if not isfolder("EWEHUB/configs") then makefolder("EWEHUB/configs") end
end

function SafeIO.SaveConfig(name, data)
	local encoded = HttpService:JSONEncode(data)
	if HasFileSystem then
		local ok = pcall(writefile, "EWEHUB/configs/" .. name .. ".json", encoded)
		if ok then return true end
	end
	MemoryStore[name] = encoded
	return true
end

function SafeIO.LoadConfig(name)
	if HasFileSystem then
		local ok, content = pcall(readfile, "EWEHUB/configs/" .. name .. ".json")
		if ok and content then
			local success, decoded = pcall(HttpService.JSONDecode, HttpService, content)
			if success then return decoded end
		end
	end
	if MemoryStore[name] then
		local success, decoded = pcall(HttpService.JSONDecode, HttpService, MemoryStore[name])
		if success then return decoded end
	end
	return nil
end

function SafeIO.DeleteConfig(name)
	if HasFileSystem then
		pcall(function()
			if typeof(isfile) == "function" and isfile("EWEHUB/configs/" .. name .. ".json") then
				delfile("EWEHUB/configs/" .. name .. ".json")
			end
		end)
	end
	MemoryStore[name] = nil
end

function SafeIO.RenameConfig(oldName, newName)
	local data = SafeIO.LoadConfig(oldName)
	if data then
		SafeIO.SaveConfig(newName, data)
		SafeIO.DeleteConfig(oldName)
		return true
	end
	return false
end

function SafeIO.ListConfigs()
	local list = {}
	if HasFileSystem and typeof(listfiles) == "function" then
		local ok, files = pcall(listfiles, "EWEHUB/configs")
		if ok then
			for _, path in ipairs(files) do
				local name = path:match("([^/\\]+)%.json$")
				if name then table.insert(list, name) end
			end
			return list
		end
	end
	for name in pairs(MemoryStore) do table.insert(list, name) end
	return list
end

EWEHUB.SafeIO = SafeIO

--============================================================
-- SetTheme — reskin seluruh library (dipanggil sebelum CreateWindow)
--============================================================
function EWEHUB:SetTheme(overrides)
	for k, v in pairs(overrides or {}) do
		if self.Theme[k] ~= nil then
			self.Theme[k] = v
		end
	end
end

--============================================================
-- DRAGGING
--============================================================
local function MakeDraggable(dragHandle, target)
	local dragging, dragStart, startPos = false, nil, nil

	local function update(input)
		local delta = input.Position - dragStart
		local newPos = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
		Tween(target, FastTween, { Position = newPos })
	end

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)

	dragHandle.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			update(input)
		end
	end)
end

--============================================================
-- NOTIFICATION SYSTEM (toast, pojok kanan bawah)
--============================================================
local NotifGui, NotifContainer

local function EnsureNotifRoot()
	if NotifGui and NotifGui.Parent then return end
	NotifGui = NewTopScreenGui("EWEHUB_Notifications")
	NotifContainer = New("Frame", {
		Size = UDim2.new(0, 280, 1, -20),
		Position = UDim2.new(1, -300, 0, 10),
		BackgroundTransparency = 1,
		Parent = NotifGui,
	})
	New("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 8),
		Parent = NotifContainer,
	})
end

function EWEHUB:Notify(config)
	config = config or {}
	EnsureNotifRoot()

	local Toast = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = self.Theme.Panel,
		ClipsDescendants = true,
		LayoutOrder = -os.clock(),
		Parent = NotifContainer,
	}, { Corner(10), Stroke(self.Theme.Accent, 1) })

	local Inner = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = Toast,
	}, { Padding(10, 12, 10, 12) })

	New("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
		Parent = Inner,
	})

	New("TextLabel", {
		Text = config.Title or "EWEHUB",
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = self.Theme.Accent,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 18),
		Parent = Inner,
	})

	New("TextLabel", {
		Text = config.Content or "",
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = self.Theme.Text,
		TextWrapped = true,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = Inner,
	})

	Toast.Size = UDim2.new(1, 0, 0, 0)
	Toast.BackgroundTransparency = 1

	task.wait() -- biarkan AutomaticSize menghitung tinggi asli
	local targetHeight = Inner.AbsoluteSize.Y
	Toast.Size = UDim2.new(1, 0, 0, 0)
	Tween(Toast, MediumTween, { BackgroundTransparency = 0 })
	Tween(Toast, MediumTween, { Size = UDim2.new(1, 0, 0, targetHeight) })

	task.delay(config.Duration or 4, function()
		if Toast and Toast.Parent then
			Tween(Toast, MediumTween, { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 })
			task.delay(0.35, function()
				if Toast then Toast:Destroy() end
			end)
		end
	end)
end

--============================================================
-- OPENING CUTSCENE (fade in/out + logo + tombol Skip)
--============================================================
local function PlayCutscene(screenGui, windowName, callback)
	local Splash = New("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = EWEHUB.Theme.Background,
		BackgroundTransparency = 1,
		ZIndex = 100,
		Parent = screenGui,
	})

	-- "Logo" sederhana: lingkaran ber-accent + inisial, tanpa aset eksternal
	local LogoRing = New("Frame", {
		Size = UDim2.new(0, 64, 0, 64),
		Position = UDim2.new(0.5, -32, 0.5, -78),
		BackgroundColor3 = EWEHUB.Theme.Panel,
		BackgroundTransparency = 1,
		ZIndex = 101,
		Parent = Splash,
	}, { Corner(32), Stroke(EWEHUB.Theme.Accent, 2) })

	local LogoText = New("TextLabel", {
		Text = "E",
		Font = Enum.Font.GothamBlack,
		TextSize = 30,
		TextColor3 = EWEHUB.Theme.Accent,
		TextTransparency = 1,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 102,
		Parent = LogoRing,
	})

	local Title = New("TextLabel", {
		Text = windowName,
		Font = Enum.Font.GothamBold,
		TextSize = 26,
		TextColor3 = EWEHUB.Theme.Text,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 36),
		Position = UDim2.new(0, 0, 0.5, 4),
		TextTransparency = 1,
		ZIndex = 101,
		Parent = Splash,
	})

	local Subtitle = New("TextLabel", {
		Text = "by " .. EWEHUB.Author .. "  •  v" .. EWEHUB.Version,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = EWEHUB.Theme.SubText,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0.5, 40),
		TextTransparency = 1,
		ZIndex = 101,
		Parent = Splash,
	})

	local SkipBtn = New("TextButton", {
		Text = "Skip ›",
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = EWEHUB.Theme.SubText,
		BackgroundColor3 = EWEHUB.Theme.PanelLight,
		BackgroundTransparency = 1,
		TextTransparency = 1,
		Size = UDim2.new(0, 74, 0, 30),
		Position = UDim2.new(1, -94, 1, -50),
		AutoButtonColor = false,
		ZIndex = 101,
		Parent = Splash,
	}, { Corner(8) })

	local finished = false
	local function Finish()
		if finished then return end
		finished = true
		Tween(Splash, MediumTween, { BackgroundTransparency = 1 })
		Tween(LogoRing, FastTween, { BackgroundTransparency = 1 })
		Tween(LogoText, FastTween, { TextTransparency = 1 })
		Tween(Title, FastTween, { TextTransparency = 1 })
		Tween(Subtitle, FastTween, { TextTransparency = 1 })
		Tween(SkipBtn, FastTween, { TextTransparency = 1, BackgroundTransparency = 1 })
		task.delay(0.3, function()
			Splash:Destroy()
			if callback then callback() end
		end)
	end

	SkipBtn.MouseEnter:Connect(function()
		Tween(SkipBtn, FastTween, { BackgroundTransparency = 0, TextColor3 = EWEHUB.Theme.Text })
	end)
	SkipBtn.MouseLeave:Connect(function()
		Tween(SkipBtn, FastTween, { BackgroundTransparency = 1, TextColor3 = EWEHUB.Theme.SubText })
	end)
	SkipBtn.MouseButton1Click:Connect(Finish)

	-- Urutan animasi fade-in
	Tween(Splash, MediumTween, { BackgroundTransparency = 0 })
	Tween(LogoRing, MediumTween, { BackgroundTransparency = 0 })
	Tween(LogoText, MediumTween, { TextTransparency = 0 })
	task.delay(0.1, function()
		Tween(Title, MediumTween, { TextTransparency = 0 })
	end)
	task.delay(0.2, function()
		Tween(Subtitle, MediumTween, { TextTransparency = 0.1 })
		Tween(SkipBtn, MediumTween, { TextTransparency = 0.3 })
	end)

	-- Auto-selesai jika tidak di-skip
	task.delay(1.4, Finish)
end

--============================================================
-- DISCORD JOIN NOTIFICATION
--============================================================
local function SetupDiscordNotification(EWEHUBRef, screenGui, Theme, discordConfig)
	if not discordConfig or not discordConfig.Enabled then return end

	local invite = discordConfig.Invite or ""
	local interval = discordConfig.Interval or 300 -- default 5 menit
	local joined = false
	local active = true

	local function ShowPopup()
		if not active or joined then return end

		local Overlay = New("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 1,
			ZIndex = 80,
			Parent = screenGui,
		})

		local Popup = New("Frame", {
			Size = UDim2.new(0, 320, 0, 150),
			Position = UDim2.new(0.5, -160, 0.5, -75),
			BackgroundColor3 = Theme.Panel,
			ZIndex = 81,
			Parent = Overlay,
		}, { Corner(14), Stroke(Theme.Accent, 1) })

		New("TextLabel", {
			Text = "Gabung Discord Kami!",
			Font = Enum.Font.GothamBold,
			TextSize = 16,
			TextColor3 = Theme.Text,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 16, 0, 14),
			Size = UDim2.new(1, -32, 0, 22),
			ZIndex = 81,
			Parent = Popup,
		})

		New("TextLabel", {
			Text = "Dapatkan update, bantuan, dan info terbaru dengan bergabung ke server Discord kami.",
			Font = Enum.Font.Gotham,
			TextSize = 13,
			TextColor3 = Theme.SubText,
			TextWrapped = true,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 16, 0, 42),
			Size = UDim2.new(1, -32, 0, 50),
			ZIndex = 81,
			Parent = Popup,
		})

		local JoinBtn = New("TextButton", {
			Text = "Join Discord",
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextColor3 = Color3.fromRGB(10, 10, 10),
			BackgroundColor3 = Theme.Accent,
			AutoButtonColor = false,
			Position = UDim2.new(0, 16, 1, -46),
			Size = UDim2.new(1, -84, 0, 32),
			ZIndex = 81,
			Parent = Popup,
		}, { Corner(8) })

		local CloseBtn = New("TextButton", {
			Text = "✕",
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextColor3 = Theme.SubText,
			BackgroundColor3 = Theme.PanelLight,
			AutoButtonColor = false,
			Position = UDim2.new(1, -56, 1, -46),
			Size = UDim2.new(0, 40, 0, 32),
			ZIndex = 81,
			Parent = Popup,
		}, { Corner(8) })

		local function DestroyPopup()
			Tween(Popup, FastTween, { Position = UDim2.new(0.5, -160, 0.5, -60) })
			Tween(Overlay, MediumTween, { BackgroundTransparency = 1 })
			Tween(Popup, MediumTween, { BackgroundTransparency = 1 })
			task.delay(0.3, function() Overlay:Destroy() end)
		end

		JoinBtn.MouseButton1Click:Connect(function()
			if typeof(setclipboard) == "function" then
				pcall(setclipboard, invite)
				EWEHUBRef:Notify({
					Title = "Discord",
					Content = "Link Discord berhasil disalin ke clipboard!",
					Duration = 4,
				})
			else
				EWEHUBRef:Notify({
					Title = "Discord",
					Content = "Buka link berikut untuk join: " .. invite,
					Duration = 6,
				})
			end
			joined = true
			DestroyPopup()
		end)

		CloseBtn.MouseButton1Click:Connect(DestroyPopup)
		CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn, FastTween, { BackgroundColor3 = Theme.Danger }) end)
		CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn, FastTween, { BackgroundColor3 = Theme.PanelLight }) end)

		Popup.Position = UDim2.new(0.5, -160, 0.5, -60)
		Popup.BackgroundTransparency = 1
		Tween(Overlay, MediumTween, { BackgroundTransparency = 0.4 })
		Tween(Popup, SlowTween, { BackgroundTransparency = 0, Position = UDim2.new(0.5, -160, 0.5, -75) })
	end

	-- Tampilkan pertama kali beberapa detik setelah UI utama muncul
	task.delay(2, ShowPopup)

	-- Pengingat berkala setiap `interval` detik selama sesi berjalan
	task.spawn(function()
		while active and not joined do
			task.wait(interval)
			if active and not joined then
				ShowPopup()
			end
		end
	end)

	return {
		Disable = function() active = false end,
		Enable = function() active = true end,
		MarkJoined = function() joined = true end,
	}
end

--============================================================
-- CREATE WINDOW
--============================================================
function EWEHUB:CreateWindow(config)
	config = config or {}
	local windowName  = config.Name or "EWEHUB"
	local toggleKey   = config.ToggleKey or Enum.KeyCode.RightControl
	local Theme       = self.Theme
	local discordCfg  = config.Discord -- { Enabled, Invite, Interval }

	local guiName = "EWEHUB_" .. windowName
	-- Hapus semua sisa ScreenGui lama dgn nama sama, di PlayerGui MAUPUN
	-- di GuiParent (CoreGui/gethui) — mencegah "kotak hitam" nyangkut
	-- kalau script sempat dijalankan ulang di sesi yang sama.
	for _, root in ipairs({ PlayerGui, GuiParent }) do
		local existing = root:FindFirstChild(guiName)
		if existing then existing:Destroy() end
	end

	local ScreenGui = NewTopScreenGui(guiName, config.ForcePlayerGui and PlayerGui or nil)

	-- Layout HORIZONTAL: lebih lebar, jauh lebih pendek daripada versi lama,
	-- supaya tidak menutupi layar pemain secara vertikal.
	local windowSize = IsMobile()
		and UDim2.new(0, 400, 0, 250)
		or UDim2.new(0, 640, 0, 300)

	local Main = New("Frame", {
		Name = "Main",
		Size = windowSize,
		Position = UDim2.new(0.5, -windowSize.X.Offset / 2, 0.5, -windowSize.Y.Offset / 2),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Visible = false,
		Parent = ScreenGui,
	}, { Corner(16), Stroke(Theme.Stroke, 1) })

	-- TOP BAR
	local TopBar = New("Frame", {
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		Parent = Main,
	}, { Corner(16) })

	New("Frame", {
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 1, -16),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		Parent = TopBar,
	})

	local AccentDot = New("Frame", {
		Size = UDim2.new(0, 8, 0, 8),
		Position = UDim2.new(0, 16, 0.5, -4),
		BackgroundColor3 = Theme.Accent,
		Parent = TopBar,
	}, { Corner(4) })

	New("TextLabel", {
		Text = windowName,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextColor3 = Theme.Text,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 32, 0, 0),
		Size = UDim2.new(0.6, 0, 1, 0),
		Parent = TopBar,
	})

	task.spawn(function()
		while AccentDot.Parent do
			Tween(AccentDot, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundTransparency = 0.5 })
			task.wait(1)
			Tween(AccentDot, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundTransparency = 0 })
			task.wait(1)
		end
	end)

	local CloseBtn = New("TextButton", {
		Text = "✕",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Theme.SubText,
		BackgroundColor3 = Theme.PanelLight,
		Size = UDim2.new(0, 28, 0, 28),
		Position = UDim2.new(1, -37, 0.5, -14),
		AutoButtonColor = false,
		Parent = TopBar,
	}, { Corner(8) })

	local MinimizeBtn = New("TextButton", {
		Text = "—",
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = Theme.SubText,
		BackgroundColor3 = Theme.PanelLight,
		Size = UDim2.new(0, 28, 0, 28),
		Position = UDim2.new(1, -70, 0.5, -14),
		AutoButtonColor = false,
		Parent = TopBar,
	}, { Corner(8) })

	for _, btn in ipairs({ MinimizeBtn, CloseBtn }) do
		btn.MouseEnter:Connect(function() Tween(btn, FastTween, { BackgroundColor3 = Theme.AccentDark }) end)
		btn.MouseLeave:Connect(function() Tween(btn, FastTween, { BackgroundColor3 = Theme.PanelLight }) end)
	end

	local FloatIcon = New("TextButton", {
		Name = "FloatIcon",
		Text = "🚀",
		Font = Enum.Font.GothamBold,
		TextSize = 22,
		BackgroundColor3 = Theme.Panel,
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0, 20, 0.5, -25),
		Visible = false,
		AutoButtonColor = false,
		Parent = ScreenGui,
	}, { Corner(25), Stroke(Theme.Accent, 1.5) })

	local isMinimized = false
	local function Minimize()
		isMinimized = true
		Tween(Main, MediumTween, { Size = UDim2.new(Main.Size.X.Scale, Main.Size.X.Offset, 0, 0), BackgroundTransparency = 1 })
		task.delay(0.26, function()
			Main.Visible = false
			FloatIcon.Visible = true
			Tween(FloatIcon, SlowTween, { Size = UDim2.new(0, 50, 0, 50) })
		end)
	end

	local function Restore()
		isMinimized = false
		Tween(FloatIcon, FastTween, { Size = UDim2.new(0, 0, 0, 0) })
		task.delay(0.14, function()
			FloatIcon.Visible = false
			Main.Visible = true
			Main.Size = UDim2.new(windowSize.X.Scale, windowSize.X.Offset, 0, 0)
			Main.BackgroundTransparency = 1
			Tween(Main, SlowTween, { Size = windowSize, BackgroundTransparency = 0 })
		end)
	end

	MinimizeBtn.MouseButton1Click:Connect(Minimize)
	FloatIcon.MouseButton1Click:Connect(Restore)
	MakeDraggable(FloatIcon, FloatIcon)
	MakeDraggable(TopBar, Main)

	-- toggle show/hide dengan keybind
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == toggleKey then
			if isMinimized then Restore() else Minimize() end
		end
	end)

	-- Sidebar tab tetap di kiri (sudah horizontal terhadap konten),
	-- tapi dibuat ramping karena tinggi window sekarang lebih pendek.
	-- CATATAN FIX: ClipsDescendants pada `Main` cuma meng-clip ke bounding
	-- box PERSEGI, bukan ke bentuk melengkung UICorner. Makanya TabList &
	-- ContentArea (background polos, persegi) dulu bikin sudut bawah
	-- window kelihatan "kotak" lagi walau Main sudah rounded. Solusinya:
	-- kasih UICorner senilai radius Main ke keduanya juga — sudut atas
	-- toh ketutup TopBar, sudut bawah jadi ikut melengkung dengan benar.
	local TabListWidth = IsMobile() and 84 or 118
	local TabList = New("Frame", {
		Size = UDim2.new(0, TabListWidth, 1, -42),
		Position = UDim2.new(0, 0, 0, 42),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = Main,
	}, { Corner(16) })
	New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = TabList })
	Padding(10).Parent = TabList

	local ContentArea = New("Frame", {
		Size = UDim2.new(1, -TabListWidth, 1, -42),
		Position = UDim2.new(0, TabListWidth, 0, 42),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = Main,
	}, { Corner(16) })

	local Window = setmetatable({}, { __index = EWEHUB })
	Window.Tabs = {}
	Window._firstTab = nil
	Window.ScreenGui = ScreenGui
	Window.Main = Main
	Window.Discord = nil

	-- Daftar SEMUA halaman (tab buatan user + tab "Pengaturan" bawaan)
	-- supaya switching-nya konsisten & saling ekslusif satu sama lain.
	local AllPages = {}
	local function SwitchTo(entry)
		for _, t in ipairs(AllPages) do
			if t.Page ~= entry.Page then
				Tween(t.Button, FastTween, { BackgroundColor3 = Theme.PanelLight, TextColor3 = Theme.SubText })
				t.Page.Visible = false
			end
		end
		entry.Page.Position = UDim2.new(0, 6, 0, 10)
		entry.Page.Visible = true
		Tween(entry.Button, FastTween, { BackgroundColor3 = Theme.AccentDark, TextColor3 = Theme.Text })
		Tween(entry.Page, SoftTween, { Position = UDim2.new(0, 10, 0, 10) })
	end

	function Window:Destroy()
		if Window.Discord then Window.Discord.Disable() end
		ScreenGui:Destroy()
		EWEHUB.Windows[windowName] = nil
	end

	-- Kontrol manual untuk fitur Discord (bisa dipanggil setelah CreateWindow)
	function Window:SetDiscordNotification(enabled, invite, interval)
		if Window.Discord then Window.Discord.Disable() end
		if enabled then
			Window.Discord = SetupDiscordNotification(EWEHUB, ScreenGui, Theme, {
				Enabled = true,
				Invite = invite or (discordCfg and discordCfg.Invite) or "",
				Interval = interval or (discordCfg and discordCfg.Interval) or 300,
			})
		else
			Window.Discord = nil
		end
	end

	CloseBtn.MouseButton1Click:Connect(function()
		Window:Destroy()
	end)

	--------------------------------------------------------------
	function Window:CreateTab(tabConfig)
		tabConfig = type(tabConfig) == "string" and { Name = tabConfig } or tabConfig
		local tabName = tabConfig.Name or "Tab"
		local tabIcon = tabConfig.Icon -- contoh: "🏠", "⚙️", "👤" (emoji, tanpa asset eksternal)

		local TabButton = New("TextButton", {
			Text = tabIcon and (tabIcon .. "  " .. tabName) or tabName,
			Font = Enum.Font.GothamMedium,
			TextSize = 13,
			TextColor3 = Theme.SubText,
			BackgroundColor3 = Theme.PanelLight,
			Size = UDim2.new(1, 0, 0, 32),
			AutoButtonColor = false,
			Parent = TabList,
		}, { Corner(8) })

		local Page = New("ScrollingFrame", {
			Name = tabName .. "_Page",
			Size = UDim2.new(1, -20, 1, -20),
			Position = UDim2.new(0, 10, 0, 10),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.Accent,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
			Parent = ContentArea,
		})
		New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Page })

		local Tab = { Button = TabButton, Page = Page }
		table.insert(AllPages, Tab)

		-- Transisi tab: fade + sedikit slide, lebih halus daripada sekadar Visible toggle
		local function SelectTab()
			SwitchTo(Tab)
		end

		TabButton.MouseButton1Click:Connect(SelectTab)
		TabButton.MouseEnter:Connect(function()
			if not Page.Visible then Tween(TabButton, FastTween, { BackgroundColor3 = Theme.Stroke }) end
		end)
		TabButton.MouseLeave:Connect(function()
			if not Page.Visible then Tween(TabButton, FastTween, { BackgroundColor3 = Theme.PanelLight }) end
		end)

		if not Window._firstTab then
			Window._firstTab = true
			SelectTab()
		end

		function Tab:CreateLabel(text)
			return New("TextLabel", {
				Text = text, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Theme.SubText,
				TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 20), Parent = Page,
			})
		end

		function Tab:CreateButton(opt)
			opt = opt or {}
			local Btn = New("TextButton", {
				Text = opt.Name or "Button", Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = Theme.Text,
				BackgroundColor3 = Theme.Panel, Size = UDim2.new(1, 0, 0, 36), AutoButtonColor = false, Parent = Page,
			}, { Corner(10), Stroke() })

			Btn.MouseEnter:Connect(function() Tween(Btn, FastTween, { BackgroundColor3 = Theme.AccentDark }) end)
			Btn.MouseLeave:Connect(function() Tween(Btn, FastTween, { BackgroundColor3 = Theme.Panel }) end)
			Btn.MouseButton1Click:Connect(function()
				Tween(Btn, TweenInfo.new(0.08), { BackgroundColor3 = Theme.Accent })
				task.delay(0.1, function() Tween(Btn, FastTween, { BackgroundColor3 = Theme.Panel }) end)
				if opt.Callback then task.spawn(opt.Callback) end
			end)
			return Btn
		end

		function Tab:CreateToggle(opt)
			opt = opt or {}
			local state = opt.Default or false
			local flagName = opt.Flag or opt.Name

			local Holder = New("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Theme.Panel, Parent = Page }, { Corner(10), Stroke() })
			New("TextLabel", {
				Text = opt.Name or "Toggle", Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -60, 1, 0), Parent = Holder,
			})

			local Switch = New("Frame", {
				Size = UDim2.new(0, 40, 0, 20), Position = UDim2.new(1, -50, 0.5, -10),
				BackgroundColor3 = state and Theme.Accent or Theme.Stroke, Parent = Holder,
			}, { Corner(10) })

			local Knob = New("Frame", {
				Size = UDim2.new(0, 16, 0, 16),
				Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255), Parent = Switch,
			}, { Corner(8) })

			local ClickArea = New("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = Holder })

			local function SetState(newState, silent)
				state = newState
				Tween(Switch, FastTween, { BackgroundColor3 = state and Theme.Accent or Theme.Stroke })
				Tween(Knob, FastTween, { Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8) })
				if flagName then EWEHUB.Flags[flagName] = state end
				if opt.Callback and not silent then task.spawn(opt.Callback, state) end
			end

			ClickArea.MouseButton1Click:Connect(function() SetState(not state) end)

			if flagName then
				EWEHUB.Flags[flagName] = state
				EWEHUB.ConfigCallbacks[flagName] = function(v) SetState(v, true) end
			end

			return { Set = SetState, Get = function() return state end }
		end

		function Tab:CreateSlider(opt)
			opt = opt or {}
			local min, max = opt.Min or 0, opt.Max or 100
			local value = opt.Default or min
			local flagName = opt.Flag or opt.Name

			local Holder = New("Frame", { Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Theme.Panel, Parent = Page }, { Corner(10), Stroke() })
			New("TextLabel", {
				Text = opt.Name or "Slider", Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 6), Size = UDim2.new(1, -80, 0, 18), Parent = Holder,
			})
			local ValueLabel = New("TextLabel", {
				Text = tostring(value), Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Theme.Accent,
				BackgroundTransparency = 1, Position = UDim2.new(1, -60, 0, 6), Size = UDim2.new(0, 50, 0, 18),
				TextXAlignment = Enum.TextXAlignment.Right, Parent = Holder,
			})
			local Track = New("Frame", {
				Size = UDim2.new(1, -24, 0, 6), Position = UDim2.new(0, 12, 0, 32),
				BackgroundColor3 = Theme.Stroke, Parent = Holder,
			}, { Corner(3) })
			local Fill = New("Frame", {
				Size = UDim2.new((value - min) / (max - min), 0, 1, 0), BackgroundColor3 = Theme.Accent, Parent = Track,
			}, { Corner(3) })

			local dragging = false
			local function SetValue(newValue, silent)
				newValue = math.clamp(newValue, min, max)
				if opt.Round ~= false then newValue = math.floor(newValue + 0.5) end
				value = newValue
				local pct = (value - min) / (max - min)
				Tween(Fill, FastTween, { Size = UDim2.new(pct, 0, 1, 0) })
				ValueLabel.Text = tostring(value)
				if flagName then EWEHUB.Flags[flagName] = value end
				if opt.Callback and not silent then task.spawn(opt.Callback, value) end
			end

			local function UpdateFromInput(input)
				local relative = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
				SetValue(min + (max - min) * relative)
			end

			Track.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					UpdateFromInput(input)
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					UpdateFromInput(input)
				end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)

			if flagName then
				EWEHUB.Flags[flagName] = value
				EWEHUB.ConfigCallbacks[flagName] = function(v) SetValue(v, true) end
			end

			return { Set = SetValue, Get = function() return value end }
		end

		function Tab:CreateDropdown(opt)
			opt = opt or {}
			local options = opt.Options or {}
			local selected = opt.Default
			local flagName = opt.Flag or opt.Name
			local open = false

			local Holder = New("Frame", {
				Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Theme.Panel,
				ClipsDescendants = true, ZIndex = 5, Parent = Page,
			}, { Corner(10), Stroke() })

			local MainRow = New("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36), ZIndex = 5, Parent = Holder })

			New("TextLabel", {
				Text = opt.Name or "Dropdown", Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0.5, 0, 0, 36), ZIndex = 5, Parent = MainRow,
			})

			local SelectedLabel = New("TextLabel", {
				Text = selected or "Select...", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.SubText,
				TextXAlignment = Enum.TextXAlignment.Right, BackgroundTransparency = 1,
				Position = UDim2.new(0.4, 0, 0, 0), Size = UDim2.new(0.5, -30, 0, 36), ZIndex = 5, Parent = MainRow,
			})

			local Arrow = New("TextLabel", {
				Text = "▾", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.Accent,
				BackgroundTransparency = 1, Position = UDim2.new(1, -24, 0, 0), Size = UDim2.new(0, 20, 0, 36),
				ZIndex = 5, Parent = MainRow,
			})

			local ListFrame = New("Frame", {
				Position = UDim2.new(0, 0, 0, 36), Size = UDim2.new(1, 0, 0, 0),
				BackgroundColor3 = Theme.PanelLight, ZIndex = 5, Parent = Holder,
			})
			local ListLayout = New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = ListFrame })

			local optionButtons = {}
			local function RefreshOptions()
				for _, b in ipairs(optionButtons) do b:Destroy() end
				optionButtons = {}
				for _, optionName in ipairs(options) do
					local OptBtn = New("TextButton", {
						Text = optionName, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.Text,
						BackgroundColor3 = Theme.PanelLight, Size = UDim2.new(1, 0, 0, 28),
						AutoButtonColor = false, ZIndex = 5, Parent = ListFrame,
					})
					OptBtn.MouseEnter:Connect(function() Tween(OptBtn, FastTween, { BackgroundColor3 = Theme.AccentDark }) end)
					OptBtn.MouseLeave:Connect(function() Tween(OptBtn, FastTween, { BackgroundColor3 = Theme.PanelLight }) end)
					OptBtn.MouseButton1Click:Connect(function()
						selected = optionName
						SelectedLabel.Text = optionName
						if flagName then EWEHUB.Flags[flagName] = selected end
						if opt.Callback then task.spawn(opt.Callback, selected) end
						open = false
						Tween(Holder, FastTween, { Size = UDim2.new(1, 0, 0, 36) })
						Tween(Arrow, FastTween, { Rotation = 0 })
					end)
					table.insert(optionButtons, OptBtn)
				end
			end
			RefreshOptions()

			MainRow.MouseButton1Click:Connect(function()
				open = not open
				local targetHeight = open and (36 + ListLayout.AbsoluteContentSize.Y) or 36
				Tween(Holder, MediumTween, { Size = UDim2.new(1, 0, 0, targetHeight) })
				Tween(Arrow, FastTween, { Rotation = open and 180 or 0 })
			end)

			local api = {}
			function api.SetOptions(newOptions) options = newOptions RefreshOptions() end
			function api.Set(value, silent)
				selected = value
				SelectedLabel.Text = value or "Select..."
				if flagName then EWEHUB.Flags[flagName] = selected end
				if opt.Callback and not silent then task.spawn(opt.Callback, selected) end
			end
			function api.Get() return selected end

			if flagName then
				EWEHUB.Flags[flagName] = selected
				EWEHUB.ConfigCallbacks[flagName] = function(v) api.Set(v, true) end
			end

			return api
		end

		function Tab:CreateTextbox(opt)
			opt = opt or {}
			local flagName = opt.Flag or opt.Name

			local Holder = New("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Theme.Panel, Parent = Page }, { Corner(10), Stroke() })
			local Box = New("TextBox", {
				Text = opt.Default or "", PlaceholderText = opt.Placeholder or opt.Name or "Enter text...",
				Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Theme.Text, PlaceholderColor3 = Theme.SubText,
				BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -24, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = Holder,
			})

			Box.Focused:Connect(function() Tween(Holder, FastTween, { BackgroundColor3 = Theme.PanelLight }) end)
			Box.FocusLost:Connect(function(enterPressed)
				Tween(Holder, FastTween, { BackgroundColor3 = Theme.Panel })
				if flagName then EWEHUB.Flags[flagName] = Box.Text end
				if opt.Callback then task.spawn(opt.Callback, Box.Text, enterPressed) end
			end)

			if flagName then
				EWEHUB.Flags[flagName] = Box.Text
				EWEHUB.ConfigCallbacks[flagName] = function(v) Box.Text = v end
			end

			return { Set = function(v) Box.Text = v end, Get = function() return Box.Text end, Instance = Box }
		end

		Window.Tabs[tabName] = Tab
		return Tab
	end

	--------------------------------------------------------------
	-- TAB BAWAAN "⚙ Pengaturan" — SELALU ada, SELALU di paling ujung
	-- (bawah) daftar tab, dan TIDAK diekspos lewat API publik manapun
	-- sehingga tidak bisa dihapus/diubah oleh script yang memakai
	-- library ini. Isinya: profil pemain, HWID, & info library.
	--------------------------------------------------------------
	do
		local SettingsButton = New("TextButton", {
			Text = "⚙  Pengaturan",
			Font = Enum.Font.GothamMedium,
			TextSize = 13,
			TextColor3 = Theme.SubText,
			BackgroundColor3 = Theme.PanelLight,
			Size = UDim2.new(1, 0, 0, 32),
			AutoButtonColor = false,
			LayoutOrder = 9999, -- dijamin selalu paling bawah/ujung di TabList
			Parent = TabList,
		}, { Corner(8) })

		local SettingsPage = New("ScrollingFrame", {
			Name = "Settings_Page",
			Size = UDim2.new(1, -20, 1, -20),
			Position = UDim2.new(0, 10, 0, 10),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.Accent,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
			Parent = ContentArea,
		})
		New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = SettingsPage })

		SettingsButton.MouseEnter:Connect(function()
			if not SettingsPage.Visible then Tween(SettingsButton, FastTween, { BackgroundColor3 = Theme.Stroke }) end
		end)
		SettingsButton.MouseLeave:Connect(function()
			if not SettingsPage.Visible then Tween(SettingsButton, FastTween, { BackgroundColor3 = Theme.PanelLight }) end
		end)

		local SettingsEntry = { Button = SettingsButton, Page = SettingsPage }
		table.insert(AllPages, SettingsEntry)
		SettingsButton.MouseButton1Click:Connect(function() SwitchTo(SettingsEntry) end)

		-- Kartu profil: headshot + nama + UserId
		local ProfileCard = New("Frame", {
			Size = UDim2.new(1, 0, 0, 70),
			BackgroundColor3 = Theme.Panel,
			Parent = SettingsPage,
		}, { Corner(12), Stroke() })

		local Headshot = New("ImageLabel", {
			Size = UDim2.new(0, 54, 0, 54),
			Position = UDim2.new(0, 8, 0.5, -27),
			BackgroundColor3 = Theme.PanelLight,
			ScaleType = Enum.ScaleType.Crop,
			Image = "",
			Parent = ProfileCard,
		}, { Corner(27), Stroke(Theme.Accent, 1) })

		task.spawn(function()
			local ok, content = pcall(function()
				return Players:GetUserThumbnailAsync(
					LocalPlayer.UserId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size100x100
				)
			end)
			if ok and content then
				Headshot.Image = content
			end
		end)

		local displayName = LocalPlayer.DisplayName
		local nameText = (displayName ~= "" and displayName ~= LocalPlayer.Name)
			and (displayName .. "  (@" .. LocalPlayer.Name .. ")")
			or LocalPlayer.Name

		New("TextLabel", {
			Text = nameText,
			Font = Enum.Font.GothamBold,
			TextSize = 15,
			TextColor3 = Theme.Text,
			TextTruncate = Enum.TextTruncate.AtEnd,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 72, 0, 14),
			Size = UDim2.new(1, -84, 0, 20),
			Parent = ProfileCard,
		})

		New("TextLabel", {
			Text = "User ID: " .. tostring(LocalPlayer.UserId),
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = Theme.SubText,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 72, 0, 36),
			Size = UDim2.new(1, -84, 0, 16),
			Parent = ProfileCard,
		})

		-- HWID — dicoba dari beberapa nama fungsi umum yang disediakan executor
		local hwid = "Tidak tersedia"
		local hwidFnNames = { "gethwid", "get_hwid", "getHWID", "get_hardware_id" }
		local env = (typeof(getgenv) == "function") and getgenv() or _G
		for _, fnName in ipairs(hwidFnNames) do
			local fn = env[fnName]
			if typeof(fn) == "function" then
				local ok, result = pcall(fn)
				if ok and result and tostring(result) ~= "" then
					hwid = tostring(result)
					break
				end
			end
		end

		-- Nama executor (kalau tersedia)
		local executorName = "Tidak diketahui"
		if typeof(identifyexecutor) == "function" then
			local ok, name = pcall(identifyexecutor)
			if ok and name then executorName = tostring(name) end
		end

		local function InfoRow(label, value)
			local Row = New("Frame", {
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundColor3 = Theme.Panel,
				Parent = SettingsPage,
			}, { Corner(8), Stroke() })

			New("TextLabel", {
				Text = label,
				Font = Enum.Font.GothamMedium,
				TextSize = 12,
				TextColor3 = Theme.SubText,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.new(0, 10, 0, 0),
				Size = UDim2.new(0.4, 0, 1, 0),
				Parent = Row,
			})

			New("TextLabel", {
				Text = value,
				Font = Enum.Font.Gotham,
				TextSize = 12,
				TextColor3 = Theme.Text,
				TextTruncate = Enum.TextTruncate.AtEnd,
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Right,
				Position = UDim2.new(0.4, 0, 0, 0),
				Size = UDim2.new(0.6, -10, 1, 0),
				Parent = Row,
			})

			return Row
		end

		InfoRow("HWID", hwid)
		InfoRow("Executor", executorName)
		InfoRow("Library", "EWEHUB v" .. EWEHUB.Version .. " by " .. EWEHUB.Author)
	end

	self.Windows[windowName] = Window

	-- Tampilkan cutscene pembuka, lalu window utama, lalu (opsional) popup Discord
	Main.Visible = true
	Main.Size = UDim2.new(windowSize.X.Scale, windowSize.X.Offset, 0, 0)
	Main.BackgroundTransparency = 1

	PlayCutscene(ScreenGui, windowName, function()
		Tween(Main, SlowTween, { Size = windowSize, BackgroundTransparency = 0 })

		if discordCfg and discordCfg.Enabled then
			Window.Discord = SetupDiscordNotification(EWEHUB, ScreenGui, Theme, discordCfg)
		end
	end)

	return Window
end

return EWEHUB
