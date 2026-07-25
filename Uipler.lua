--[[
	NovaUI - Modern Roblox UI Library
	================================================================
	Library UI dua-panel (sidebar/navbar + content panel) bertema dark
	modern dengan aksen merah. Dibangun murni sebagai framework UI
	(tidak berisi logic exploit/game apa pun) - komponen: Button,
	Toggle, Slider, Dropdown (Single/Multi), Textbox, ColorPicker,
	Keybind, Label, Section, Paragraph, Status, Notification, Dialog,
	Tab, Window.

	Dokumentasi lengkap: lihat DOCS.md yang menyertai file ini.

	Struktur file (cari header "SECTION:" untuk navigasi cepat):
		SECTION: SERVICES & CONSTANTS
		SECTION: THEME
		SECTION: UTILITIES
		SECTION: ICONS
		SECTION: CONFIG
		SECTION: NOTIFICATION
		SECTION: DIALOG
		SECTION: COMPONENTS
		SECTION: SECTION (wrapper)
		SECTION: TAB
		SECTION: WINDOW
		SECTION: PUBLIC API
	================================================================
]]

local NovaUI = {}
NovaUI.__index = NovaUI
NovaUI._version = "1.1.0"

--====================================================================
-- SECTION: SERVICES & CONSTANTS
--====================================================================
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local EASE = Enum.EasingStyle.Quint
local EASE_OUT = Enum.EasingDirection.Out

-- Pita ZIndex terpusat supaya urutan layer selalu konsisten dan tidak
-- ada elemen yang tertutup/bertumpuk secara tidak sengaja.
local ZLayer = {
	Base      = 1,   -- konten normal di dalam card/section
	Popout    = 500, -- dropdown / color picker (dirender lewat Overlay, bukan di dalam card)
	Notify    = 800, -- notifikasi
	Dialog    = 900, -- modal dialog
}

--====================================================================
-- SECTION: THEME
--====================================================================
-- Semua warna & radius terpusat di sini. Komponen lain hanya membaca
-- dari theme, sehingga menambah theme baru = menambah entry baru saja.
NovaUI.Themes = {
	Default = {
		Background      = Color3.fromRGB(13, 13, 15),
		PanelPrimary     = Color3.fromRGB(18, 18, 21),
		PanelSecondary   = Color3.fromRGB(24, 24, 28),
		PanelTertiary    = Color3.fromRGB(31, 31, 36),
		PanelHover       = Color3.fromRGB(38, 38, 44),
		Accent           = Color3.fromRGB(224, 58, 68),
		AccentHover      = Color3.fromRGB(240, 74, 84),
		AccentDim        = Color3.fromRGB(70, 28, 32),
		AccentGradient   = Color3.fromRGB(255, 90, 90),
		Stroke           = Color3.fromRGB(42, 42, 48),
		StrokeLight      = Color3.fromRGB(55, 55, 62),
		TextPrimary      = Color3.fromRGB(238, 238, 242),
		TextSecondary    = Color3.fromRGB(150, 150, 160),
		TextTertiary     = Color3.fromRGB(96, 96, 106),
		Success          = Color3.fromRGB(64, 200, 122),
		Warning          = Color3.fromRGB(235, 180, 64),
		Error            = Color3.fromRGB(230, 70, 70),
		Font             = Enum.Font.GothamMedium,
		FontBold         = Enum.Font.GothamBold,
		FontSemibold     = Enum.Font.GothamSemibold,

		-- Radius terpusat: satu skala dipakai di seluruh library supaya
		-- tidak ada sudut yang "kotak" atau tidak konsisten.
		Radius = {
			xs   = 6,   -- elemen kecil (icon chip, badge kecil)
			sm   = 8,   -- input, tombol, dropdown
			md   = 10,  -- card komponen (baris Button/Toggle/dll)
			lg   = 16,  -- window utama
			pill = 999, -- toggle track, status pill, badge
		},
	},
}

--====================================================================
-- SECTION: UTILITIES
--====================================================================
local Util = {}

function Util.Create(class, props, children)
	local inst = Instance.new(class)
	for prop, value in pairs(props or {}) do
		if prop ~= "Parent" then
			inst[prop] = value
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

function Util.Tween(obj, info, props)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

function Util.QuickTween(obj, props, duration, style, direction)
	return Util.Tween(obj, TweenInfo.new(duration or 0.22, style or EASE, direction or EASE_OUT), props)
end

function Util.Corner(parent, radius)
	return Util.Create("UICorner", { CornerRadius = UDim.new(0, radius or 10), Parent = parent })
end

function Util.Stroke(parent, color, thickness, transparency)
	return Util.Create("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

function Util.Padding(parent, all, l, r, t, b)
	return Util.Create("UIPadding", {
		PaddingLeft = UDim.new(0, l or all),
		PaddingRight = UDim.new(0, r or all),
		PaddingTop = UDim.new(0, t or all),
		PaddingBottom = UDim.new(0, b or all),
		Parent = parent,
	})
end

function Util.Gradient(parent, colorSequence, rotation)
	return Util.Create("UIGradient", { Color = colorSequence, Rotation = rotation or 0, Parent = parent })
end

-- Glow/dropshadow generik berbasis ImageLabel 9-slice.
function Util.Glow(parent, color, transparency, extraSize, zindex)
	return Util.Create("ImageLabel", {
		Name = "Glow",
		BackgroundTransparency = 1,
		Image = "rbxassetid://6014261993",
		ImageColor3 = color or Color3.new(0, 0, 0),
		ImageTransparency = transparency or 0.55,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		Size = UDim2.new(1, extraSize or 30, 1, extraSize or 30),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = zindex or 0,
		Parent = parent,
	})
end

-- Efek ripple material-design saat elemen ditekan.
function Util.Ripple(button)
	button.ClipsDescendants = true
	button.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local relX = input.Position.X - button.AbsolutePosition.X
		local relY = input.Position.Y - button.AbsolutePosition.Y
		local size = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 1.6

		local ripple = Util.Create("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.82,
			Size = UDim2.new(0, 0, 0, 0),
			Position = UDim2.new(0, relX, 0, relY),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ZIndex = button.ZIndex + 1,
			Parent = button,
		})
		Util.Corner(ripple, 999)
		Util.QuickTween(ripple, { Size = UDim2.new(0, size, 0, size), BackgroundTransparency = 1 }, 0.5, Enum.EasingStyle.Quad)
		task.delay(0.5, function() ripple:Destroy() end)
	end)
end

-- Hover generik: interpolasi warna background antara Normal <-> Hover.
function Util.Hover(obj, normalColor, hoverColor, duration)
	obj.MouseEnter:Connect(function()
		Util.QuickTween(obj, { BackgroundColor3 = hoverColor }, duration or 0.15)
	end)
	obj.MouseLeave:Connect(function()
		Util.QuickTween(obj, { BackgroundColor3 = normalColor }, duration or 0.15)
	end)
end

-- Frame draggable lewat sebuah "handle" (mis. brand/topbar area).
function Util.Draggify(frame, handle)
	handle = handle or frame
	local dragging, dragInput, startPos, startInputPos

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPos = frame.Position
			startInputPos = input.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - startInputPos
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

-- Frame resizable lewat grip kecil di pojok kanan-bawah.
function Util.Resizify(frame, minSize, maxSize)
	minSize = minSize or Vector2.new(640, 420)
	maxSize = maxSize or Vector2.new(1600, 1000)

	local grip = Util.Create("Frame", {
		Name = "ResizeGrip",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 20, 0, 20),
		Position = UDim2.new(1, -20, 1, -20),
		ZIndex = 20,
		Parent = frame,
	})

	local resizing, startSize, startInputPos
	grip.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			startSize = frame.Size
			startInputPos = input.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then resizing = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - startInputPos
			local newX = math.clamp(startSize.X.Offset + delta.X, minSize.X, maxSize.X)
			local newY = math.clamp(startSize.Y.Offset + delta.Y, minSize.Y, maxSize.Y)
			frame.Size = UDim2.new(0, newX, 0, newY)
		end
	end)

	return grip
end

