local UserInputService = game:GetService 'UserInputService'

local function Show(self)
	return function()
		self.Instance.Visible = true
		self:OnShown()
	end
end

local function Move(self)
	return function(X: number, Y: number)
		local WasHidden = not self.Instance.Visible
		self.Instance.Visible = true

		if WasHidden then self:OnShown() end

		self:OnMoved(UDim2.fromOffset(X, Y))
	end
end

local function Hide(self)
	return function()
		self.Instance.Visible = false
		self:OnHidden()
	end
end

local function Connect(self: ToolTip, Gui: GuiObject)
	self.Connections[Gui] = {
		Enter = Gui.MouseEnter:Connect(self.Show),
		Moved = Gui.MouseMoved:Connect(self.Move),
		Leave = Gui.MouseLeave:Connect(self.Hide),
		Destroying = Gui.Destroying:Connect(function()
			self:Remove(Gui)
		end),
	}
end

local function Disconnect(self: ToolTip, Gui: GuiObject)
	local Connections = self.Connections[Gui]
	Connections.Enter:Disconnect()
	Connections.Moved:Disconnect()
	Connections.Leave:Disconnect()
	Connections.Destroying:Disconnect()
end

local ToolTip = {}
ToolTip.__index = ToolTip

function ToolTip.Anchor(self: ToolTip, Value: UDim2?): UDim2 --* should be able to dynamically change the tooltip
	if Value then self.Instance.AnchorPoint = Value end
	return self.Instance.AnchorPoint
end

function ToolTip.Offset(self: ToolTip, Value: UDim2?): UDim2
	if Value then self.Offset = Value end
	return self.Offset
end

function ToolTip.IsEnabled(self: ToolTip)
	return next(self.Connections) ~= nil
end

function ToolTip.Enable(self: ToolTip)
	if self:IsEnabled() then return end

	for Gui in self.Guis do
		Connect(self, Gui)
	end
end

function ToolTip.Disable(self: ToolTip)
	if not self:IsEnabled() then return end

	self.Instance.Visible = false

	for _, Connection in self.Connections do
		Disconnect(self, Connection)
	end

	table.clear(self.Connections)
end

function ToolTip.Add(self: ToolTip, Gui: GuiObject)
	if self.Guis[Gui] then return end

	self.Guis[Gui] = true

	if not self:IsEnabled() then return end

	Connect(self, Gui)
end

function ToolTip.Remove(self: ToolTip, Gui: GuiObject)
	if not self.Guis[Gui] then return end

	if self:IsEnabled() then Disconnect(self, Gui) end

	self.Guis[Gui] = nil
end

function ToolTip.Update(self: ToolTip)
	local MousePosition = UserInputService:GetMouseLocation()
	self.Instance.Position = UDim2.fromOffset(MousePosition.X + self.Offset.X, MousePosition.Y + self.Offset.Y)
	self:OnUpdate(self.Instance.Position)
end

function ToolTip.Destroy(self: ToolTip)
	self:Disable()
	self.Instance:Destroy()
end

function ToolTip.OnShown(self: ToolTip) end
function ToolTip.OnMoved(self: ToolTip, Position: UDim2) end
function ToolTip.OnHidden(self: ToolTip) end
function ToolTip.OnUpdate(self: ToolTip, Position: UDim2) end

local TextToolTip = table.clone(ToolTip)
TextToolTip.__index = TextToolTip

function TextToolTip.Text(self: TextToolTip, Value: string): string
	if Value then self.Text = Value end
	return self.Text
end

local Module = {}

do
	local textLabel = Instance.new 'TextLabel'
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeTransparency = 0
	textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	textLabel.TextScaled = true

	Module.DefaultTextLabel = textLabel
end

function Module.fromGui(GuiObject: GuiObject, Offset: Vector2, Anchor: Vector2)
	local self = {
		Instance = GuiObject,
		Offset = UDim2.fromOffset(Offset.X, Offset.Y),
		Anchor = UDim2.fromScale(Anchor.X, Anchor.Y),
		Connections = {},
		Guis = {},
	}

	self.Show = Show(self)
	self.Move = Move(self)
	self.Hide = Hide(self)

	return setmetatable(self, ToolTip)
end

function Module.fromText(Text: string, Offset: Vector2, Anchor: Vector2)
	local TextInstance = Module.DefaultTextLabel:Clone()
	TextInstance.Text = Text

	local self = {
		Instance = TextInstance,
		Offset = UDim2.fromOffset(Offset.X, Offset.Y),
		Anchor = UDim2.fromScale(Anchor.X, Anchor.Y),
		Connections = {},
		Guis = {},
		Text = Text,
	}

	self.Show = Show(self)
	self.Move = Move(self)
	self.Hide = Hide(self)

	return setmetatable(self, TextToolTip)
end

export type ToolTip = typeof(Module.fromGui(Instance.new 'Frame', Vector2.new(), Vector2.new()))
export type TextToolTip = typeof(Module.fromText('', Vector2.new(), Vector2.new()))

return Module
