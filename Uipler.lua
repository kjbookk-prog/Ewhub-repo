--[[
	NovaUI - Modern Roblox UI Library
	================================================================
	Sebuah library UI dua-panel (sidebar + content panel) dengan tema
	dark modern, aksen merah, animasi halus (TweenService), dan
	komponen lengkap: Button, Toggle, Slider, Dropdown (Single/Multi),
	Textbox, ColorPicker, Keybind, Label, Section, Paragraph,
	Notification, Dialog, Tab, Window.

	Struktur file (cari header "SECTION:" untuk navigasi cepat):
		SECTION: SERVICES & CONSTANTS
		SECTION: THEME
		SECTION: UTILITIES (Create, Tween, Corner/Stroke/Shadow, Ripple, Drag, Resize)
		SECTION: ICONS
		SECTION: CONFIG (save/load, guarded utk lingkungan non-executor)
		SECTION: NOTIFICATION
		SECTION: DIALOG
		SECTION: COMPONENTS (Button, Toggle, Slider, Dropdown, Textbox,
		                     ColorPicker, Keybind, Label, Section, Paragraph)
		SECTION: TAB
		SECTION: WINDOW (sidebar, topbar, search, drag/resize/minimize)
		SECTION: PUBLIC API

	Pemakaian dasar:
		local NovaUI = loadstring(game:HttpGet("...NovaUI.lua"))()
		local Window = NovaUI:CreateWindow({
			Title = "Oxyo",
			SubTitle = "Premium Hub",
			Theme = "Default",
		})
		local Tab = Window:CreateTab({ Title = "Evade", Subtitle = "Survive Nextbots", Icon = "gamepad" })
		local Section = Tab:CreateSection("General")
		Section:CreateToggle({ Title = "Anti AFK", Default = false, Callback = function(v) end })

	================================================================
]]

local NovaUI = {}
NovaUI.__index = NovaUI
NovaUI._version = "1.0.0"

--====================================================================
-- SECTION: SERVICES & CONSTANTS
--====================================================================
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local TextService      = game:GetService("TextService")
local GuiService       = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local EASE = Enum.EasingStyle.Quint
local EASE_OUT = Enum.EasingDirection.Out

--====================================================================
-- SECTION: THEME
--====================================================================
-- Palet warna terpusat. Semua komponen membaca dari sini sehingga
-- theme baru bisa ditambahkan cukup dengan menambah entry baru.
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
	},
}

--====================================================================
-- SECTION: UTILITIES
--====================================================================
local Util = {}

-- Factory pembuat instance ringkas ala "declarative" -> mengurangi duplikasi
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
	return Util.Create("UIGradient", {
		Color = colorSequence,
		Rotation = rotation or 0,
		Parent = parent,
	})
end

-- Shadow halus menggunakan ImageLabel 9-slice (dropshadow generik)
function Util.Shadow(parent, transparency, size)
	local shadow = Util.Create("ImageLabel", {
		Name = "Shadow",
		BackgroundTransparency = 1,
		Image = "rbxassetid://6014261993",
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		ImageTransparency = transparency or 0.55,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		Size = UDim2.new(1, size or 30, 1, size or 30),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = 0,
		Parent = parent,
	})
	return shadow
end

-- Efek ripple material-design saat elemen ditekan
function Util.Ripple(button, theme)
	button.ClipsDescendants = true
	button.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local pos = input.Position
		local relX = pos.X - button.AbsolutePosition.X
		local relY = pos.Y - button.AbsolutePosition.Y
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
		task.delay(0.5, function()
			ripple:Destroy()
		end)
	end)
end

-- Hover generik: interpolasi warna background antara Normal <-> Hover
function Util.Hover(obj, normalColor, hoverColor, duration)
	obj.MouseEnter:Connect(function()
		Util.QuickTween(obj, { BackgroundColor3 = hoverColor }, duration or 0.15)
	end)
	obj.MouseLeave:Connect(function()
		Util.QuickTween(obj, { BackgroundColor3 = normalColor }, duration or 0.15)
	end)
end

-- Membuat frame draggable lewat sebuah "handle" (mis. topbar)
function Util.Draggify(frame, handle)
	handle = handle or frame
	local dragging, dragInput, startPos, startInputPos

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPos = frame.Position
			startInputPos = input.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
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

