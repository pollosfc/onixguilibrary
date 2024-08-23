-- Servicios principales
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- Biblioteca personalizada para la GUI
local CustomUILib = {
    Elements = {},
    Connections = {},
    Themes = {
        Default = {
            Background = Color3.fromRGB(30, 30, 30),
            Primary = Color3.fromRGB(40, 40, 40),
            Accent = Color3.fromRGB(70, 70, 70),
            Text = Color3.fromRGB(255, 255, 255),
            Highlight = Color3.fromRGB(100, 100, 255)
        }
    },
    SelectedTheme = "Default"
}

-- Función para crear elementos GUI
local function CreateElement(ElementType, Properties, Children)
    local Element = Instance.new(ElementType)
    for prop, value in pairs(Properties) do
        Element[prop] = value
    end
    for _, child in ipairs(Children or {}) do
        child.Parent = Element
    end
    return Element
end

-- Función para crear la ventana principal de la GUI
function CustomUILib:CreateWindow(WindowTitle)
    -- Crear ScreenGui
    local ScreenGui = CreateElement("ScreenGui", {Name = "CustomUI", Parent = game.CoreGui})

    -- Crear el marco principal
    local MainFrame = CreateElement("Frame", {
        Size = UDim2.new(0, 400, 0, 300),
        Position = UDim2.new(0.5, -200, 0.5, -150),
        BackgroundColor3 = self.Themes[self.SelectedTheme].Background,
        Parent = ScreenGui
    }, {
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 8)})
    })

    -- Crear la barra de título
    local TitleBar = CreateElement("TextLabel", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = self.Themes[self.SelectedTheme].Primary,
        Text = WindowTitle,
        TextColor3 = self.Themes[self.SelectedTheme].Text,
        Font = Enum.Font.GothamBold,
        TextSize = 16
    }, {
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 8)})
    })

    TitleBar.Parent = MainFrame

    -- Hacer la ventana arrastrable
    local Dragging, DragInput, StartPos, DragStart = false, nil, nil, nil

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Dragging = true
            DragStart = input.Position
            StartPos = MainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)

    TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            DragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then
            local Delta = input.Position - DragStart
            MainFrame.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
        end
    end)

    return MainFrame
end

-- Función para crear un botón
function CustomUILib:CreateButton(Parent, ButtonText, Callback)
    local Button = CreateElement("TextButton", {
        Size = UDim2.new(0, 200, 0, 50),
        BackgroundColor3 = self.Themes[self.SelectedTheme].Accent,
        Text = ButtonText,
        TextColor3 = self.Themes[self.SelectedTheme].Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Parent = Parent
    }, {
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 8)})
    })

    Button.MouseButton1Click:Connect(function()
        Callback()
    end)

    return Button
end

-- Función para crear un toggle (interruptor)
function CustomUILib:CreateToggle(Parent, ToggleText, Default, Callback)
    local Toggle = {Value = Default}

    local ToggleFrame = CreateElement("Frame", {
        Size = UDim2.new(0, 200, 0, 50),
        BackgroundColor3 = self.Themes[self.SelectedTheme].Accent,
        Parent = Parent
    }, {
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 8)})
    })

    local Label = CreateElement("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = ToggleText,
        TextColor3 = self.Themes[self.SelectedTheme].Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = ToggleFrame
    })

    local Switch = CreateElement("Frame", {
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -50, 0.5, -10),
        BackgroundColor3 = Default and self.Themes[self.SelectedTheme].Highlight or self.Themes[self.SelectedTheme].Primary,
        Parent = ToggleFrame
    }, {
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 10)})
    })

    Switch.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Toggle.Value = not Toggle.Value
            Switch.BackgroundColor3 = Toggle.Value and CustomUILib.Themes[CustomUILib.SelectedTheme].Highlight or CustomUILib.Themes[CustomUILib.SelectedTheme].Primary
            Callback(Toggle.Value)
        end
    end)

    return Toggle
end

-- Función para crear un slider (deslizador)
function CustomUILib:CreateSlider(Parent, SliderText, Min, Max, Default, Callback)
    local Slider = {Value = Default}

    local SliderFrame = CreateElement("Frame", {
        Size = UDim2.new(0, 200, 0, 50),
        BackgroundColor3 = self.Themes[self.SelectedTheme].Accent,
        Parent = Parent
    }, {
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 8)})
    })

    local Label = CreateElement("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = SliderText,
        TextColor3 = self.Themes[self.SelectedTheme].Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = SliderFrame
    })

    local SliderBar = CreateElement("Frame", {
        Size = UDim2.new(1, -120, 0, 10),
        Position = UDim2.new(0, 100, 0.5, -5),
        BackgroundColor3 = self.Themes[self.SelectedTheme].Primary,
        Parent = SliderFrame
    }, {
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 8)})
    })

    local SliderHandle = CreateElement("Frame", {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new((Default - Min) / (Max - Min), -10, 0.5, -10),
        BackgroundColor3 = self.Themes[self.SelectedTheme].Highlight,
        Parent = SliderBar
    }, {
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 8)})
    })

    SliderHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local Dragging = true

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)

            local function UpdateInput(input)
                if Dragging then
                    local Delta = input.Position.X - SliderBar.AbsolutePosition.X
                    local Percent = math.clamp(Delta / SliderBar.AbsoluteSize.X, 0, 1)
                    Slider.Value = math.floor(Min + Percent * (Max - Min))
                    SliderHandle.Position = UDim2.new(Percent, -10, 0.5, -10)
                    Callback(Slider.Value)
                end
            end

            UserInputService.InputChanged:Connect(UpdateInput)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Dragging = false
                end
            end)
        end
    end)

    return Slider
end

-- Función para mostrar notificaciones
function CustomUILib:Notify(NotificationText, Duration)
    local ScreenGui = game.CoreGui:FindFirstChild("CustomUI")
    if not ScreenGui then return end

    local Notification = CreateElement("TextLabel", {
        Size = UDim2.new(0, 300, 0, 50),
        Position = UDim2.new(0.5, -150, 0, -100),
        BackgroundColor3 = self.Themes[self.SelectedTheme].Primary,
        Text = NotificationText,
        TextColor3 = self.Themes[self.SelectedTheme].Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Parent = ScreenGui
    }, {
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 8)})
    })

    TweenService:Create(Notification, TweenInfo.new(0.5), {Position = UDim2.new(0.5, -150, 0, 10)}):Play()
    
    wait(Duration or 3)
    
    TweenService:Create(Notification, TweenInfo.new(0.5), {Position = UDim2.new(0.5, -150, 0, -100)}):Play()
    wait(0.5)
    Notification:Destroy()
end

return CustomUILib
