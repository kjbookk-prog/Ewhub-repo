--[[
	================================================================
	 EWEHUB â€” UI SHELL (versi sederhana, standar)
	 Dibuat oleh: Asep

	 - Hanya berisi: Sidebar (search + daftar game) dan
	   panel detail (icon, judul, tagline, status, tombol Execute).
	 - Tidak ada simbol Unicode dekoratif (panah/emoji/bintang) supaya
	   tidak muncul karakter aneh di beberapa client.
	 - Tombol Execute TIDAK berisi script apapun â€” cuma memanggil
	   Callback kosong (OnExecute) yang kamu isi sendiri.
	 ================================================================
]]

local TweenService = game:GetService("TweenService")
local Players       = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local Theme = {
	Background = Color3.fromRGB(10, 10, 10),
	Panel      = Color3.fromRGB(16, 16, 16),
	PanelLight = Color3.fromRGB(24, 24, 24),
	Card       = Color3.fromRGB(20, 20, 20),
	CardActive = Color3.fromRGB(30, 20, 20),
	Stroke     = Color3.fromRGB(36, 36, 36),
	Accent     = Color3.fromRGB(0, 255, 140),
	AccentRed  = Color3.fromRGB(220, 60, 60),
	Text       = Color3.fromRGB(235, 235, 235),
	SubText    = Color3.fromRGB(140, 140, 140),
}