-- Membuat frame resizable lewat handle kecil di pojok kanan-bawah
function Util.Resizify(frame, minSize, maxSize)
	minSize = minSize or Vector2.new(560, 380)
	maxSize = maxSize or Vector2.new(1400, 900)

	local grip = Util.Create("Frame", {
		Name = "ResizeGrip",
		Size = UDim2.new(0, 18, 0, 18),
		Position = UDim2.new(1, -18, 1, -18),
		BackgroundTransparency = 1,
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
				if input.UserInputState == Enum.UserInputState.End then
					resizing = false
				end
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

NovaUI._Util = Util

--====================================================================
-- SECTION: ICONS
-- Table nama -> asset id. Bisa ditambah bebas. Jika nama tidak ada,
-- fallback ke bullet sederhana sehingga library tidak pernah error.
--====================================================================
NovaUI.Icons = {
	home        = "rbxassetid://10723347404",
	gamepad     = "rbxassetid://10734950309",
	settings    = "rbxassetid://10734943902",
	search      = "rbxassetid://10734950309",
	close       = "rbxassetid://10747384394",
	minimize    = "rbxassetid://10747371002",
	dice        = "rbxassetid://10723407163",
	shield      = "rbxassetid://10723407923",
	bolt        = "rbxassetid://10723406145",
	chevronDown = "rbxassetid://10709790771",
	check       = "rbxassetid://10709790644",
	discord     = "rbxassetid://10723407510",
	user        = "rbxassetid://10723365040",
	info        = "rbxassetid://10734950404",
	warning     = "rbxassetid://10734949905",
	x           = "rbxassetid://10747384394",
}

function NovaUI:GetIcon(name)
	return self.Icons[name] or self.Icons.bolt
end

--====================================================================
-- SECTION: CONFIG
-- Penyimpanan konfigurasi memakai writefile/readfile/isfile jika
-- tersedia di lingkungan eksekusi (dijaga dengan pcall), dengan
-- fallback ke penyimpanan dalam-memori supaya library tetap berjalan
-- normal di lingkungan tanpa akses filesystem (mis. Roblox Studio).
--====================================================================
local Config = {}
Config.__index = Config

local function fsAvailable()
	return typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"
end

function Config.new(name)
	local self = setmetatable({}, Config)
	self.Name = name or "NovaUI_Config"
	self.Path = self.Name .. ".json"
	self.Store = {}
	self:Load()
	return self
end

function Config:Load()
	if fsAvailable() then
		local ok, result = pcall(function()
			if isfile(self.Path) then
				return HttpService:JSONDecode(readfile(self.Path))
			end
			return {}
		end)
		self.Store = ok and result or {}
	end
end

function Config:Save()
	if fsAvailable() then
		pcall(function()
			writefile(self.Path, HttpService:JSONEncode(self.Store))
		end)
	end
end

function Config:Set(key, value)
	self.Store[key] = value
	self:Save()
end

function Config:Get(key, default)
	if self.Store[key] == nil then
		return default
	end
	return self.Store[key]
end

NovaUI._Config = Config

--====================================================================
-- SECTION: NOTIFICATION
--====================================================================
local Notification = {}
Notification.__index = Notification

function Notification.new(gui, theme)
	local self = setmetatable({}, Notification)
	self.Theme = theme
	self.Container = Util.Create("Frame", {
		Name = "NotificationContainer",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 320, 1, -40),
		Position = UDim2.new(1, -340, 0, 20),
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

-- Types: "Info", "Success", "Warning", "Error"
function Notification:Push(opts)
	opts = opts or {}
	local theme = self.Theme
	local accentByType = {
		Info = theme.Accent,
		Success = theme.Success,
		Warning = theme.Warning,
		Error = theme.Error,
	}
	local accent = accentByType[opts.Type] or theme.Accent

	local card = Util.Create("Frame", {
		BackgroundColor3 = theme.PanelSecondary,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(1, 40, 0, 0),
		ClipsDescendants = true,
	})
	Util.Corner(card, 12)
	Util.Stroke(card, theme.Stroke, 1)
	Util.Padding(card, 14)

	Util.Create("Frame", {
		BackgroundColor3 = accent,
		Size = UDim2.new(0, 3, 1, -8),
		Position = UDim2.new(0, 0, 0, 4),
		Parent = card,
	}, {}).Parent = card
	Util.Corner(card:FindFirstChildOfClass("Frame"), 4)

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

	local desc = Util.Create("TextLabel", {
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
	card.Size = UDim2.new(1, 0, 0, 0)

	-- Slide-in + fade
	card.BackgroundTransparency = 1
	title.TextTransparency = 1
	desc.TextTransparency = 1
	Util.QuickTween(card, { Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0 }, 0.35)
	Util.QuickTween(title, { TextTransparency = 0 }, 0.35)
	Util.QuickTween(desc, { TextTransparency = 0 }, 0.35)

	local duration = opts.Duration or 4.5
	task.delay(duration, function()
		if card and card.Parent then
			Util.QuickTween(card, { Position = UDim2.new(1, 40, 0, 0) }, 0.3)
			task.delay(0.3, function()
				if card then card:Destroy() end
			end)
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
	local self = setmetatable({}, Dialog)
	self.Theme = theme
	self.Gui = gui
	return self
end

function Dialog:Open(opts)
	opts = opts or {}
	local theme = self.Theme

	local backdrop = Util.Create("Frame", {
		Name = "DialogBackdrop",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 100,
		Parent = self.Gui,
	})

	local box = Util.Create("Frame", {
		BackgroundColor3 = theme.PanelSecondary,
		Size = UDim2.new(0, 360, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = 101,
		Parent = backdrop,
	})
	Util.Corner(box, 14)
	Util.Stroke(box, theme.Stroke, 1)
	Util.Shadow(box, 0.5, 60)
	Util.Padding(box, 20)

	local layout = Util.Create("UIListLayout", {
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = box,
	})

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

	local btnRow = Util.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 36),
		LayoutOrder = 3,
		Parent = box,
	})
	Util.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 10),
		Parent = btnRow,
	})

	local function closeDialog()
		Util.QuickTween(backdrop, { BackgroundTransparency = 1 }, 0.2)
		Util.QuickTween(box, { Size = UDim2.new(0, 340, 0, box.AbsoluteSize.Y) }, 0.2)
		task.delay(0.2, function() backdrop:Destroy() end)
	end

	for i, btnOpt in ipairs(opts.Buttons or { { Text = "OK", Callback = function() end } }) do
		local isAccent = btnOpt.Accent
		local btn = Util.Create("TextButton", {
			BackgroundColor3 = isAccent and theme.Accent or theme.PanelTertiary,
			Size = UDim2.new(0, 96, 1, 0),
			Text = btnOpt.Text or "OK",
			Font = theme.FontSemibold,
			TextSize = 14,
			TextColor3 = isAccent and Color3.new(1,1,1) or theme.TextPrimary,
			AutoButtonColor = false,
			Parent = btnRow,
		})
		Util.Corner(btn, 8)
		Util.Ripple(btn, theme)
		Util.Hover(btn, btn.BackgroundColor3, isAccent and theme.AccentHover or theme.PanelHover)
		btn.MouseButton1Click:Connect(function()
			if btnOpt.Callback then btnOpt.Callback() end
			closeDialog()
		end)
	end

	backdrop.BackgroundTransparency = 1
	box.Size = UDim2.new(0, 320, 0, 0)
	Util.QuickTween(backdrop, { BackgroundTransparency = 0.45 }, 0.25)
	Util.QuickTween(box, { Size = UDim2.new(0, 360, 0, box.AbsoluteSize.Y) }, 0.25, Enum.EasingStyle.Back)

	return backdrop
end

NovaUI._Dialog = Dialog

--====================================================================
-- SECTION: COMPONENTS
-- Setiap komponen adalah fungsi factory yang menerima (parent, theme, opts)
-- dan mengembalikan sebuah object dengan API :Set()/:Get() bila relevan.
-- Semua komponen berbagi "shell" (card container) yang seragam lewat
-- Components.BaseCard supaya tampilan konsisten & kode tidak berduplikasi.
--====================================================================
local Components = {}

-- Card dasar dipakai semua komponen baris-tunggal (Button/Toggle/Slider/dst)
function Components.BaseCard(parent, theme, title, subtitle, height)
	local card = Util.Create("Frame", {
		BackgroundColor3 = theme.PanelSecondary,
		Size = UDim2.new(1, 0, 0, height or 52),
		Parent = parent,
	})
	Util.Corner(card, 10)
	local stroke = Util.Stroke(card, theme.Stroke, 1)

	-- Highlight tipis di sisi atas (kesan "glass") supaya card tidak flat
	local highlight = Util.Create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.94,
		Size = UDim2.new(1, 0, 0, 1),
		Parent = card,
	})
	Util.Corner(highlight, 10)

	-- Hover: border menyala aksen + background sedikit terang, terasa hidup saat dipakai
	Util.Hover(card, theme.PanelSecondary, theme.PanelHover)
	card.MouseEnter:Connect(function()
		Util.QuickTween(stroke, { Color = theme.Accent, Transparency = 0.55 }, 0.18)
	end)
	card.MouseLeave:Connect(function()
		Util.QuickTween(stroke, { Color = theme.Stroke, Transparency = 0 }, 0.18)
	end)

	local textHolder = Util.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0.55, 0, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		Parent = card,
	})

	local titleLabel = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title or "",
		Font = theme.FontSemibold,
		TextSize = 14,
		TextColor3 = theme.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, subtitle and 0.5 or 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
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
			Size = UDim2.new(1, 0, 0.5, 0),
			Position = UDim2.new(0, 0, 0.5, 0),
			Parent = textHolder,
		})
	end

	Util.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = textHolder,
	})

	return card, titleLabel, subLabel