-- Badge pill status (dipakai oleh header Window & komponen Status di Section)
-- supaya tampilannya selalu konsisten di manapun dipakai.
function Util.MakeStatusPill(parent, theme, text, color)
	local pill = Util.Create("Frame", {
		BackgroundColor3 = color,
		BackgroundTransparency = 0.85,
		Size = UDim2.new(0, 0, 0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = parent,
	})
	Util.Corner(pill, theme.Radius.pill)
	local stroke = Util.Stroke(pill, color, 1, 0.5)
	Util.Padding(pill, 0, 10, 10, 0, 0)

	local dot = Util.Create("Frame", {
		BackgroundColor3 = color,
		Size = UDim2.new(0, 7, 0, 7),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ZIndex = 2,
		Parent = pill,
	})
	Util.Corner(dot, theme.Radius.pill)
	local dotGlow = Util.Glow(dot, color, 0.4, -8, 1)

	local label = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		Font = theme.FontSemibold,
		TextSize = 11,
		TextColor3 = color,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.new(0, 13, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = pill,
	})

	-- Denyut lembut pada dot supaya status terasa "live", bukan statis.
	local alive = true
	task.spawn(function()
		while alive and dot.Parent do
			Util.QuickTween(dotGlow, { ImageTransparency = 0.75 }, 0.9)
			task.wait(0.9)
			if not (alive and dot.Parent) then break end
			Util.QuickTween(dotGlow, { ImageTransparency = 0.35 }, 0.9)
			task.wait(0.9)
		end
	end)

	local api = { Instance = pill }
	function api:Set(newText, newColor)
		label.Text = newText
		label.TextColor3 = newColor
		pill.BackgroundColor3 = newColor
		stroke.Color = newColor
		dot.BackgroundColor3 = newColor
		dotGlow.ImageColor3 = newColor
	end
	function api:Destroy()
		alive = false
		pill:Destroy()
	end

	return api
end

-- Peta State -> warna theme, dipakai komponen Status supaya developer
-- cukup bilang "positive"/"warning"/"negative"/"neutral".
function Util.StatusColor(theme, state)
	local map = {
		positive = theme.Success,
		warning = theme.Warning,
		negative = theme.Error,
		neutral = theme.TextTertiary,
	}
	return map[state] or theme.Success
end

NovaUI._Util = Util
NovaUI._ZLayer = ZLayer

--====================================================================
-- SECTION: ICONS
-- Table nama -> asset id. Tambahkan bebas. Nama tak dikenal -> fallback.
--====================================================================
NovaUI.Icons = {
	home        = "rbxassetid://10723347404",
	gamepad     = "rbxassetid://10734950309",
	settings    = "rbxassetid://10734943902",
	search      = "rbxassetid://10734950309",
	dice        = "rbxassetid://10723407163",
	shield      = "rbxassetid://10723407923",
	bolt        = "rbxassetid://10723406145",
	check       = "rbxassetid://10709790644",
	user        = "rbxassetid://10723365040",
	info        = "rbxassetid://10734950404",
	warning     = "rbxassetid://10734949905",
}

function NovaUI:GetIcon(name)
	return self.Icons[name] or self.Icons.bolt
end

--====================================================================
-- SECTION: CONFIG
-- writefile/readfile/isfile dijaga pcall; fallback in-memory apabila
-- tidak tersedia (mis. Roblox Studio) supaya library tetap berjalan.
--====================================================================
local Config = {}
Config.__index = Config

local function fsAvailable()
	return typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"
end

function Config.new(name)
	local self = setmetatable({ Name = name or "NovaUI_Config", Store = {} }, Config)
	self.Path = self.Name .. ".json"
	self:Load()
	return self
end

function Config:Load()
	if not fsAvailable() then return end
	local ok, result = pcall(function()
		if isfile(self.Path) then
			return HttpService:JSONDecode(readfile(self.Path))
		end
		return {}
	end)
	self.Store = ok and result or {}
end

function Config:Save()
	if not fsAvailable() then return end
	pcall(function() writefile(self.Path, HttpService:JSONEncode(self.Store)) end)
end

function Config:Set(key, value)
	self.Store[key] = value
	self:Save()
end

function Config:Get(key, default)
	if self.Store[key] == nil then return default end
	return self.Store[key]
end

NovaUI._Config = Config

--====================================================================
-- SECTION: NOTIFICATION
--====================================================================
local Notification = {}
Notification.__index = Notification

function Notification.new(gui, theme)
	local self = setmetatable({ Theme = theme }, Notification)
	self.Container = Util.Create("Frame", {
		Name = "NotificationContainer",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 320, 1, -40),
		Position = UDim2.new(1, -340, 0, 20),
		ZIndex = ZLayer.Notify,
		Parent = gui,
	})
	Util.Create("UIListLayout", {
		Padding = UDim.new(0, 10),
		VerticalAlignment = Enum.VerticalAlignment.Top,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = self.Container,
	})
	return self
end

-- opts.Type: "Info" | "Success" | "Warning" | "Error"
function Notification:Push(opts)
	opts = opts or {}
	local theme = self.Theme
	local accent = ({
		Info = theme.Accent, Success = theme.Success, Warning = theme.Warning, Error = theme.Error,
	})[opts.Type] or theme.Accent

	local card = Util.Create("Frame", {
		BackgroundColor3 = theme.PanelSecondary,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(1, 40, 0, 0),
		ClipsDescendants = true,
		ZIndex = ZLayer.Notify,
	})
	Util.Corner(card, theme.Radius.md)
	Util.Stroke(card, theme.Stroke, 1)
	Util.Padding(card, 14)

	local accentBar = Util.Create("Frame", {
		BackgroundColor3 = accent,
		Size = UDim2.new(0, 3, 1, -8),
		Position = UDim2.new(0, 0, 0, 4),
		ZIndex = ZLayer.Notify + 1,
		Parent = card,
	})
	Util.Corner(accentBar, theme.Radius.xs)

	local title = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = opts.Title or "Notification",
		Font = theme.FontSemibold,
		TextSize = 15,
		TextColor3 = theme.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -12, 0, 20),
		Position = UDim2.new(0, 12, 0, 0),
		Parent = card,
	})
	Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = opts.Content or "",
		Font = theme.Font,
		TextSize = 13,
		TextColor3 = theme.TextSecondary,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Size = UDim2.new(1, -12, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0, 12, 0, 24),
		Parent = card,
	})

	card.Parent = self.Container
	card.BackgroundTransparency = 1
	title.TextTransparency = 1
	Util.QuickTween(card, { Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0 }, 0.35)
	Util.QuickTween(title, { TextTransparency = 0 }, 0.35)

	task.delay(opts.Duration or 4.5, function()
		if card and card.Parent then
			Util.QuickTween(card, { Position = UDim2.new(1, 40, 0, 0) }, 0.3)
			task.delay(0.3, function() if card then card:Destroy() end end)
		end
	end)

	return card
end

NovaUI._Notification = Notification

--====================================================================
-- SECTION: DIALOG
--====================================================================
local Dialog = {}
Dialog.__index = Dialog

function Dialog.new(gui, theme)
	return setmetatable({ Theme = theme, Gui = gui }, Dialog)
end

function Dialog:Open(opts)
	opts = opts or {}
	local theme = self.Theme

	local backdrop = Util.Create("Frame", {
		Name = "DialogBackdrop",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = ZLayer.Dialog,
		Parent = self.Gui,
	})

	local box = Util.Create("Frame", {
		BackgroundColor3 = theme.PanelSecondary,
		Size = UDim2.new(0, 320, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = ZLayer.Dialog + 1,
		Parent = backdrop,
	})
	Util.Corner(box, theme.Radius.md)
	Util.Stroke(box, theme.Stroke, 1)
	Util.Glow(box, Color3.new(0, 0, 0), 0.5, 60)
	Util.Padding(box, 20)
	Util.Create("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = box })

	Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = opts.Title or "Confirm",
		Font = theme.FontBold,
		TextSize = 18,
		TextColor3 = theme.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = 1,
		Parent = box,
	})
	Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = opts.Content or "",
		Font = theme.Font,
		TextSize = 14,
		TextColor3 = theme.TextSecondary,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
		Parent = box,
	})

	local btnRow = Util.Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36), LayoutOrder = 3, Parent = box })
	Util.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 10),
		Parent = btnRow,
	})

	local function closeDialog()
		Util.QuickTween(backdrop, { BackgroundTransparency = 1 }, 0.2)
		task.delay(0.2, function() backdrop:Destroy() end)
	end

	for _, btnOpt in ipairs(opts.Buttons or { { Text = "OK" } }) do
		local isAccent = btnOpt.Accent
		local btn = Util.Create("TextButton", {
			BackgroundColor3 = isAccent and theme.Accent or theme.PanelTertiary,
			Size = UDim2.new(0, 96, 1, 0),
			Text = btnOpt.Text or "OK",
			Font = theme.FontSemibold,
			TextSize = 14,
			TextColor3 = isAccent and Color3.new(1, 1, 1) or theme.TextPrimary,
			AutoButtonColor = false,
			Parent = btnRow,
		})
		Util.Corner(btn, theme.Radius.sm)
		Util.Ripple(btn)
		Util.Hover(btn, btn.BackgroundColor3, isAccent and theme.AccentHover or theme.PanelHover)
		btn.MouseButton1Click:Connect(function()
			if btnOpt.Callback then btnOpt.Callback() end
			closeDialog()
		end)
	end

	backdrop.BackgroundTransparency = 1
	Util.QuickTween(backdrop, { BackgroundTransparency = 0.45 }, 0.25)
	box.Size = UDim2.new(0, 300, 0, box.AbsoluteSize.Y)
	Util.QuickTween(box, { Size = UDim2.new(0, 320, 0, box.AbsoluteSize.Y) }, 0.25, Enum.EasingStyle.Back)

	return backdrop
