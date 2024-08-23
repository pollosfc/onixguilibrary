local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

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

function CustomUILib:CreateWindow(WindowTitle)
    local ScreenGui = CreateElement("ScreenGui", {Name = "CustomUI", Parent = game.CoreGui})

    local MainFrame = CreateElement("Frame", {
        Size = UDim2.new(0, 500, 0, 400),
        Position = UDim2.new(0.5, -250, 0.5, -200),
        BackgroundColor3 = self.Themes[self.SelectedTheme].Background,
        Parent = ScreenGui
    }, {
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 8)})
    })

    local TitleBar = CreateElement("TextLabel", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = self.Themes[self.SelectedTheme].Primary,
        Text = WindowTitle,
        TextColor3 = self.Themes[self.SelectedTheme].Text,
        Font = Enum.Font.GothamBold,
        TextSize = 18
    }, {
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 8)})
    })

    TitleBar.Parent = MainFrame

    -- Draggable functionality
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

function CustomUILib:CreateTabWindow(WindowTitle)
    local ScreenGui = CreateElement("ScreenGui", {Name = "CustomUI", Parent = game.CoreGui})

    local MainFrame = CreateElement("Frame", {
        Size = UDim2.new(0, 500, 0, 400),
        Position = UDim2.new(0.5, -250, 0.5, -200),
        BackgroundColor3 = self.Themes[self.SelectedTheme].Background,
        Parent = ScreenGui
    }, {
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 8)})
    })

    local TitleBar = CreateElement("TextLabel", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = self.Themes[self.SelectedTheme].Primary,
        Text = WindowTitle,
        TextColor3 = self.Themes[self.SelectedTheme].Text,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        Parent = MainFrame
    }, {
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 8)})
    })

    local TabFrame = CreateElement("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundColor3 = self.Themes[self.SelectedTheme].Accent,
        Parent = MainFrame
    })

    local ContentFrame = CreateElement("Frame", {
        Size = UDim2.new(1, 0, 1, -70),
        Position = UDim2.new(0, 0, 0, 70),
        BackgroundColor3 = self.Themes[self.SelectedTheme].Background,
        Parent = MainFrame
    }, {
        CreateElement("UICorner", {CornerRadius = UDim.new(0, 8)})
    })

    return {
        MainFrame = MainFrame,
        TabFrame = TabFrame,
        ContentFrame = ContentFrame
    }
end

function CustomUILib:AddTab(TabWindow, TabName)
    local TabButton = CreateElement("TextButton", {
        Size = UDim2.new(0, 100, 0, 30),
        BackgroundColor3 = self.Themes[self.SelectedTheme].Primary,
        Text = TabName,
        TextColor3 = self.Themes[self.SelectedTheme].Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Parent = TabWindow.TabFrame
    })

    local TabContent = CreateElement("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = self.Themes[self.SelectedTheme].Background,
        Visible = false,
        Parent = TabWindow.ContentFrame
    })

    TabButton.MouseButton1Click:Connect(function()
        for _, sibling in pairs(TabWindow.ContentFrame:GetChildren()) do
            sibling.Visible = false
        end
        TabContent.Visible = true
    end)

    return TabContent
end

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