end

-- ---------------------------------------------------------------
-- BUTTON
-- ---------------------------------------------------------------
function Components.CreateButton(parent, theme, opts)
	opts = opts or {}
	local card = Components.BaseCard(parent, theme, opts.Title, opts.Description, 52)

	local action = Util.Create("TextButton", {
		BackgroundColor3 = theme.Accent,
		Size = UDim2.new(0, 110, 0, 32),
		Position = UDim2.new(1, -124, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Text = opts.ButtonText or "Execute",
		Font = theme.FontSemibold,
		TextSize = 13,
		TextColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Parent = card,
	})
	Util.Corner(action, 8)
	Util.Gradient(action, ColorSequence.new(theme.AccentGradient, theme.Accent), 90)
	Util.Ripple(action, theme)

	action.MouseEnter:Connect(function()
		Util.QuickTween(action, { BackgroundColor3 = theme.AccentHover }, 0.15)
		Util.QuickTween(action, { Size = UDim2.new(0, 114, 0, 33) }, 0.15)
	end)
	action.MouseLeave:Connect(function()
		Util.QuickTween(action, { BackgroundColor3 = theme.Accent }, 0.15)
		Util.QuickTween(action, { Size = UDim2.new(0, 110, 0, 32) }, 0.15)
	end)

	action.MouseButton1Click:Connect(function()
		if opts.Callback then
			task.spawn(opts.Callback)
		end
	end)

	return { Instance = card, SetText = function(_, t) action.Text = t end }
end

-- ---------------------------------------------------------------
-- TOGGLE
-- ---------------------------------------------------------------
function Components.CreateToggle(parent, theme, opts)
	opts = opts or {}
	local card = Components.BaseCard(parent, theme, opts.Title, opts.Description, 52)
	local state = opts.Default or false

	local track = Util.Create("Frame", {
		BackgroundColor3 = state and theme.Accent or theme.PanelTertiary,
		Size = UDim2.new(0, 44, 0, 24),
		Position = UDim2.new(1, -58, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Parent = card,
	})
	Util.Corner(track, 999)
	Util.Stroke(track, theme.Stroke, 1)

	local knob = Util.Create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size = UDim2.new(0, 18, 0, 18),
		Position = state and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Parent = track,
	})
	Util.Corner(knob, 999)

	local hitbox = Util.Create("TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.new(1, 0, 1, 0),
		Parent = track,
	})

	local self = { Value = state }

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

	self.Instance = card
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

	local card = Components.BaseCard(parent, theme, opts.Title, nil, 58)

	local valueLabel = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = tostring(value) .. (opts.Suffix or ""),
		Font = theme.FontSemibold,
		TextSize = 13,
		TextColor3 = theme.Accent,
		Size = UDim2.new(0, 60, 0, 18),
		Position = UDim2.new(1, -74, 0, 8),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = card,
	})

	local barBack = Util.Create("Frame", {
		BackgroundColor3 = theme.PanelTertiary,
		Size = UDim2.new(1, -28, 0, 6),
		Position = UDim2.new(0, 14, 1, -16),
		Parent = card,
	})
	Util.Corner(barBack, 999)

	local ratio = (value - min) / math.max(max - min, 1e-6)
	local barFill = Util.Create("Frame", {
		BackgroundColor3 = theme.Accent,
		Size = UDim2.new(ratio, 0, 1, 0),
		Parent = barBack,
	})
	Util.Corner(barFill, 999)

	local knob = Util.Create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size = UDim2.new(0, 14, 0, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(ratio, 0, 0.5, 0),
		Parent = barBack,
	})
	Util.Corner(knob, 999)
	Util.Stroke(knob, theme.Accent, 2)

	local self = { Value = value }

	local function setFromRatio(r, fire)
		r = math.clamp(r, 0, 1)
		local raw = min + (max - min) * r
		local stepped = math.floor(raw / increment + 0.5) * increment
		stepped = math.clamp(stepped, min, max)
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
		Size = UDim2.new(1, 20, 0, 20),
		Position = UDim2.new(0, -10, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Parent = barBack,
	})

	hitbox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			local r = (input.Position.X - barBack.AbsolutePosition.X) / barBack.AbsoluteSize.X
			setFromRatio(r, true)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local r = (input.Position.X - barBack.AbsolutePosition.X) / barBack.AbsoluteSize.X
			setFromRatio(r, true)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	function self:Set(v)
		setFromRatio((v - min) / math.max(max - min, 1e-6), false)
	end

	self.Instance = card
	return self
end

