local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local HttpService = game:GetService("HttpService")

-- Inicialización de la biblioteca Orion
local OrionLib = {
    Elements = {},
    ThemeObjects = {},
    Connections = {},
    Flags = {},
    Themes = {
        Default = {
            Main = Color3.fromRGB(25, 25, 25),
            Second = Color3.fromRGB(32, 32, 32),
            Stroke = Color3.fromRGB(60, 60, 60),
            Divider = Color3.fromRGB(60, 60, 60),
            Text = Color3.fromRGB(240, 240, 240),
            TextDark = Color3.fromRGB(150, 150, 150)
        }
    },
    SelectedTheme = "Default",
    Folder = nil,
    SaveCfg = false
}

-- Carga de íconos de Feather desde una fuente externa
local Icons = {}
local Success, Response = pcall(function()
    Icons = HttpService:JSONDecode(game:HttpGetAsync("https://raw.githubusercontent.com/evoincorp/lucideblox/master/src/modules/util/icons.json")).icons
end)

if not Success then
    warn("\nOrion Library - Failed to load Feather Icons. Error code: " .. Response .. "\n")
end    

local function GetIcon(IconName)
    if Icons[IconName] ~= nil then
        return Icons[IconName]
    else
        return nil
    end
end   

-- Creación del ScreenGui principal
local Orion = Instance.new("ScreenGui")
Orion.Name = "Orion"
if syn then
    syn.protect_gui(Orion)
    Orion.Parent = game.CoreGui
else
    Orion.Parent = gethui() or game.CoreGui
end

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

-- Función para verificar si la GUI está activa
function OrionLib:IsRunning()
    if gethui then
        return Orion.Parent == gethui()
    else
        return Orion.Parent == game:GetService("CoreGui")
    end
end

-- Función para añadir conexiones y guardarlas para desconectar al cerrar la GUI
local function AddConnection(Signal, Function)
    if (not OrionLib:IsRunning()) then
        return
    end
    local SignalConnect = Signal:Connect(Function)
    table.insert(OrionLib.Connections, SignalConnect)
    return SignalConnect
end

task.spawn(function()
    while (OrionLib:IsRunning()) do
        wait()
    end

    for _, Connection in next, OrionLib.Connections do
        Connection:Disconnect()
    end
end)

-- Función para hacer draggable (movible) la ventana principal
local function MakeDraggable(DragPoint, Main)
    pcall(function()
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
                Main.Position  = UDim2.new(FramePos.X.Scale,FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)
            end
        end)
    end)
end    

-- Función para crear instancias con propiedades y hijos
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

-- Función para crear elementos y añadirlos a la lista de elementos
local function CreateElement(ElementName, ElementFunction)
    OrionLib.Elements[ElementName] = function(...)
        return ElementFunction(...)
    end
end

-- Función para crear un nuevo elemento a partir de la lista de elementos
local function MakeElement(ElementName, ...)
    local NewElement = OrionLib.Elements[ElementName](...)
    return NewElement
end

-- Función para establecer propiedades en un objeto
local function SetProps(Element, Props)
    table.foreach(Props, function(Property, Value)
        Element[Property] = Value
    end)
    return Element
end

-- Función para establecer hijos en un objeto
local function SetChildren(Element, Children)
    table.foreach(Children, function(_, Child)
        Child.Parent = Element
    end)
    return Element
end

-- Función para redondear un número a un factor específico
local function Round(Number, Factor)
    local Result = math.floor(Number/Factor + (math.sign(Number) * 0.5)) * Factor
    if Result < 0 then Result = Result + Factor end
    return Result
end

-- Función para determinar la propiedad de color de un objeto
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

-- Función para añadir un objeto de tema a la lista de objetos temáticos
local function AddThemeObject(Object, Type)
    if not OrionLib.ThemeObjects[Type] then
        OrionLib.ThemeObjects[Type] = {}
    end    
    table.insert(OrionLib.ThemeObjects[Type], Object)
    Object[ReturnProperty(Object)] = OrionLib.Themes[OrionLib.SelectedTheme][Type]
    return Object
end    

-- Función para aplicar el tema seleccionado a todos los objetos temáticos
local function SetTheme()
    for Name, Type in pairs(OrionLib.ThemeObjects) do
        for _, Object in pairs(Type) do
            Object[ReturnProperty(Object)] = OrionLib.Themes[OrionLib.SelectedTheme][Name]
        end    
    end    
end

-- Función para empacar un color en una tabla
local function PackColor(Color)
    return {R = Color.R * 255, G = Color.G * 255, B = Color.B * 255}
end    

-- Función para desempacar un color de una tabla
local function UnpackColor(Color)
    return Color3.fromRGB(Color.R, Color.G, Color.B)
end

-- Función para cargar una configuración desde un archivo
local function LoadCfg(Config)
    local Data = HttpService:JSONDecode(Config)
    table.foreach(Data, function(a,b)
        if OrionLib.Flags[a] then
            spawn(function() 
                if OrionLib.Flags[a].Type == "Colorpicker" then
                    OrionLib.Flags[a]:Set(UnpackColor(b))
                else
                    OrionLib.Flags[a]:Set(b)
                end    
            end)
        else
            warn("Orion Library Config Loader - Could not find ", a ,b)
        end
    end)
end

-- Función para guardar la configuración en un archivo
local function SaveCfg(Name)
    local Data = {}
    for i,v in pairs(OrionLib.Flags) do
        if v.Save then
            if v.Type == "Colorpicker" then
                Data[i] = PackColor(v.Value)
            else
                Data[i] = v.Value
            end
        end    
    end
    writefile(OrionLib.Folder .. "/" .. Name .. ".txt", tostring(HttpService:JSONEncode(Data)))
end

-- Funciones auxiliares para manejar teclas y botones del ratón
local WhitelistedMouse = {Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2,Enum.UserInputType.MouseButton3}
local BlacklistedKeys = {Enum.KeyCode.Unknown,Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Up,Enum.KeyCode.Left,Enum.KeyCode.Down,Enum.KeyCode.Right,Enum.KeyCode.Slash,Enum.KeyCode.Tab,Enum.KeyCode.Backspace,Enum.KeyCode.Escape}

local function CheckKey(Table, Key)
    for _, v in next, Table do
        if v == Key then
            return true
        end
    end
end

-- Creación de elementos de la GUI
CreateElement("Corner", function(Scale, Offset)
    local Corner = Create("UICorner", {
        CornerRadius = UDim.new(Scale or 0, Offset or 10)
    })
    return Corner
end)

