--[[
	================================================================
	 EWEHUB BOOTSTRAP LOADER
	 ----------------------------------------------------------------
	 Script BERDIRI SENDIRI (standalone). TIDAK memuat/menyentuh
	 library EWEHUB (Uipler.lua) sama sekali sampai baris PALING
	 AKHIR proses ini. Semua UI, notifikasi, logger, cache, dan
	 sistem retry di file ini adalah IMPLEMENTASI SENDIRI — bukan
	 pinjam dari library.

	 HUBUNGAN DENGAN LIBRARY: satu arah, Loader -> Library.
	   - Loader TIDAK TAHU apa-apa soal isi/API library.
	   - Library TIDAK TAHU apa-apa soal loader ini (dan tidak perlu tahu).
	   - Ganti Library-nya kapan saja tanpa perlu ubah file ini.
	   - Ganti Loader ini kapan saja tanpa perlu ubah library.

	 STRUKTUR FILE (top-to-bottom):
	   1.  Config             - pengaturan yang boleh diubah pemakai
	   2.  Constants           - tema visual & nilai tetap milik LOADER
	                              (independen, bukan ambil dari library)
	   3.  Services             - referensi game:GetService(...) terpusat
	   4.  Utils                - fungsi bantu generik, tanpa state
	   5.  Logger                - output Output/Console berjenjang level
	   6.  UIPrimitives          - helper Instance.new tingkat rendah,
	                              dipakai bareng oleh Notification/LoaderUI/
	                              UnsupportedScreen (biar gak duplikat kode)
	   7.  Notification          - toast, implementasi sendiri dari nol
	   8.  LoaderAnimator        - resep TweenService yang reusable
	   9.  LoaderUI               - kartu loading kecil (splash sementara)
	  10.  LoaderController       - API publik: ShowLoading/UpdateStatus/
	                              ShowSuccess/ShowUnsupported/Hide
	  11.  UnsupportedScreen      - halaman detail game belum didukung
	  12.  GameRegistry           - allow-list game (opsional, lihat Config)
	  13.  GameDetector           - baca game.GameId / game.PlaceId
	  14.  RetryPolicy            - aturan retry & timeout jaringan
	  15.  Network                - HttpGet + retry + timeout
	  16.  CacheStore             - cache lokal (writefile/readfile sendiri,
	                              TIDAK pakai SafeIO milik library)
	  17.  GameDatabase           - DATA allow-list (tambah game di sini)
	  18.  Main                   - satukan semua jadi 1 alur eksekusi
	================================================================
]]

--======================================================================
-- 1) CONFIG
--======================================================================
local Config = {
	VERSION                = "1.0.0",
	HUB_NAME               = "Lynxx",

	-- Entry point library — SATU-SATUNYA titik kontak loader ke library.
	-- Loader cuma download & eksekusi ini di akhir, tidak tahu isinya.
	MAIN_SCRIPT_URL        = "https://raw.githubusercontent.com/kjbookk-prog/Ewhub-repo/refs/heads/main/Uipler.lua",

	DEBUG_MODE             = false,
	AUTO_RETRY             = true,
	MAX_RETRY              = 3,
	REQUEST_TIMEOUT        = 10,    -- detik (soft-timeout, lihat §15)
	CACHE_TTL              = 3600,  -- detik; 0 = matikan cache

	SHOW_SPLASH            = true,
	SHOW_NOTIFICATION      = true,
	SHOW_LOGGER            = true,

	-- Kalau true: UniverseId WAJIB ada di GameDatabase (§17), kalau
	-- enggak loader berhenti & nampilin layar "Not Supported".
	-- Kalau false: loader lewatin pengecekan ini, langsung load
	-- MAIN_SCRIPT_URL di game manapun.
	ENFORCE_GAME_ALLOWLIST = true,

	SUPPORT_DISCORD        = "", -- isi invite link buat tombol Join Discord, "" = sembunyikan
}