-- ---------------------------------------------------------------
-- DROPDOWN (Single & Multi select)
-- ---------------------------------------------------------------
function Components.CreateDropdown(parent, theme, opts)
	opts = opts or {}
	local options = opts.Options or {}
	local multi = opts.Multi or false
	local selected = {}

	if multi then
		for _, v in ipairs(opts.Default or {}) do selected[v] = true end
	else
		if opts.Default then selected[opts.Default] = true end
	end

	local card = Components.BaseCard(parent, theme, opts.Title, nil, 52)
	card.ClipsDescendants = false

	local function currentText()
		local list = {}
		for k, v in pairs(selected) do if v then table.insert(list, k) end end
		if #list == 0 then return opts.Placeholder or "Select..." end
		return table.concat(list, ", ")
	end

	local display = Util.Create("TextButton", {
		BackgroundColor3 = theme.PanelTertiary,
		Size = UDim2.new(0, 160, 0, 32),
		Position = UDim2.new(1, -174, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Text = "",
		AutoButtonColor = false,
		Parent = card,
	})
	Util.Corner(display, 8)
	Util.Stroke(display, theme.Stroke, 1)

	local displayLabel = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = currentText(),
		Font = theme.Font,
		TextSize = 12,
		TextColor3 = theme.TextSecondary,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -30, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		Parent = display,
	})

	local arrow = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "▾",
		Font = theme.Font,
		TextSize = 14,
		TextColor3 = theme.TextSecondary,
		Size = UDim2.new(0, 20, 1, 0),
		Position = UDim2.new(1, -24, 0, 0),
		Parent = display,
	})

	local listFrame = Util.Create("Frame", {
		BackgroundColor3 = theme.PanelTertiary,
		Size = UDim2.new(0, 160, 0, 0),
		Position = UDim2.new(1, -174, 1, 6),
		ClipsDescendants = true,
		Visible = false,
		ZIndex = 50,
		Parent = card,
	})
	Util.Corner(listFrame, 8)
	Util.Stroke(listFrame, theme.Stroke, 1)
	local listLayout = Util.Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = listFrame })
	Util.Padding(listFrame, 4)

	local open = false
	local function toggleList()
		open = not open
		listFrame.Visible = true
		local targetHeight = math.min(#options * 30 + 8, 180)
		Util.QuickTween(listFrame, { Size = UDim2.new(0, 160, 0, open and targetHeight or 0) }, 0.2)
		Util.QuickTween(arrow, { Rotation = open and 180 or 0 }, 0.2)
		if not open then
			task.delay(0.2, function() if not open then listFrame.Visible = false end end)
		end
	end

	display.MouseButton1Click:Connect(toggleList)

	for i, option in ipairs(options) do
		local optBtn = Util.Create("TextButton", {
			BackgroundColor3 = theme.PanelTertiary,
			Size = UDim2.new(1, 0, 0, 28),
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = i,
			ZIndex = 51,
			Parent = listFrame,
		})
		Util.Corner(optBtn, 6)
		local optLabel = Util.Create("TextLabel", {
			BackgroundTransparency = 1,
			Text = tostring(option),
			Font = theme.Font,
			TextSize = 12,
			TextColor3 = selected[option] and theme.Accent or theme.TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, -16, 1, 0),
			Position = UDim2.new(0, 8, 0, 0),
			ZIndex = 51,
			Parent = optBtn,
		})
		Util.Hover(optBtn, theme.PanelTertiary, theme.PanelHover)

		optBtn.MouseButton1Click:Connect(function()
			if multi then
				selected[option] = not selected[option]
				optLabel.TextColor3 = selected[option] and theme.Accent or theme.TextSecondary
			else
				selected = { [option] = true }
				for _, child in ipairs(listFrame:GetChildren()) do
					if child:IsA("TextButton") then
						child:FindFirstChildOfClass("TextLabel").TextColor3 = theme.TextSecondary
					end
				end
				optLabel.TextColor3 = theme.Accent
				toggleList()
			end
			displayLabel.Text = currentText()
			if opts.Callback then
				if multi then
					local list = {}
					for k, v in pairs(selected) do if v then table.insert(list, k) end end
					task.spawn(opts.Callback, list)
				else
					task.spawn(opts.Callback, option)
				end
			end
		end)
	end

	return {
		Instance = card,
		Get = function() return selected end,
	}
end

-- ---------------------------------------------------------------
-- TEXTBOX
-- ---------------------------------------------------------------
function Components.CreateTextbox(parent, theme, opts)
	opts = opts or {}
	local card = Components.BaseCard(parent, theme, opts.Title, nil, 52)

	local box = Util.Create("Frame", {
		BackgroundColor3 = theme.PanelTertiary,
		Size = UDim2.new(0, 160, 0, 32),
		Position = UDim2.new(1, -174, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Parent = card,
	})
	Util.Corner(box, 8)
	Util.Stroke(box, theme.Stroke, 1)

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

	input.Focused:Connect(function()
		Util.QuickTween(box, {}, 0.1)
		Util.Stroke(box, theme.Accent, 1.5)
	end)

	input.FocusLost:Connect(function(enterPressed)
		if opts.Callback then task.spawn(opts.Callback, input.Text, enterPressed) end
	end)

	return { Instance = card, Get = function() return input.Text end, Set = function(_, t) input.Text = t end }
end

-- ---------------------------------------------------------------
-- COLOR PICKER (HSV sederhana: hue strip + saturation/value canvas)
-- ---------------------------------------------------------------
function Components.CreateColorPicker(parent, theme, opts)
	opts = opts or {}
	local color = opts.Default or Color3.fromRGB(255, 255, 255)

	local card = Components.BaseCard(parent, theme, opts.Title, nil, 52)
	card.ClipsDescendants = false

	local swatch = Util.Create("TextButton", {
		BackgroundColor3 = color,
		Size = UDim2.new(0, 44, 0, 28),
		Position = UDim2.new(1, -58, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Text = "",
		AutoButtonColor = false,
		Parent = card,
	})
	Util.Corner(swatch, 6)
	Util.Stroke(swatch, theme.Stroke, 1)

	local panel = Util.Create("Frame", {
		BackgroundColor3 = theme.PanelTertiary,
		Size = UDim2.new(0, 200, 0, 0),
		Position = UDim2.new(1, -244, 1, 6),
		ClipsDescendants = true,
		Visible = false,
		ZIndex = 50,
		Parent = card,
	})
	Util.Corner(panel, 10)
	Util.Stroke(panel, theme.Stroke, 1)
	Util.Padding(panel, 10)

	local svCanvas = Util.Create("ImageLabel", {
		Image = "rbxassetid://4155801252", -- generic saturation/value gradient map
		Size = UDim2.new(1, 0, 0, 120),
		BackgroundColor3 = color,
		ZIndex = 51,
		Parent = panel,
	})
	Util.Corner(svCanvas, 6)

	local svCursor = Util.Create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size = UDim2.new(0, 10, 0, 10),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, 0, 0, 0),
		ZIndex = 52,
		Parent = svCanvas,
	})
	Util.Corner(svCursor, 999)
	Util.Stroke(svCursor, Color3.new(0,0,0), 1)

	local hueBar = Util.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 0, 130),
		ZIndex = 51,
		Parent = panel,
	})
	Util.Corner(hueBar, 999)
	Util.Gradient(hueBar, ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
		ColorSequenceKeypoint.new(1/6, Color3.fromHSV(1/6, 1, 1)),
		ColorSequenceKeypoint.new(2/6, Color3.fromHSV(2/6, 1, 1)),
		ColorSequenceKeypoint.new(3/6, Color3.fromHSV(3/6, 1, 1)),
		ColorSequenceKeypoint.new(4/6, Color3.fromHSV(4/6, 1, 1)),
		ColorSequenceKeypoint.new(5/6, Color3.fromHSV(5/6, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
	}))

	local hueCursor = Util.Create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size = UDim2.new(0, 4, 1, 4),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		ZIndex = 52,
		Parent = hueBar,
	})
	Util.Corner(hueCursor, 2)

	local h, s, v = Color3.toHSV(color)
	local self = { Value = color }

	local function updateColor()
		local c = Color3.fromHSV(h, s, v)
		self.Value = c
		swatch.BackgroundColor3 = c
		svCanvas.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		if opts.Callback then task.spawn(opts.Callback, c) end
	end

	local draggingSV, draggingHue = false, false

	svCanvas.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSV = true
		end
	end)
	hueBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingHue = true
		end
	end)
	UserInputService.InputEnded:Connect(function()
		draggingSV = false
		draggingHue = false
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if draggingSV then
			local relX = math.clamp((input.Position.X - svCanvas.AbsolutePosition.X) / svCanvas.AbsoluteSize.X, 0, 1)
			local relY = math.clamp((input.Position.Y - svCanvas.AbsolutePosition.Y) / svCanvas.AbsoluteSize.Y, 0, 1)
			s = relX
			v = 1 - relY
			svCursor.Position = UDim2.new(relX, 0, relY, 0)
			updateColor()
		elseif draggingHue then
			local relX = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
			h = relX
			hueCursor.Position = UDim2.new(relX, 0, 0.5, 0)
			updateColor()
		end
	end)

	local panelOpen = false
	swatch.MouseButton1Click:Connect(function()
		panelOpen = not panelOpen
		panel.Visible = true
		Util.QuickTween(panel, { Size = UDim2.new(0, 200, 0, panelOpen and 160 or 0) }, 0.22)
		if not panelOpen then
			task.delay(0.22, function() if not panelOpen then panel.Visible = false end end)
		end
	end)

	self.Instance = card
	return self