CreateElement("Stroke", function(Color, Thickness)
    local Stroke = Create("UIStroke", {
        Color = Color or Color3.fromRGB(255, 255, 255),
        Thickness = Thickness or 1
    })
    return Stroke
end)

CreateElement("List", function(Scale, Offset)
    local List = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(Scale or 0, Offset or 0)
    })
    return List
end)

CreateElement("Padding", function(Bottom, Left, Right, Top)
    local Padding = Create("UIPadding", {
        PaddingBottom = UDim.new(0, Bottom or 4),
        PaddingLeft = UDim.new(0, Left or 4),
        PaddingRight = UDim.new(0, Right or 4),
        PaddingTop = UDim.new(0, Top or 4)
    })
    return Padding
end)

CreateElement("TFrame", function()
    local TFrame = Create("Frame", {
        BackgroundTransparency = 1
    })
    return TFrame
end)

CreateElement("Frame", function(Color)
    local Frame = Create("Frame", {
        BackgroundColor3 = Color or Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0
    })
    return Frame
end)

CreateElement("RoundFrame", function(Color, Scale, Offset)
    local Frame = Create("Frame", {
        BackgroundColor3 = Color or Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0
    }, {
        Create("UICorner", {
            CornerRadius = UDim.new(Scale, Offset)
        })
    })
    return Frame
end)

CreateElement("Button", function()
    local Button = Create("TextButton", {
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    })
    return Button
end)

CreateElement("ScrollFrame", function(Color, Width)
    local ScrollFrame = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        MidImage = "rbxassetid://7445543667",
        BottomImage = "rbxassetid://7445543667",
        TopImage = "rbxassetid://7445543667",
        ScrollBarImageColor3 = Color,
        BorderSizePixel = 0,
        ScrollBarThickness = Width,
        CanvasSize = UDim2.new(0, 0, 0, 0)
    })
    return ScrollFrame
end)

CreateElement("Image", function(ImageID)
    local ImageNew = Create("ImageLabel", {
        Image = ImageID,
        BackgroundTransparency = 1
    })

    if GetIcon(ImageID) ~= nil then
        ImageNew.Image = GetIcon(ImageID)
    end    

    return ImageNew
end)

CreateElement("ImageButton", function(ImageID)
    local Image = Create("ImageButton", {
        Image = ImageID,
        BackgroundTransparency = 1
    })
    return Image
end)

CreateElement("Label", function(Text, TextSize, Transparency)
    local Label = Create("TextLabel", {
        Text = Text or "",
        TextColor3 = Color3.fromRGB(240, 240, 240),
        TextTransparency = Transparency or 0,
        TextSize = TextSize or 15,
        Font = Enum.Font.Gotham,
        RichText = true,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    return Label
end)

-- Creación del contenedor de notificaciones
local NotificationHolder = SetProps(SetChildren(MakeElement("TFrame"), {
    SetProps(MakeElement("List"), {
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding = UDim.new(0, 5)
    })
}), {
    Position = UDim2.new(1, -25, 1, -25),
    Size = UDim2.new(0, 300, 1, -25),
    AnchorPoint = Vector2.new(1, 1),
    Parent = Orion
})

-- Función para crear una notificación
function OrionLib:MakeNotification(NotificationConfig)
    spawn(function()
        NotificationConfig.Name = NotificationConfig.Name or "Notification"
        NotificationConfig.Content = NotificationConfig.Content or "Test"
        NotificationConfig.Image = NotificationConfig.Image or "rbxassetid://4384403532"
        NotificationConfig.Time = NotificationConfig.Time or 15

        local NotificationParent = SetProps(MakeElement("TFrame"), {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = NotificationHolder
        })

        local NotificationFrame = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(25, 25, 25), 0, 10), {
            Parent = NotificationParent, 
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(1, -55, 0, 0),
            BackgroundTransparency = 0,
            AutomaticSize = Enum.AutomaticSize.Y
        }), {
            MakeElement("Stroke", Color3.fromRGB(93, 93, 93), 1.2),
            MakeElement("Padding", 12, 12, 12, 12),
            SetProps(MakeElement("Image", NotificationConfig.Image), {
                Size = UDim2.new(0, 20, 0, 20),
                ImageColor3 = Color3.fromRGB(240, 240, 240),
                Name = "Icon"
            }),
            SetProps(MakeElement("Label", NotificationConfig.Name, 15), {
                Size = UDim2.new(1, -30, 0, 20),
                Position = UDim2.new(0, 30, 0, 0),
                Font = Enum.Font.GothamBold,
                Name = "Title"
            }),
            SetProps(MakeElement("Label", NotificationConfig.Content, 14), {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 25),
                Font = Enum.Font.GothamSemibold,
                Name = "Content",
                AutomaticSize = Enum.AutomaticSize.Y,
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextWrapped = true
            })
        })

        TweenService:Create(NotificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 0, 0, 0)}):Play()

        wait(NotificationConfig.Time - 0.88)
        TweenService:Create(NotificationFrame.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
        TweenService:Create(NotificationFrame, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.6}):Play()
        wait(0.3)
        TweenService:Create(NotificationFrame.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Transparency = 0.9}):Play()
        TweenService:Create(NotificationFrame.Title, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 0.4}):Play()
        TweenService:Create(NotificationFrame.Content, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 0.5}):Play()
        wait(0.05)

        NotificationFrame:TweenPosition(UDim2.new(1, 20, 0, 0),'In','Quint',0.8,true)
        wait(1.35)
        NotificationFrame:Destroy()
    end)
end    

-- Función para inicializar la biblioteca Orion
function OrionLib:Init()
    if OrionLib.SaveCfg then    
        pcall(function()
            if isfile(OrionLib.Folder .. "/" .. game.GameId .. ".txt") then
                LoadCfg(readfile(OrionLib.Folder .. "/" .. game.GameId .. ".txt"))
                OrionLib:MakeNotification({
                    Name = "Configuration",
                    Content = "Auto-loaded configuration for the game " .. game.GameId .. ".",
                    Time = 5
                })
            end
        end)        
    end    
end    

