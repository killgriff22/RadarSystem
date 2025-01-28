local Radar = nil
local localplayer = LocalPlayer.value
local win = nil
local RadarPartName = 'Connector 1-Hole Axle Resizable'
local poslabel = nil
local collabel = nil
local rotlabel = nil
local shapes = nil
local hits = {}
local maxdistance = 500
local maxframetime = 150
local rays = 120
local arcangle = 30
function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
  end
function append(t, v)
    t[tablelength(t)+1] = v
end
function remove(t, v)
    for i, value in ipairs(t) do
        if value == v then
            table.remove(t, i)
            return
        end
    end
end
function pop(t, i)
    local value = t[i]
    table.remove(t, i)
    return value 
end
local function SpawnRadar()
    print('Spawning radar')
    local parts = {  }
    local radarhead = nil
    for part in Parts.Instances do
        parts[part.ID] = part
    end
    local position = Vector3.__new (
        localplayer.Aim.Position.X + 3 * math.sin(math.pi * localplayer.Aim.Orientation.EulerAngles.Y / 180) * math.abs(math.cos(math.pi * localplayer.Aim.Orientation.EulerAngles.X / 180)),
        localplayer.Aim.Position.Y + 3 * math.sin(math.pi * (-localplayer.Aim.Orientation.EulerAngles.X) / 180),
        localplayer.Aim.Position.Z + 3 * math.cos(math.pi * localplayer.Aim.Orientation.EulerAngles.Y / 180) * math.abs(math.cos(math.pi * localplayer.Aim.Orientation.EulerAngles.X / 180))
    )
    local rotation = Quaternion.Euler( 
        0, 
        0, 
        0
    )
    PopConstructions.SpawnPart( RadarPartName, position, rotation )
    for part in Parts.Instances do
        if not parts[part.ID] then
            radarhead = part
        end
    end
    
    radarhead.SetSize( Vector3.__new( 0.5, 0, 4) )
    Radar = radarhead
end

local function CreateWindow(l, w, closefunc)
    win = Windows.CreateWindow()
    win.SetAlignment(align_RightEdge, 20, l)
    win.SetAlignment(align_TopEdge, 80, w)
    win.OnClose.add(closefunc)
    win.Title = ""
    win.Show(true)
    return win
end
local function CreateLabel(x,y,w,h,txt,win)
    local lbl = win.CreateLabel()
    lbl.SetAlignment(align_RightEdge,  x, w)
    lbl.SetAlignment(align_TopEdge,  y, h)
    lbl.Text = txt
    return lbl
    
end

local function CreateButton(x,y,w,h,txt,win,clickfunc)
    local btn = win.CreateTextButton()
    btn.SetAlignment(align_RightEdge,  x, w)
    btn.SetAlignment(align_TopEdge,  y, h)
    btn.Text = txt
    btn.OnClick.add(clickfunc)
    return btn
end
local function onWindowClose()
    UnloadScript.Raise(ScriptName) -- Window closed, so unload this script.
end

local function populatemainwin()

    local win = CreateWindow(maxdistance, maxdistance, onWindowClose)
    win.Title = 'Radar View'
    SpawnRadar()
    CreateLabel(10, 10, 100, 20, 'Radar Position', win)
    poslabel = CreateLabel(10, 30, 100, 20, Radar.Position, win)
    CreateLabel(10, 50, 100, 20, 'Radar Rotation', win)
    rotlabel = CreateLabel(10, 70, 100, 20, Radar.Forward, win)
    CreateLabel(10, 90, 100, 20, 'Radar Collided?', win)
    collabel = CreateLabel(10, 110, 100, 20, "N/A", win)
    shapes = win.CreateShapes()
    shapes.SetAlignment( align_HorizEdges, 5, 5 )
    shapes.SetAlignment( align_VertEdges, 5, 5 )
end
populatemainwin()
function Update()
    if not Radar then
        return
    end
    shapes.Clear()

    local shapesRect = shapes.PixelRect
    local edge = shapesRect.Size.x
    local linepoints = {
        Vector2.__new( 0, 0 ),
        Vector2.__new( edge, 0 )
    }
    -- rotate line to match radar forward
    local angle = math.atan2(Radar.Forward.x, Radar.Forward.z)
    local sin = math.sin(angle)
    local cos = math.cos(angle)
    for i, point in ipairs(linepoints) do
        local x = point.x
        local z = point.y
        point.x = x * cos - z * sin
        point.y = x * sin + z * cos
    end
    for i, hit in ipairs(hits) do
        local pos = hit[1]
        local frametime = hit[2]
        if frametime <= 0 then
            table.remove(hits, i)
        else
            hits[i][2] = frametime - 1
            print(frametime)
            shapes.AddQuad( pos, Vector2.__new( 10, 10 ), Colour.__new( 255, 0, 0, 255 ) )
        end 
    end
    shapes.addLine( linepoints, 5 )
    poslabel.Text = Radar.Position
    rotlabel.Text = Radar.Forward
    if Physics.RayCast( Radar.Position+(-Radar.Forward*0.1), -Radar.Forward, maxdistance ) then
        local distance, position, normal, colliderInstanceID = Physics.QueryCastHit( 0 )
        collabel.Text = "Yes"
        local pos = Vector2.__new( distance*10-5 , -5 )
        local x = pos.x
        local z = pos.y
        pos.x = x * cos - z * sin
        pos.y = x * sin + z * cos
        for i, hit in ipairs(hits) do
            if hit[1] == pos then
                hit[2] = 60
                return
            end
        end
        hits[tablelength(hits)+1] = {pos, maxframetime}
        print("Hit at ")
        print(pos.x)
        print(pos.y)
    else
        collabel.Text = "No"
    end
end
function Cleanup()
    Windows.DestroyWindow(win)
    PopConstructions.DestroyPart(Radar.ID)
end