end

-- ---------------------------------------------------------------
-- KEYBIND
-- ---------------------------------------------------------------
function Components.CreateKeybind(parent, theme, opts)
	opts = opts or {}
	local currentKey = opts.Default or Enum.KeyCode.Unknown
	local card = Components.BaseCard(parent, theme, opts.Title, nil, 52)

	local keyBtn = Util.Create("TextButton", {
		BackgroundColor3 = theme.PanelTertiary,
		Size = UDim2.new(0, 100, 0, 30),
		Position = UDim2.new(1, -114, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Text = currentKey.Name ~= "Unknown" and currentKey.Name or "None",
		Font = theme.FontSemibold,
		TextSize = 12,
		TextColor3 = theme.TextSecondary,
		AutoButtonColor = false,
		Parent = card,
	})
	Util.Corner(keyBtn, 8)
	Util.Stroke(keyBtn, theme.Stroke, 1)

	local listening = false
	local self = { Value = currentKey }

	keyBtn.MouseButton1Click:Connect(function()
		listening = true
		keyBtn.Text = "..."
		Util.Stroke(keyBtn, theme.Accent, 1.5)
	end)

	UserInputService.InputBegan:Connect(function(input, gpe)
		if not listening then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			currentKey = input.KeyCode
			self.Value = currentKey
			keyBtn.Text = currentKey.Name
			listening = false
			Util.Stroke(keyBtn, theme.Stroke, 1)
			if opts.Callback then task.spawn(opts.Callback, currentKey) end
		end
	end)

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
	local holder = Util.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 28),
		Parent = parent,
	})
	Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title or "Section",
		Font = theme.FontBold,
		TextSize = 13,
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
	Util.Corner(card, 10)
	Util.Stroke(card, theme.Stroke, 1)
	Util.Padding(card, 14)

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

local function newSection(parent, theme, title, registry)
	local self = setmetatable({}, SectionObj)
	self.Theme = theme
	self.Registry = registry -- dipakai fitur search global

	self.Holder = Util.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = parent,
	})
	Util.Create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = self.Holder,
	})

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
	local c = Components.CreateDropdown(self.Holder, self.Theme, opts)
	registerSearchable(self, opts and opts.Title, c.Instance)
	return c
end

function SectionObj:CreateTextbox(opts)
	local c = Components.CreateTextbox(self.Holder, self.Theme, opts)
	registerSearchable(self, opts and opts.Title, c.Instance)
	return c
end

function SectionObj:CreateColorPicker(opts)
	local c = Components.CreateColorPicker(self.Holder, self.Theme, opts)
	registerSearchable(self, opts and opts.Title, c.Instance)
	return c
end

function SectionObj:CreateKeybind(opts)
	local c = Components.CreateKeybind(self.Holder, self.Theme, opts)
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
-- Setiap Tab merepresentasikan satu "card" di sidebar + satu halaman
-- konten di panel kanan. Window yang mengatur perpindahan antar-tab.
--====================================================================
local TabObj = {}
TabObj.__index = TabObj

function TabObj:CreateSection(title)
	return newSection(self.Page, self.Theme, title, self.Window.SearchRegistry)
end

NovaUI._Tab = TabObj

--====================================================================
-- SECTION: WINDOW
--====================================================================
local Window = {}
Window.__index = Window

