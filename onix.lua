local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local HttpService = game:GetService("HttpService")

local CustomUILib = {
    Elements = {},
    ThemeObjects = {},
    Connections = {},
    Flags = {},
    Themes = {
        Default = {
            Main = Color3.fromRGB(30, 30, 30),
            Second = Color3.fromRGB(40, 40, 40),
            Stroke = Color3.fromRGB(60, 60, 60),
            Divider = Color3.fromRGB(70, 70, 70),
            Text = Color3.fromRGB(255, 255, 255),
            TextDark = Color3.fromRGB(150, 150, 150)
        }
    },
    SelectedTheme = "Default",
    Folder = nil,
    SaveCfg = false
}

local function CloseExistingGUI()
    for _, gui in ipairs(game.CoreGui:GetChildren()) do
        if gui.Name == "CustomUI" and gui:IsA("ScreenGui") then
            gui:Destroy()
        end
    end
end

-- Llamar a la función para cerrar cualquier GUI existente
CloseExistingGUI()

local CustomUI = Instance.new("ScreenGui")
CustomUI.Name = "CustomUI"
if syn then
    syn.protect_gui(CustomUI)
    CustomUI.Parent = game.CoreGui
else
    CustomUI.Parent = gethui() or game.CoreGui
end

if gethui then
    for _, Interface in ipairs(gethui():GetChildren()) do
        if Interface.Name == CustomUI.Name and Interface ~= CustomUI then
            Interface:Destroy()
        end
    end
else
    for _, Interface in ipairs(game.CoreGui:GetChildren()) do
        if Interface.Name == CustomUI.Name and Interface ~= CustomUI then
            Interface:Destroy()
        end
    end
end

local function AddConnection(Signal, Function)
    local SignalConnect = Signal:Connect(Function)
    table.insert(CustomUILib.Connections, SignalConnect)
    return SignalConnect
end

local function MakeDraggable(DragPoint, Main)
    local Dragging, DragInput, MousePos, FramePos = false
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
    for i, v in next, Properties or {} do
        Object[i] = v
    end
    for i, v in next, Children or {} do
        v.Parent = Object
    end
    return Object
end

local function AddThemeObject(Object, Type)
    if not CustomUILib.ThemeObjects[Type] then
        CustomUILib.ThemeObjects[Type] = {}
    end
    table.insert(CustomUILib.ThemeObjects[Type], Object)
    Object[ReturnProperty(Object)] = CustomUILib.Themes[CustomUILib.SelectedTheme][Type]
    return Object
end

local function ReturnProperty(Object)
    if Object:IsA("Frame") or Object:IsA("TextButton") then
        return "BackgroundColor3"
    end
    if Object:IsA("ScrollingFrame") then
        return "ScrollBarImageColor3"
    end
    if Object:IsA("UIStroke") then
        return "Color"
    end
    if Object:IsA("TextLabel") or Object:IsA("TextBox") then
        return "TextColor3"
    end
    if Object:IsA("ImageLabel") or Object:IsA("ImageButton") then
        return "ImageColor3"
    end
end

local function SetTheme()
    for Name, Type in pairs(CustomUILib.ThemeObjects) do
        for _, Object in pairs(Type) do
            Object[ReturnProperty(Object)] = CustomUILib.Themes[CustomUILib.SelectedTheme][Name]
        end
    end
end

function CustomUILib:CreateTabWindow(WindowTitle)
    local MainFrame = Create("Frame", {
        Size = UDim2.new(0, 500, 0, 300),
        Position = UDim2.new(0.5, -250, 0.5, -150),
        BackgroundColor3 = CustomUILib.Themes[CustomUILib.SelectedTheme].Main,
        Parent = CustomUI
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
        Create("UIStroke", {Color = CustomUILib.Themes[CustomUILib.SelectedTheme].Stroke}),
    })

    local TitleBar = Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = CustomUILib.Themes[CustomUILib.SelectedTheme].Second,
        Text = WindowTitle,
        TextColor3 = CustomUILib.Themes[CustomUILib.SelectedTheme].Text,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        Parent = MainFrame
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
        Create("UIStroke", {Color = CustomUILib.Themes[CustomUILib.SelectedTheme].Stroke}),
    })

    MakeDraggable(TitleBar, MainFrame)

    return MainFrame