--======================================================================
-- 2) CONSTANTS — tema visual MILIK LOADER SENDIRI. Nilainya sengaja
--    disamakan dengan palet default EWEHUB supaya keliatan satu produk,
--    tapi ini SALINAN independen, bukan referensi ke library manapun.
--======================================================================
local Constants = {
	Theme = {
		Background = Color3.fromRGB(14, 14, 14),
		Panel      = Color3.fromRGB(20, 20, 20),
		PanelLight = Color3.fromRGB(26, 26, 26),
		Stroke     = Color3.fromRGB(38, 38, 38),
		Accent     = Color3.fromRGB(0, 255, 140),
		Text       = Color3.fromRGB(235, 235, 235),
		SubText    = Color3.fromRGB(145, 145, 145),
		Success    = Color3.fromRGB(60, 220, 130),
		Danger     = Color3.fromRGB(255, 96, 96),
	},

	GAME_STATUS = {
		SUPPORTED   = "SUPPORTED",
		BETA        = "BETA",
		MAINTENANCE = "MAINTENANCE",
	},

	-- "warn" vs "print" adalah satu-satunya cara native buat bedain
	-- warna log di Output Roblox (gak ada rich-text color di print/warn).
	LOG_LEVELS = {
		INFO    = { Tag = "INFO",    Emit = "print" },
		SUCCESS = { Tag = "SUCCESS", Emit = "print" },
		WARNING = { Tag = "WARNING", Emit = "warn"  },
		ERROR   = { Tag = "ERROR",   Emit = "warn"  },
		DEBUG   = { Tag = "DEBUG",   Emit = "print" },
	},
}

--======================================================================
-- 3) SERVICES — satu tempat manggil game:GetService, hindari panggilan
--    berulang tersebar di banyak modul.
--======================================================================
local Services = {
	TweenService      = game:GetService("TweenService"),
	UserInputService  = game:GetService("UserInputService"),
	Players           = game:GetService("Players"),
	CoreGui           = game:GetService("CoreGui"),
}

--======================================================================
-- 4) UTILS
--======================================================================
local Utils = {}

function Utils.now()
	return os.date("%H:%M:%S")
end

function Utils.clampPercent(value)
	if value < 0 then return 0 end
	if value > 100 then return 100 end
	return value
end

function Utils.isMobileViewport()
	return Services.UserInputService.TouchEnabled and not Services.UserInputService.MouseEnabled
end

-- Sama prinsipnya kayak GetGuiParent() di library — tapi implementasi
-- SENDIRI, gak manggil apapun dari EWEHUB. Coba gethui()/CoreGui dulu
-- (layer paling atas), fallback ke PlayerGui.
function Utils.resolveTopLayerParent()
	if typeof(gethui) == "function" then
		local ok, hui = pcall(gethui)
		if ok and hui then return hui end
	end

	local ok2, writable = pcall(function()
		local probe = Instance.new("Folder")
		probe.Name = "__EWEHUB_LoaderProbe"
		probe.Parent = Services.CoreGui
		probe:Destroy()
		return true
	end)
	if ok2 and writable then return Services.CoreGui end

	return Services.Players.LocalPlayer:WaitForChild("PlayerGui")
end

--======================================================================
-- 5) LOGGER
--======================================================================
local Logger = {}
Logger.__index = Logger

function Logger.new(config)
	return setmetatable({ config = config }, Logger)
end

function Logger:_emit(levelName, fmt, ...)
	if not self.config.SHOW_LOGGER then return end
	if levelName == "DEBUG" and not self.config.DEBUG_MODE then return end

	local level = Constants.LOG_LEVELS[levelName]
	local line = string.format(
		"[%s Loader v%s] %s :: %-7s :: %s",
		self.config.HUB_NAME, self.config.VERSION, Utils.now(), level.Tag,
		string.format(fmt, ...)
	)

	if level.Emit == "warn" then warn(line) else print(line) end
end

function Logger:info(fmt, ...)    self:_emit("INFO", fmt, ...) end
function Logger:success(fmt, ...) self:_emit("SUCCESS", fmt, ...) end
function Logger:warning(fmt, ...) self:_emit("WARNING", fmt, ...) end
function Logger:error(fmt, ...)   self:_emit("ERROR", fmt, ...) end
function Logger:debug(fmt, ...)   self:_emit("DEBUG", fmt, ...) end

--======================================================================
-- 6) UI PRIMITIVES — helper Instance.new tingkat rendah, dipakai bareng
--    Notification/LoaderUI/UnsupportedScreen. Bukan komponen library.
--======================================================================
local UIPrimitives = {}

function UIPrimitives.new(class, props, children)
	local inst = Instance.new(class)
	for key, value in pairs(props or {}) do inst[key] = value end
	for _, child in ipairs(children or {}) do child.Parent = inst end
	return inst
end

function UIPrimitives.corner(radius)
	return UIPrimitives.new("UICorner", { CornerRadius = UDim.new(0, radius) })
end