function Window.new(opts)
	opts = opts or {}
	local themeName = opts.Theme or "Default"
	local theme = NovaUI.Themes[themeName] or NovaUI.Themes.Default

	local self = setmetatable({}, Window)
	self.Theme = theme
	self.Tabs = {}
	self.SearchRegistry = {}
	self.Config = Config.new(opts.ConfigName or (opts.Title or "NovaUI") .. "_Config")

	-- Root ScreenGui
	local gui = Util.Create("ScreenGui", {
		Name = "NovaUI_" .. (opts.Title or "Window"),
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
	})
	local ok = pcall(function()
		gui.Parent = (gethui and gethui()) or PlayerGui
	end)
	if not ok then gui.Parent = PlayerGui end
	self.Gui = gui

	-- Root window frame
	local root = Util.Create("Frame", {
		Name = "Root",
		BackgroundColor3 = theme.Background,
		Size = UDim2.new(0, opts.Width or 920, 0, opts.Height or 560),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ClipsDescendants = true,
		Parent = gui,
	})
	Util.Corner(root, 14)
	Util.Stroke(root, theme.Stroke, 1)
	Util.Shadow(root, 0.4, 80)
	self.Root = root

	-- Glow aksen lembut di belakang window supaya tidak terasa "flat"
	local accentGlow = Util.Create("ImageLabel", {
		Name = "AccentGlow",
		BackgroundTransparency = 1,
		Image = "rbxassetid://6014261993",
		ImageColor3 = theme.Accent,
		ImageTransparency = 0.82,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		Size = UDim2.new(1, 120, 1, 120),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = -1,
		Parent = root,
	})

	-- Garis aksen tipis di bagian paling atas window (ikut ter-clip oleh sudut membulat root)
	local topAccentLine = Util.Create("Frame", {
		Name = "TopAccentLine",
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 3),
		ZIndex = 5,
		Parent = root,
	})
	Util.Gradient(topAccentLine, ColorSequence.new({
		ColorSequenceKeypoint.new(0, theme.AccentDim),
		ColorSequenceKeypoint.new(0.5, theme.AccentGradient),
		ColorSequenceKeypoint.new(1, theme.AccentDim),
	}))

	if IS_MOBILE then
		root.Size = UDim2.new(0.95, 0, 0.85, 0)
	end

	Util.Resizify(root, Vector2.new(640, 420), Vector2.new(1500, 950))

	-- Animasi entrance: fade + scale-in supaya window terasa "hidup" saat dibuka
	do
		local finalSize = root.Size
		root.Size = UDim2.new(finalSize.X.Scale, finalSize.X.Offset * 0.92, finalSize.Y.Scale, finalSize.Y.Offset * 0.92)
		root.BackgroundTransparency = 1
		accentGlow.ImageTransparency = 1
		task.defer(function()
			Util.QuickTween(root, { Size = finalSize, BackgroundTransparency = 0 }, 0.4, Enum.EasingStyle.Back)
			Util.QuickTween(accentGlow, { ImageTransparency = 0.82 }, 0.5)
		end)
	end

	--------------------------------------------------------------
	-- SIDEBAR (kiri)
	--------------------------------------------------------------
	local sidebarWidth = 240
	local sidebar = Util.Create("Frame", {
		Name = "Sidebar",
		BackgroundColor3 = theme.PanelPrimary,
		Size = UDim2.new(0, sidebarWidth, 1, 0),
		Parent = root,
	})
	self.Sidebar = sidebar
	self.SidebarWidth = sidebarWidth
	self.SidebarCollapsed = false

	-- Logo + nama app
	local brand = Util.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 64),
		Parent = sidebar,
	})
	local logo = Util.Create("Frame", {
		BackgroundColor3 = theme.Accent,
		Size = UDim2.new(0, 34, 0, 34),
		Position = UDim2.new(0, 16, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Parent = brand,
	})
	Util.Corner(logo, 9)
	Util.Gradient(logo, ColorSequence.new(theme.Accent, theme.AccentGradient), 45)
	Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = (opts.Title or "N"):sub(1, 1):upper(),
		Font = theme.FontBold,
		TextSize = 16,
		TextColor3 = Color3.new(1, 1, 1),
		Size = UDim2.new(1, 0, 1, 0),
		Parent = logo,
	})

	local brandText = Util.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -66, 1, 0),
		Position = UDim2.new(0, 60, 0, 0),
		Parent = brand,
	})
	Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = opts.Title or "NovaUI",
		Font = theme.FontBold,
		TextSize = 15,
		TextColor3 = theme.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0.5, 0),
		Parent = brandText,
	})
	Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = opts.SubTitle or "Premium Hub",
		Font = theme.Font,
		TextSize = 11,
		TextColor3 = theme.Success,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0.5, 0),
		Position = UDim2.new(0, 0, 0.5, 0),
		Parent = brandText,
	})
	self.BrandFrame = brandText

	Util.Draggify(root, brand)

	-- Tombol collapse sidebar
	local collapseBtn = Util.Create("TextButton", {
		BackgroundTransparency = 1,
		Text = "≡",
		Font = theme.FontBold,
		TextSize = 18,
		TextColor3 = theme.TextSecondary,
		Size = UDim2.new(0, 28, 0, 28),
		Position = UDim2.new(1, -34, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Parent = brand,
	})

	-- Daftar tab (card list) dengan scroll otomatis
	local footerHeight = 56 + (opts.Discord and 44 or 0)
	local tabList = Util.Create("ScrollingFrame", {
		Name = "TabList",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -(72 + footerHeight)),
		Position = UDim2.new(0, 0, 0, 72),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = theme.Accent,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = sidebar,
	})
	Util.Padding(tabList, 0, 12, 12, 0, 8)
	Util.Create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tabList,
	})
	self.TabList = tabList

	collapseBtn.MouseButton1Click:Connect(function()
		self:ToggleSidebar()
	end)

	-- Footer sidebar: nama library + versi, dan discord (keduanya diisi developer lewat opts)
	local footer = Util.Create("Frame", {
		Name = "Footer",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, footerHeight),
		Position = UDim2.new(0, 0, 1, -footerHeight),
		Parent = sidebar,
	})
	Util.Create("Frame", { -- divider tipis pemisah dari daftar tab
		BackgroundColor3 = theme.Stroke,
		BackgroundTransparency = 0.4,
		Size = UDim2.new(1, -24, 0, 1),
		Position = UDim2.new(0, 12, 0, 0),
		Parent = footer,
	})
	Util.Create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = footer,
	})
	Util.Padding(footer, 0, 12, 12, 10, 10)

	-- Baris 1: nama library + badge versi
	local libRow = Util.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		LayoutOrder = 1,
		Parent = footer,
	})
	Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = opts.LibraryName or opts.Title or "NovaUI",
		Font = theme.FontBold,
		TextSize = 12,
		TextColor3 = theme.TextSecondary,
		Size = UDim2.new(1, -50, 1, 0),
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
	Util.Corner(versionBadge, 999)
	Util.Padding(versionBadge, 0, 8, 8, 0, 0)
	Util.Stroke(versionBadge, theme.Stroke, 1)

	-- Baris 2 (opsional): discord, tinggal isi opts.Discord = "discord.gg/xxxx"
	if opts.Discord then
		local discordRow = Util.Create("TextButton", {
			BackgroundColor3 = theme.PanelSecondary,
			Size = UDim2.new(1, 0, 0, 34),
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = 2,
			Parent = footer,
		})
		Util.Corner(discordRow, 8)
		Util.Stroke(discordRow, theme.Stroke, 1)
		Util.Hover(discordRow, theme.PanelSecondary, theme.PanelHover)

		local discordIcon = Util.Create("Frame", {
			BackgroundColor3 = Color3.fromRGB(88, 101, 242), -- warna khas Discord
			Size = UDim2.new(0, 22, 0, 22),
			Position = UDim2.new(0, 8, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Parent = discordRow,
		})
		Util.Corner(discordIcon, 6)
		Util.Create("TextLabel", {
			BackgroundTransparency = 1,
			Text = "D",
			Font = theme.FontBold,
			TextSize = 12,
			TextColor3 = Color3.new(1, 1, 1),
			Size = UDim2.new(1, 0, 1, 0),
			Parent = discordIcon,
		})

		Util.Create("TextLabel", {
			BackgroundTransparency = 1,
			Text = opts.Discord,
			Font = theme.FontSemibold,
			TextSize = 11,
			TextColor3 = theme.TextSecondary,
			Size = UDim2.new(1, -42, 1, 0),
			Position = UDim2.new(0, 38, 0, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = discordRow,
		})

		discordRow.MouseButton1Click:Connect(function()
			local copied = false
			pcall(function()
				if typeof(setclipboard) == "function" then
					setclipboard(opts.Discord)
					copied = true
				end
			end)
			self:Notify({
				Title = "Discord",
				Content = copied and "Link disalin ke clipboard." or opts.Discord,
				Type = "Info",
				Duration = 3,
			})
		end)
	end

	--------------------------------------------------------------
	-- CONTENT PANEL (kanan)
	--------------------------------------------------------------
	local content = Util.Create("Frame", {
		Name = "Content",
		BackgroundColor3 = theme.Background,
		Size = UDim2.new(1, -sidebarWidth, 1, 0),
		Position = UDim2.new(0, sidebarWidth, 0, 0),
		Parent = root,
	})
	self.Content = content

	-- Topbar: search, close
	local topbar = Util.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 56),
		Parent = content,
	})
	Util.Padding(topbar, 0, 24, 24, 12, 0)

	local searchBox = Util.Create("Frame", {
		BackgroundColor3 = theme.PanelSecondary,
		Size = UDim2.new(0, 240, 0, 32),
		Position = UDim2.new(1, -276, 0, 0),
		Parent = topbar,
	})
	Util.Corner(searchBox, 8)
	Util.Stroke(searchBox, theme.Stroke, 1)
	local searchInput = Util.Create("TextBox", {
		BackgroundTransparency = 1,
		PlaceholderText = "Search...",
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
	self.SearchInput = searchInput

	local closeBtn = Util.Create("TextButton", {
		BackgroundColor3 = theme.PanelSecondary,
		Size = UDim2.new(0, 32, 0, 32),
		Position = UDim2.new(1, -32, 0, 0),
		Text = "✕",
		Font = theme.FontBold,
		TextSize = 14,
		TextColor3 = theme.TextSecondary,
		AutoButtonColor = false,
		Parent = topbar,
	})
	Util.Corner(closeBtn, 8)
	Util.Hover(closeBtn, theme.PanelSecondary, theme.Error)
	closeBtn.MouseButton1Click:Connect(function() self:Close() end)

	local minimizeBtn = Util.Create("TextButton", {
		BackgroundColor3 = theme.PanelSecondary,
		Size = UDim2.new(0, 32, 0, 32),
		Position = UDim2.new(1, -70, 0, 0),
		Text = "–",
		Font = theme.FontBold,
		TextSize = 16,
		TextColor3 = theme.TextSecondary,
		AutoButtonColor = false,
		Parent = topbar,
	})
	Util.Corner(minimizeBtn, 8)
	Util.Hover(minimizeBtn, theme.PanelSecondary, theme.PanelHover)
	minimizeBtn.MouseButton1Click:Connect(function() self:ToggleMinimize() end)

	-- Judul halaman + subtitle + status
	local header = Util.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 56),
		Position = UDim2.new(0, 0, 0, 56),
		Parent = content,
	})
	Util.Padding(header, 0, 24, 24, 0, 0)

	local pageTitle = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "",
		Font = theme.FontBold,
		TextSize = 26,
		TextColor3 = theme.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(0.6, 0, 0, 32),
		Parent = header,
	})
	local pageSubtitle = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "",
		Font = theme.Font,
		TextSize = 13,
		TextColor3 = theme.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(0.6, 0, 0, 18),
		Position = UDim2.new(0, 0, 0, 32),
		Parent = header,
	})

	-- Baris status: dua "pill" (badge berlatar warna) -> Online/Offline & Updated/Outdated
	local statusRow = Util.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 220, 0, 22),
		Position = UDim2.new(1, -220, 0, 2),
		Parent = header,
	})
	Util.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
		Parent = statusRow,
	})

	-- Factory pill kecil dipakai untuk kedua badge (menghindari duplikasi)
	local function makeStatusPill(text, color)
		local pill = Util.Create("Frame", {
			BackgroundColor3 = color,
			BackgroundTransparency = 0.85,
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Parent = statusRow,
		})
		Util.Corner(pill, 999)
		Util.Stroke(pill, color, 1, 0.5)
		Util.Padding(pill, 0, 10, 10, 0, 0)

		local dot = Util.Create("Frame", {
			BackgroundColor3 = color,
			Size = UDim2.new(0, 7, 0, 7),
			Position = UDim2.new(0, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Parent = pill,
		})
		Util.Corner(dot, 999)
		-- Glow halus di sekitar dot untuk kesan "online" yang hidup
		local dotGlow = Util.Create("ImageLabel", {
			BackgroundTransparency = 1,
			Image = "rbxassetid://6014261993",
			ImageColor3 = color,
			ImageTransparency = 0.4,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(49, 49, 450, 450),
			Size = UDim2.new(0, 22, 0, 22),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ZIndex = dot.ZIndex - 1,
			Parent = dot,
		})

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

		-- Denyut lembut pada dot supaya terasa "live"
		task.spawn(function()
			while dot.Parent do
				Util.QuickTween(dotGlow, { ImageTransparency = 0.75 }, 0.9)
				task.wait(0.9)
				if not dot.Parent then break end
				Util.QuickTween(dotGlow, { ImageTransparency = 0.4 }, 0.9)
				task.wait(0.9)
			end
		end)

		return pill, label, dot
	end

	local statusOpts = opts.Status or {}
	local isOnline = statusOpts.Online
	if isOnline == nil then isOnline = true end
	local isUpdated = statusOpts.Updated
	if isUpdated == nil then isUpdated = true end

	local onlinePill, onlineLabel = makeStatusPill(isOnline and "ONLINE" or "OFFLINE", isOnline and theme.Success or theme.Error)
	local updatePill, updateLabel = makeStatusPill(isUpdated and "UPDATED" or "OUTDATED", isUpdated and theme.Success or theme.Warning)

	self.PageTitle, self.PageSubtitle = pageTitle, pageSubtitle
	self.OnlinePill, self.OnlineLabel = onlinePill, onlineLabel
	self.UpdatePill, self.UpdateLabel = updatePill, updateLabel

	-- Ubah status online/update kapan saja, mis. Window:SetStatus(true, false)
	function self:SetStatus(online, updated)
		if online ~= nil then
			local c = online and theme.Success or theme.Error
			onlineLabel.Text = online and "ONLINE" or "OFFLINE"
			onlineLabel.TextColor3 = c
			onlinePill.BackgroundColor3 = c
			onlinePill.UIStroke.Color = c
		end
		if updated ~= nil then
			local c = updated and theme.Success or theme.Warning
			updateLabel.Text = updated and "UPDATED" or "OUTDATED"
			updateLabel.TextColor3 = c
			updatePill.BackgroundColor3 = c
			updatePill.UIStroke.Color = c
		end
	end

	-- Container halaman (tempat semua Tab.Page berada, hanya 1 yang Visible)
	local pageContainer = Util.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -128),
		Position = UDim2.new(0, 0, 0, 120),
		Parent = content,
	})
	self.PageContainer = pageContainer

	-- Notification & Dialog subsystem
	self.Notifications = Notification.new(gui, theme)
	self.Dialogs = Dialog.new(gui, theme)

	-- Watermark (opsional)
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
		Util.Corner(watermark, 8)
		Util.Stroke(watermark, theme.Stroke, 1)
		self.Watermark = watermark
	end

	-- Realtime search: filter card komponen berdasarkan judul
	searchInput:GetPropertyChangedSignal("Text"):Connect(function()
		local query = searchInput.Text:lower()
		for _, entry in ipairs(self.SearchRegistry) do
			local matches = query == "" or entry.Title:find(query, 1, true) ~= nil
			entry.Instance.Visible = matches
		end
	end)

	self.Minimized = false
	self.PrevSize = root.Size

	return self