end

NovaUI._Dialog = Dialog

--====================================================================
-- SECTION: COMPONENTS
-- Setiap komponen adalah fungsi factory (parent, theme, opts, window)
-- yang mengembalikan sebuah object dengan API :Set()/:Get() bila
-- relevan. `window` opsional - hanya dibutuhkan oleh komponen yang
-- membuka popout (Dropdown, ColorPicker) supaya bisa dirender lewat
-- Overlay Window (lapisan teratas, tidak ter-clip oleh ScrollingFrame).
--====================================================================
local Components = {}

-- Card dasar dipakai semua komponen baris-tunggal (Button/Toggle/Slider/dll)
-- supaya tinggi, padding, radius, dan efek hover selalu konsisten.
function Components.BaseCard(parent, theme, title, subtitle, height)
	local card = Util.Create("Frame", {
		BackgroundColor3 = theme.PanelSecondary,
		Size = UDim2.new(1, 0, 0, height or 54),
		ZIndex = ZLayer.Base,
		Parent = parent,
	})
	Util.Corner(card, theme.Radius.md)
	local stroke = Util.Stroke(card, theme.Stroke, 1)

	Util.Hover(card, theme.PanelSecondary, theme.PanelHover)
	card.MouseEnter:Connect(function() Util.QuickTween(stroke, { Color = theme.Accent, Transparency = 0.55 }, 0.18) end)
	card.MouseLeave:Connect(function() Util.QuickTween(stroke, { Color = theme.Stroke, Transparency = 0 }, 0.18) end)

	local textHolder = Util.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0.52, 0, 1, 0),
		Position = UDim2.new(0, 16, 0, 0),
		Parent = card,
	})
	Util.Create("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Center, Parent = textHolder })

	local titleLabel = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title or "",
		Font = theme.FontSemibold,
		TextSize = 14,
		TextColor3 = theme.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.new(1, 0, subtitle and 0.5 or 1, 0),
		Parent = textHolder,
	})

	local subLabel
	if subtitle and subtitle ~= "" then
		subLabel = Util.Create("TextLabel", {
			BackgroundTransparency = 1,
			Text = subtitle,
			Font = theme.Font,
			TextSize = 12,
			TextColor3 = theme.TextTertiary,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Size = UDim2.new(1, 0, 0.5, 0),
			Parent = textHolder,
		})
	end

	return card, titleLabel, subLabel
end

-- ---------------------------------------------------------------
-- BUTTON
-- ---------------------------------------------------------------
function Components.CreateButton(parent, theme, opts)
	opts = opts or {}
	local card = Components.BaseCard(parent, theme, opts.Title, opts.Description, 54)

	local action = Util.Create("TextButton", {
		BackgroundColor3 = theme.Accent,
		Size = UDim2.new(0, 116, 0, 34),
		Position = UDim2.new(1, -16, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Text = opts.ButtonText or "Execute",
		Font = theme.FontBold,
		TextSize = 13,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.85,
		AutoButtonColor = false,
		ZIndex = ZLayer.Base + 1,
		Parent = card,
	})
	Util.Corner(action, theme.Radius.sm)
	Util.Gradient(action, ColorSequence.new(theme.AccentGradient, theme.Accent), 90)
	Util.Ripple(action)

	action.MouseEnter:Connect(function()
		Util.QuickTween(action, { BackgroundColor3 = theme.AccentHover }, 0.15)
	end)
	action.MouseLeave:Connect(function()
		Util.QuickTween(action, { BackgroundColor3 = theme.Accent }, 0.15)
	end)
	action.MouseButton1Click:Connect(function()
		if opts.Callback then task.spawn(opts.Callback) end
	end)

	return { Instance = card, SetText = function(_, t) action.Text = t end }
end

-- ---------------------------------------------------------------
-- TOGGLE
-- ---------------------------------------------------------------
function Components.CreateToggle(parent, theme, opts)
	opts = opts or {}
	local card = Components.BaseCard(parent, theme, opts.Title, opts.Description, 54)
	local state = opts.Default or false

	local track = Util.Create("Frame", {
		BackgroundColor3 = state and theme.Accent or theme.PanelTertiary,
		Size = UDim2.new(0, 44, 0, 24),
		Position = UDim2.new(1, -16, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		ZIndex = ZLayer.Base + 1,
		Parent = card,
	})
	Util.Corner(track, theme.Radius.pill)
	Util.Stroke(track, theme.Stroke, 1)

	local knob = Util.Create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size = UDim2.new(0, 18, 0, 18),
		Position = state and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ZIndex = ZLayer.Base + 2,
		Parent = track,
	})
	Util.Corner(knob, theme.Radius.pill)

	local hitbox = Util.Create("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.new(1, 0, 1, 0), Parent = track })

	local self = { Value = state, Instance = card }
	local function render(animate)
		local dur = animate and 0.2 or 0
		Util.QuickTween(track, { BackgroundColor3 = self.Value and theme.Accent or theme.PanelTertiary }, dur)
		Util.QuickTween(knob, { Position = self.Value and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, dur, Enum.EasingStyle.Back)
	end

	hitbox.MouseButton1Click:Connect(function()
		self.Value = not self.Value
		render(true)
		if opts.Callback then task.spawn(opts.Callback, self.Value) end
	end)

	function self:Set(value)
		self.Value = value
		render(true)
	end

	return self
end

-- ---------------------------------------------------------------
-- SLIDER
-- ---------------------------------------------------------------
function Components.CreateSlider(parent, theme, opts)
	opts = opts or {}
	local min, max = opts.Min or 0, opts.Max or 100
	local increment = opts.Increment or 1
	local value = math.clamp(opts.Default or min, min, max)

	local card = Components.BaseCard(parent, theme, opts.Title, nil, 60)

	local valueLabel = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = tostring(value) .. (opts.Suffix or ""),
		Font = theme.FontSemibold,
		TextSize = 13,
		TextColor3 = theme.Accent,
		Size = UDim2.new(0, 70, 0, 18),
		Position = UDim2.new(1, -16, 0, 10),
		AnchorPoint = Vector2.new(1, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = card,
	})

	local barBack = Util.Create("Frame", {
		BackgroundColor3 = theme.PanelTertiary,
		Size = UDim2.new(1, -32, 0, 6),
		Position = UDim2.new(0, 16, 1, -18),
		Parent = card,
	})
	Util.Corner(barBack, theme.Radius.pill)

	local ratio = (value - min) / math.max(max - min, 1e-6)
	local barFill = Util.Create("Frame", { BackgroundColor3 = theme.Accent, Size = UDim2.new(ratio, 0, 1, 0), Parent = barBack })
	Util.Corner(barFill, theme.Radius.pill)

	local knob = Util.Create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size = UDim2.new(0, 14, 0, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(ratio, 0, 0.5, 0),
		ZIndex = ZLayer.Base + 1,
		Parent = barBack,
	})
	Util.Corner(knob, theme.Radius.pill)
	Util.Stroke(knob, theme.Accent, 2)

	local self = { Value = value, Instance = card }
	local function setFromRatio(r, fire)
		r = math.clamp(r, 0, 1)
		local stepped = math.clamp(math.floor((min + (max - min) * r) / increment + 0.5) * increment, min, max)
		self.Value = stepped
		local newRatio = (stepped - min) / math.max(max - min, 1e-6)
		Util.QuickTween(barFill, { Size = UDim2.new(newRatio, 0, 1, 0) }, 0.05)
		Util.QuickTween(knob, { Position = UDim2.new(newRatio, 0, 0.5, 0) }, 0.05)
		valueLabel.Text = tostring(stepped) .. (opts.Suffix or "")
		if fire and opts.Callback then task.spawn(opts.Callback, stepped) end
	end

	local dragging = false
	local hitbox = Util.Create("TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.new(1, 20, 0, 24),
		Position = UDim2.new(0, -10, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Parent = barBack,
	})
	hitbox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromRatio((input.Position.X - barBack.AbsolutePosition.X) / barBack.AbsoluteSize.X, true)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFromRatio((input.Position.X - barBack.AbsolutePosition.X) / barBack.AbsoluteSize.X, true)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	function self:Set(v) setFromRatio((v - min) / math.max(max - min, 1e-6), false) end
	return self