end

function CustomUILib:AddTab(Window, TabTitle)
    local TabButton = Create("TextButton", {
        Size = UDim2.new(0, 100, 0, 40),
        BackgroundColor3 = CustomUILib.Themes[CustomUILib.SelectedTheme].Second,
        Text = TabTitle,
        TextColor3 = CustomUILib.Themes[CustomUILib.SelectedTheme].Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Parent = Window
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
        Create("UIStroke", {Color = CustomUILib.Themes[CustomUILib.SelectedTheme].Stroke}),
    })

    local TabContent = Create("Frame", {
        Size = UDim2.new(1, 0, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundColor3 = CustomUILib.Themes[CustomUILib.SelectedTheme].Main,
        Visible = false,
        Parent = Window
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
        Create("UIStroke", {Color = CustomUILib.Themes[CustomUILib.SelectedTheme].Stroke}),
    })

    TabButton.MouseButton1Click:Connect(function()
        for _, child in ipairs(Window:GetChildren()) do
            if child:IsA("Frame") and child ~= TabContent then
                child.Visible = false
            end
        end
        TabContent.Visible = true
    end)

    return TabContent
end

function CustomUILib:CreateButton(Parent, ButtonText, Callback)
    local Button = Create("TextButton", {
        Size = UDim2.new(0, 200, 0, 50),
        BackgroundColor3 = CustomUILib.Themes[CustomUILib.SelectedTheme].Second,
        Text = ButtonText,
        TextColor3 = CustomUILib.Themes[CustomUILib.SelectedTheme].Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Parent = Parent
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
        Create("UIStroke", {Color = CustomUILib.Themes[CustomUILib.SelectedTheme].Stroke}),
    })

    Button.MouseButton1Click:Connect(function()
        Callback()
    end)

    return Button
end

function CustomUILib:CreateToggle(Parent, ToggleText, Default, Callback)
    local Toggle = {Value = Default}

    local ToggleFrame = Create("Frame", {
        Size = UDim2.new(0, 200, 0, 50),
        BackgroundColor3 = CustomUILib.Themes[CustomUILib.SelectedTheme].Second,
        Parent = Parent
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
        Create("UIStroke", {Color = CustomUILib.Themes[CustomUILib.SelectedTheme].Stroke}),
    })

    local Label = Create("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = ToggleText,
        TextColor3 = CustomUILib.Themes[CustomUILib.SelectedTheme].Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = ToggleFrame
    })

    local Switch = Create("Frame", {
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -50, 0.5, -10),
        BackgroundColor3 = Default and CustomUILib.Themes[CustomUILib.SelectedTheme].Divider or CustomUILib.Themes[CustomUILib.SelectedTheme].Stroke,
        Parent = ToggleFrame
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 10)})
    })

    Switch.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Toggle.Value = not Toggle.Value
            Switch.BackgroundColor3 = Toggle.Value and CustomUILib.Themes[CustomUILib.SelectedTheme].Divider or CustomUILib.Themes[CustomUILib.SelectedTheme].Stroke
            Callback(Toggle.Value)
        end
    end)

    return Toggle
end

function CustomUILib:Notify(NotificationText, Duration)
    local Notification = Create("TextLabel", {
        Size = UDim2.new(0, 300, 0, 50),
        Position = UDim2.new(0.5, -150, 0, -100),
        BackgroundColor3 = CustomUILib.Themes[CustomUILib.SelectedTheme].Second,
        Text = NotificationText,
        TextColor3 = CustomUILib.Themes[CustomUILib.SelectedTheme].Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Parent = CustomUI
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
        Create("UIStroke", {Color = CustomUILib.Themes[CustomUILib.SelectedTheme].Stroke}),
    })

    TweenService:Create(Notification, TweenInfo.new(0.5), {Position = UDim2.new(0.5, -150, 0, 10)}):Play()

    wait(Duration or 3)

    TweenService:Create(Notification, TweenInfo.new(0.5), {Position = UDim2.new(0.5, -150, 0, -100)}):Play()
    wait(0.5)
    Notification:Destroy()
end

return CustomUILib