end

function Window:ToggleSidebar()
	self.SidebarCollapsed = not self.SidebarCollapsed
	local target = self.SidebarCollapsed and 72 or self.SidebarWidth
	Util.QuickTween(self.Sidebar, { Size = UDim2.new(0, target, 1, 0) }, 0.25)
	Util.QuickTween(self.Content, {
		Size = UDim2.new(1, -target, 1, 0),
		Position = UDim2.new(0, target, 0, 0),
	}, 0.25)
	Util.QuickTween(self.BrandFrame, { GroupTransparency = self.SidebarCollapsed and 1 or 0 }, 0.2)
	self.BrandFrame.Visible = not self.SidebarCollapsed
	for _, tab in pairs(self.Tabs) do
		if tab.LabelHolder then
			tab.LabelHolder.Visible = not self.SidebarCollapsed
		end
	end
end

function Window:ToggleMinimize()
	self.Minimized = not self.Minimized
	if self.Minimized then
		self.PrevSize = self.Root.Size
		Util.QuickTween(self.Root, { Size = UDim2.new(0, self.Root.AbsoluteSize.X, 0, 56) }, 0.25)
	else
		Util.QuickTween(self.Root, { Size = self.PrevSize }, 0.25)
	end
end

function Window:Close()
	Util.QuickTween(self.Root, { Size = UDim2.new(self.Root.Size.X.Scale, self.Root.Size.X.Offset, 0, 0) }, 0.25)
	task.delay(0.25, function()
		self.Gui.Enabled = false
	end)
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

	-- Card di sidebar
	local card = Util.Create("TextButton", {
		BackgroundColor3 = theme.PanelSecondary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 56),
		Text = "",
		AutoButtonColor = false,
		Parent = self.TabList,
	})
	Util.Corner(card, 10)
	local cardStroke = Util.Stroke(card, theme.Accent, 1, 1)
	local activeBar = Util.Create("Frame", {
		BackgroundColor3 = theme.Accent,
		Size = UDim2.new(0, 3, 0, 0),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Parent = card,
	})
	Util.Corner(activeBar, 2)

	local iconHolder = Util.Create("Frame", {
		BackgroundColor3 = theme.PanelTertiary,
		Size = UDim2.new(0, 36, 0, 36),
		Position = UDim2.new(0, 10, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Parent = card,
	})
	Util.Corner(iconHolder, 8)
	local iconImage = Util.Create("ImageLabel", {
		BackgroundTransparency = 1,
		Image = opts.Icon and NovaUI:GetIcon(opts.Icon) or "",
		ImageColor3 = theme.TextSecondary,
		Size = UDim2.new(0, 18, 0, 18),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Parent = iconHolder,
	})

	local labelHolder = Util.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -66, 1, 0),
		Position = UDim2.new(0, 56, 0, 0),
		Parent = card,
	})
	Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = opts.Title or "Tab",
		Font = theme.FontSemibold,
		TextSize = 13,
		TextColor3 = theme.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0.55, 0),
		Parent = labelHolder,
	})
	Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = opts.Subtitle or "",
		Font = theme.Font,
		TextSize = 11,
		TextColor3 = theme.TextTertiary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0.45, 0),
		Position = UDim2.new(0, 0, 0.55, 0),
		Parent = labelHolder,
	})
	Util.Create("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, VerticalAlignment = Enum.VerticalAlignment.Center, Parent = labelHolder })

	card.MouseEnter:Connect(function()
		if self.ActiveTab ~= card then
			Util.QuickTween(card, { BackgroundTransparency = 0 }, 0.15)
		end
	end)
	card.MouseLeave:Connect(function()
		if self.ActiveTab ~= card then
			Util.QuickTween(card, { BackgroundTransparency = 1 }, 0.15)
		end
	end)

	-- Halaman konten milik tab ini
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
	Util.Padding(page, 0, 24, 24, 0, 24)
	Util.Create("UIListLayout", {
		Padding = UDim.new(0, 14),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = page,
	})

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

	card.MouseButton1Click:Connect(function()
		self:SelectTab(tabObj)
	end)

	-- Tab pertama otomatis aktif
	if #self.Tabs == 1 then
		self:SelectTab(tabObj)
	end

	return tabObj
end

function Window:SelectTab(tabObj)
	for _, t in ipairs(self.Tabs) do
		local isActive = t == tabObj
		Util.QuickTween(t.Card, { BackgroundTransparency = isActive and 0 or 1 }, 0.2)
		Util.QuickTween(t.CardStroke, { Transparency = isActive and 0.6 or 1 }, 0.2)
		Util.QuickTween(t.ActiveBarInst, { Size = UDim2.new(0, 3, 0, isActive and 28 or 0) }, 0.2)
		Util.QuickTween(t.IconHolder, { BackgroundColor3 = isActive and self.Theme.Accent or self.Theme.PanelTertiary }, 0.2)
		Util.QuickTween(t.IconImage, { ImageColor3 = isActive and Color3.new(1, 1, 1) or self.Theme.TextSecondary }, 0.2)

		if isActive then
			t.Page.Visible = true
		elseif t.Page.Visible and t ~= tabObj then
			t.Page.Visible = false
		end
	end

	-- Fade-in halus (slide kecil) untuk halaman yang baru dibuka
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