end

-- ---------------------------------------------------------------
-- Backdrop tak-terlihat dipakai Dropdown & ColorPicker: menutupi
-- seluruh layar di Overlay, klik di luar popout akan menutupnya.
-- ---------------------------------------------------------------
local function createBackdropCatcher(overlay, onClose)
	local catcher = Util.Create("TextButton", {
		Name = "PopoutCatcher",
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = ZLayer.Popout,
		Parent = overlay,
	})
	catcher.MouseButton1Click:Connect(function()
		onClose()
		catcher:Destroy()
	end)
	return catcher
end

-- Menghitung posisi popout (dalam koordinat layar) tepat di bawah `anchor`.
local function popoutPositionBelow(anchor, width)
	return UDim2.fromOffset(anchor.AbsolutePosition.X, anchor.AbsolutePosition.Y + anchor.AbsoluteSize.Y + 6),
		width or anchor.AbsoluteSize.X
end

-- ---------------------------------------------------------------
-- DROPDOWN (Single & Multi select)
-- ---------------------------------------------------------------
function Components.CreateDropdown(parent, theme, opts, window)
	opts = opts or {}
	local options = opts.Options or {}
	local multi = opts.Multi or false
	local selected = {}
	if multi then
		for _, v in ipairs(opts.Default or {}) do selected[v] = true end
	elseif opts.Default then
		selected[opts.Default] = true
	end

	local card = Components.BaseCard(parent, theme, opts.Title, nil, 54)

	local function currentText()
		local list = {}
		for k, v in pairs(selected) do if v then table.insert(list, k) end end
		if #list == 0 then return opts.Placeholder or "Select..." end
		return table.concat(list, ", ")
	end

	local display = Util.Create("TextButton", {
		BackgroundColor3 = theme.PanelTertiary,
		Size = UDim2.new(0, 170, 0, 34),
		Position = UDim2.new(1, -16, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Text = "",
		AutoButtonColor = false,
		ZIndex = ZLayer.Base + 1,
		Parent = card,
	})
	Util.Corner(display, theme.Radius.sm)
	Util.Stroke(display, theme.Stroke, 1)

	local displayLabel = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = currentText(),
		Font = theme.Font,
		TextSize = 12,
		TextColor3 = theme.TextSecondary,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -32, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		Parent = display,
	})
	local arrow = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "▾",
		Font = theme.Font,
		TextSize = 14,
		TextColor3 = theme.TextSecondary,
		Size = UDim2.new(0, 22, 1, 0),
		Position = UDim2.new(1, -26, 0, 0),
		Parent = display,
	})

	local self = { Instance = card, Get = function() return selected end }
	local overlay = window and window.Overlay
	local openList, catcher

	local function closeList()
		if openList then
			local l = openList
			openList = nil
			Util.QuickTween(arrow, { Rotation = 0 }, 0.15)
			Util.QuickTween(l, { Size = UDim2.new(l.Size.X.Scale, l.Size.X.Offset, 0, 0) }, 0.15)
			task.delay(0.15, function() l:Destroy() end)
		end
		if catcher then catcher:Destroy(); catcher = nil end
	end

	local function openListFn()
		if not overlay then return end
		local pos, width = popoutPositionBelow(display)
		local targetHeight = math.min(#options * 32 + 8, 200)

		catcher = createBackdropCatcher(overlay, closeList)

		local listFrame = Util.Create("Frame", {
			BackgroundColor3 = theme.PanelTertiary,
			Size = UDim2.new(0, width, 0, 0),
			Position = pos,
			ClipsDescendants = true,
			ZIndex = ZLayer.Popout + 1,
			Parent = overlay,
		})
		Util.Corner(listFrame, theme.Radius.sm)
		Util.Stroke(listFrame, theme.Stroke, 1)
		Util.Glow(listFrame, Color3.new(0, 0, 0), 0.6, 30, ZLayer.Popout)
		Util.Padding(listFrame, 4)
		Util.Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), Parent = listFrame })

		openList = listFrame
		Util.QuickTween(arrow, { Rotation = 180 }, 0.15)
		Util.QuickTween(listFrame, { Size = UDim2.new(0, width, 0, targetHeight) }, 0.18)

		for i, option in ipairs(options) do
			local optBtn = Util.Create("TextButton", {
				BackgroundColor3 = theme.PanelTertiary,
				Size = UDim2.new(1, 0, 0, 28),
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = i,
				ZIndex = ZLayer.Popout + 2,
				Parent = listFrame,
			})
			Util.Corner(optBtn, theme.Radius.xs)
			local optLabel = Util.Create("TextLabel", {
				BackgroundTransparency = 1,
				Text = tostring(option),
				Font = theme.Font,
				TextSize = 12,
				TextColor3 = selected[option] and theme.Accent or theme.TextSecondary,
				TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.new(1, -16, 1, 0),
				Position = UDim2.new(0, 8, 0, 0),
				ZIndex = ZLayer.Popout + 2,
				Parent = optBtn,
			})
			Util.Hover(optBtn, theme.PanelTertiary, theme.PanelHover)

			optBtn.MouseButton1Click:Connect(function()
				if multi then
					selected[option] = not selected[option]
					optLabel.TextColor3 = selected[option] and theme.Accent or theme.TextSecondary
				else
					selected = { [option] = true }
					displayLabel.Text = currentText()
					if opts.Callback then task.spawn(opts.Callback, option) end
					closeList()
					return
				end
				displayLabel.Text = currentText()
				if opts.Callback then
					local list = {}
					for k, v in pairs(selected) do if v then table.insert(list, k) end end
					task.spawn(opts.Callback, list)
				end
			end)
		end
	end

	display.MouseButton1Click:Connect(function()
		if openList then closeList() else openListFn() end
	end)

	return self
end

