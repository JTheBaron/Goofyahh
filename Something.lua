local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local HttpService = game:GetService("HttpService")

local OrionLib = {
    Elements = {},
    ThemeObjects = {},
    Connections = {},
    Flags = {},
    Themes = {
        Default = {
            Main = Color3.fromRGB(30, 30, 30),
            Second = Color3.fromRGB(40, 40, 40),
            Stroke = Color3.fromRGB(70, 70, 70),
            Divider = Color3.fromRGB(70, 70, 70),
            Text = Color3.fromRGB(255, 255, 255),
            TextDark = Color3.fromRGB(170, 170, 170)
        }
    },
    SelectedTheme = "Default",
    Folder = nil,
    SaveCfg = false
}

local Icons = {}
local Success, Response = pcall(function()
    Icons = HttpService:JSONDecode(game:HttpGetAsync("https://raw.githubusercontent.com/evoincorp/lucideblox/master/src/modules/util/icons.json")).icons
end)

if not Success then
    warn("Orion Library - Failed to load Feather Icons. Error code: " .. Response)
end

local function GetIcon(IconName)
    return Icons[IconName] or nil
end

local Orion = Instance.new("ScreenGui")
Orion.Name = "Orion"
if syn then
    syn.protect_gui(Orion)
    Orion.Parent = game.CoreGui
else
    Orion.Parent = gethui() or game.CoreGui
end

local function ClearDuplicates()
    if gethui then
        for _, Interface in ipairs(gethui():GetChildren()) do
            if Interface.Name == Orion.Name and Interface ~= Orion then
                Interface:Destroy()
            end
        end
    else
        for _, Interface in ipairs(game.CoreGui:GetChildren()) do
            if Interface.Name == Orion.Name and Interface ~= Orion then
                Interface:Destroy()
            end
        end
    end
end

ClearDuplicates()

function OrionLib:IsRunning()
    return Orion.Parent == (gethui and gethui() or game.CoreGui)
end

local function AddConnection(Signal, Function)
    if not OrionLib:IsRunning() then return end
    local SignalConnect = Signal:Connect(Function)
    table.insert(OrionLib.Connections, SignalConnect)
    return SignalConnect
end

task.spawn(function()
    while OrionLib:IsRunning() do wait() end
    for _, Connection in ipairs(OrionLib.Connections) do
        Connection:Disconnect()
    end
end)

local function MakeDraggable(DragPoint, Main)
    local Dragging, DragInput, MousePos, FramePos
    AddConnection(DragPoint.InputBegan, function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            Dragging = true
            MousePos = Input.Position
            FramePos = Main.Position
            Input.Changed:Connect(function()
                if Input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)
    AddConnection(DragPoint.InputChanged, function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseMovement then
            DragInput = Input
        end
    end)
    AddConnection(UserInputService.InputChanged, function(Input)
        if Input == DragInput and Dragging then
            local Delta = Input.Position - MousePos
            Main.Position = UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)
        end
    end)
end

local function Create(Name, Properties, Children)
    local Object = Instance.new(Name)
    for i, v in pairs(Properties or {}) do
        Object[i] = v
    end
    for i, v in pairs(Children or {}) do
        v.Parent = Object
    end
    return Object
end

local function CreateElement(ElementName, ElementFunction)
    OrionLib.Elements[ElementName] = function(...)
        return ElementFunction(...)
    end
end

local function MakeElement(ElementName, ...)
    return OrionLib.Elements[ElementName](...)
end

local function SetProps(Element, Props)
    for Property, Value in pairs(Props) do
        Element[Property] = Value
    end
    return Element
end

local function SetChildren(Element, Children)
    for _, Child in pairs(Children) do
        Child.Parent = Element
    end
    return Element
end

local function AddThemeObject(Object, Type)
    OrionLib.ThemeObjects[Type] = OrionLib.ThemeObjects[Type] or {}
    table.insert(OrionLib.ThemeObjects[Type], Object)
    Object[ReturnProperty(Object)] = OrionLib.Themes[OrionLib.SelectedTheme][Type]
    return Object
end

local function SetTheme()
    for Type, Objects in pairs(OrionLib.ThemeObjects) do
        for _, Object in pairs(Objects) do
            Object[ReturnProperty(Object)] = OrionLib.Themes[OrionLib.SelectedTheme][Type]
        end
    end
end

local function PackColor(Color)
    return {R = Color.R * 255, G = Color.G * 255, B = Color.B * 255}
end

local function UnpackColor(Color)
    return Color3.fromRGB(Color.R, Color.G, Color.B)
end

local function LoadCfg(Config)
    local Data = HttpService:JSONDecode(Config)
    for a, b in pairs(Data) do
        if OrionLib.Flags[a] then
            task.spawn(function()
                if OrionLib.Flags[a].Type == "Colorpicker" then
                    OrionLib.Flags[a]:Set(UnpackColor(b))
                else
                    OrionLib.Flags[a]:Set(b)
                end
            end)
        else
            warn("Orion Library Config Loader - Could not find ", a, b)
        end
    end