-- Función para crear la ventana principal de la GUI
function OrionLib:MakeWindow(WindowConfig)
    local FirstTab = true
    local Minimized = false
    local Loaded = false
    local UIHidden = false

    WindowConfig = WindowConfig or {}
    WindowConfig.Name = WindowConfig.Name or "Orion Library"
    WindowConfig.ConfigFolder = WindowConfig.ConfigFolder or WindowConfig.Name
    WindowConfig.SaveConfig = WindowConfig.SaveConfig or false
    WindowConfig.HidePremium = WindowConfig.HidePremium or false
    if WindowConfig.IntroEnabled == nil then
        WindowConfig.IntroEnabled = true
    end
    WindowConfig.IntroText = WindowConfig.IntroText or "Orion Library"
    WindowConfig.CloseCallback = WindowConfig.CloseCallback or function() end
    WindowConfig.ShowIcon = WindowConfig.ShowIcon or false
    WindowConfig.Icon = WindowConfig.Icon or "rbxassetid://8834748103"
    WindowConfig.IntroIcon = WindowConfig.IntroIcon or "rbxassetid://8834748103"
    OrionLib.Folder = WindowConfig.ConfigFolder
    OrionLib.SaveCfg = WindowConfig.SaveConfig

    if WindowConfig.SaveConfig then
        if not isfolder(WindowConfig.ConfigFolder) then
            makefolder(WindowConfig.ConfigFolder)
        end    
    end

    local TabHolder = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255, 255, 255), 4), {
        Size = UDim2.new(1, 0, 1, -50)
    }), {
        MakeElement("List"),
        MakeElement("Padding", 8, 0, 0, 8)
    }), "Divider")

    AddConnection(TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        TabHolder.CanvasSize = UDim2.new(0, 0, 0, TabHolder.UIListLayout.AbsoluteContentSize.Y + 16)
    end)

    local CloseBtn = SetChildren(SetProps(MakeElement("Button"), {
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        BackgroundTransparency = 1
    }), {
        AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072725342"), {
            Position = UDim2.new(0, 9, 0, 6),
            Size = UDim2.new(0, 18, 0, 18)
        }), "Text")
    })

    local MinimizeBtn = SetChildren(SetProps(MakeElement("Button"), {
        Size = UDim2.new(0.5, 0, 1, 0),
        BackgroundTransparency = 1
    }), {
        AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072719338"), {
            Position = UDim2.new(0, 9, 0, 6),
            Size = UDim2.new(0, 18, 0, 18),
            Name = "Ico"
        }), "Text")
    })

    local DragPoint = SetProps(MakeElement("TFrame"), {
        Size = UDim2.new(1, 0, 0, 50)
    })

    local WindowStuff = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 10), {
        Size = UDim2.new(0, 150, 1, -50),
        Position = UDim2.new(0, 0, 0, 50)
    }), {
        AddThemeObject(SetProps(MakeElement("Frame"), {
            Size = UDim2.new(1, 0, 0, 10),
            Position = UDim2.new(0, 0, 0, 0)
        }), "Second"), 
        AddThemeObject(SetProps(MakeElement("Frame"), {
            Size = UDim2.new(0, 10, 1, 0),
            Position = UDim2.new(1, -10, 0, 0)
        }), "Second"), 
        AddThemeObject(SetProps(MakeElement("Frame"), {
            Size = UDim2.new(0, 1, 1, 0),
            Position = UDim2.new(1, -1, 0, 0)
        }), "Stroke"), 
        TabHolder,
        SetChildren(SetProps(MakeElement("TFrame"), {
            Size = UDim2.new(1, 0, 0, 50),
            Position = UDim2.new(0, 0, 1, -50)
        }), {
            AddThemeObject(SetProps(MakeElement("Frame"), {
                Size = UDim2.new(1, 0, 0, 1)
            }), "Stroke"), 
            AddThemeObject(SetChildren(SetProps(MakeElement("Frame"), {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, 32, 0, 32),
                Position = UDim2.new(0, 10, 0.5, 0)
            }), {
                SetProps(MakeElement("Image", "https://www.roblox.com/headshot-thumbnail/image?userId=".. LocalPlayer.UserId .."&width=420&height=420&format=png"), {
                    Size = UDim2.new(1, 0, 1, 0)
                }),
                AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://4031889928"), {
                    Size = UDim2.new(1, 0, 1, 0),
                }), "Second"),
                MakeElement("Corner", 1)
            }), "Divider"),
            SetChildren(SetProps(MakeElement("TFrame"), {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, 32, 0, 32),
                Position = UDim2.new(0, 10, 0.5, 0)
            }), {
                AddThemeObject(MakeElement("Stroke"), "Stroke"),
                MakeElement("Corner", 1)
            }),
            AddThemeObject(SetProps(MakeElement("Label", LocalPlayer.DisplayName, WindowConfig.HidePremium and 14 or 13), {
                Size = UDim2.new(1, -60, 0, 13),
                Position = WindowConfig.HidePremium and UDim2.new(0, 50, 0, 19) or UDim2.new(0, 50, 0, 12),
                Font = Enum.Font.GothamBold,
                ClipsDescendants = true
            }), "Text"),
            AddThemeObject(SetProps(MakeElement("Label", "", 12), {
                Size = UDim2.new(1, -60, 0, 12),
                Position = UDim2.new(0, 50, 1, -25),
                Visible = not WindowConfig.HidePremium
            }), "TextDark")
        }),
    }), "Second")

    local WindowName = AddThemeObject(SetProps(MakeElement("Label", WindowConfig.Name, 14), {
        Size = UDim2.new(1, -30, 2, 0),
        Position = UDim2.new(0, 25, 0, -24),
        Font = Enum.Font.GothamBlack,
        TextSize = 20
    }), "Text")

    local WindowTopBarLine = AddThemeObject(SetProps(MakeElement("Frame"), {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1)
    }), "Stroke")

    local MainWindow = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 10), {
        Parent = Orion,
        Position = UDim2.new(0.5, -307, 0.5, -172),
        Size = UDim2.new(0, 615, 0, 344),
        ClipsDescendants = true
    }), {
        SetChildren(SetProps(MakeElement("TFrame"), {
            Size = UDim2.new(1, 0, 0, 50),
            Name = "TopBar"
        }), {
            WindowName,
            WindowTopBarLine,
            AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 7), {
                Size = UDim2.new(0, 70, 0, 30),
                Position = UDim2.new(1, -90, 0, 10)
            }), {
                AddThemeObject(MakeElement("Stroke"), "Stroke"),
                AddThemeObject(SetProps(MakeElement("Frame"), {
                    Size = UDim2.new(0, 1, 1, 0),
                    Position = UDim2.new(0.5, 0, 0, 0)
                }), "Stroke"), 
                CloseBtn,
                MinimizeBtn
            }), "Second"), 
        }),
        DragPoint,
        WindowStuff
    }), "Main")

    if WindowConfig.ShowIcon then
        WindowName.Position = UDim2.new(0, 50, 0, -24)
        local WindowIcon = SetProps(MakeElement("Image", WindowConfig.Icon), {
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 25, 0, 15)
        })
        WindowIcon.Parent = MainWindow.TopBar
    end    

    MakeDraggable(DragPoint, MainWindow)

    AddConnection(CloseBtn.MouseButton1Up, function()
        MainWindow.Visible = false
        UIHidden = true
        OrionLib:MakeNotification({
            Name = "Interface Hidden",
            Content = "Tap RightShift to reopen the interface",
            Time = 5
        })
        WindowConfig.CloseCallback()
    end)

    AddConnection(UserInputService.InputBegan, function(Input)
        if Input.KeyCode == Enum.KeyCode.RightShift and UIHidden then
            MainWindow.Visible = true
        end
    end)

    AddConnection(MinimizeBtn.MouseButton1Up, function()
        if Minimized then
            TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, 615, 0, 344)}):Play()
            MinimizeBtn.Ico.Image = "rbxassetid://7072719338"
            wait(.02)
            MainWindow.ClipsDescendants = false
            WindowStuff.Visible = true
            WindowTopBarLine.Visible = true
        else
            MainWindow.ClipsDescendants = true
            WindowTopBarLine.Visible = false
            MinimizeBtn.Ico.Image = "rbxassetid://7072720870"

            TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, WindowName.TextBounds.X + 140, 0, 50)}):Play()
            wait(0.1)
            WindowStuff.Visible = false    
        end
        Minimized = not Minimized    
    end)

    local function LoadSequence()
        MainWindow.Visible = false
        local LoadSequenceLogo = SetProps(MakeElement("Image", WindowConfig.IntroIcon), {
            Parent = Orion,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.4, 0),
            Size = UDim2.new(0, 28, 0, 28),
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            ImageTransparency = 1
        })

        local LoadSequenceText = SetProps(MakeElement("Label", WindowConfig.IntroText, 14), {
            Parent = Orion,
            Size = UDim2.new(1, 0, 1, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 19, 0.5, 0),
            TextXAlignment = Enum.TextXAlignment.Center,
            Font = Enum.Font.GothamBold,
            TextTransparency = 1
        })

        TweenService:Create(LoadSequenceLogo, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0, Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
        wait(0.8)
        TweenService:Create(LoadSequenceLogo, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -(LoadSequenceText.TextBounds.X/2), 0.5, 0)}):Play()
        wait(0.3)
        TweenService:Create(LoadSequenceText, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
        wait(2)
        TweenService:Create(LoadSequenceText, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
        MainWindow.Visible = true
        LoadSequenceLogo:Destroy()
        LoadSequenceText:Destroy()
    end 

    if WindowConfig.IntroEnabled then
        LoadSequence()
    end    

    local TabFunction = {}
    function TabFunction:MakeTab(TabConfig)
        TabConfig = TabConfig or {}
        TabConfig.Name = TabConfig.Name or "Tab"
        TabConfig.Icon = TabConfig.Icon or ""
        TabConfig.PremiumOnly = TabConfig.PremiumOnly or false

        local TabFrame = SetChildren(SetProps(MakeElement("Button"), {
            Size = UDim2.new(1, 0, 0, 30),
            Parent = TabHolder
        }), {
            AddThemeObject(SetProps(MakeElement("Image", TabConfig.Icon), {
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, 18, 0, 18),
                Position = UDim2.new(0, 10, 0.5, 0),
                ImageTransparency = 0.4,
                Name = "Ico"
            }), "Text"),
            AddThemeObject(SetProps(MakeElement("Label", TabConfig.Name, 14), {
                Size = UDim2.new(1, -35, 1, 0),
                Position = UDim2.new(0, 35, 0, 0),
                Font = Enum.Font.GothamSemibold,
                TextTransparency = 0.4,
                Name = "Title"
            }), "Text")
        })

        if GetIcon(TabConfig.Icon) ~= nil then
            TabFrame.Ico.Image = GetIcon(TabConfig.Icon)
        end    

        local Container = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255, 255, 255), 5), {
            Size = UDim2.new(1, -150, 1, -50),
            Position = UDim2.new(0, 150, 0, 50),
            Parent = MainWindow,
            Visible = false,
            Name = "ItemContainer"
        }), {
            MakeElement("List", 0, 6),
            MakeElement("Padding", 15, 10, 10, 15)
        }), "Divider")

        AddConnection(Container.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            Container.CanvasSize = UDim2.new(0, 0, 0, Container.UIListLayout.AbsoluteContentSize.Y + 30)
        end)

        if FirstTab then
            FirstTab = false
            TabFrame.Ico.ImageTransparency = 0
            TabFrame.Title.TextTransparency = 0
            TabFrame.Title.Font = Enum.Font.GothamBlack
            Container.Visible = true
        end    

        AddConnection(TabFrame.MouseButton1Click, function()
            for _, Tab in next, TabHolder:GetChildren() do
                if Tab:IsA("TextButton") then
                    Tab.Title.Font = Enum.Font.GothamSemibold
                    TweenService:Create(Tab.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 0.4}):Play()
                    TweenService:Create(Tab.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0.4}):Play()
                end    
            end
            for _, ItemContainer in next, MainWindow:GetChildren() do
                if ItemContainer.Name == "ItemContainer" then
                    ItemContainer.Visible = false
                end    
            end  
            TweenService:Create(TabFrame.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
            TweenService:Create(TabFrame.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
            TabFrame.Title.Font = Enum.Font.GothamBlack
            Container.Visible = true   
        end)

        local function GetElements(ItemParent)
            local ElementFunction = {}
            function ElementFunction:AddLabel(Text)
                local LabelFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 0.7,
                    Parent = ItemParent
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", Text, 15), {
                        Size = UDim2.new(1, -12, 1, 0),
                        Position = UDim2.new(0, 12, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Name = "Content"
                    }), "Text"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke")
                }), "Second")

                local LabelFunction = {}
                function LabelFunction:Set(ToChange)
                    LabelFrame.Content.Text = ToChange
                end
                return LabelFunction
            end
            function ElementFunction:AddParagraph(Text, Content)
                Text = Text or "Text"
                Content = Content or "Content"

                local ParagraphFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 0.7,
                    Parent = ItemParent
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", Text, 15), {
                        Size = UDim2.new(1, -12, 0, 14),
                        Position = UDim2.new(0, 12, 0, 10),
                        Font = Enum.Font.GothamBold,
                        Name = "Title"
                    }), "Text"),
                    AddThemeObject(SetProps(MakeElement("Label", Content, 13), {
                        Size = UDim2.new(1, -12, 0, 14),
                        Position = UDim2.new(0, 12, 0, 25),
                        Font = Enum.Font.GothamSemibold,
                        TextColor3 = Color3.fromRGB(200, 200, 200),
                        TextTransparency = 0.1,
                        Name = "Content"
                    }), "TextDark"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke")
                }), "Second")

                local ParagraphFunction = {}
                function ParagraphFunction:SetTitle(ToChange)
                    ParagraphFrame.Title.Text = ToChange
                end    
                function ParagraphFunction:SetContent(ToChange)
                    ParagraphFrame.Content.Text = ToChange
                end
                return ParagraphFunction
            end

            function ElementFunction:AddButton(ButtonConfig)
                ButtonConfig = ButtonConfig or {}
                ButtonConfig.Name = ButtonConfig.Name or "Button"
                ButtonConfig.Callback = ButtonConfig.Callback or function() end

                local Button = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 0.7,
                    Parent = ItemParent
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", ButtonConfig.Name, 14), {
                        Size = UDim2.new(1, -12, 1, 0),
                        Position = UDim2.new(0, 12, 0, 0),
                        Font = Enum.Font.GothamBold
                    }), "Text"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    MakeElement("Button")
                }), "Second")

                AddConnection(Button.Button.MouseButton1Click, function()
                    ButtonConfig.Callback()
                    if ButtonConfig.DoubleClick then
                        Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                        wait(0.1)
                        Button.BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second
                    end
                end)

                if ButtonConfig.DoubleClick then
                    AddConnection(Button.Button.MouseEnter, function()
                        TweenService:Create(Button, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
                    end)
                    AddConnection(Button.Button.MouseLeave, function()
                        TweenService:Create(Button, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0.7}):Play()
                    end)
                end

                local ButtonFunction = {}
                function ButtonFunction:SetText(ToChange)
                    Button.Content.Text = ToChange
                end
                return ButtonFunction
            end

            function ElementFunction:AddTextbox(TextboxConfig)
                TextboxConfig = TextboxConfig or {}
                TextboxConfig.Name = TextboxConfig.Name or "Textbox"
                TextboxConfig.Default = TextboxConfig.Default or ""
                TextboxConfig.TextDisappear = TextboxConfig.TextDisappear or false
                TextboxConfig.Callback = TextboxConfig.Callback or function() end

                local Textbox = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 0.7,
                    Parent = ItemParent
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", TextboxConfig.Name, 14), {
                        Size = UDim2.new(1, -12, 1, 0),
                        Position = UDim2.new(0, 12, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Name = "Content"
                    }), "Text"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    SetProps(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(40, 40, 40), 0, 5), {
                        Size = UDim2.new(0.5, 0, 0, 24),
                        Position = UDim2.new(0, 12, 0, 5)
                    }), {
                        AddThemeObject(SetProps(MakeElement("Textbox"), {
                            PlaceholderColor3 = Color3.fromRGB(255, 255, 255),
                            TextColor3 = Color3.fromRGB(240, 240, 240),
                            TextSize = 14,
                            ClipsDescendants = true,
                            Position = UDim2.new(0, 8, 0, -1),
                            Size = UDim2.new(1, -8, 1, 0),
                            BackgroundTransparency = 1,
                            Text = TextboxConfig.Default
                        }), "Text"),
                    }), "Main"),
                }), "Second")

                AddConnection(Textbox.Textbox.FocusLost, function()
                    TextboxConfig.Callback(Textbox.Textbox.Text)
                    if TextboxConfig.TextDisappear then
                        Textbox.Textbox.Text = ""
                    end
                end)

                local TextboxFunction = {}
                function TextboxFunction:SetText(ToChange)
                    Textbox.Textbox.Text = ToChange
                end
                return TextboxFunction
            end

            function ElementFunction:AddToggle(ToggleConfig)
                ToggleConfig = ToggleConfig or {}
                ToggleConfig.Name = ToggleConfig.Name or "Toggle"
                ToggleConfig.Default = ToggleConfig.Default or false
                ToggleConfig.Save = ToggleConfig.Save or false
                ToggleConfig.Callback = ToggleConfig.Callback or function() end

                local Toggle = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 0.7,
                    Parent = ItemParent
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", ToggleConfig.Name, 14), {
                        Size = UDim2.new(1, -12, 1, 0),
                        Position = UDim2.new(0, 12, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Name = "Content"
                    }), "Text"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(40, 40, 40), 0, 5), {
                        Size = UDim2.new(0, 24, 0, 24),
                        Position = UDim2.new(1, -36, 0.5, -12)
                    }), {
                        MakeElement("Stroke"),
                        AddThemeObject(SetProps(MakeElement("ImageButton", "rbxassetid://7072719338"), {
                            Size = UDim2.new(0, 16, 0, 16),
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Position = UDim2.new(0.5, 0, 0.5, 0)
                        }), "Text")
                    })
                }), "Second")

                OrionLib.Flags[ToggleConfig.Name] = {
                    Type = "Toggle",
                    Value = ToggleConfig.Default,
                    Callback = ToggleConfig.Callback,
                    Save = ToggleConfig.Save,
                    Object = Toggle
                }

                if ToggleConfig.Default then
                    Toggle.ImageButton.Image = "rbxassetid://7072722348"
                    spawn(function() ToggleConfig.Callback(true) end)
                end    

                AddConnection(Toggle.ImageButton.MouseButton1Click, function()
                    OrionLib.Flags[ToggleConfig.Name].Value = not OrionLib.Flags[ToggleConfig.Name].Value
                    if OrionLib.Flags[ToggleConfig.Name].Value then
                        Toggle.ImageButton.Image = "rbxassetid://7072722348"
                    else
                        Toggle.ImageButton.Image = "rbxassetid://7072719338"
                    end    
                    ToggleConfig.Callback(OrionLib.Flags[ToggleConfig.Name].Value)
                end)

                local ToggleFunction = {}
                function ToggleFunction:Set(ToChange)
                    OrionLib.Flags[ToggleConfig.Name].Value = ToChange
                    if OrionLib.Flags[ToggleConfig.Name].Value then
                        Toggle.ImageButton.Image = "rbxassetid://7072722348"
                    else
                        Toggle.ImageButton.Image = "rbxassetid://7072719338"
                    end    
                    ToggleConfig.Callback(OrionLib.Flags[ToggleConfig.Name].Value)
                end
                return ToggleFunction
            end

            function ElementFunction:AddBind(BindConfig)
                BindConfig = BindConfig or {}
                BindConfig.Name = BindConfig.Name or "Bind"
                BindConfig.Default = BindConfig.Default or Enum.KeyCode.Unknown
                BindConfig.Hold = BindConfig.Hold or false
                BindConfig.Save = BindConfig.Save or false
                BindConfig.Callback = BindConfig.Callback or function() end

                local WaitingForBind = false
                local Bind = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 0.7,
                    Parent = ItemParent
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", BindConfig.Name, 14), {
                        Size = UDim2.new(1, -12, 1, 0),
                        Position = UDim2.new(0, 12, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Name = "Content"
                    }), "Text"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    SetProps(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(40, 40, 40), 0, 5), {
                        Size = UDim2.new(0, 60, 0, 24),
                        Position = UDim2.new(1, -76, 0.5, -12)
                    }), {
                        AddThemeObject(SetProps(MakeElement("Label", BindConfig.Default == Enum.KeyCode.Unknown and "None" or BindConfig.Default.Name, 13), {
                            Size = UDim2.new(1, -8, 1, 0),
                            Position = UDim2.new(0, 8, 0, 0),
                            Font = Enum.Font.GothamBold,
                            Name = "BindText"
                        }), "TextDark")
                    }), "Main")
                }), "Second")

                OrionLib.Flags[BindConfig.Name] = {
                    Type = "Bind",
                    Value = BindConfig.Default,
                    Callback = BindConfig.Callback,
                    Save = BindConfig.Save,
                    Object = Bind
                }

                AddConnection(Bind.InputBegan, function(Input)
                    if WaitingForBind then return end
                    if not CheckKey(BlacklistedKeys, Input.KeyCode) and Input.UserInputType == Enum.UserInputType.Keyboard and not WaitingForBind then
                        if Input.KeyCode == OrionLib.Flags[BindConfig.Name].Value then
                            if not BindConfig.Hold then
                                spawn(function() BindConfig.Callback() end)
                            end    
                        end    
                    elseif not CheckKey(WhitelistedMouse, Input.UserInputType) and Input.UserInputType == OrionLib.Flags[BindConfig.Name].Value and not WaitingForBind then
                        if not BindConfig.Hold then
                            spawn(function() BindConfig.Callback() end)
                        end    
                    end    
                end)

                if BindConfig.Hold then
                    AddConnection(UserInputService.InputEnded, function(Input)
                        if WaitingForBind then return end
                        if not CheckKey(BlacklistedKeys, Input.KeyCode) and Input.UserInputType == Enum.UserInputType.Keyboard and not WaitingForBind then
                            if Input.KeyCode == OrionLib.Flags[BindConfig.Name].Value then
                                spawn(function() BindConfig.Callback() end)
                            end    
                        elseif not CheckKey(WhitelistedMouse, Input.UserInputType) and Input.UserInputType == OrionLib.Flags[BindConfig.Name].Value and not WaitingForBind then
                            spawn(function() BindConfig.Callback() end)
                        end    
                    end)
                end

                AddConnection(Bind.MouseButton1Click, function()
                    if WaitingForBind then return end
                    Bind.BindText.Text = "..."
                    WaitingForBind = true
                    local BindInput, _ = UserInputService.InputBegan:Wait()
                    local Key = BindInput.UserInputType == Enum.UserInputType.Keyboard and BindInput.KeyCode or BindInput.UserInputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseButton1
                    Bind.BindText.Text = Key.Name
                    OrionLib.Flags[BindConfig.Name].Value = Key
                    spawn(function()
                        BindConfig.Callback()
                    end)
                    wait(0.1)
                    WaitingForBind = false
                end)

                local BindFunction = {}
                function BindFunction:Set(ToChange)
                    OrionLib.Flags[BindConfig.Name].Value = ToChange
                    Bind.BindText.Text = ToChange.Name
                end    
                return BindFunction
            end

            function ElementFunction:AddSlider(SliderConfig)
                SliderConfig = SliderConfig or {}
                SliderConfig.Name = SliderConfig.Name or "Slider"
                SliderConfig.Min = SliderConfig.Min or 0
                SliderConfig.Max = SliderConfig.Max or 100
                SliderConfig.Increment = SliderConfig.Increment or 1
                SliderConfig.Default = SliderConfig.Default or 50
                SliderConfig.Decimals = SliderConfig.Decimals or 1
                SliderConfig.Callback = SliderConfig.Callback or function() end

                local Dragging = false
                local Slider = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
                    Size = UDim2.new(1, 0, 0, 40),
                    BackgroundTransparency = 0.7,
                    Parent = ItemParent
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", SliderConfig.Name, 14), {
                        Size = UDim2.new(1, -12, 1, 0),
                        Position = UDim2.new(0, 12, 0, -5),
                        Font = Enum.Font.GothamBold,
                        Name = "Content"
                    }), "Text"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    SetChildren(SetProps(MakeElement("TFrame"), {
                        Size = UDim2.new(1, -24, 0, 20),
                        Position = UDim2.new(0, 12, 0, 18)
                    }), {
                        SetProps(MakeElement("RoundFrame", Color3.fromRGB(40, 40, 40), 0, 5), {
                            Size = UDim2.new(1, 0, 1, 0)
                        }),
                        AddThemeObject(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
                            Size = UDim2.new(0, 0, 1, 0),
                            ZIndex = 2
                        }), "Second"),
                        SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(40, 40, 40), 1, 0), {
                            Size = UDim2.new(0, 16, 0, 16),
                            Position = UDim2.new(0, -8, 0.5, -8),
                            ZIndex = 3
                        }), {
                            AddThemeObject(MakeElement("Stroke"), "Stroke"),
                            MakeElement("Button")
                        })
                    })
                }), "Second")

                local SliderBar = Slider.TFrame.RoundFrame[1]
                local SliderBtn = Slider.TFrame.RoundFrame[2]

                local function SnapValue(Value)
                    if SliderConfig.Increment == 0 then
                        return math.clamp(math.floor((Value * (1 / SliderConfig.Increment) + 0.5)) / (1 / SliderConfig.Increment), SliderConfig.Min, SliderConfig.Max)
                    else
                        return math.clamp(Round(Value, SliderConfig.Increment), SliderConfig.Min, SliderConfig.Max)
                    end    
                end    

                local function SetValue(x)
                    local Value = math.clamp(x, 0, Slider.TFrame.AbsoluteSize.X) / Slider.TFrame.AbsoluteSize.X
                    Value = SnapValue(SliderConfig.Min + (SliderConfig.Max - SliderConfig.Min) * Value)
                    local Size = UDim2.new(((Value - SliderConfig.Min) / (SliderConfig.Max - SliderConfig.Min)), 0, 1, 0)
                    TweenService:Create(SliderBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(Size.X.Scale, -8, 0.5, -8)}):Play()
                    TweenService:Create(SliderBar, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Size}):Play()
                    SliderConfig.Callback(Value)
                    return Value
                end

                AddConnection(SliderBtn.Button.InputBegan, function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Dragging = true
                    end
                end)
                AddConnection(UserInputService.InputEnded, function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Dragging = false
                    end
                end)
                AddConnection(UserInputService.InputChanged, function(Input)
                    if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
                        SetValue(Mouse.X - Slider.TFrame.AbsolutePosition.X)
                    end
                end)

                SliderConfig.Default = SnapValue(SliderConfig.Default)
                local DefaultScale = (SliderConfig.Default - SliderConfig.Min) / (SliderConfig.Max - SliderConfig.Min)
                SliderBar.Size = UDim2.new(DefaultScale, 0, 1, 0)
                SliderBtn.Position = UDim2.new(DefaultScale, -8, 0.5, -8)
                spawn(function() SliderConfig.Callback(SliderConfig.Default) end)

                local SliderFunction = {}
                function SliderFunction:Set(ToChange)
                    SetValue((ToChange / SliderConfig.Max) * Slider.TFrame.AbsoluteSize.X)
                end
                return SliderFunction
            end

            function ElementFunction:AddDropdown(DropdownConfig)
                DropdownConfig = DropdownConfig or {}
                DropdownConfig.Name = DropdownConfig.Name or "Dropdown"
                DropdownConfig.Options = DropdownConfig.Options or {}
                DropdownConfig.Default = DropdownConfig.Default or DropdownConfig.Options[1]
                DropdownConfig.Callback = DropdownConfig.Callback or function() end

                local DropdownSize = UDim2.new(1, 0, 0, 30)
                local OptionSelected = DropdownConfig.Default
                local Dropdown = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
                    Size = DropdownSize,
                    BackgroundTransparency = 0.7,
                    Parent = ItemParent,
                    ClipsDescendants = true
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", DropdownConfig.Name, 14), {
                        Size = UDim2.new(1, -12, 1, 0),
                        Position = UDim2.new(0, 12, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Name = "Content"
                    }), "Text"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(40, 40, 40), 0, 5), {
                        Size = UDim2.new(0.5, 0, 0, 24),
                        Position = UDim2.new(0, 12, 0, 5)
                    }), {
                        AddThemeObject(SetProps(MakeElement("Label", DropdownConfig.Default, 14), {
                            Size = UDim2.new(1, -8, 1, 0),
                            Position = UDim2.new(0, 8, 0, 0),
                            Font = Enum.Font.GothamBold,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            Name = "Selected"
                        }), "Text"),
                        AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072706622"), {
                            Size = UDim2.new(0, 12, 0, 12),
                            Position = UDim2.new(1, -16, 0.5, -6),
                            ImageTransparency = 0.4
                        }), "TextDark"),
                        MakeElement("Button")
                    })
                }), "Second")

                local function CreateOptions()
                    for _, Element in pairs(Dropdown:GetChildren()) do
                        if not Element:IsA("UIStroke") and not Element:IsA("UICorner") and not Element:IsA("UIPadding") then
                            if Element.Name ~= "Container" and Element.Name ~= "Content" then
                                Element:Destroy()
                            end
                        end    
                    end    

                    Dropdown.Size = DropdownSize
                    if Dropdown.Container then
                        Dropdown.Container:Destroy()
                    end    

                    Dropdown.Container = AddThemeObject(SetProps(MakeElement("TFrame"), {
                        Position = UDim2.new(0, 0, 1, 0),
                        Size = UDim2.new(1, 0, 0, (#DropdownConfig.Options * 30) + 6),
                        ClipsDescendants = true,
                        Parent = Dropdown
                    }), "Main")

                    SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(40, 40, 40), 0, 5), {
                        Size = UDim2.new(1, -12, 1, -6),
                        Position = UDim2.new(0, 6, 0, 6),
                        BackgroundTransparency = 0.6
                    }), {
                        AddThemeObject(MakeElement("Stroke"), "Stroke"),
                        SetChildren(SetProps(MakeElement("TFrame"), {
                            Size = UDim2.new(1, 0, 1, 0)
                        }), {
                            AddThemeObject(SetProps(MakeElement("List", 0, 6), {
                                SortOrder = Enum.SortOrder.LayoutOrder
                            }), "Divider")
                        })
                    }).Parent = Dropdown.Container

                    Dropdown.Size = UDim2.new(1, 0, 0, (Dropdown.Container.AbsoluteSize.Y) + 30)
                    for _, Option in ipairs(DropdownConfig.Options) do
                        local OptionBtn = SetProps(SetChildren(SetProps(MakeElement("Button"), {
                            Size = UDim2.new(1, 0, 0, 30),
                            BackgroundTransparency = 1,
                            Parent = Dropdown.Container
                        }), {
                            AddThemeObject(SetProps(MakeElement("Label", Option, 14), {
                                Size = UDim2.new(1, -20, 1, 0),
                                Position = UDim2.new(0, 20, 0, 0),
                                Font = Enum.Font.GothamBold,
                                TextXAlignment = Enum.TextXAlignment.Left
                            }), "Text"),
                            AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072706622"), {
                                Size = UDim2.new(0, 12, 0, 12),
                                Position = UDim2.new(0, 8, 0.5, -6),
                                ImageTransparency = 1
                            }), "Text")
                        }), {
                            Name = Option
                        })

                        if Option == OptionSelected then
                            OptionBtn.Image.ImageTransparency = 0
                        end    

                        AddConnection(OptionBtn.MouseButton1Click, function()
                            TweenService:Create(Dropdown.Image, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = 0}):Play()
                            for _, Element in pairs(Dropdown.Container:GetChildren()) do
                                if not Element:IsA("UIListLayout") and not Element:IsA("UIPadding") then
                                    if Element.Name ~= Option then
                                        TweenService:Create(Element.Image, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 1}):Play()
                                    end    
                                end    
                            end    

                            OptionBtn.Image.ImageTransparency = 0
                            Dropdown.Selected.Text = Option
                            OptionSelected = Option
                            spawn(function() DropdownConfig.Callback(Option) end)
                            wait(.2)
                            Dropdown.Container:Destroy()
                            Dropdown.Size = DropdownSize
                        end)
                    end    
                end

                AddConnection(Dropdown.Button.MouseButton1Click, function()
                    if Dropdown.Container then
                        Dropdown.Container:Destroy()
                        Dropdown.Size = DropdownSize
                    else    
                        CreateOptions()
                        Dropdown.Container.Size = UDim2.new(1, 0, 0, 0)
                        TweenService:Create(Dropdown.Container, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, (#DropdownConfig.Options * 30) + 6)}):Play()
                        TweenService:Create(Dropdown.Image, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = 180}):Play()
                    end
                end)

                local DropdownFunction = {}
                function DropdownFunction:Set(ToChange)
                    Dropdown.Selected.Text = ToChange
                    OptionSelected = ToChange
                    DropdownConfig.Callback(ToChange)
                end    
                function DropdownFunction:Refresh(OptionsTable, Delete)
                    if Delete then
                        DropdownConfig.Options = OptionsTable
                        CreateOptions()
                    else    
                        DropdownConfig.Options = OptionsTable
                    end
                end
                return DropdownFunction
            end

            function ElementFunction:AddColorpicker(ColorpickerConfig)
                ColorpickerConfig = ColorpickerConfig or {}
                ColorpickerConfig.Name = ColorpickerConfig.Name or "Colorpicker"
                ColorpickerConfig.Default = ColorpickerConfig.Default or Color3.fromRGB(255, 255, 255)
                ColorpickerConfig.Callback = ColorpickerConfig.Callback or function() end
                ColorpickerConfig.Save = ColorpickerConfig.Save or false

                local OldToggleColor = ColorpickerConfig.Default
                local ColorH, ColorS, ColorV = Color3.toHSV(ColorpickerConfig.Default)

                local Colorpicker = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 0.7,
                    Parent = ItemParent
                }), {
                    AddThemeObject(SetProps(MakeElement("Label", ColorpickerConfig.Name, 14), {
                        Size = UDim2.new(1, -12, 1, 0),
                        Position = UDim2.new(0, 12, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Name = "Content"
                    }), "Text"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    SetChildren(SetProps(MakeElement("RoundFrame", OldToggleColor, 0, 5), {
                        Size = UDim2.new(0, 24, 0, 24),
                        Position = UDim2.new(1, -36, 0.5, -12)
                    }), {
                        MakeElement("Stroke"),
                        MakeElement("Button")
                    })
                }), "Second")

                OrionLib.Flags[ColorpickerConfig.Name] = {
                    Type = "Colorpicker",
                    Value = ColorpickerConfig.Default,
                    Callback = ColorpickerConfig.Callback,
                    Save = ColorpickerConfig.Save,
                    OldColor = OldToggleColor,
                    Object = Colorpicker
                }

                local function UpdateToggleColor()
                    OrionLib.Flags[ColorpickerConfig.Name].OldColor = Color3.fromHSV(ColorH, ColorS, ColorV)
                    Colorpicker.RoundFrame.BackgroundColor3 = Color3.fromHSV(ColorH, ColorS, ColorV)
                    OrionLib.Flags[ColorpickerConfig.Name].Callback(Colorpicker.RoundFrame.BackgroundColor3)
                end    

                local function SetColor(Value)
                    local XScale = (math.clamp(Value.X - Colorpicker.Container.AbsolutePosition.X, 0, Colorpicker.Container.AbsoluteSize.X) / Colorpicker.Container.AbsoluteSize.X)
                    local YScale = (math.clamp(Value.Y - Colorpicker.Container.AbsolutePosition.Y, 0, Colorpicker.Container.AbsoluteSize.Y) / Colorpicker.Container.AbsoluteSize.Y)
                    Colorpicker.Select.Position = UDim2.new(XScale, 0, YScale, 0)
                    ColorH = 1 - XScale
                    ColorS = 1 - YScale
                    UpdateToggleColor()
                end    

                AddConnection(Colorpicker.Button.MouseButton1Click, function()
                    if Colorpicker.Container then
                        Colorpicker.Container:Destroy()
                    else    
                        local Displaying = true
                        Colorpicker.Container = SetProps(MakeElement("TFrame"), {
                            Size = UDim2.new(1, 0, 0, 0),
                            Parent = Colorpicker
                        })

                        local ColorContainer = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(40, 40, 40), 0, 5), {
                            Size = UDim2.new(1, -12, 0, 90),
                            Position = UDim2.new(0, 6, 0, 6),
                            BackgroundTransparency = 0.6
                        }), {
                            MakeElement("Stroke"),
                            SetChildren(SetProps(MakeElement("Image", "rbxassetid://4155801252"), {
                                Size = UDim2.new(1, 0, 1, 0),
                                ZIndex = 3,
                                ImageColor3 = OldToggleColor
                            }), {
                                SetProps(MakeElement("Image", "rbxassetid://3641079629"), {
                                    Size = UDim2.new(1, 0, 1, 0),
                                    ImageTransparency = 1
                                }),
                                AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://3887014957"), {
                                    Size = UDim2.new(1, 0, 1, 0),
                                    ImageTransparency = 0.6,
                                    ZIndex = 2
                                }), "Second"),
                                SetProps(MakeElement("ImageButton", "rbxassetid://3887017050"), {
                                    Size = UDim2.new(0, 10, 0, 10),
                                    Position = UDim2.new(0, 1, 0, 1),
                                    ZIndex = 4
                                }),
                            })
                        }), "Main")

                        ColorContainer.Parent = Colorpicker.Container
                        Colorpicker.Container.Size = UDim2.new(1, 0, 0, 102)

                        Colorpicker.Select = ColorContainer.ImageButton
                        SetColor(Vector2.new(ColorContainer.AbsolutePosition.X, ColorContainer.AbsolutePosition.Y))

                        AddConnection(Colorpicker.Select.InputBegan, function(Input)
                            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                                Dragging = true
                            end    
                        end)
                        AddConnection(UserInputService.InputEnded, function(Input)
                            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                                Dragging = false
                            end    
                        end)
                        AddConnection(UserInputService.InputChanged, function(Input)
                            if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
                                SetColor(Input.Position)
                            end
                        end)

                        local function UpdateTransparency(TransparencyValue)
                            ColorV = TransparencyValue
                            UpdateToggleColor()
                            ColorContainer.Image.ImageColor3 = Color3.fromHSV(0, 0, TransparencyValue)
                        end    

                        UpdateTransparency(1)
                    end
                end)

                local ColorpickerFunction = {}
                function ColorpickerFunction:Set(ToChange)
                    OrionLib.Flags[ColorpickerConfig.Name].Value = ToChange
                    OldToggleColor = ToChange
                    UpdateToggleColor()
                end    
                return ColorpickerFunction
            end

            return ElementFunction
        end    

        return GetElements(Container)
    end    

    return TabFunction
end    

return OrionLib