local FastTween = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function Tween(obj, info, props) local t = TweenService:Create(obj, info, props) t:Play() return t end
local function New(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do inst[k] = v end
	for _, c in ipairs(children or {}) do c.Parent = inst end
	return inst
end
local function Corner(r) return New("UICorner", { CornerRadius = UDim.new(0, r or 8) }) end
local function Stroke(color, thick) return New("UIStroke", { Color = color or Theme.Stroke, Thickness = thick or 1 }) end

local EWEHUB = {}
EWEHUB.__index = EWEHUB

--============================================================
-- CreateHub
--============================================================
function EWEHUB.new(config)
	config = config or {}
	local self = setmetatable({}, EWEHUB)
	self.Games = {}

	local guiName = "EWEHUB_Hub"
	local old = PlayerGui:FindFirstChild(guiName)
	if old then old:Destroy() end

	local ScreenGui = New("ScreenGui", {
		Name = guiName, ResetOnSpawn = false, IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
		Parent = PlayerGui,
	})

	local Main = New("Frame", {
		Size = UDim2.new(0, 860, 0, 520),
		Position = UDim2.new(0.5, -430, 0.5, -260),
		BackgroundColor3 = Theme.Background,
		ClipsDescendants = true,
		Parent = ScreenGui,
	}, { Corner(12), Stroke(Theme.Stroke, 1) })

	--------------------------------------------------------------
	-- TOP BAR (judul + tombol X, selalu kelihatan)
	--------------------------------------------------------------
	local TopBar = New("Frame", {
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = Theme.Panel,
		Parent = Main,
	}, { Corner(12) })
	New("Frame", {
		Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12),
		BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Parent = TopBar,
	})

	New("TextLabel", {
		Text = config.Name or "EWEHUB",
		Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Theme.Text,
		BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0, 0), Size = UDim2.new(1, -60, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar,
	})

	local CloseBtn = New("TextButton", {
		Text = "X", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.SubText,
		BackgroundColor3 = Theme.PanelLight, Size = UDim2.new(0, 30, 0, 30),
		Position = UDim2.new(1, -40, 0.5, -15), AutoButtonColor = false, Parent = TopBar,
	}, { Corner(8) })
	CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn, FastTween, { BackgroundColor3 = Theme.AccentRed }) end)
	CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn, FastTween, { BackgroundColor3 = Theme.PanelLight }) end)
	CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

	--------------------------------------------------------------
	-- SIDEBAR KIRI
	--------------------------------------------------------------
	local Sidebar = New("Frame", {
		Size = UDim2.new(0, 280, 1, -46), Position = UDim2.new(0, 0, 0, 46),
		BackgroundColor3 = Theme.Panel, Parent = Main,
	})

	local SearchBox = New("TextBox", {
		PlaceholderText = "Search...", Text = "",
		Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.Text, PlaceholderColor3 = Theme.SubText,
		BackgroundColor3 = Theme.PanelLight,
		Size = UDim2.new(1, -32, 0, 34), Position = UDim2.new(0, 16, 0, 16),
		ClearTextOnFocus = false, Parent = Sidebar,
	}, { Corner(8), Stroke() })
	New("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = SearchBox })

	local GameList = New("ScrollingFrame", {
		Position = UDim2.new(0, 16, 0, 62), Size = UDim2.new(1, -32, 1, -78),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent,
		CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = Sidebar,
	})
	New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = GameList })

	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local query = SearchBox.Text:lower()
		for _, game in pairs(self.Games) do
			game.CardFrame.Visible = (query == "" or game.Name:lower():find(query, 1, true) ~= nil)
		end
	end)

	--------------------------------------------------------------
	-- PANEL KANAN (DETAIL)
	--------------------------------------------------------------
	local ContentArea = New("Frame", {
		Position = UDim2.new(0, 280, 0, 46), Size = UDim2.new(1, -280, 1, -46),
		BackgroundColor3 = Theme.Background, Parent = Main,
	})

	local EmptyState = New("TextLabel", {
		Text = "Pilih game di sebelah kiri untuk melihat detail",
		Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Theme.SubText,
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = ContentArea,
	})

	local DetailPanel = New("Frame", {
		Size = UDim2.new(1, -64, 1, -48), Position = UDim2.new(0, 32, 0, 24),
		BackgroundTransparency = 1, Visible = false, Parent = ContentArea,
	})

	local TitleRow = New("Frame", { Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, Parent = DetailPanel })
	local DetailIcon = New("TextLabel", {
		Size = UDim2.new(0, 50, 0, 50), BackgroundColor3 = Theme.PanelLight,
		Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = Theme.Accent,
		Text = "?", Parent = TitleRow,
	}, { Corner(10), Stroke(Theme.Accent, 2) })
	local DetailTitle = New("TextLabel", {
		Font = Enum.Font.GothamBold, TextSize = 28, TextColor3 = Theme.Text,
		BackgroundTransparency = 1, Position = UDim2.new(0, 62, 0, 0), Size = UDim2.new(1, -62, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = TitleRow,
	})

	local Tagline = New("TextLabel", {
		Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Theme.SubText,
		BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 62), Size = UDim2.new(1, 0, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = DetailPanel,
	})

	local StatusRow = New("Frame", { Position = UDim2.new(0, 0, 0, 92), Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Parent = DetailPanel })
	local StatusDot = New("Frame", { Size = UDim2.new(0, 9, 0, 9), Position = UDim2.new(0, 0, 0.5, -4.5), BackgroundColor3 = Theme.Accent, Parent = StatusRow }, { Corner(5) })
	local StatusLabel = New("TextLabel", {
		Text = "ONLINE", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.Accent,
		BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0, 0), Size = UDim2.new(0, 150, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = StatusRow,
	})

	-- Tombol Execute â€” TIDAK berisi script apapun
	local ExecuteBtn = New("TextButton", {
		Text = "EXECUTE",
		Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = Theme.Text,
		BackgroundColor3 = Theme.AccentRed,
		Size = UDim2.new(1, 0, 0, 48), Position = UDim2.new(0, 0, 0, 124),
		AutoButtonColor = false, Parent = DetailPanel,
	}, { Corner(10) })
	ExecuteBtn.MouseEnter:Connect(function() Tween(ExecuteBtn, FastTween, { BackgroundColor3 = Color3.fromRGB(240, 90, 90) }) end)
	ExecuteBtn.MouseLeave:Connect(function() Tween(ExecuteBtn, FastTween, { BackgroundColor3 = Theme.AccentRed }) end)

	self.ScreenGui, self.Main, self.GameList = ScreenGui, Main, GameList
	self.DetailPanel, self.EmptyState = DetailPanel, EmptyState
	self.DetailIcon, self.DetailTitle, self.Tagline = DetailIcon, DetailTitle, Tagline
	self.StatusDot, self.StatusLabel, self.ExecuteBtn = StatusDot, StatusLabel, ExecuteBtn

	return self
end

--============================================================
-- AddGame
-- config = { Name, Category, Tagline, Status ("online"/"offline"), OnExecute = function() end }
--============================================================
function EWEHUB:AddGame(config)
	config = config or {}
	local hub = self

	local Card = New("TextButton", {
		Text = "", BackgroundColor3 = Theme.Card, Size = UDim2.new(1, 0, 0, 72),
		AutoButtonColor = false, Parent = self.GameList,
	}, { Corner(10), Stroke() })

	local initial = (config.Name or "G"):sub(1, 1):upper()
	local Icon = New("TextLabel", {
		Size = UDim2.new(0, 48, 0, 48), Position = UDim2.new(0, 12, 0.5, -24),
		BackgroundColor3 = Theme.PanelLight, Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = Theme.Accent,
		Text = initial, Parent = Card,
	}, { Corner(10) })

	New("TextLabel", {
		Text = config.Name or "Game", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.Text,
		BackgroundTransparency = 1, Position = UDim2.new(0, 70, 0, 10), Size = UDim2.new(1, -82, 0, 18),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = Card,
	})
	New("TextLabel", {
		Text = config.Category or "", Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Theme.AccentRed,
		BackgroundTransparency = 1, Position = UDim2.new(0, 70, 0, 28), Size = UDim2.new(1, -82, 0, 14),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = Card,
	})
	New("TextLabel", {
		Text = config.Tagline or "", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.SubText,
		BackgroundTransparency = 1, Position = UDim2.new(0, 70, 0, 44), Size = UDim2.new(1, -82, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = Card,
	})

	local gameEntry = { Name = config.Name or "Game", CardFrame = Card, Config = config }
	table.insert(self.Games, gameEntry)

	local function SelectThisGame()
		for _, g in ipairs(self.Games) do
			Tween(g.CardFrame, FastTween, { BackgroundColor3 = Theme.Card })
		end
		Tween(Card, FastTween, { BackgroundColor3 = Theme.CardActive })

		hub.EmptyState.Visible = false
		hub.DetailPanel.Visible = true
		hub.DetailIcon.Text = initial
		hub.DetailTitle.Text = config.Name or "Game"
		hub.Tagline.Text = config.Tagline or ""

		local isOnline = (config.Status or "online") == "online"
		hub.StatusDot.BackgroundColor3 = isOnline and Theme.Accent or Theme.SubText
		hub.StatusLabel.Text = isOnline and "ONLINE" or "OFFLINE"
		hub.StatusLabel.TextColor3 = isOnline and Theme.Accent or Theme.SubText

		if hub._executeConn then hub._executeConn:Disconnect() end
		hub._executeConn = hub.ExecuteBtn.MouseButton1Click:Connect(function()
			Tween(hub.ExecuteBtn, TweenInfo.new(0.08), { BackgroundColor3 = Theme.Accent })
			task.delay(0.12, function() Tween(hub.ExecuteBtn, FastTween, { BackgroundColor3 = Theme.AccentRed }) end)
			if config.OnExecute then task.spawn(config.OnExecute) end -- <-- kamu isi sendiri
		end)
	end

	Card.MouseButton1Click:Connect(SelectThisGame)
	Card.MouseEnter:Connect(function() Tween(Card, FastTween, { BackgroundColor3 = Theme.CardActive }) end)
	Card.MouseLeave:Connect(function() Tween(Card, FastTween, { BackgroundColor3 = Theme.Card }) end)
	gameEntry.Select = SelectThisGame
	return gameEntry
end

return EWEHUB