-- ---------------------------------------------------------------
-- TEXTBOX
-- ---------------------------------------------------------------
function Components.CreateTextbox(parent, theme, opts)
	opts = opts or {}
	local card = Components.BaseCard(parent, theme, opts.Title, nil, 54)

	local box = Util.Create("Frame", {
		BackgroundColor3 = theme.PanelTertiary,
		Size = UDim2.new(0, 170, 0, 34),
		Position = UDim2.new(1, -16, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		ZIndex = ZLayer.Base + 1,
		Parent = card,
	})
	Util.Corner(box, theme.Radius.sm)
	local boxStroke = Util.Stroke(box, theme.Stroke, 1)

	local input = Util.Create("TextBox", {
		BackgroundTransparency = 1,
		Text = opts.Default or "",
		PlaceholderText = opts.Placeholder or "Enter text...",
		Font = theme.Font,
		TextSize = 12,
		TextColor3 = theme.TextPrimary,
		PlaceholderColor3 = theme.TextTertiary,
		ClearTextOnFocus = false,
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = box,
	})
	input.Focused:Connect(function() Util.QuickTween(boxStroke, { Color = theme.Accent, Thickness = 1.5 }, 0.12) end)
	input.FocusLost:Connect(function(enterPressed)
		Util.QuickTween(boxStroke, { Color = theme.Stroke, Thickness = 1 }, 0.12)
		if opts.Callback then task.spawn(opts.Callback, input.Text, enterPressed) end
	end)

	return { Instance = card, Get = function() return input.Text end, Set = function(_, t) input.Text = t end }
end

-- ---------------------------------------------------------------
-- COLOR PICKER (HSV: hue strip + saturation/value canvas, via Overlay)
-- ---------------------------------------------------------------
function Components.CreateColorPicker(parent, theme, opts, window)
	opts = opts or {}
	local color = opts.Default or Color3.fromRGB(255, 255, 255)
	local card = Components.BaseCard(parent, theme, opts.Title, nil, 54)

	local swatch = Util.Create("TextButton", {
		BackgroundColor3 = color,
		Size = UDim2.new(0, 46, 0, 30),
		Position = UDim2.new(1, -16, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Text = "",
		AutoButtonColor = false,
		ZIndex = ZLayer.Base + 1,
		Parent = card,
	})
	Util.Corner(swatch, theme.Radius.sm)
	Util.Stroke(swatch, theme.Stroke, 1)

	local h, s, v = Color3.toHSV(color)
	local self = { Value = color, Instance = card }
	local overlay = window and window.Overlay
	local openPanel, catcher

	local function closePanel()
		if openPanel then
			local p = openPanel
			openPanel = nil
			Util.QuickTween(p, { Size = UDim2.new(p.Size.X.Scale, p.Size.X.Offset, 0, 0) }, 0.15)
			task.delay(0.15, function() p:Destroy() end)
		end
		if catcher then catcher:Destroy(); catcher = nil end
	end

	local function openPanelFn()
		if not overlay then return end
		local pos = popoutPositionBelow(swatch, 210)
		pos = UDim2.fromOffset(pos.X.Offset - 210 + swatch.AbsoluteSize.X, pos.Y.Offset)

		catcher = createBackdropCatcher(overlay, closePanel)

		local panel = Util.Create("Frame", {
			BackgroundColor3 = theme.PanelTertiary,
			Size = UDim2.new(0, 210, 0, 0),
			Position = pos,
			ClipsDescendants = true,
			ZIndex = ZLayer.Popout + 1,
			Parent = overlay,
		})
		Util.Corner(panel, theme.Radius.md)
		Util.Stroke(panel, theme.Stroke, 1)
		Util.Glow(panel, Color3.new(0, 0, 0), 0.6, 30, ZLayer.Popout)
		Util.Padding(panel, 12)
		openPanel = panel
		Util.QuickTween(panel, { Size = UDim2.new(0, 210, 0, 168) }, 0.18)

		local svCanvas = Util.Create("ImageLabel", {
			Image = "rbxassetid://4155801252",
			Size = UDim2.new(1, 0, 0, 120),
			BackgroundColor3 = Color3.fromHSV(h, 1, 1),
			ZIndex = ZLayer.Popout + 2,
			Parent = panel,
		})
		Util.Corner(svCanvas, theme.Radius.xs)
		local svCursor = Util.Create("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			Size = UDim2.new(0, 10, 0, 10),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(s, 0, 1 - v, 0),
			ZIndex = ZLayer.Popout + 3,
			Parent = svCanvas,
		})
		Util.Corner(svCursor, theme.Radius.pill)
		Util.Stroke(svCursor, Color3.new(0, 0, 0), 1)

		local hueBar = Util.Create("Frame", {
			Size = UDim2.new(1, 0, 0, 16),
			Position = UDim2.new(0, 0, 0, 130),
			ZIndex = ZLayer.Popout + 2,
			Parent = panel,
		})
		Util.Corner(hueBar, theme.Radius.pill)
		Util.Gradient(hueBar, ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
			ColorSequenceKeypoint.new(1 / 6, Color3.fromHSV(1 / 6, 1, 1)),
			ColorSequenceKeypoint.new(2 / 6, Color3.fromHSV(2 / 6, 1, 1)),
			ColorSequenceKeypoint.new(3 / 6, Color3.fromHSV(3 / 6, 1, 1)),
			ColorSequenceKeypoint.new(4 / 6, Color3.fromHSV(4 / 6, 1, 1)),
			ColorSequenceKeypoint.new(5 / 6, Color3.fromHSV(5 / 6, 1, 1)),
			ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
		}))
		local hueCursor = Util.Create("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			Size = UDim2.new(0, 4, 1, 4),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(h, 0, 0.5, 0),
			ZIndex = ZLayer.Popout + 3,
			Parent = hueBar,
		})
		Util.Corner(hueCursor, theme.Radius.xs)

		local function updateColor()
			local c = Color3.fromHSV(h, s, v)
			self.Value = c
			swatch.BackgroundColor3 = c
			svCanvas.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			if opts.Callback then task.spawn(opts.Callback, c) end
		end

		local draggingSV, draggingHue = false, false
		svCanvas.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSV = true end
		end)
		hueBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingHue = true end
		end)
		UserInputService.InputEnded:Connect(function() draggingSV = false; draggingHue = false end)
		UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
			if draggingSV and svCanvas.Parent then
				local relX = math.clamp((input.Position.X - svCanvas.AbsolutePosition.X) / svCanvas.AbsoluteSize.X, 0, 1)
				local relY = math.clamp((input.Position.Y - svCanvas.AbsolutePosition.Y) / svCanvas.AbsoluteSize.Y, 0, 1)
				s, v = relX, 1 - relY
				svCursor.Position = UDim2.new(relX, 0, relY, 0)
				updateColor()
			elseif draggingHue and hueBar.Parent then
				local relX = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
				h = relX
				hueCursor.Position = UDim2.new(relX, 0, 0.5, 0)
				updateColor()
			end
		end)
	end

	swatch.MouseButton1Click:Connect(function()
		if openPanel then closePanel() else openPanelFn() end
	end)

	return self
end

-- ---------------------------------------------------------------
-- KEYBIND
-- ---------------------------------------------------------------
function Components.CreateKeybind(parent, theme, opts)
	opts = opts or {}
	local currentKey = opts.Default or Enum.KeyCode.Unknown
	local card = Components.BaseCard(parent, theme, opts.Title, nil, 54)

	local keyBtn = Util.Create("TextButton", {
		BackgroundColor3 = theme.PanelTertiary,
		Size = UDim2.new(0, 100, 0, 32),
		Position = UDim2.new(1, -16, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Text = currentKey.Name ~= "Unknown" and currentKey.Name or "None",
		Font = theme.FontSemibold,
		TextSize = 12,
		TextColor3 = theme.TextSecondary,
		AutoButtonColor = false,
		ZIndex = ZLayer.Base + 1,
		Parent = card,
	})
	Util.Corner(keyBtn, theme.Radius.sm)
	local keyStroke = Util.Stroke(keyBtn, theme.Stroke, 1)

	local listening = false
	local self = { Value = currentKey, Instance = card }

	keyBtn.MouseButton1Click:Connect(function()
		listening = true
		keyBtn.Text = "..."
		Util.QuickTween(keyStroke, { Color = theme.Accent, Thickness = 1.5 }, 0.1)
	end)

	UserInputService.InputBegan:Connect(function(input)
		if not listening then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			currentKey = input.KeyCode
			self.Value = currentKey
			keyBtn.Text = currentKey.Name
			listening = false
			Util.QuickTween(keyStroke, { Color = theme.Stroke, Thickness = 1 }, 0.1)
			if opts.Callback then task.spawn(opts.Callback, currentKey) end
		end
	end)

	return self
end

-- ---------------------------------------------------------------
-- STATUS
-- Baris status yang bisa dipakai di dalam Section mana pun (mis.
-- "Anti-Cheat Bypass: Active", "Server: Online"). Menggunakan pill
-- yang sama dengan status di header Window supaya tampilannya
-- konsisten di seluruh UI.
-- ---------------------------------------------------------------
function Components.CreateStatus(parent, theme, opts)
	opts = opts or {}
	local card = Components.BaseCard(parent, theme, opts.Title, nil, 54)

	local pillHolder = Util.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 140, 1, 0),
		Position = UDim2.new(1, -16, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Parent = card,
	})
	Util.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = pillHolder,
	})

	local color = Util.StatusColor(theme, opts.State or "positive")
	local pill = Util.MakeStatusPill(pillHolder, theme, opts.Text or "Active", color)

	local self = { Instance = card }
	function self:Set(text, state)
		pill:Set(text, Util.StatusColor(theme, state or "positive"))
	end
	return self
end

-- ---------------------------------------------------------------
-- LABEL / SECTION HEADER / PARAGRAPH (elemen non-interaktif)
-- ---------------------------------------------------------------
function Components.CreateLabel(parent, theme, opts)
	opts = opts or {}
	local label = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = opts.Text or "",
		Font = theme.Font,
		TextSize = 13,
		TextColor3 = theme.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 20),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = parent,
	})
	return { Instance = label, Set = function(_, t) label.Text = t end }
end

function Components.CreateSectionHeader(parent, theme, title)
	local holder = Util.Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), Parent = parent })
	Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title or "Section",
		Font = theme.FontBold,
		TextSize = 12,
		TextColor3 = theme.TextTertiary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 1, 0),
		Parent = holder,
	})
	return holder
end

function Components.CreateParagraph(parent, theme, opts)
	opts = opts or {}
	local card = Util.Create("Frame", {
		BackgroundColor3 = theme.PanelSecondary,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = parent,
	})
	Util.Corner(card, theme.Radius.md)
	Util.Stroke(card, theme.Stroke, 1)
	Util.Padding(card, 16)
	Util.Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })

	Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = opts.Title or "",
		Font = theme.FontSemibold,
		TextSize = 14,
		TextColor3 = theme.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 18),
		LayoutOrder = 1,
		Parent = card,
	})
	Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = opts.Content or "",
		Font = theme.Font,
		TextSize = 13,
		TextColor3 = theme.TextSecondary,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
		Parent = card,
	})

	return { Instance = card }
end

NovaUI._Components = Components