function UIPrimitives.stroke(color, thickness)
	return UIPrimitives.new("UIStroke", { Color = color, Thickness = thickness or 1 })
end

function UIPrimitives.newScreenGui(name)
	return UIPrimitives.new("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 2147483647, -- selalu di layer paling atas
		Parent = Utils.resolveTopLayerParent(),
	})
end

--======================================================================
-- 7) NOTIFICATION — toast pojok kanan bawah, implementasi sendiri dari
--    nol (bukan EWEHUB:Notify). Gaya visual disamakan (rounded, warna
--    tema, fade+slide) tapi kodenya independen sepenuhnya.
--======================================================================
local Notification = {}
Notification.__index = Notification

function Notification.new(theme, config)
	return setmetatable({ theme = theme, config = config, container = nil }, Notification)
end

function Notification:_ensureContainer()
	if self.container and self.container.Parent then return end

	local gui = UIPrimitives.newScreenGui("EWEHUB_LoaderNotify")
	self.container = UIPrimitives.new("Frame", {
		Size = UDim2.new(0, 280, 1, -20),
		Position = UDim2.new(1, -300, 0, 10),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	UIPrimitives.new("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 8),
		Parent = self.container,
	})
end

function Notification:push(title, content, duration)
	if not self.config.SHOW_NOTIFICATION then return end
	self:_ensureContainer()

	local theme = self.theme
	local toast = UIPrimitives.new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = theme.Panel,
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		LayoutOrder = -os.clock(),
		Parent = self.container,
	}, { UIPrimitives.corner(10), UIPrimitives.stroke(theme.Accent, 1) })

	local inner = UIPrimitives.new("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = toast,
	}, {
		UIPrimitives.new("UIPadding", {
			PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
		}),
	})
	UIPrimitives.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = inner })

	UIPrimitives.new("TextLabel", {
		Text = title, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = theme.Accent,
		BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 18), Parent = inner,
	})

	UIPrimitives.new("TextLabel", {
		Text = content, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = theme.Text,
		TextWrapped = true, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = inner,
	})

	Services.TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0,
	}):Play()

	task.delay(duration or 4, function()
		if toast and toast.Parent then
			Services.TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				BackgroundTransparency = 1,
			}):Play()
			task.delay(0.35, function()
				if toast then toast:Destroy() end
			end)
		end
	end)
end

--======================================================================
-- 8) LOADER ANIMATOR — resep TweenService yang reusable, tidak tahu
--    apa-apa soal loader/game, cuma tahu cara nge-tween GuiObject.
--======================================================================
local LoaderAnimator = {}

function LoaderAnimator.tween(instance, duration, style, direction, goalProps)
	local playing = Services.TweenService:Create(instance, TweenInfo.new(duration, style, direction), goalProps)
	playing:Play()
	return playing
end

function LoaderAnimator.fadeIn(frame, duration)
	frame.BackgroundTransparency = 1
	return LoaderAnimator.tween(frame, duration or 0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = 0 })
end

function LoaderAnimator.fadeOut(frame, duration)
	return LoaderAnimator.tween(frame, duration or 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { BackgroundTransparency = 1 })
end

-- targetSize WAJIB di-capture SEBELUM manggil fungsi ini (fungsi ini
-- bakal nge-nolin Size instance dulu sebelum tween ke targetSize).
function LoaderAnimator.scaleIn(frame, targetSize, duration)
	frame.Size = UDim2.new(targetSize.X.Scale, 0, targetSize.Y.Scale, 0)
	return LoaderAnimator.tween(frame, duration or 0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Size = targetSize })
end

function LoaderAnimator.scaleOut(frame, duration)
	local current = frame.Size
	return LoaderAnimator.tween(frame, duration or 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In, {
		Size = UDim2.new(current.X.Scale, 0, current.Y.Scale, 0),
	})
end

function LoaderAnimator.popBounce(instance, targetSize, duration)
	instance.Size = UDim2.new(0, 0, 0, 0)
	return LoaderAnimator.tween(instance, duration or 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Size = targetSize })
end

function LoaderAnimator.glowPulse(strokeInstance, color, duration)
	if not strokeInstance then return end
	strokeInstance.Color = color
	strokeInstance.Transparency = 0
	LoaderAnimator.tween(strokeInstance, duration or 0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { Transparency = 0.35 })
end

function LoaderAnimator.smoothProgress(fillInstance, scaleX, duration)
	return LoaderAnimator.tween(fillInstance, duration or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
		Size = UDim2.new(scaleX, 0, 1, 0),
	})