end

local function SaveCfg(Name)
    local Data = {}
    for i, v in pairs(OrionLib.Flags) do
        if v.Save then
            Data[i] = v.Type == "Colorpicker" and PackColor(v.Value) or v.Value
        end
    end
    writefile(OrionLib.Folder .. "/" .. Name .. ".txt", HttpService:JSONEncode(Data))
end

local WhitelistedMouse = {Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3}
local BlacklistedKeys = {Enum.KeyCode.Unknown, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Up, Enum.KeyCode.Left, Enum.KeyCode.Down, Enum.KeyCode.Right, Enum.KeyCode.Slash, Enum.KeyCode.Tab, Enum.KeyCode.Backspace, Enum.KeyCode.Escape}

local function CheckKey(Table, Key)
    for _, v in pairs(Table) do
        if v == Key then
            return true
        end
    end
end

CreateElement("Corner", function(Scale, Offset)
    return Create("UICorner", {CornerRadius = UDim.new(Scale or 0, Offset or 10)})
end)

CreateElement("Stroke", function(Color, Thickness)
    return Create("UIStroke", {Color = Color or Color3.fromRGB(255, 255, 255), Thickness = Thickness or 1})
end)

CreateElement("List", function(Scale, Offset)
    return Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(Scale or 0, Offset or 0)})
end)

CreateElement("Padding", function(Bottom, Left, Right, Top)
    return Create("UIPadding", {PaddingBottom = UDim.new(0, Bottom or 4), PaddingLeft = UDim.new(0, Left or 4), PaddingRight = UDim.new(0, Right or 4), PaddingTop = UDim.new(0, Top or 4)})
end)

CreateElement("TFrame", function()
    return Create("Frame", {BackgroundTransparency = 1})
end)

CreateElement("Frame", function(Color)
    return Create("Frame", {BackgroundColor3 = Color or Color3.fromRGB(255, 255, 255), BorderSizePixel = 0})
end)

CreateElement("RoundFrame", function(Color, Scale, Offset)
    return Create("Frame", {BackgroundColor3 = Color or Color3.fromRGB(255, 255, 255), BorderSizePixel = 0}, {Create("UICorner", {CornerRadius = UDim.new(Scale, Offset)})})
end)