--====================================================================
-- SECTION: SECTION (wrapper yang mengelompokkan komponen dalam sebuah Tab)
--====================================================================
local SectionObj = {}
SectionObj.__index = SectionObj

local function newSection(parent, theme, title, window)
	local self = setmetatable({ Theme = theme, Window = window, Registry = window.SearchRegistry }, SectionObj)

	self.Holder = Util.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = parent,
	})
	Util.Create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.Holder })

	if title then
		Components.CreateSectionHeader(self.Holder, theme, title)
	end

	return self
end

local function registerSearchable(self, title, instance)
	if self.Registry and title then
		table.insert(self.Registry, { Title = title:lower(), Instance = instance })
	end
end

function SectionObj:CreateButton(opts)
	local c = Components.CreateButton(self.Holder, self.Theme, opts)
	registerSearchable(self, opts and opts.Title, c.Instance)
	return c
end

function SectionObj:CreateToggle(opts)
	local c = Components.CreateToggle(self.Holder, self.Theme, opts)
	registerSearchable(self, opts and opts.Title, c.Instance)
	return c
end

function SectionObj:CreateSlider(opts)
	local c = Components.CreateSlider(self.Holder, self.Theme, opts)
	registerSearchable(self, opts and opts.Title, c.Instance)
	return c
end

function SectionObj:CreateDropdown(opts)
	local c = Components.CreateDropdown(self.Holder, self.Theme, opts, self.Window)
	registerSearchable(self, opts and opts.Title, c.Instance)
	return c
end

function SectionObj:CreateTextbox(opts)
	local c = Components.CreateTextbox(self.Holder, self.Theme, opts)
	registerSearchable(self, opts and opts.Title, c.Instance)
	return c
end

function SectionObj:CreateColorPicker(opts)
	local c = Components.CreateColorPicker(self.Holder, self.Theme, opts, self.Window)
	registerSearchable(self, opts and opts.Title, c.Instance)
	return c
end

function SectionObj:CreateKeybind(opts)
	local c = Components.CreateKeybind(self.Holder, self.Theme, opts)
	registerSearchable(self, opts and opts.Title, c.Instance)
	return c
end

-- Status bisa dipakai di section manapun, tidak hanya di header Window.
-- Contoh: Section:CreateStatus({ Title = "Server", Text = "Online", State = "positive" })
function SectionObj:CreateStatus(opts)
	local c = Components.CreateStatus(self.Holder, self.Theme, opts)
	registerSearchable(self, opts and opts.Title, c.Instance)
	return c
end

function SectionObj:CreateLabel(opts)
	return Components.CreateLabel(self.Holder, self.Theme, opts)
end

function SectionObj:CreateParagraph(opts)
	local c = Components.CreateParagraph(self.Holder, self.Theme, opts)
	registerSearchable(self, opts and opts.Title, c.Instance)
	return c
end

NovaUI._Section = SectionObj

--====================================================================
-- SECTION: TAB
-- Setiap Tab merepresentasikan satu card di navbar + satu halaman
-- konten. Window mengatur perpindahan antar-tab (lihat Window:SelectTab).
--====================================================================
local TabObj = {}
TabObj.__index = TabObj

function TabObj:CreateSection(title)
	return newSection(self.Page, self.Theme, title, self.Window)
end

NovaUI._Tab = TabObj

--====================================================================
-- SECTION: WINDOW
-- Struktur: Root (tak ter-clip, menampung shadow/glow) -> Surface
-- (ter-clip, sudut membulat, isi UI sebenarnya). Pemisahan ini
-- mencegah shadow/glow ikut terpotong oleh sudut membulat window.
--====================================================================
local Window = {}
Window.__index = Window