end

--======================================================================
-- 9) LOADER UI — kartu loading kecil (BUKAN window utama, BUKAN splash
--    permanen). Cuma muncul sebentar terus ilang. Style-nya ngikut
--    Constants.Theme milik loader sendiri.
--======================================================================
local LoaderUI = {}
LoaderUI.__index = LoaderUI

function LoaderUI.new(theme, config)
	return setmetatable({ theme = theme, config = config, pulsing = false }, LoaderUI)
end

function LoaderUI:_build()
	local theme = self.theme
	local cardWidth = Utils.isMobileViewport() and 220 or 260
	local cardHeight = 164

	self.screenGui = UIPrimitives.newScreenGui("EWEHUB_LoaderUI")

	UIPrimitives.new("Frame", { -- shadow semu di belakang kartu
		Size = UDim2.new(0, cardWidth, 0, cardHeight),
		Position = UDim2.new(0.5, 0, 0.5, 4),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		ZIndex = 1,
		Parent = self.screenGui,
	}, { UIPrimitives.corner(16) })

	self.card = UIPrimitives.new("Frame", {
		Size = UDim2.new(0, cardWidth, 0, cardHeight),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = theme.Panel,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 2,
		Parent = self.screenGui,
	}, { UIPrimitives.corner(16), UIPrimitives.stroke(theme.Stroke, 1) })

	self.iconRing = UIPrimitives.new("Frame", {
		Size = UDim2.new(0, 44, 0, 44),
		Position = UDim2.new(0.5, 0, 0, 18),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = theme.PanelLight,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = self.card,
	}, { UIPrimitives.corner(22), UIPrimitives.stroke(theme.Accent, 2) })

	self.iconLabel = UIPrimitives.new("TextLabel", {
		Text = "", Font = Enum.Font.GothamBlack, TextSize = 20, TextColor3 = theme.Accent,
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 4, Parent = self.iconRing,
	})

	UIPrimitives.new("TextLabel", {
		Text = self.config.HUB_NAME, Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = theme.Text,
		BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 70), Size = UDim2.new(1, 0, 0, 18),
		ZIndex = 3, Parent = self.card,
	})

	UIPrimitives.new("TextLabel", {
		Text = "Loader v" .. self.config.VERSION, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = theme.SubText,
		BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 88), Size = UDim2.new(1, 0, 0, 14),
		ZIndex = 3, Parent = self.card,
	})

	self.statusLabel = UIPrimitives.new("TextLabel", {
		Text = "Initializing...", Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = theme.SubText,
		TextWrapped = true, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 108),
		Size = UDim2.new(1, -24, 0, 30), ZIndex = 3, Parent = self.card,
	})

	self.progressTrack = UIPrimitives.new("Frame", {
		Size = UDim2.new(1, -32, 0, 4), Position = UDim2.new(0, 16, 1, -16),
		BackgroundColor3 = theme.Stroke, BorderSizePixel = 0, ZIndex = 3, Parent = self.card,
	}, { UIPrimitives.corner(2) })

	self.progressFill = UIPrimitives.new("Frame", {
		Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = theme.Accent, BorderSizePixel = 0,
		ZIndex = 4, Parent = self.progressTrack,
	}, { UIPrimitives.corner(2) })
end

function LoaderUI:mount()
	if self.screenGui then return end
	self:_build()
end

function LoaderUI:_startPulse()
	self.pulsing = true
	local ring = self.iconRing
	task.spawn(function()
		local strokeInst = ring:FindFirstChildOfClass("UIStroke")
		while self.pulsing and strokeInst and strokeInst.Parent do
			LoaderAnimator.tween(strokeInst, 0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, { Transparency = 0.6 })
			task.wait(0.9)
			if not self.pulsing then break end
			LoaderAnimator.tween(strokeInst, 0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, { Transparency = 0 })
			task.wait(0.9)
		end
	end)
end

function LoaderUI:stopPulse()
	self.pulsing = false
end

function LoaderUI:playIntro()
	if not self.card then return end
	LoaderAnimator.fadeIn(self.card, 0.28)
	LoaderAnimator.scaleIn(self.card, self.card.Size, 0.32)
	self:_startPulse()
end

function LoaderUI:setStatusText(text)
	if self.statusLabel then self.statusLabel.Text = text end
end

