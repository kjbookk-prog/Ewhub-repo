--[[
	================================================================
	 EWEHUB
	 UI Library untuk Roblox — dibuat murni dengan Luau.
	 Dibuat oleh: Asep
	 Versi: 4.3.2

	 CATATAN PERUBAHAN v4.3.2:
	 1. Minimize sekarang bener-bener COMPACT — lebar window ikut
	    mengecil jadi pill kecil (~200px), bukan cuma tingginya doang
	    kayak sebelumnya (yang lebarnya masih selebar window penuh dan
	    jadi menghalangi pandangan). Tombol Close disembunyikan sementara
	    saat minimized buat hemat ruang, tombol Minimize otomatis geser
	    ke posisi tombol Close biar tetap rapi.

	 CATATAN PERUBAHAN v4.3.1:
	 1. Minimize diganti model "collapse-to-bar" (ala Rayfield) — window
	    mengecil jadi cuma nyisain top bar DI TEMPAT YANG SAMA, bukan lagi
	    jadi ikon bulat 🚀 terpisah yang melayang di layar. Ini menghindari
	    masalah "ikon gak nyambung sama tema script", dan lebih ringan di
	    hp low-end karena cuma resize 1 frame + toggle Visible (gak perlu
	    bikin/drag objek baru sama sekali).

	 CATATAN PERUBAHAN v4.2.0 (fitur baru):
	 1. RELIABILITAS: semua Callback sekarang dibungkus SafeCall (pcall) —
	    kalau ada 1 elemen yang error, elemen lain tetap jalan normal,
	    dan user dikasih toast notifikasi error alih-alih diam-diam gagal.
	 2. Proteksi GUI otomatis (protectgui/syn.protect_gui) kalau executor
	    mendukung, supaya UI tidak mudah dideteksi/diutak-atik dari luar.
	 3. Search bar di tiap tab — filter elemen berdasarkan nama secara live.
	 4. Watermark kecil yang tetap terlihat walau window di-minimize,
	    menampilkan nama hub, FPS, dan ping.
	 5. Panel "Konfigurasi" (Save/Load/Delete) langsung di tab Pengaturan,
	    memakai backend EWEHUB.SafeIO yang sudah ada.
	 6. Tab:CreateColorPicker — pilih warna (R/G/B) + hex, dengan preview.
	 7. Tab:CreateKeybind — user bisa bind tombol sendiri ke suatu aksi.
	 8. Tab:CreateDropdown sekarang mendukung `Multi = true` untuk pilih
	    lebih dari satu opsi sekaligus (checkbox-style).

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
local RunService       = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

--============================================================
-- EWEHUB CORE TABLE
--============================================================
local EWEHUB = {}
EWEHUB.__index = EWEHUB

EWEHUB.Version  = "4.3.2"
EWEHUB.Author   = "Asep"
EWEHUB.Windows  = {}
EWEHUB.Flags    = {}
EWEHUB.ConfigCallbacks = {}

-- Data custom di luar kontrol UI (Toggle/Slider/dst) yang mau ikut
-- disimpan/dimuat lewat tab "💾 Konfig" bawaan. Didaftarkan lewat
-- EWEHUB:RegisterConfigField(key, getFn, setFn) — lihat §RegisterConfigField.
EWEHUB.CustomConfigFields = {}

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

-- Menjalankan Callback user dengan aman (pcall). Kalau error, elemen lain
-- TETAP jalan normal — user cuma dikasih toast error, bukan seluruh UI
-- ikut diam-diam gagal seperti kasus bug GroupTransparency dulu.
local function SafeCall(fn, ...)
	if typeof(fn) ~= "function" then return end
	local args = table.pack(...)
	local ok, err = pcall(function()
		fn(table.unpack(args, 1, args.n))
	end)
	if not ok then
		warn("[EWEHUB] Callback error: " .. tostring(err))
		pcall(function()
			EWEHUB:Notify({
				Title = "Error",
				Content = "Ada elemen yang error: " .. tostring(err),
				Duration = 5,
			})
		end)
	end
end

-- Coba sembunyikan ScreenGui dari deteksi luar kalau executor mendukung
-- (protectgui/protect_gui/syn.protect_gui). Aman kalau tidak didukung —
-- cuma di-skip diam-diam, tidak error.
local function TryProtectGui(gui)
	local env = (typeof(getgenv) == "function") and getgenv() or _G
	for _, fnName in ipairs({ "protectgui", "protect_gui" }) do
		local fn = env[fnName]
		if typeof(fn) == "function" then
			pcall(fn, gui)
			return
		end
	end
	if typeof(syn) == "table" and typeof(syn.protect_gui) == "function" then
		pcall(syn.protect_gui, gui)
	end
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
	local gui = New("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = EWEHUB.DisplayOrder,
		Parent = parentOverride or GuiParent,
	})
	TryProtectGui(gui)
	return gui
end

--============================================================
-- HWID — dipakai bareng buat isolasi folder config & info di tab
-- Pengaturan. Dicoba dari beberapa nama fungsi umum yang disediakan
-- executor; fallback "unknown" kalau tidak ada satupun yang didukung.
--============================================================
local function GetHWID()
	local hwidFnNames = { "gethwid", "get_hwid", "getHWID", "get_hardware_id" }
	local env = (typeof(getgenv) == "function") and getgenv() or _G
	for _, fnName in ipairs(hwidFnNames) do
		local fn = env[fnName]
		if typeof(fn) == "function" then
			local ok, result = pcall(fn)
			if ok and result and tostring(result) ~= "" then
				-- Bersihkan karakter yang tidak aman buat nama folder
				return (tostring(result):gsub("[^%w%-]", "_"))
			end
		end
	end
	return "unknown"
end

local CurrentHWID = GetHWID()

--============================================================
-- PENYIMPANAN CONFIG (aman untuk executor maupun Studio)
-- Folder diisolasi PER-HWID: EWEHUB/configs/<hwid>/<nama>.json — jadi
-- config dari 1 perangkat tidak akan kecampur/kelihatan di perangkat lain.
--============================================================
local SafeIO = {}
local MemoryStore = {}
local HasFileSystem = (typeof(writefile) == "function") and (typeof(readfile) == "function")
local ConfigDir = "EWEHUB/configs/" .. CurrentHWID

if HasFileSystem and typeof(isfolder) == "function" and typeof(makefolder) == "function" then
	if not isfolder("EWEHUB") then makefolder("EWEHUB") end
	if not isfolder("EWEHUB/configs") then makefolder("EWEHUB/configs") end
	if not isfolder(ConfigDir) then makefolder(ConfigDir) end
end

function SafeIO.SaveConfig(name, data)
	local encoded = HttpService:JSONEncode(data)
	if HasFileSystem then
		local ok = pcall(writefile, ConfigDir .. "/" .. name .. ".json", encoded)
		if ok then return true end
	end
	MemoryStore[name] = encoded
	return true
end

function SafeIO.LoadConfig(name)
	if HasFileSystem then
		local ok, content = pcall(readfile, ConfigDir .. "/" .. name .. ".json")
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
			if typeof(isfile) == "function" and isfile(ConfigDir .. "/" .. name .. ".json") then
				delfile(ConfigDir .. "/" .. name .. ".json")
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
		local ok, files = pcall(listfiles, ConfigDir)
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
EWEHUB.HWID = CurrentHWID

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
-- RegisterConfigField — daftarkan data CUSTOM (di luar kontrol UI
-- yang punya Flag) supaya ikut ke-save/ke-load lewat tab "💾 Konfig"
-- bawaan. Berguna buat variabel biasa di script pemakai library
-- (mis. tabel `Settings` sendiri) yang bukan hasil dari Tab:Create...
--
-- Contoh:
--   EWEHUB:RegisterConfigField("LoopSpeed",
--       function() return MySettings.LoopSpeed end,      -- Get
--       function(v) MySettings.LoopSpeed = v end)        -- Set
--============================================================
function EWEHUB:RegisterConfigField(key, getFn, setFn)
	assert(type(key) == "string" and key ~= "", "RegisterConfigField: key harus string")
	assert(typeof(getFn) == "function", "RegisterConfigField: getFn harus function")
	assert(typeof(setFn) == "function", "RegisterConfigField: setFn harus function")
	self.CustomConfigFields[key] = { Get = getFn, Set = setFn }
end

function EWEHUB:UnregisterConfigField(key)
	self.CustomConfigFields[key] = nil
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
-- WATERMARK — pill kecil yang tetap kelihatan walau Main di-minimize,
-- nunjukin nama hub, FPS, dan ping. Draggable, ScreenGui terpisah
-- (jadi independen dari state minimize window utama).
--============================================================
local function SetupWatermark(windowName, Theme)
	local WMGui = NewTopScreenGui("EWEHUB_Watermark_" .. windowName)

	local WM = New("Frame", {
		Size = UDim2.new(0, 190, 0, 26),
		Position = UDim2.new(0, 10, 0, 10),
		BackgroundColor3 = Theme.Panel,
		Parent = WMGui,
	}, { Corner(8), Stroke() })

	New("Frame", {
		Size = UDim2.new(0, 6, 0, 6),
		Position = UDim2.new(0, 8, 0.5, -3),
		BackgroundColor3 = Theme.Accent,
		Parent = WM,
	}, { Corner(3) })

	local Label = New("TextLabel", {
		Text = windowName .. " | FPS: -- | Ping: --ms",
		Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = Theme.Text,
		BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 20, 0, 0), Size = UDim2.new(1, -26, 1, 0),
		Parent = WM,
	})

	MakeDraggable(WM, WM)

	local statsService
	pcall(function() statsService = game:GetService("Stats") end)

	local running = true
	task.spawn(function()
		local frameCount = 0
		local heartbeatConn = RunService.Heartbeat:Connect(function()
			frameCount = frameCount + 1
		end)

		while running and WM.Parent do
			task.wait(1)
			local fps = frameCount
			frameCount = 0

			local ping = "--"
			if statsService then
				local ok, val = pcall(function()
					return statsService.Network.ServerStatsItem["Data Ping"]:GetValue()
				end)
				if ok and val then ping = tostring(math.floor(val)) end
			end

			Label.Text = windowName .. " | FPS: " .. fps .. " | Ping: " .. ping .. "ms"
		end

		heartbeatConn:Disconnect()
	end)

	return {
		Destroy = function()
			running = false
			WMGui:Destroy()
		end,
		SetVisible = function(v) WMGui.Enabled = v end,
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

	-- Watermark AKTIF secara default. Matikan dgn Watermark = false,
	-- atau Watermark = { Enabled = false }.
	local watermarkEnabled = true
	if config.Watermark == false then
		watermarkEnabled = false
	elseif type(config.Watermark) == "table" and config.Watermark.Enabled == false then
		watermarkEnabled = false
	end

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
		TextTruncate = Enum.TextTruncate.AtEnd,
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

	-- Forward-declare, diisi pas TabList/ContentArea dibuat di bawah —
	-- dipakai Minimize/Restore buat sembunyiin isi window pas di-collapse.
	local TabList, ContentArea

	local TopBarHeight = 42
	local MinimizedWidth = IsMobile() and 170 or 200
	local isMinimized = false

	-- Model "collapse-to-bar" (ala Rayfield): window mengecil jadi pill
	-- KECIL & COMPACT (lebar ikut mengecil, bukan cuma tingginya) di
	-- TEMPAT YANG SAMA — bukan jadi ikon bulat terpisah (jadi gak ada
	-- masalah "logo gak sesuai tema script"), dan lebih ringan buat hp
	-- low-end karena cuma resize 1 frame + toggle Visible, gak perlu
	-- bikin/drag objek baru.
	local function Minimize()
		isMinimized = true
		MinimizeBtn.Text = "▾"
		Tween(CloseBtn, FastTween, { BackgroundTransparency = 1, TextTransparency = 1 })
		task.delay(0.12, function() if isMinimized then CloseBtn.Visible = false end end)
		Tween(MinimizeBtn, MediumTween, { Position = UDim2.new(1, -37, 0.5, -14) })
		Tween(Main, MediumTween, { Size = UDim2.new(0, MinimizedWidth, 0, TopBarHeight) })
		task.delay(0.2, function()
			if isMinimized then
				if TabList then TabList.Visible = false end
				if ContentArea then ContentArea.Visible = false end
			end
		end)
	end

	local function Restore()
		isMinimized = false
		MinimizeBtn.Text = "—"
		CloseBtn.Visible = true
		Tween(CloseBtn, FastTween, { BackgroundTransparency = 0, TextTransparency = 0 })
		Tween(MinimizeBtn, MediumTween, { Position = UDim2.new(1, -70, 0.5, -14) })
		if TabList then TabList.Visible = true end
		if ContentArea then ContentArea.Visible = true end
		Tween(Main, SlowTween, { Size = windowSize })
	end

	MinimizeBtn.MouseButton1Click:Connect(function()
		if isMinimized then Restore() else Minimize() end
	end)
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
	-- FIX: TabList sebelumnya cuma Frame biasa — kalau tab-nya banyak
	-- (lebih dari muat 1 layar), sisanya (termasuk tab "Pengaturan" yang
	-- dipin di paling bawah) jadi kepotong dan TIDAK BISA di-scroll sama
	-- sekali. Sekarang jadi ScrollingFrame supaya selalu bisa digulir.
	TabList = New("ScrollingFrame", {
		Size = UDim2.new(0, TabListWidth, 1, -42),
		Position = UDim2.new(0, 0, 0, 42),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Accent,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = Main,
	}, { Corner(16) })
	New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = TabList })
	Padding(10).Parent = TabList

	ContentArea = New("Frame", {
		Size = UDim2.new(1, -TabListWidth, 1, -42),
		Position = UDim2.new(0, TabListWidth, 0, 42),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = Main,
	}, { Corner(16) })

	-- Search bar: nempel di atas ContentArea, dipakai buat filter elemen
	-- di tab yang lagi aktif (semua Page digeser turun 34px buat kasih ruang).
	local SearchBoxHolder = New("Frame", {
		Size = UDim2.new(1, -20, 0, 26),
		Position = UDim2.new(0, 10, 0, 6),
		BackgroundColor3 = Theme.Panel,
		Parent = ContentArea,
	}, { Corner(8), Stroke() })

	New("TextLabel", {
		Text = "🔍",
		Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.SubText,
		BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.new(0, 4, 0, 0), Size = UDim2.new(0, 20, 1, 0),
		Parent = SearchBoxHolder,
	})

	local SearchBox = New("TextBox", {
		Text = "", PlaceholderText = "Cari elemen...",
		Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, PlaceholderColor3 = Theme.SubText,
		BackgroundTransparency = 1, ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 26, 0, 0), Size = UDim2.new(1, -34, 1, 0),
		Parent = SearchBoxHolder,
	})

	-- Filter elemen langsung di dalam sebuah Page berdasar teks query.
	local function ApplySearchFilter(page, query)
		query = (query or ""):lower()
		for _, child in ipairs(page:GetChildren()) do
			if child:IsA("GuiObject") then
				if query == "" then
					child.Visible = true
				else
					local text = ""
					if child:IsA("TextLabel") or child:IsA("TextButton") then
						text = child.Text
					else
						local lbl = child:FindFirstChildWhichIsA("TextLabel") or child:FindFirstChildWhichIsA("TextButton")
						if lbl then text = lbl.Text end
					end
					child.Visible = text:lower():find(query, 1, true) ~= nil
				end
			end
		end
	end

	local Window = setmetatable({}, { __index = EWEHUB })
	Window.Tabs = {}
	Window._firstTab = nil
	Window.ScreenGui = ScreenGui
	Window.Main = Main
	Window.Discord = nil
	Window.Watermark = nil

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
		entry.Page.Position = UDim2.new(0, 6, 0, 44)
		entry.Page.Visible = true
		Tween(entry.Button, FastTween, { BackgroundColor3 = Theme.AccentDark, TextColor3 = Theme.Text })
		Tween(entry.Page, SoftTween, { Position = UDim2.new(0, 10, 0, 44) })
		ApplySearchFilter(entry.Page, SearchBox.Text)
	end

	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		for _, entry in ipairs(AllPages) do
			if entry.Page.Visible then
				ApplySearchFilter(entry.Page, SearchBox.Text)
			end
		end
	end)

	function Window:Destroy()
		if Window.Discord then Window.Discord.Disable() end
		if Window.Watermark then Window.Watermark.Destroy() end
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
			Size = UDim2.new(1, -20, 1, -54),
			Position = UDim2.new(0, 10, 0, 44),
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
				if opt.Callback then task.spawn(SafeCall, opt.Callback) end
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
				if opt.Callback and not silent then task.spawn(SafeCall, opt.Callback, state) end
			end

			ClickArea.MouseButton1Click:Connect(function() SetState(not state) end)

			if flagName then
				EWEHUB.Flags[flagName] = state
				EWEHUB.ConfigCallbacks[flagName] = function(v) SetState(v, true) end
			end

			-- FIX: sinkronkan Callback dengan nilai Default sejak awal.
			-- Sebelumnya Default cuma tampil di UI tapi Callback baru
			-- kepanggil kalau user klik manual — bikin variabel eksternal
			-- (di script pemakai) nggak sinkron kalau Default = true.
			if opt.Callback then task.spawn(SafeCall, opt.Callback, state) end

			return { Set = SetState, Get = function() return state end }
		end

		function Tab:CreateSlider(opt)
			opt = opt or {}
			local min, max = opt.Min or 0, opt.Max or 100
			local roundValue = opt.Round ~= false -- default true: hasil selalu bilangan bulat (1, 2, 3, dst)
			local value = opt.Default or min
			if roundValue then value = math.floor(value + 0.5) end
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
				if roundValue then newValue = math.floor(newValue + 0.5) end
				value = newValue
				local pct = (value - min) / (max - min)
				Tween(Fill, FastTween, { Size = UDim2.new(pct, 0, 1, 0) })
				ValueLabel.Text = tostring(value)
				if flagName then EWEHUB.Flags[flagName] = value end
				if opt.Callback and not silent then task.spawn(SafeCall, opt.Callback, value) end
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

			if opt.Callback then task.spawn(SafeCall, opt.Callback, value) end

			return { Set = SetValue, Get = function() return value end }
		end

		function Tab:CreateDropdown(opt)
			opt = opt or {}
			local options = opt.Options or {}
			local isMulti = opt.Multi == true
			local flagName = opt.Flag or opt.Name
			local open = false

			-- Untuk single-select: selected = string | nil
			-- Untuk multi-select:  selected = { [optionName] = true, ... } (set)
			local selected
			if isMulti then
				selected = {}
				if type(opt.Default) == "table" then
					for _, v in ipairs(opt.Default) do selected[v] = true end
				elseif type(opt.Default) == "string" then
					selected[opt.Default] = true
				end
			else
				selected = opt.Default
			end

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
				Text = "Select...", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.SubText,
				TextXAlignment = Enum.TextXAlignment.Right, BackgroundTransparency = 1,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Position = UDim2.new(0.35, 0, 0, 0), Size = UDim2.new(0.55, -30, 0, 36), ZIndex = 5, Parent = MainRow,
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

			local api = {}

			-- Update teks label kanan ("Select...", "Opsi A", atau "3 dipilih")
			local function RefreshSelectedLabel()
				if isMulti then
					local names, count = {}, 0
					for name in pairs(selected) do
						count = count + 1
						if #names < 2 then table.insert(names, name) end
					end
					if count == 0 then
						SelectedLabel.Text = "Select..."
					elseif count <= 2 then
						SelectedLabel.Text = table.concat(names, ", ")
					else
						SelectedLabel.Text = count .. " dipilih"
					end
				else
					SelectedLabel.Text = selected or "Select..."
				end
			end

			local optionButtons = {}
			local function RefreshOptions()
				for _, b in ipairs(optionButtons) do b:Destroy() end
				optionButtons = {}
				for _, optionName in ipairs(options) do
					local isChecked = isMulti and selected[optionName] == true
					local OptBtn = New("TextButton", {
						Text = (isMulti and (isChecked and "☑  " or "☐  ") or "") .. optionName,
						Font = Enum.Font.Gotham, TextSize = 13,
						TextColor3 = (not isMulti and selected == optionName) and Theme.Accent or Theme.Text,
						TextXAlignment = Enum.TextXAlignment.Left,
						BackgroundColor3 = Theme.PanelLight, Size = UDim2.new(1, 0, 0, 28),
						AutoButtonColor = false, ZIndex = 5, Parent = ListFrame,
					}, { Padding(0, 0, 0, 10) })
					OptBtn.MouseEnter:Connect(function() Tween(OptBtn, FastTween, { BackgroundColor3 = Theme.AccentDark }) end)
					OptBtn.MouseLeave:Connect(function() Tween(OptBtn, FastTween, { BackgroundColor3 = Theme.PanelLight }) end)

					OptBtn.MouseButton1Click:Connect(function()
						if isMulti then
							selected[optionName] = not selected[optionName] or nil
							RefreshSelectedLabel()
							RefreshOptions() -- redraw centang, dropdown TETAP terbuka
							if flagName then
								local arr = {}
								for name in pairs(selected) do table.insert(arr, name) end
								EWEHUB.Flags[flagName] = arr
							end
							if opt.Callback then
								local arr = {}
								for name in pairs(selected) do table.insert(arr, name) end
								task.spawn(SafeCall, opt.Callback, arr)
							end
						else
							selected = optionName
							RefreshSelectedLabel()
							if flagName then EWEHUB.Flags[flagName] = selected end
							if opt.Callback then task.spawn(SafeCall, opt.Callback, selected) end
							open = false
							Tween(Holder, FastTween, { Size = UDim2.new(1, 0, 0, 36) })
							Tween(Arrow, FastTween, { Rotation = 0 })
						end
					end)
					table.insert(optionButtons, OptBtn)
				end
			end
			RefreshOptions()
			RefreshSelectedLabel()

			local function UpdateHolderHeight()
				if open then
					Tween(Holder, FastTween, { Size = UDim2.new(1, 0, 0, 36 + ListLayout.AbsoluteContentSize.Y) })
				end
			end
			-- FIX: AbsoluteContentSize kadang belum ke-update kalau dibaca
			-- LANGSUNG saat itu juga (Roblox baru hitung ulang di frame
			-- berikutnya) — bikin dropdown kelihatan "macet" (kebuka tapi
			-- tinggi 0 / gak keliatan isinya). Sekarang dengar perubahan
			-- ukurannya secara live, dan tunda 1 frame pas baru dibuka.
			ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateHolderHeight)

			MainRow.MouseButton1Click:Connect(function()
				open = not open
				Tween(Arrow, FastTween, { Rotation = open and 180 or 0 })
				if open then
					Tween(Holder, MediumTween, { Size = UDim2.new(1, 0, 0, 36 + ListLayout.AbsoluteContentSize.Y) })
					task.defer(UpdateHolderHeight)
				else
					Tween(Holder, MediumTween, { Size = UDim2.new(1, 0, 0, 36) })
				end
			end)

			function api.SetOptions(newOptions) options = newOptions RefreshOptions() end

			function api.Set(value, silent)
				if isMulti then
					selected = {}
					if type(value) == "table" then
						for _, v in ipairs(value) do selected[v] = true end
					elseif type(value) == "string" then
						selected[value] = true
					end
					RefreshOptions()
				else
					selected = value
				end
				RefreshSelectedLabel()
				if flagName then
					if isMulti then
						local arr = {}
						for name in pairs(selected) do table.insert(arr, name) end
						EWEHUB.Flags[flagName] = arr
					else
						EWEHUB.Flags[flagName] = selected
					end
				end
				if opt.Callback and not silent then
					if isMulti then
						local arr = {}
						for name in pairs(selected) do table.insert(arr, name) end
						task.spawn(SafeCall, opt.Callback, arr)
					else
						task.spawn(SafeCall, opt.Callback, selected)
					end
				end
			end

			function api.Get()
				if isMulti then
					local arr = {}
					for name in pairs(selected) do table.insert(arr, name) end
					return arr
				end
				return selected
			end

			if flagName then
				EWEHUB.Flags[flagName] = api.Get()
				EWEHUB.ConfigCallbacks[flagName] = function(v) api.Set(v, true) end
			end

			-- FIX UTAMA: sebelumnya Default cuma tampil di label dropdown,
			-- tapi Callback baru kepanggil kalau user klik opsi secara
			-- manual. Akibatnya variabel eksternal (mis. SelectedDropdownConfig
			-- di script pemakai) tetap kosong walau dropdown KELIHATAN sudah
			-- ada pilihan — bikin tombol "Muat" dkk seperti macet/gak respons.
			if opt.Callback then task.spawn(SafeCall, opt.Callback, api.Get()) end

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
				if opt.Callback then task.spawn(SafeCall, opt.Callback, Box.Text, enterPressed) end
			end)

			if flagName then
				EWEHUB.Flags[flagName] = Box.Text
				EWEHUB.ConfigCallbacks[flagName] = function(v) Box.Text = v end
			end

			if opt.Callback then task.spawn(SafeCall, opt.Callback, Box.Text, false) end

			return { Set = function(v) Box.Text = v end, Get = function() return Box.Text end, Instance = Box }
		end

		function Tab:CreateColorPicker(opt)
			opt = opt or {}
			local flagName = opt.Flag or opt.Name
			local color = opt.Default or Color3.fromRGB(255, 255, 255)
			local open = false

			local Holder = New("Frame", {
				Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Theme.Panel,
				ClipsDescendants = true, Parent = Page,
			}, { Corner(10), Stroke() })

			New("TextLabel", {
				Text = opt.Name or "Warna", Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -60, 0, 36), Parent = Holder,
			})

			local SwatchBtn = New("TextButton", {
				Text = "", BackgroundColor3 = color, AutoButtonColor = false,
				Size = UDim2.new(0, 28, 0, 20), Position = UDim2.new(1, -40, 0, 8), Parent = Holder,
			}, { Corner(6), Stroke() })

			local Panel = New("Frame", {
				Position = UDim2.new(0, 10, 0, 40), Size = UDim2.new(1, -20, 0, 90),
				BackgroundTransparency = 1, Parent = Holder,
			})
			New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Panel })

			local r = math.floor(color.R * 255)
			local g = math.floor(color.G * 255)
			local b = math.floor(color.B * 255)

			local function ApplyColor(fireCallback)
				color = Color3.fromRGB(r, g, b)
				SwatchBtn.BackgroundColor3 = color
				if flagName then EWEHUB.Flags[flagName] = color end
				if fireCallback and opt.Callback then task.spawn(SafeCall, opt.Callback, color) end
			end

			local function BuildChannel(label, initialValue, onDrag)
				local Row = New("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Parent = Panel })
				New("TextLabel", {
					Text = label, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Theme.SubText,
					BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
					Size = UDim2.new(0, 14, 1, 0), Parent = Row,
				})
				local Track = New("Frame", {
					Size = UDim2.new(1, -56, 0, 6), Position = UDim2.new(0, 18, 0.5, -3),
					BackgroundColor3 = Theme.Stroke, Parent = Row,
				}, { Corner(3) })
				local Fill = New("Frame", {
					Size = UDim2.new(initialValue / 255, 0, 1, 0), BackgroundColor3 = Theme.Accent, Parent = Track,
				}, { Corner(3) })
				local ValueLabel = New("TextLabel", {
					Text = tostring(initialValue), Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Text,
					BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Right,
					Position = UDim2.new(1, -32, 0, 0), Size = UDim2.new(0, 32, 1, 0), Parent = Row,
				})

				local function SetValue(v)
					v = math.clamp(math.floor(v + 0.5), 0, 255)
					Tween(Fill, FastTween, { Size = UDim2.new(v / 255, 0, 1, 0) })
					ValueLabel.Text = tostring(v)
					return v
				end

				local dragging = false
				local function UpdateFromInput(input)
					local relative = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
					local v = SetValue(relative * 255)
					onDrag(v)
					ApplyColor(true)
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

				return SetValue
			end

			local SetR = BuildChannel("R", r, function(v) r = v end)
			local SetG = BuildChannel("G", g, function(v) g = v end)
			local SetB = BuildChannel("B", b, function(v) b = v end)

			SwatchBtn.MouseButton1Click:Connect(function()
				open = not open
				Tween(Holder, MediumTween, { Size = UDim2.new(1, 0, 0, open and 134 or 36) })
			end)

			local api = {}
			function api.Set(newColor, silent)
				color = newColor
				r = math.floor(color.R * 255)
				g = math.floor(color.G * 255)
				b = math.floor(color.B * 255)
				SetR(r)
				SetG(g)
				SetB(b)
				SwatchBtn.BackgroundColor3 = color
				if flagName then EWEHUB.Flags[flagName] = color end
				if opt.Callback and not silent then task.spawn(SafeCall, opt.Callback, color) end
			end
			function api.Get() return color end

			if flagName then
				EWEHUB.Flags[flagName] = color
				EWEHUB.ConfigCallbacks[flagName] = function(v) api.Set(v, true) end
			end

			if opt.Callback then task.spawn(SafeCall, opt.Callback, color) end

			return api
		end

		function Tab:CreateKeybind(opt)
			opt = opt or {}
			local flagName = opt.Flag or opt.Name
			local currentKey = opt.Default -- Enum.KeyCode | nil
			local listening = false

			local Holder = New("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Theme.Panel, Parent = Page }, { Corner(10), Stroke() })
			New("TextLabel", {
				Text = opt.Name or "Keybind", Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -100, 1, 0), Parent = Holder,
			})

			local KeyBtn = New("TextButton", {
				Text = currentKey and currentKey.Name or "...",
				Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Theme.Accent,
				BackgroundColor3 = Theme.PanelLight, AutoButtonColor = false,
				Size = UDim2.new(0, 80, 0, 26), Position = UDim2.new(1, -90, 0.5, -13),
				Parent = Holder,
			}, { Corner(6), Stroke() })

			KeyBtn.MouseButton1Click:Connect(function()
				if listening then return end
				listening = true
				KeyBtn.Text = "..."
				Tween(KeyBtn, FastTween, { BackgroundColor3 = Theme.AccentDark })
			end)

			UserInputService.InputBegan:Connect(function(input, processed)
				if listening and input.UserInputType == Enum.UserInputType.Keyboard then
					listening = false
					currentKey = input.KeyCode
					KeyBtn.Text = currentKey.Name
					Tween(KeyBtn, FastTween, { BackgroundColor3 = Theme.PanelLight })
					if flagName then EWEHUB.Flags[flagName] = currentKey end
					if opt.Callback then task.spawn(SafeCall, opt.Callback, currentKey, false) end
					return
				end
				if not processed and not listening and currentKey and input.KeyCode == currentKey then
					if opt.Callback then task.spawn(SafeCall, opt.Callback, currentKey, true) end
				end
			end)

			local api = {}
			function api.Set(key, silent)
				currentKey = key
				KeyBtn.Text = key and key.Name or "..."
				if flagName then EWEHUB.Flags[flagName] = currentKey end
				if opt.Callback and not silent then task.spawn(SafeCall, opt.Callback, currentKey, false) end
			end
			function api.Get() return currentKey end

			if flagName then
				EWEHUB.Flags[flagName] = currentKey
				EWEHUB.ConfigCallbacks[flagName] = function(v) api.Set(v, true) end
			end

			if opt.Callback and currentKey then task.spawn(SafeCall, opt.Callback, currentKey, false) end

			return api
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
			Size = UDim2.new(1, -20, 1, -54),
			Position = UDim2.new(0, 10, 0, 44),
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

		-- HWID dipakai dari CurrentHWID (dihitung sekali di level module,
		-- sama persis dengan yang dipakai buat isolasi folder config).
		local hwid = CurrentHWID ~= "unknown" and CurrentHWID or "Tidak tersedia"

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

	--------------------------------------------------------------
	-- TAB BAWAAN "💾 Konfig" — pinned, terpisah dari Pengaturan.
	-- Simpan/Muat/Hapus config, otomatis mencakup:
	--   1. Semua kontrol yang punya Flag (EWEHUB.Flags)
	--   2. Semua data custom yang didaftarkan lewat
	--      EWEHUB:RegisterConfigField(key, getFn, setFn)
	-- Disimpan di folder YANG DIISOLASI PER-HWID (lihat CurrentHWID di
	-- atas) — config dari 1 device tidak akan kecampur ke device lain.
	--------------------------------------------------------------
	do
		local function BuildConfigSnapshot()
			local snapshot = {}
			for k, v in pairs(EWEHUB.Flags) do
				snapshot[k] = v
			end
			for key, field in pairs(EWEHUB.CustomConfigFields) do
				local ok, value = pcall(field.Get)
				if ok then snapshot[key] = value end
			end
			return snapshot
		end

		local function ApplyConfigSnapshot(data)
			for key, value in pairs(data) do
				if EWEHUB.CustomConfigFields[key] then
					SafeCall(EWEHUB.CustomConfigFields[key].Set, value)
				elseif EWEHUB.ConfigCallbacks[key] then
					SafeCall(EWEHUB.ConfigCallbacks[key], value)
				else
					EWEHUB.Flags[key] = value
				end
			end
		end

		local KonfigButton = New("TextButton", {
			Text = "💾  Konfig",
			Font = Enum.Font.GothamMedium,
			TextSize = 13,
			TextColor3 = Theme.SubText,
			BackgroundColor3 = Theme.PanelLight,
			Size = UDim2.new(1, 0, 0, 32),
			AutoButtonColor = false,
			LayoutOrder = 9998, -- pinned, tepat sebelum "Pengaturan" (9999)
			Parent = TabList,
		}, { Corner(8) })

		local KonfigPage = New("ScrollingFrame", {
			Name = "Konfig_Page",
			Size = UDim2.new(1, -20, 1, -54),
			Position = UDim2.new(0, 10, 0, 44),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.Accent,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
			Parent = ContentArea,
		})
		New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = KonfigPage })

		KonfigButton.MouseEnter:Connect(function()
			if not KonfigPage.Visible then Tween(KonfigButton, FastTween, { BackgroundColor3 = Theme.Stroke }) end
		end)
		KonfigButton.MouseLeave:Connect(function()
			if not KonfigPage.Visible then Tween(KonfigButton, FastTween, { BackgroundColor3 = Theme.PanelLight }) end
		end)

		local KonfigEntry = { Button = KonfigButton, Page = KonfigPage }
		table.insert(AllPages, KonfigEntry)
		KonfigButton.MouseButton1Click:Connect(function() SwitchTo(KonfigEntry) end)

		New("TextLabel", {
			Text = "Config diisolasi per perangkat — HWID: " .. (CurrentHWID ~= "unknown" and CurrentHWID or "tidak tersedia"),
			Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.SubText,
			TextWrapped = true, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, 28), Parent = KonfigPage,
		})

		local ConfigNameHolder = New("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Theme.Panel, Parent = KonfigPage }, { Corner(10), Stroke() })
		local ConfigNameInput = New("TextBox", {
			Text = "", PlaceholderText = "Nama config baru...",
			Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.Text, PlaceholderColor3 = Theme.SubText,
			BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -24, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = ConfigNameHolder,
		})

		-- Dropdown mini buat pilih config yang sudah tersimpan
		local ConfigDropdownHolder = New("Frame", {
			Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Theme.Panel,
			ClipsDescendants = true, ZIndex = 5, Parent = KonfigPage,
		}, { Corner(10), Stroke() })

		local ConfigMainRow = New("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36), ZIndex = 5, Parent = ConfigDropdownHolder })

		New("TextLabel", {
			Text = "Config Tersimpan", Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0.55, 0, 0, 36), ZIndex = 5, Parent = ConfigMainRow,
		})

		local ConfigSelectedLabel = New("TextLabel", {
			Text = "Pilih...", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.SubText,
			TextXAlignment = Enum.TextXAlignment.Right, BackgroundTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd,
			Position = UDim2.new(0.4, 0, 0, 0), Size = UDim2.new(0.5, -30, 0, 36), ZIndex = 5, Parent = ConfigMainRow,
		})

		local ConfigArrow = New("TextLabel", {
			Text = "▾", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.Accent,
			BackgroundTransparency = 1, Position = UDim2.new(1, -24, 0, 0), Size = UDim2.new(0, 20, 0, 36),
			ZIndex = 5, Parent = ConfigMainRow,
		})

		local ConfigListFrame = New("Frame", {
			Position = UDim2.new(0, 0, 0, 36), Size = UDim2.new(1, 0, 0, 0),
			BackgroundColor3 = Theme.PanelLight, ZIndex = 5, Parent = ConfigDropdownHolder,
		})
		local ConfigListLayout = New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = ConfigListFrame })

		local selectedConfig = nil
		local configOpen = false
		local configButtons = {}

		local function RefreshConfigList()
			for _, b in ipairs(configButtons) do b:Destroy() end
			configButtons = {}
			local ok, list = pcall(EWEHUB.SafeIO.ListConfigs)
			if not ok or not list then list = {} end
			for _, cfgName in ipairs(list) do
				local Btn = New("TextButton", {
					Text = cfgName, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text,
					BackgroundColor3 = Theme.PanelLight, Size = UDim2.new(1, 0, 0, 26),
					AutoButtonColor = false, ZIndex = 5, Parent = ConfigListFrame,
				})
				Btn.MouseEnter:Connect(function() Tween(Btn, FastTween, { BackgroundColor3 = Theme.AccentDark }) end)
				Btn.MouseLeave:Connect(function() Tween(Btn, FastTween, { BackgroundColor3 = Theme.PanelLight }) end)
				Btn.MouseButton1Click:Connect(function()
					selectedConfig = cfgName
					ConfigSelectedLabel.Text = cfgName
					configOpen = false
					Tween(ConfigDropdownHolder, FastTween, { Size = UDim2.new(1, 0, 0, 36) })
					Tween(ConfigArrow, FastTween, { Rotation = 0 })
				end)
				table.insert(configButtons, Btn)
			end
		end
		RefreshConfigList()

		ConfigMainRow.MouseButton1Click:Connect(function()
			configOpen = not configOpen
			local targetHeight = configOpen and (36 + ConfigListLayout.AbsoluteContentSize.Y) or 36
			Tween(ConfigDropdownHolder, MediumTween, { Size = UDim2.new(1, 0, 0, targetHeight) })
			Tween(ConfigArrow, FastTween, { Rotation = configOpen and 180 or 0 })
		end)

		-- Tombol Simpan / Muat / Hapus
		local ButtonRow = New("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Parent = KonfigPage })
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = ButtonRow,
		})

		local function MiniButton(text, bgColor)
			local btnColor = bgColor or Theme.Panel
			local Btn = New("TextButton", {
				Text = text, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.Text,
				BackgroundColor3 = btnColor, Size = UDim2.new(0.333, -4, 1, 0),
				AutoButtonColor = false, Parent = ButtonRow,
			}, { Corner(8), Stroke() })
			Btn.MouseEnter:Connect(function() Tween(Btn, FastTween, { BackgroundColor3 = Theme.AccentDark }) end)
			Btn.MouseLeave:Connect(function() Tween(Btn, FastTween, { BackgroundColor3 = btnColor }) end)
			return Btn
		end

		local SaveBtn = MiniButton("💾 Simpan")
		local LoadBtn = MiniButton("📂 Muat")
		local DeleteBtn = MiniButton("🗑 Hapus", Theme.Danger)

		SaveBtn.MouseButton1Click:Connect(function()
			local name = ConfigNameInput.Text ~= "" and ConfigNameInput.Text or selectedConfig
			if not name or name == "" then
				EWEHUB:Notify({ Title = "Config", Content = "Isi nama config dulu.", Duration = 3 })
				return
			end
			local ok = EWEHUB.SafeIO.SaveConfig(name, BuildConfigSnapshot())
			if ok then
				EWEHUB:Notify({ Title = "Config", Content = "Config '" .. name .. "' tersimpan.", Duration = 3 })
				ConfigNameInput.Text = ""
				RefreshConfigList()
			end
		end)

		LoadBtn.MouseButton1Click:Connect(function()
			if not selectedConfig then
				EWEHUB:Notify({ Title = "Config", Content = "Pilih config dulu dari dropdown.", Duration = 3 })
				return
			end
			local data = EWEHUB.SafeIO.LoadConfig(selectedConfig)
			if not data then
				EWEHUB:Notify({ Title = "Config", Content = "Gagal memuat config.", Duration = 3 })
				return
			end
			ApplyConfigSnapshot(data)
			EWEHUB:Notify({ Title = "Config", Content = "Config '" .. selectedConfig .. "' dimuat.", Duration = 3 })
		end)

		DeleteBtn.MouseButton1Click:Connect(function()
			if not selectedConfig then
				EWEHUB:Notify({ Title = "Config", Content = "Pilih config dulu dari dropdown.", Duration = 3 })
				return
			end
			EWEHUB.SafeIO.DeleteConfig(selectedConfig)
			EWEHUB:Notify({ Title = "Config", Content = "Config '" .. selectedConfig .. "' dihapus.", Duration = 3 })
			selectedConfig = nil
			ConfigSelectedLabel.Text = "Pilih..."
			RefreshConfigList()
		end)
	end

	self.Windows[windowName] = Window

	if watermarkEnabled then
		Window.Watermark = SetupWatermark(windowName, Theme)
	end

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