function Window.new(opts)
	opts = opts or {}
	local theme = NovaUI.Themes[opts.Theme or "Default"] or NovaUI.Themes.Default
	local R = theme.Radius

	local self = setmetatable({}, Window)
	self.Theme = theme
	self.Tabs = {}
	self.SearchRegistry = {}
	self.Config = Config.new(opts.ConfigName or (opts.Title or "NovaUI") .. "_Config")

	local gui = Util.Create("ScreenGui", {
		Name = "NovaUI_" .. (opts.Title or "Window"),
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
	})
	local parented = pcall(function() gui.Parent = (gethui and gethui()) or PlayerGui end)
	if not parented then gui.Parent = PlayerGui end
	self.Gui = gui

	----------------------------------------------------------------
	-- ROOT (tidak clip - wadah untuk shadow/glow + Surface) & drag target
	----------------------------------------------------------------
	local windowWidth = opts.Width or (IS_MOBILE and 380 or 960)
	local windowHeight = opts.Height or (IS_MOBILE and 560 or 600)

	local root = Util.Create("Frame", {
		Name = "Root",
		BackgroundTransparency = 1,
		Size = IS_MOBILE and UDim2.new(0.95, 0, 0.85, 0) or UDim2.new(0, windowWidth, 0, windowHeight),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Parent = gui,
	})
	self.Root = root

	Util.Glow(root, Color3.new(0, 0, 0), 0.45, 70, 0)
	Util.Glow(root, theme.Accent, 0.82, 110, -1)

	local surface = Util.Create("Frame", {
		Name = "Surface",
		BackgroundColor3 = theme.Background,
		Size = UDim2.new(1, 0, 1, 0),
		ClipsDescendants = true,
		ZIndex = ZLayer.Base,
		Parent = root,
	})
	Util.Corner(surface, R.lg)
	Util.Stroke(surface, theme.Stroke, 1)
	self.Surface = surface

	local topAccentLine = Util.Create("Frame", { -- garis aksen tipis paling atas, ikut ter-clip oleh Surface
		Name = "TopAccentLine",
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 3),
		ZIndex = ZLayer.Base + 5,
		Parent = surface,
	})
	Util.Gradient(topAccentLine, ColorSequence.new({
		ColorSequenceKeypoint.new(0, theme.AccentDim),
		ColorSequenceKeypoint.new(0.5, theme.AccentGradient),
		ColorSequenceKeypoint.new(1, theme.AccentDim),
	}))

	Util.Resizify(root, Vector2.new(720, 480), Vector2.new(1600, 1000))

	-- Overlay: lapisan paling atas untuk popout (Dropdown/ColorPicker) &
	-- backdrop klik-luar, supaya tidak pernah tertutup/terpotong oleh
	-- ScrollingFrame manapun di dalam Surface.
	self.Overlay = Util.Create("Frame", {
		Name = "Overlay",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = ZLayer.Popout,
		Parent = gui,
	})

	-- Animasi entrance: fade + scale-in.
	do
		local finalSize = root.Size
		root.Size = UDim2.new(finalSize.X.Scale, finalSize.X.Offset * 0.92, finalSize.Y.Scale, finalSize.Y.Offset * 0.92)
		surface.BackgroundTransparency = 1
		task.defer(function()
			Util.QuickTween(root, { Size = finalSize }, 0.4, Enum.EasingStyle.Back)
			Util.QuickTween(surface, { BackgroundTransparency = 0 }, 0.3)
		end)
	end

	----------------------------------------------------------------
	-- SIDEBAR / NAVBAR (kiri)
	----------------------------------------------------------------
	local sidebarWidth = 270
	local sidebar = Util.Create("Frame", {
		Name = "Sidebar",
		BackgroundColor3 = theme.PanelPrimary,
		Size = UDim2.new(0, sidebarWidth, 1, 0),
		ZIndex = ZLayer.Base,
		Parent = surface,
	})
	self.Sidebar = sidebar
	self.SidebarWidth = sidebarWidth
	self.SidebarCollapsed = false

	local brand = Util.Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 72), Parent = sidebar })
	local logo = Util.Create("Frame", {
		BackgroundColor3 = theme.Accent,
		Size = UDim2.new(0, 38, 0, 38),
		Position = UDim2.new(0, 18, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Parent = brand,
	})
	Util.Corner(logo, R.sm)
	Util.Gradient(logo, ColorSequence.new(theme.Accent, theme.AccentGradient), 45)
	Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = (opts.Title or "N"):sub(1, 1):upper(),
		Font = theme.FontBold,
		TextSize = 17,
		TextColor3 = Color3.new(1, 1, 1),
		Size = UDim2.new(1, 0, 1, 0),
		Parent = logo,
	})

	local brandText = Util.Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -100, 1, 0), Position = UDim2.new(0, 66, 0, 0), Parent = brand })
	Util.Create("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Center, Parent = brandText })
	Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = opts.Title or "NovaUI",
		Font = theme.FontBold,
		TextSize = 16,
		TextColor3 = theme.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 20),
		Parent = brandText,
	})
	Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = opts.SubTitle or "",
		Font = theme.Font,
		TextSize = 12,
		TextColor3 = theme.TextTertiary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 16),
		Parent = brandText,
	})
	self.BrandFrame = brandText

	Util.Draggify(root, brand)

	local collapseBtn = Util.Create("TextButton", {
		BackgroundTransparency = 1,
		Text = "≡",
		Font = theme.FontBold,
		TextSize = 20,
		TextColor3 = theme.TextSecondary,
		Size = UDim2.new(0, 32, 0, 32),
		Position = UDim2.new(1, -14, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Parent = brand,
	})
	collapseBtn.MouseButton1Click:Connect(function() self:ToggleSidebar() end)

	local tabList = Util.Create("ScrollingFrame", {
		Name = "TabList",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 72),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = theme.Accent,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = sidebar,
	})
	Util.Padding(tabList, 0, 14, 14, 4, 8)
	Util.Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tabList })
	self.TabList = tabList

	-- Footer sidebar: nama library + versi, dan discord (diisi developer lewat opts)
	local footerHeight = 58 + (opts.Discord and 46 or 0)
	tabList.Size = UDim2.new(1, 0, 1, -(72 + footerHeight))

	local footer = Util.Create("Frame", {
		Name = "Footer",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, footerHeight),
		Position = UDim2.new(0, 0, 1, -footerHeight),
		Parent = sidebar,
	})
	Util.Create("Frame", {
		BackgroundColor3 = theme.Stroke,
		BackgroundTransparency = 0.4,
		Size = UDim2.new(1, -28, 0, 1),
		Position = UDim2.new(0, 14, 0, 0),
		Parent = footer,
	})
	Util.Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = footer })
	Util.Padding(footer, 0, 14, 14, 12, 12)

	local libRow = Util.Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 1, Parent = footer })
	Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = opts.LibraryName or opts.Title or "NovaUI",
		Font = theme.FontBold,
		TextSize = 12,
		TextColor3 = theme.TextSecondary,
		Size = UDim2.new(1, -60, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = libRow,
	})
	local versionBadge = Util.Create("TextLabel", {
		BackgroundColor3 = theme.PanelTertiary,
		Text = opts.Version or "v1.0.0",
		Font = theme.FontSemibold,
		TextSize = 10,
		TextColor3 = theme.Accent,
		Size = UDim2.new(0, 0, 0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.new(1, 0, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Parent = libRow,
	})
	Util.Corner(versionBadge, R.pill)
	Util.Padding(versionBadge, 0, 8, 8, 0, 0)
	Util.Stroke(versionBadge, theme.Stroke, 1)

	if opts.Discord then
		local discordRow = Util.Create("TextButton", {
			BackgroundColor3 = theme.PanelSecondary,
			Size = UDim2.new(1, 0, 0, 36),
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = 2,
			Parent = footer,
		})
		Util.Corner(discordRow, R.sm)
		Util.Stroke(discordRow, theme.Stroke, 1)
		Util.Hover(discordRow, theme.PanelSecondary, theme.PanelHover)

		local discordIcon = Util.Create("Frame", {
			BackgroundColor3 = Color3.fromRGB(88, 101, 242),
			Size = UDim2.new(0, 24, 0, 24),
			Position = UDim2.new(0, 8, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Parent = discordRow,
		})
		Util.Corner(discordIcon, R.xs)
		Util.Create("TextLabel", {
			BackgroundTransparency = 1, Text = "D", Font = theme.FontBold, TextSize = 13,
			TextColor3 = Color3.new(1, 1, 1), Size = UDim2.new(1, 0, 1, 0), Parent = discordIcon,
		})
		Util.Create("TextLabel", {
			BackgroundTransparency = 1,
			Text = opts.Discord,
			Font = theme.FontSemibold,
			TextSize = 11,
			TextColor3 = theme.TextSecondary,
			Size = UDim2.new(1, -44, 1, 0),
			Position = UDim2.new(0, 40, 0, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = discordRow,
		})
		discordRow.MouseButton1Click:Connect(function()
			local copied = false
			pcall(function()
				if typeof(setclipboard) == "function" then setclipboard(opts.Discord); copied = true end
			end)
			self:Notify({ Title = "Discord", Content = copied and "Link disalin ke clipboard." or opts.Discord, Type = "Info", Duration = 3 })
		end)
	end

	----------------------------------------------------------------
	-- CONTENT PANEL (kanan)
	----------------------------------------------------------------
	local content = Util.Create("Frame", {
		Name = "Content",
		BackgroundColor3 = theme.Background,
		Size = UDim2.new(1, -sidebarWidth, 1, 0),
		Position = UDim2.new(0, sidebarWidth, 0, 0),
		ZIndex = ZLayer.Base,
		Parent = surface,
	})
	self.Content = content

	local topbar = Util.Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 62), Parent = content })
	Util.Padding(topbar, 0, 26, 26, 14, 0)

	local closeBtn = Util.Create("TextButton", {
		BackgroundColor3 = theme.PanelSecondary,
		Size = UDim2.new(0, 36, 0, 36),
		Position = UDim2.new(1, 0, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
		Text = "",
		AutoButtonColor = false,
		Parent = topbar,
	})
	Util.Corner(closeBtn, R.sm)
	Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "✕",
		Font = theme.FontBold,
		TextSize = 15,
		TextColor3 = theme.TextSecondary,
		Size = UDim2.new(1, 0, 1, 0),
		Name = "Icon",
		Parent = closeBtn,
	})
	closeBtn.MouseEnter:Connect(function()
		Util.QuickTween(closeBtn, { BackgroundColor3 = theme.Error }, 0.15)
		Util.QuickTween(closeBtn.Icon, { TextColor3 = Color3.new(1, 1, 1) }, 0.15)
	end)
	closeBtn.MouseLeave:Connect(function()
		Util.QuickTween(closeBtn, { BackgroundColor3 = theme.PanelSecondary }, 0.15)
		Util.QuickTween(closeBtn.Icon, { TextColor3 = theme.TextSecondary }, 0.15)
	end)
	closeBtn.MouseButton1Click:Connect(function() self:Close() end)

	local minimizeBtn = Util.Create("TextButton", {
		BackgroundColor3 = theme.PanelSecondary,
		Size = UDim2.new(0, 36, 0, 36),
		Position = UDim2.new(1, -46, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
		Text = "–",
		Font = theme.FontBold,
		TextSize = 17,
		TextColor3 = theme.TextSecondary,
		AutoButtonColor = false,
		Parent = topbar,
	})
	Util.Corner(minimizeBtn, R.sm)
	Util.Hover(minimizeBtn, theme.PanelSecondary, theme.PanelHover)
	minimizeBtn.MouseButton1Click:Connect(function() self:ToggleMinimize() end)

	local searchBox = Util.Create("Frame", {
		BackgroundColor3 = theme.PanelSecondary,
		Size = UDim2.new(0, 230, 0, 36),
		Position = UDim2.new(1, -102, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
		Parent = topbar,
	})
	Util.Corner(searchBox, R.sm)
	local searchStroke = Util.Stroke(searchBox, theme.Stroke, 1)
	local searchInput = Util.Create("TextBox", {
		BackgroundTransparency = 1,
		PlaceholderText = "Search components...",
		Text = "",
		Font = theme.Font,
		TextSize = 12,
		TextColor3 = theme.TextPrimary,
		PlaceholderColor3 = theme.TextTertiary,
		ClearTextOnFocus = false,
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = searchBox,
	})
	searchInput.Focused:Connect(function() Util.QuickTween(searchStroke, { Color = theme.Accent }, 0.12) end)
	searchInput.FocusLost:Connect(function() Util.QuickTween(searchStroke, { Color = theme.Stroke }, 0.12) end)
	self.SearchInput = searchInput

	local header = Util.Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 54), Position = UDim2.new(0, 0, 0, 62), Parent = content })
	Util.Padding(header, 0, 26, 26, 0, 0)

	local pageTitle = Util.Create("TextLabel", {
		BackgroundTransparency = 1, Text = "", Font = theme.FontBold, TextSize = 25, TextColor3 = theme.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(0.55, 0, 0, 30), Parent = header,
	})
	local pageSubtitle = Util.Create("TextLabel", {
		BackgroundTransparency = 1, Text = "", Font = theme.Font, TextSize = 13, TextColor3 = theme.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(0.55, 0, 0, 16), Position = UDim2.new(0, 0, 0, 30), Parent = header,
	})
	self.PageTitle, self.PageSubtitle = pageTitle, pageSubtitle

	-- Status pills (Online/Offline & Updated/Outdated) di kanan header.
	local statusRow = Util.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 230, 0, 22),
		Position = UDim2.new(1, 0, 0, 2),
		AnchorPoint = Vector2.new(1, 0),
		Parent = header,
	})
	Util.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
		Parent = statusRow,
	})

	local statusOpts = opts.Status or {}
	local isOnline = statusOpts.Online; if isOnline == nil then isOnline = true end
	local isUpdated = statusOpts.Updated; if isUpdated == nil then isUpdated = true end

	self.OnlinePill = Util.MakeStatusPill(statusRow, theme, isOnline and "ONLINE" or "OFFLINE", isOnline and theme.Success or theme.Error)
	self.UpdatePill = Util.MakeStatusPill(statusRow, theme, isUpdated and "UPDATED" or "OUTDATED", isUpdated and theme.Success or theme.Warning)

	-- Ubah status kapan saja, mis. Window:SetStatus(true, false)
	function self:SetStatus(online, updated)
		if online ~= nil then
			self.OnlinePill:Set(online and "ONLINE" or "OFFLINE", online and theme.Success or theme.Error)
		end
		if updated ~= nil then
			self.UpdatePill:Set(updated and "UPDATED" or "OUTDATED", updated and theme.Success or theme.Warning)
		end
	end

	local pageContainer = Util.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -136),
		Position = UDim2.new(0, 0, 0, 132),
		Parent = content,
	})
	self.PageContainer = pageContainer

	self.Notifications = Notification.new(gui, theme)
	self.Dialogs = Dialog.new(gui, theme)

	if opts.Watermark ~= false then
		local watermark = Util.Create("TextLabel", {
			BackgroundColor3 = theme.PanelSecondary,
			Text = "  " .. (opts.Title or "NovaUI") .. "  ",
			Font = theme.FontSemibold,
			TextSize = 12,
			TextColor3 = theme.TextSecondary,
			Size = UDim2.new(0, 0, 0, 26),
			AutomaticSize = Enum.AutomaticSize.X,
			Position = UDim2.new(0, 16, 0, 16),
			Parent = gui,
		})
		Util.Corner(watermark, R.sm)
		Util.Stroke(watermark, theme.Stroke, 1)
		self.Watermark = watermark
	end

	-- Search realtime: filter card komponen berdasarkan judul.
	searchInput:GetPropertyChangedSignal("Text"):Connect(function()
		local query = searchInput.Text:lower()
		for _, entry in ipairs(self.SearchRegistry) do
			entry.Instance.Visible = query == "" or entry.Title:find(query, 1, true) ~= nil
		end
	end)

	self.Minimized = false
	self.PrevSize = root.Size

	if IS_MOBILE then
		task.defer(function() self:ToggleSidebar() end)
	end

	return self