function LoaderUI:setProgress(percent)
	if not self.progressFill then return end
	LoaderAnimator.smoothProgress(self.progressFill, Utils.clampPercent(percent) / 100, 0.3)
end

function LoaderUI:playSuccess(label)
	if not self.iconLabel then return end
	self:stopPulse()
	self.iconLabel.Text = "✓"
	self.iconLabel.TextColor3 = self.theme.Success
	LoaderAnimator.popBounce(self.iconRing, self.iconRing.Size, 0.45)
	LoaderAnimator.glowPulse(self.iconRing:FindFirstChildOfClass("UIStroke"), self.theme.Success, 0.5)
	self:setStatusText(label)
	self:setProgress(100)
end

function LoaderUI:playUnsupported(label)
	if not self.iconLabel then return end
	self:stopPulse()
	self.iconLabel.Text = "✕"
	self.iconLabel.TextColor3 = self.theme.Danger
	LoaderAnimator.popBounce(self.iconRing, self.iconRing.Size, 0.4)
	LoaderAnimator.glowPulse(self.iconRing:FindFirstChildOfClass("UIStroke"), self.theme.Danger, 0.5)
	self:setStatusText(label)
end

function LoaderUI:playOutro(onComplete)
	self:stopPulse()
	if not self.screenGui then
		if onComplete then onComplete() end
		return
	end

	local gui, card = self.screenGui, self.card
	self.screenGui, self.card = nil, nil

	if card then
		LoaderAnimator.fadeOut(card, 0.22)
		LoaderAnimator.scaleOut(card, 0.22)
	end

	task.delay(0.26, function()
		gui:Destroy()
		if onComplete then onComplete() end
	end)
end

--======================================================================
-- 10) LOADER CONTROLLER — satu-satunya API publik yang dipanggil dari
--     Main (§18). Pemanggil TIDAK PERLU TAHU cara kerja LoaderUI di
--     dalamnya — cukup 5 fungsi ini.
--======================================================================
local LoaderController = {}
LoaderController.__index = LoaderController

function LoaderController.new(theme, config)
	return setmetatable({ config = config, ui = LoaderUI.new(theme, config) }, LoaderController)
end

function LoaderController:ShowLoading()
	if not self.config.SHOW_SPLASH then return end
	self.ui:mount()
	self.ui:playIntro()
end

function LoaderController:UpdateStatus(text, percent)
	if not self.config.SHOW_SPLASH then return end
	self.ui:setStatusText(text)
	if percent then self.ui:setProgress(percent) end
end

function LoaderController:ShowSuccess(label)
	if not self.config.SHOW_SPLASH then return end
	self.ui:playSuccess(label)
end

function LoaderController:ShowUnsupported(label)
	if not self.config.SHOW_SPLASH then return end
	self.ui:playUnsupported(label)
end

function LoaderController:Hide(delaySeconds, onComplete)
	if not self.config.SHOW_SPLASH then
		if onComplete then onComplete() end
		return
	end
	task.delay(delaySeconds or 0, function()
		self.ui:playOutro(onComplete)
	end)
end

--======================================================================
-- 11) UNSUPPORTED SCREEN — halaman detail (Copy UniverseId/Discord/
--     Close). Instance mentah juga (bukan window library), ditampilkan
--     SETELAH kartu LoaderUI selesai menghilang.
--======================================================================
local UnsupportedScreen = {}