CreateElement("Button", function()
    return Create("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0})
end)

CreateElement("ScrollFrame", function(Color, Width)
    return Create("ScrollingFrame", {BackgroundTransparency = 1, MidImage = "rbxassetid://7445543667", BottomImage = "rbxassetid://7445543667", TopImage = "rbxassetid://7445543667", ScrollBarImageColor3 = Color, BorderSizePixel = 0, ScrollBarThickness = Width, CanvasSize = UDim2.new(0, 0, 0, 0)})
end)

CreateElement("Label", function(Text, TextScaled, Transparency, Color)
    return Create("TextLabel", {Text = Text, BackgroundTransparency = Transparency, BorderSizePixel = 0, TextColor3 = Color, TextScaled = TextScaled})
end)

CreateElement("Icon", function(IconName, Transparency)
    local IconFrame = MakeElement("RoundFrame", OrionLib.Themes[OrionLib.SelectedTheme].Second, 0, 6)
    IconFrame.Name = "Icon"
    IconFrame.Size = UDim2.new(0, 40, 0, 40)
    MakeElement("Corner", 1, 0).Parent = IconFrame
    MakeElement("Padding", 6, 6, 6, 6).Parent = IconFrame

    local Icon = Create("ImageLabel", {Name = "Icon", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = GetIcon(IconName), ImageTransparency = Transparency, ImageColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Text})
    Icon.Parent = IconFrame

    return IconFrame
end)

CreateElement("Toggle", function(Properties)
    local ToggleFrame = MakeElement("RoundFrame", OrionLib.Themes[OrionLib.SelectedTheme].Second, 0, 6)
    ToggleFrame.Name = "Toggle"
    ToggleFrame.Size = UDim2.new(1, 0, 0, 40)

    local ToggleLabel = Create("TextLabel", {Name = "Label", BackgroundTransparency = 1, Position = UDim2.fromOffset(45, 0), Size = UDim2.new(0.75, 0, 1, 0), Font = Enum.Font.Gotham, Text = Properties.Name, TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})
    ToggleLabel.Parent = ToggleFrame

    local Toggle = Create("TextButton", {Name = "Button", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = Enum.Font.Gotham, Text = "", TextSize = 14})
    Toggle.Parent = ToggleFrame

    local ToggleIcon = MakeElement("Icon", Properties.Icon or "toggle-on", 0)
    ToggleIcon.Position = UDim2.fromOffset(5, 5)
    ToggleIcon.Parent = ToggleFrame

    AddThemeObject(ToggleFrame, "Second")
    AddThemeObject(ToggleLabel, "Text")
    AddThemeObject(ToggleIcon:FindFirstChild("Icon"), "Text")

    Toggle.MouseButton1Click:Connect(function()
        Properties.Callback()
        ToggleIcon:FindFirstChild("Icon").Image = GetIcon(Properties.Enabled and "toggle-off" or "toggle-on")
        Properties.Enabled = not Properties.Enabled
    end)

    return ToggleFrame
end)

function OrionLib:MakeWindow(Properties)
    local Window = {
        Tabs = {}
    }

    local WindowFrame = MakeElement("RoundFrame", OrionLib.Themes[OrionLib.SelectedTheme].Main, 0, 6)
    WindowFrame.Size = UDim2.new(0, 500, 0, 300)
    WindowFrame.Position = Properties.Position or UDim2.new(0.5, -250, 0.5, -150)
    WindowFrame.Parent = Orion

    MakeElement("Stroke", OrionLib.Themes[OrionLib.SelectedTheme].Stroke, 1).Parent = WindowFrame
    MakeElement("Corner", 0, 6).Parent = WindowFrame

    local Title = MakeElement("Label", Properties.Title, false, 1, OrionLib.Themes[OrionLib.SelectedTheme].Text)
    Title.Font = Enum.Font.GothamBold
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.Size = UDim2.new(1, -15, 0, 40)
    Title.TextSize = 20
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = WindowFrame

    local Divider = MakeElement("Frame", OrionLib.Themes[OrionLib.SelectedTheme].Divider)
    Divider.Size = UDim2.new(1, 0, 0, 1)
    Divider.Position = UDim2.new(0, 0, 0, 40)
    Divider.Parent = WindowFrame

    MakeDraggable(WindowFrame, WindowFrame)

    function Window:MakeTab(TabProperties)
        local Tab = {
            Sections = {}
        }

        local TabButton = MakeElement("Button")
        TabButton.Size = UDim2.new(0, 100, 0, 30)
        TabButton.Position = UDim2.new(0, #Window.Tabs * 110 + 15, 0, 50)
        TabButton.Text = TabProperties.Name
        TabButton.TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Text
        TabButton.Parent = WindowFrame

        local TabFrame = MakeElement("RoundFrame", OrionLib.Themes[OrionLib.SelectedTheme].Second, 0, 6)
        TabFrame.Size = UDim2.new(1, -30, 1, -90)
        TabFrame.Position = UDim2.new(0, 15, 0, 80)
        TabFrame.Visible = false
        TabFrame.Parent = WindowFrame

        TabButton.MouseButton1Click:Connect(function()
            for _, v in pairs(Window.Tabs) do
                v.TabFrame.Visible = false
            end
            TabFrame.Visible = true
        end)

        function Tab:MakeSection(SectionProperties)
            local Section = {}

            local SectionFrame = MakeElement("RoundFrame", OrionLib.Themes[OrionLib.SelectedTheme].Main, 0, 6)
            SectionFrame.Size = UDim2.new(1, -30, 0, 50)
            SectionFrame.Position = UDim2.new(0, 15, 0, #Tab.Sections * 60 + 10)
            SectionFrame.Parent = TabFrame

            local SectionLabel = MakeElement("Label", SectionProperties.Name, true, 1, OrionLib.Themes[OrionLib.SelectedTheme].Text)
            SectionLabel.Size = UDim2.new(1, -30, 0, 30)
            SectionLabel.Position = UDim2.new(0, 15, 0, 10)
            SectionLabel.Font = Enum.Font.Gotham
            SectionLabel.TextSize = 14
            SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
            SectionLabel.Parent = SectionFrame

            function Section:AddElement(ElementProperties)
                local Element = {}

                local ElementFrame = MakeElement("RoundFrame", OrionLib.Themes[OrionLib.SelectedTheme].Second, 0, 6)
                ElementFrame.Size = UDim2.new(1, -30, 0, 30)
                ElementFrame.Position = UDim2.new(0, 15, 0, #Section.Elements * 40 + 40)
                ElementFrame.Parent = SectionFrame

                local ElementLabel = MakeElement("Label", ElementProperties.Name, true, 1, OrionLib.Themes[OrionLib.SelectedTheme].Text)
                ElementLabel.Size = UDim2.new(1, -30, 0, 30)
                ElementLabel.Position = UDim2.new(0, 15, 0, 0)
                ElementLabel.Font = Enum.Font.Gotham
                ElementLabel.TextSize = 14
                ElementLabel.TextXAlignment = Enum.TextXAlignment.Left
                ElementLabel.Parent = ElementFrame

                function Element:Set(Value)
                    ElementProperties.Callback(Value)
                end

                table.insert(Section.Elements, Element)
                return Element
            end

            table.insert(Tab.Sections, Section)
            return Section
        end

        table.insert(Window.Tabs, {TabButton = TabButton, TabFrame = TabFrame})
        return Tab
    end

    return Window
end

return OrionLib