end

function Window:ToggleSidebar()
	self.SidebarCollapsed = not self.SidebarCollapsed
	local target = self.SidebarCollapsed and 76 or self.SidebarWidth
	Util.QuickTween(self.Sidebar, { Size = UDim2.new(0, target, 1, 0) }, 0.25)
	Util.QuickTween(self.Content, { Size = UDim2.new(1, -target, 1, 0), Position = UDim2.new(0, target, 0, 0) }, 0.25)
	self.BrandFrame.Visible = not self.SidebarCollapsed
	for _, tab in ipairs(self.Tabs) do
		tab.LabelHolder.Visible = not self.SidebarCollapsed
	end
end

function Window:ToggleMinimize()
	self.Minimized = not self.Minimized
	if self.Minimized then
		self.PrevSize = self.Root.Size
		Util.QuickTween(self.Root, { Size = UDim2.new(0, self.Root.AbsoluteSize.X, 0, 64) }, 0.25)
	else
		Util.QuickTween(self.Root, { Size = self.PrevSize }, 0.25)
	end
end

function Window:Close()
	Util.QuickTween(self.Root, { Size = UDim2.new(self.Root.Size.X.Scale, self.Root.Size.X.Offset, 0, 0) }, 0.25)
	task.delay(0.25, function() self.Gui.Enabled = false end)
end

function Window:Notify(opts)
	return self.Notifications:Push(opts)
end

function Window:Dialog(opts)
	return self.Dialogs:Open(opts)
end

function Window:CreateTab(opts)
	opts = opts or {}
	local theme = self.Theme
	local R = theme.Radius

	local card = Util.Create("TextButton", {
		BackgroundColor3 = theme.PanelSecondary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 60),
		Text = "",
		AutoButtonColor = false,
		Parent = self.TabList,
	})
	Util.Corner(card, R.md)
	local cardStroke = Util.Stroke(card, theme.Accent, 1, 1)
	local activeBar = Util.Create("Frame", {
		BackgroundColor3 = theme.Accent,
		Size = UDim2.new(0, 3, 0, 0),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Parent = card,
	})
	Util.Corner(activeBar, R.xs)

	local iconHolder = Util.Create("Frame", {
		BackgroundColor3 = theme.PanelTertiary,
		Size = UDim2.new(0, 40, 0, 40),
		Position = UDim2.new(0, 10, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Parent = card,
	})
	Util.Corner(iconHolder, R.sm)
	local iconImage = Util.Create("ImageLabel", {
		BackgroundTransparency = 1,
		Image = opts.Icon and NovaUI:GetIcon(opts.Icon) or "",
		ImageColor3 = theme.TextSecondary,
		Size = UDim2.new(0, 19, 0, 19),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Parent = iconHolder,
	})

	local labelHolder = Util.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -66, 1, 0),
		Position = UDim2.new(0, 60, 0, 0),
		Parent = card,
	})
	Util.Create("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Center, Parent = labelHolder })
	Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = opts.Title or "Tab",
		Font = theme.FontSemibold,
		TextSize = 13,
		TextColor3 = theme.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 18),
		Parent = labelHolder,
	})
	Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = opts.Subtitle or "",
		Font = theme.Font,
		TextSize = 11,
		TextColor3 = theme.TextTertiary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 15),
		Parent = labelHolder,
	})

	card.MouseEnter:Connect(function()
		if self.ActiveTab ~= card then Util.QuickTween(card, { BackgroundTransparency = 0 }, 0.15) end
	end)
	card.MouseLeave:Connect(function()
		if self.ActiveTab ~= card then Util.QuickTween(card, { BackgroundTransparency = 1 }, 0.15) end
	end)

	local page = Util.Create("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = theme.Accent,
		Visible = false,
		Parent = self.PageContainer,
	})
	Util.Padding(page, 0, 26, 26, 4, 26)
	Util.Create("UIListLayout", { Padding = UDim.new(0, 18), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })

	local tabObj = setmetatable({
		Window = self,
		Theme = theme,
		Page = page,
		Card = card,
		CardStroke = cardStroke,
		IconHolder = iconHolder,
		IconImage = iconImage,
		LabelHolder = labelHolder,
		ActiveBarInst = activeBar,
		Title = opts.Title,
		Subtitle = opts.Subtitle,
	}, TabObj)

	table.insert(self.Tabs, tabObj)
	card.MouseButton1Click:Connect(function() self:SelectTab(tabObj) end)

	if #self.Tabs == 1 then
		self:SelectTab(tabObj)
	end

	return tabObj
end

function Window:SelectTab(tabObj)
	local theme = self.Theme
	for _, t in ipairs(self.Tabs) do
		local isActive = t == tabObj
		Util.QuickTween(t.Card, { BackgroundTransparency = isActive and 0 or 1 }, 0.2)
		Util.QuickTween(t.CardStroke, { Transparency = isActive and 0.6 or 1 }, 0.2)
		Util.QuickTween(t.ActiveBarInst, { Size = UDim2.new(0, 3, 0, isActive and 30 or 0) }, 0.2)
		Util.QuickTween(t.IconHolder, { BackgroundColor3 = isActive and theme.Accent or theme.PanelTertiary }, 0.2)
		Util.QuickTween(t.IconImage, { ImageColor3 = isActive and Color3.new(1, 1, 1) or theme.TextSecondary }, 0.2)

		if isActive then
			t.Page.Visible = true
		elseif t.Page.Visible then
			t.Page.Visible = false
		end
	end

	tabObj.Page.Position = UDim2.new(0, 8, 0, 0)
	Util.QuickTween(tabObj.Page, { Position = UDim2.new(0, 0, 0, 0) }, 0.22)

	self.ActiveTab = tabObj.Card
	self.PageTitle.Text = tabObj.Title or ""
	self.PageSubtitle.Text = tabObj.Subtitle or ""
end

NovaUI._Window = Window

--====================================================================
-- SECTION: PUBLIC API
--====================================================================
function NovaUI:CreateWindow(opts)
	return Window.new(opts)
end

return NovaUI