function UnsupportedScreen.show(theme, config, gameInfo, headline, detailMessage)
	local screenGui = UIPrimitives.newScreenGui("EWEHUB_LoaderUnsupported")
	local cardWidth = Utils.isMobileViewport() and 260 or 320

	local card = UIPrimitives.new("Frame", {
		Size = UDim2.new(0, cardWidth, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = theme.Panel,
		BorderSizePixel = 0,
		Parent = screenGui,
	}, {
		UIPrimitives.corner(16), UIPrimitives.stroke(theme.Danger, 1),
		UIPrimitives.new("UIPadding", {
			PaddingTop = UDim.new(0, 16), PaddingBottom = UDim.new(0, 16),
			PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16),
		}),
		UIPrimitives.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }),
	})

	UIPrimitives.new("TextLabel", {
		Text = "🚫 " .. headline, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = theme.Text,
		TextWrapped = true, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = card,
	})

	UIPrimitives.new("TextLabel", {
		Text = detailMessage, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = theme.SubText,
		TextWrapped = true, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = card,
	})

	UIPrimitives.new("TextLabel", {
		Text = "Universe ID: " .. tostring(gameInfo.UniverseId), Font = Enum.Font.Gotham, TextSize = 12,
		TextColor3 = theme.SubText, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 16), Parent = card,
	})

	UIPrimitives.new("TextLabel", {
		Text = "Place ID: " .. tostring(gameInfo.PlaceId), Font = Enum.Font.Gotham, TextSize = 12,
		TextColor3 = theme.SubText, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 16), Parent = card,
	})

	local function actionButton(label, order, callback)
		local btn = UIPrimitives.new("TextButton", {
			Text = label, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = theme.Text,
			BackgroundColor3 = theme.PanelLight, AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 34),
			LayoutOrder = order, Parent = card,
		}, { UIPrimitives.corner(8), UIPrimitives.stroke(theme.Stroke, 1) })

		btn.MouseButton1Click:Connect(callback)
		btn.MouseEnter:Connect(function()
			LoaderAnimator.tween(btn, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundColor3 = theme.Accent })
		end)
		btn.MouseLeave:Connect(function()
			LoaderAnimator.tween(btn, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundColor3 = theme.PanelLight })
		end)
		return btn
	end

	actionButton("📋 Copy UniverseId", 1, function()
		if typeof(setclipboard) == "function" then
			pcall(setclipboard, tostring(gameInfo.UniverseId))
		end
	end)

	if config.SUPPORT_DISCORD ~= "" then
		actionButton("💬 Join Discord", 2, function()
			if typeof(setclipboard) == "function" then
				pcall(setclipboard, config.SUPPORT_DISCORD)
			end
		end)
	end

	actionButton("✖ Close", 3, function()
		screenGui:Destroy()
	end)

	LoaderAnimator.fadeIn(card, 0.25)
	LoaderAnimator.scaleIn(card, card.Size, 0.3)
end

--======================================================================
-- 12) GAME REGISTRY — allow-list opsional (lihat Config.ENFORCE_GAME_ALLOWLIST)
--======================================================================
local GameRegistry = {}
GameRegistry.__index = GameRegistry

function GameRegistry.new()
	return setmetatable({ entries = {} }, GameRegistry)
end

function GameRegistry:register(data)
	assert(type(data.UniverseId) == "number", "GameRegistry: UniverseId wajib number")
	self.entries[data.UniverseId] = {
		UniverseId = data.UniverseId,
		Name       = data.Name or ("Game #" .. tostring(data.UniverseId)),
		Status     = data.Status or Constants.GAME_STATUS.SUPPORTED,
		Notes      = data.Notes,
	}
	return self
end

function GameRegistry:registerMany(list)
	for _, data in ipairs(list) do self:register(data) end
	return self
end

function GameRegistry:find(universeId)
	return self.entries[universeId]
end

--======================================================================
-- 13) GAME DETECTOR
--======================================================================
local GameDetector = {}

function GameDetector.capture()
	return { UniverseId = game.GameId, PlaceId = game.PlaceId }
end

--======================================================================
-- 14) RETRY POLICY
--======================================================================
local RetryPolicy = {}
RetryPolicy.__index = RetryPolicy

function RetryPolicy.new(maxAttempts, timeoutSeconds)
	return setmetatable({ maxAttempts = math.max(1, maxAttempts), timeoutSeconds = timeoutSeconds }, RetryPolicy)
end

function RetryPolicy:backoffFor(attemptNumber)
	return 0.4 * (attemptNumber - 1)
end

--======================================================================
-- 15) NETWORK — HttpGet + retry + soft-timeout.
--     CATATAN: HttpGet Roblox itu blocking & gak punya cancel token
--     asli. Request dijalankan di coroutine terpisah (task.spawn);
--     thread pemanggil cuma nungguin maksimal `timeoutSeconds` lalu
--     nyerah & retry. Kalau request lama itu akhirnya selesai di
--     background, hasilnya cuma diabaikan (aman, gak nge-crash apapun).
--======================================================================
local Network = {}
Network.__index = Network

function Network.new(logger, retryPolicy)
	return setmetatable({ logger = logger, retry = retryPolicy }, Network)
end

function Network:_singleAttempt(url)
	local finished, payload = false, nil

	task.spawn(function()
		local ok, response = pcall(game.HttpGet, game, url)
		if ok then payload = response end
		finished = true
	end)

	local elapsed = 0
	while not finished and elapsed < self.retry.timeoutSeconds do
		task.wait(0.1)
		elapsed = elapsed + 0.1
	end

	return payload
end

