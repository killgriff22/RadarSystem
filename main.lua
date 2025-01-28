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
local rays = 300
local arcangle = 60
local Zero = Vector2.__new(0,0)
local One = Vector2.__new(1,1)
local first = Vector2.__new(1,1)
local second = Vector2.__new(-1,1)
local third = Vector2.__new(-1,-1)
local fourth = Vector2.__new(1,-1)
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
function degsToRads(degs)
    return degs * math.pi / 180
end
function radsToDegs(rads)
    return rads * 180 / math.pi
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
    
    radarhead.SetSize( Vector3.__new( 0.5, 0, 1) )
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
function vect2angle(vect)
    return math.atan2(vect.x, vect.z)
end
function angle2vect3(angle)
    return Vector3.__new(math.cos(angle),0, math.sin(angle))
end
function angle2vect2(angle)
    return Vector2.__new(math.cos(angle), math.sin(angle))
end
function rotatepoint(point, angle)
    local sin = math.sin(angle)
    local cos = math.cos(angle)
    local x = point.x * cos - point.y * sin
    local y = point.x * sin + point.y * cos
    return Vector2.__new(x, y)
    
end
function rotatepointvect3(point, vect)
    local angle = vect2angle(vect)
    return rotatepoint(point, angle)
    
end
populatemainwin()
function Update()
    if not Radar then
        return
    end
    shapes.Clear()

    local shapesRect = shapes.PixelRect
    local edge = shapesRect.Size.x
    -- rotate line to match radar forward
    for i, hit in ipairs(hits) do
        local pos = hit[1]
        local frametime = hit[2]
        if frametime <= 0 then
            table.remove(hits, i)
        else
            hits[i][2] = frametime - 1
            shapes.AddQuad( pos, Vector2.__new( 10, 10 ), Colour.__new( 255, 0, 0, 255 ) )
        end 
    end
    poslabel.Text = Radar.Position
    rotlabel.Text = Radar.Forward
    local point = Vector2.__new(edge,0)
    point = rotatepointvect3(point, -Radar.Forward)
    --shapes.AddLine({Zero, point}, 5)
    point = rotatepoint(point, degsToRads(arcangle/2))
    shapes.AddLine({Zero, point}, 5)
    point = rotatepoint(point, -degsToRads(arcangle))
    shapes.AddLine({Zero, point}, 5)
    for i=1, rays do
        local angle = -Radar.Forward
        angle = angle - angle2vect3(degsToRads(arcangle/2))
        angle = angle + angle2vect3(degsToRads(arcangle/(rays-1)*i))
        if Physics.RayCast( Radar.Position+(angle*0.1), angle, maxdistance ) then
            local distance, position, normal, colliderInstanceID = Physics.QueryCastHit( 0 )
            local pos = rotatepointvect3(Vector2.__new( distance , -5 ), angle)
            for i, hit in ipairs(hits) do
                if hit[1] == pos then
                    hit[2] = 60
                    return
                end
            end
            append(hits, {pos, maxframetime})
        end
    end
end
function Cleanup()
    Windows.DestroyWindow(win)
    PopConstructions.DestroyPart(Radar.ID)
end