function Network:download(url)
	for attempt = 1, self.retry.maxAttempts do
		self.logger:debug("Fetch attempt %d/%d -> %s", attempt, self.retry.maxAttempts, url)

		local body = self:_singleAttempt(url)
		if body and #body > 0 then
			return true, body
		end

		self.logger:warning("Fetch attempt %d/%d failed or timed out.", attempt, self.retry.maxAttempts)
		if attempt < self.retry.maxAttempts then
			task.wait(self.retry:backoffFor(attempt + 1))
		end
	end

	return false, nil
end

--======================================================================
-- 16) CACHE STORE — implementasi file-cache SENDIRI (writefile/readfile
--     langsung), TIDAK memakai SafeIO milik library.
--======================================================================
local CacheStore = {}
CacheStore.__index = CacheStore

local CACHE_DIR = "EWEHUB_Loader/cache"

function CacheStore.new(ttlSeconds)
	local hasFs = typeof(writefile) == "function" and typeof(readfile) == "function"
	if hasFs and typeof(isfolder) == "function" and typeof(makefolder) == "function" then
		if not isfolder("EWEHUB_Loader") then makefolder("EWEHUB_Loader") end
		if not isfolder(CACHE_DIR) then makefolder(CACHE_DIR) end
	end
	return setmetatable({ ttl = ttlSeconds, hasFs = hasFs, memory = {} }, CacheStore)
end

function CacheStore:_path(universeId)
	return CACHE_DIR .. "/" .. tostring(universeId) .. ".cache"
end

function CacheStore:read(universeId)
	if self.ttl <= 0 then return nil end

	local raw
	if self.hasFs then
		local ok, content = pcall(readfile, self:_path(universeId))
		if ok then raw = content end
	else
		raw = self.memory[universeId]
	end
	if not raw then return nil end

	local savedAt, body = raw:match("^(%d+)\n(.*)$")
	if not savedAt then return nil end
	if os.time() - tonumber(savedAt) > self.ttl then return nil end

	return body
end

function CacheStore:write(universeId, body)
	if self.ttl <= 0 then return end
	local payload = tostring(os.time()) .. "\n" .. body

	if self.hasFs then
		pcall(writefile, self:_path(universeId), payload)
	else
		self.memory[universeId] = payload
	end
end

--======================================================================
-- 17) GAME DATABASE — allow-list. TAMBAH GAME BARU CUKUP DI SINI.
--     (Dipakai HANYA kalau Config.ENFORCE_GAME_ALLOWLIST = true)
--======================================================================
local GameDatabase = {
	{ UniverseId = 6701277882 },
	{ UniverseId = 9691752199 },
	{ UniverseId = 7326934954 },
	{ UniverseId = 8316902627 },
	{ UniverseId = 9721900284 },
	{ UniverseId = 9546331833 },
	{ UniverseId = 6739698191 },
	{ UniverseId = 9465913467 },
	{ UniverseId = 994732206  },
	{ UniverseId = 9186719164 },
	{ UniverseId = 10200395747 },

	-- Contoh field opsional:
	-- { UniverseId = 123456789, Name = "Nama Game", Status = "BETA", Notes = "Catatan singkat." },
}

--======================================================================
-- 18) MAIN — satukan semua modul jadi 1 alur eksekusi
--======================================================================
local HOLD_SECONDS = { Success = 1.2, Failure = 2.0 }

local function main()
	local logger   = Logger.new(Config)
	local notify   = Notification.new(Constants.Theme, Config)
	local loader   = LoaderController.new(Constants.Theme, Config)
	local registry = GameRegistry.new():registerMany(GameDatabase)
	local retry    = RetryPolicy.new(Config.AUTO_RETRY and Config.MAX_RETRY or 1, Config.REQUEST_TIMEOUT)
	local network  = Network.new(logger, retry)
	local cache    = CacheStore.new(Config.CACHE_TTL)

	-- ===== 1. Inisialisasi & tampilkan Loader UI =====
	logger:info("%s Loader v%s starting up.", Config.HUB_NAME, Config.VERSION)
	loader:ShowLoading()
	loader:UpdateStatus("Initializing...", 10)

	-- ===== 2. Deteksi game =====
	loader:UpdateStatus("Detecting Game...", 30)
	local gameInfo = GameDetector.capture()
	logger:info("PlaceId=%d  UniverseId=%d", gameInfo.PlaceId, gameInfo.UniverseId)

	-- ===== 3. Cek dukungan (opsional, lihat ENFORCE_GAME_ALLOWLIST) =====
	loader:UpdateStatus("Checking Support...", 45)
	local entry = nil

	if Config.ENFORCE_GAME_ALLOWLIST then
		entry = registry:find(gameInfo.UniverseId)

		if not entry then
			logger:warning("UniverseId %d tidak ada di allow-list.", gameInfo.UniverseId)
			notify:push("⚠ Unsupported Game", "UniverseId: " .. gameInfo.UniverseId, 5)
			loader:ShowUnsupported("Game Not Supported\nUniverse " .. gameInfo.UniverseId)
			loader:Hide(HOLD_SECONDS.Failure, function()
				UnsupportedScreen.show(Constants.Theme, Config, gameInfo, "Game Not Supported", "Game ini belum ada di allow-list loader.")
			end)
			return
		end

		if entry.Status == Constants.GAME_STATUS.MAINTENANCE then
			logger:warning("%s sedang MAINTENANCE.", entry.Name)
			notify:push("🔧 Maintenance", entry.Name .. " sedang dalam perbaikan.", 5)
			loader:ShowUnsupported(entry.Name .. "\nUnder Maintenance")
			loader:Hide(HOLD_SECONDS.Failure, function()
				UnsupportedScreen.show(Constants.Theme, Config, gameInfo, entry.Name .. " Under Maintenance", entry.Notes or "Coba lagi beberapa saat lagi.")
			end)
			return
		end

		logger:success("Game cocok: %s (status=%s)", entry.Name, entry.Status)
		if entry.Status == Constants.GAME_STATUS.BETA then
			notify:push("🧪 Beta", entry.Notes or (entry.Name .. " masih tahap beta."), 4)
		end
	else
		logger:info("ENFORCE_GAME_ALLOWLIST = false, lewatin pengecekan registry.")
	end

	-- ===== 4. Ambil script utama (cache dulu, baru network) =====
	loader:UpdateStatus("Fetching Main Script...", 65)

	local cacheKey = gameInfo.UniverseId
	local body = cache:read(cacheKey)
	local servedFromCache = body ~= nil

	if servedFromCache then
		logger:info("Pakai cache lokal (umur < %ds).", Config.CACHE_TTL)
	else
		local ok, downloaded = network:download(Config.MAIN_SCRIPT_URL)
		if ok then body = downloaded end
	end

	if not body then
		logger:error("Gagal mengambil script utama setelah %d percobaan.", retry.maxAttempts)
		notify:push("❌ Failed to Load", "Gagal mengambil script. Cek koneksi internet kamu.", 6)
		loader:ShowUnsupported("Failed to Load Script")
		loader:Hide(HOLD_SECONDS.Failure)
		return
	end

	if not servedFromCache then
		cache:write(cacheKey, body)
	end

	-- ===== 5. Tandai SUKSES, sembunyikan Loader UI, BARU jalankan =====
	-- Script utama SENGAJA belum dieksekusi di sini — ditunda sampai
	-- kartu LoaderUI ini selesai menghilang, biar UI dari library
	-- (kalau ada) gak numpuk/tabrakan sama animasi fade-out loader ini.
	loader:UpdateStatus("Ready.", 100)
	loader:ShowSuccess((entry and entry.Name or "Game") .. " Supported")

	loader:Hide(HOLD_SECONDS.Success, function()
		local compileOk, compiledOrErr = pcall(loadstring, body)
		if not compileOk or not compiledOrErr then
			logger:error("Compile error: %s", tostring(compiledOrErr))
			notify:push("❌ Failed to Load", "Script utama gagal di-compile.", 6)
			return
		end

		-- ===== 6. Kontrol berpindah SEPENUHNYA ke script utama =====
		local runOk, runErr = pcall(compiledOrErr)
		if runOk then
			logger:success("Script utama berhasil dijalankan. Kontrol berpindah ke library.")
		else
			logger:error("Runtime error dari script utama: %s", tostring(runErr))
			notify:push("❌ Script Error", tostring(runErr), 6)
		end
	end)
end

--======================================================================
-- ENTRY POINT — pcall paling luar, biar loader gak pernah "diam ngehang"
-- tanpa penjelasan kalaupun ada bug tak terduga di salah satu modul.
--======================================================================
local bootOk, bootErr = pcall(main)
if not bootOk then
	warn(string.format("[%s Loader Fatal] %s", Config.HUB_NAME, tostring(bootErr)))
end
