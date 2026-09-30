"""Whole-floor mockup of floor 100 built from the prop pack, to preview the layout before it goes into Roblox.

Zones: elevator lobby + reception (west), restrooms (south-west), trading floor (center), glass offices + meeting room
(north), print/phone-booth strip (south), cafeteria (north-east), game lounge (south-east).
Run after props.py:  python3 office_scene.py [-- view names]   -> renders/office_*.png + office_scene.blend
"""
import math
import os
import random
import sys

import bpy
from mathutils import Vector

D = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, D)
import bmesh  # noqa: E402
from lib import finish, mat, render  # noqa: E402

R = math.radians
rng = random.Random(11)
bpy.ops.wm.open_mainfile(filepath=os.path.join(D, "props.blend"))
sc = bpy.context.scene
for o in list(sc.objects):  # drop the old studio set, keep the props as templates
    if o.type in {"CAMERA", "LIGHT"} or (o.type == "MESH" and o.parent is None):
        bpy.data.objects.remove(o, do_unlink=True)
TEMPLATES = [o for o in sc.objects if o.type == "EMPTY" and o.parent is None]
CEILING_STUFF = []  # hidden in the bird's-eye views


_UNIT_CUBE = None
# Everything placed at scene level is also recorded here and written to roblox/src/shared/OfficeLayout.lua,
# so the Roblox office is built from exactly this layout (Blender meters, Z up; the game converts to studs).
LAYOUT = {"parts": [], "props": [], "screens": [], "tickers": [], "signs": [], "lights": [], "chaos": [], "points": {}, "boards": []}
RECORD = [True]


def cube(name, size, loc, scale=(1, 1, 1), material=None, parent=None, rot=(0, 0, 0), bevel=0.02, **kw):
    """Same as lib.cube, but built straight from mesh data: bpy.ops primitives crawl in a scene this big."""
    global _UNIT_CUBE
    if _UNIT_CUBE is None:
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=1.0)
        _UNIT_CUBE = bpy.data.meshes.new("UnitCube")
        bm.to_mesh(_UNIT_CUBE)
        bm.free()
    me = _UNIT_CUBE.copy()  # own copy: finish() appends materials to the mesh
    o = bpy.data.objects.new(name, me)
    sc.collection.objects.link(o)
    o.location = loc
    o.rotation_euler = rot
    o.scale = tuple(v * size for v in scale)
    if bevel:
        b = o.modifiers.new("Bevel", "BEVEL")
        b.width = bevel
        b.segments = 3
    kw.setdefault("smooth", False)
    if parent is None and RECORD[0]:
        LAYOUT["parts"].append({"n": name, "p": tuple(loc), "s": tuple(v * size for v in scale), "r": rot[2],
                                "m": material.name if material else "SceneWall"})
    return finish(o, material, parent, **kw)


def text(name, body, loc, size, material, parent=None, rot=(R(90), 0, 0), extrude=0.004):
    cu = bpy.data.curves.new(name, "FONT")
    cu.body = body
    cu.size = size
    cu.extrude = extrude
    cu.align_x = "CENTER"
    cu.align_y = "CENTER"
    cu.materials.append(material)
    o = bpy.data.objects.new(name, cu)
    sc.collection.objects.link(o)
    o.location = loc
    o.rotation_euler = rot
    if parent:
        o.parent = parent
    elif name == "TickerText":
        LAYOUT["tickers"].append({"p": tuple(loc), "r": rot[2], "len": 18.0})
    return o


def kids(o):
    out = []
    for c in o.children:
        out.append(c)
        out += kids(c)
    return out


def place(name, loc, rot=0.0, scale=1.0, ceiling=False, record=True):
    """Linked copy of a prop template. rot turns the prop's front (-Y) around Z: 0 = faces -Y, pi = +Y,
    R(90) = +X, R(-90) = -X."""
    root = bpy.data.objects.get(name)
    if root is None:
        print("missing prop", name)
        return None
    copies = {}
    for o in [root] + kids(root):
        n = o.copy()  # shares mesh data, like a linked duplicate
        sc.collection.objects.link(n)
        copies[o] = n
    for o, n in copies.items():
        if o.parent in copies:
            n.parent = copies[o.parent]
    new_root = copies[root]
    new_root.location = loc
    new_root.rotation_euler = (0, 0, rot)
    new_root.scale = (scale, scale, scale)
    if ceiling:
        CEILING_STUFF.append(new_root)
    if record and RECORD[0]:
        LAYOUT["props"].append({"n": name, "p": tuple(loc), "r": rot, "s": scale})
    return new_root


W, L, H = 48.0, 34.0, 3.6  # floor width (x), length (y), ceiling height
X0, X1, Y0, Y1 = -W / 2, W / 2, -L / 2, L / 2
CARPET = mat("SceneCarpet", (0.07, 0.08, 0.16), 0.95)
MARBLE_FLOOR = bpy.data.materials["Marble_White"]
TILE = mat("SceneTile", (0.75, 0.78, 0.8), 0.3)
CAFE_FLOOR = bpy.data.materials["WoodPlanks_Oak"]
LOUNGE_FLOOR = mat("SceneLoungeCarpet", (0.35, 0.05, 0.08), 0.95)
CEILING = mat("SceneCeiling", (0.85, 0.82, 0.76), 0.8)
MULLION = mat("SceneMullion", (0.03, 0.03, 0.035), 0.4, 0.8)
GLASSWALL = mat("SceneGlass", (0.8, 0.9, 0.95), 0.02)
GLASSWALL.node_tree.nodes["Principled BSDF"].inputs["Transmission Weight"].default_value = 0.95
WALL = mat("SceneWall", (0.9, 0.88, 0.84), 0.7)
WALNUT = bpy.data.materials["Wood_Walnut"]
MARBLE_BLK = bpy.data.materials["Marble_Black"]
RUNNER = mat("SceneRunner", (0.45, 0.05, 0.08), 0.95)
SCREEN_BG = mat("SceneScreen", (0.01, 0.015, 0.03), 0.2, emit=0.5)
UP = mat("CandleUp", (0.15, 1.0, 0.35), 0.3, emit=3)
DOWN = mat("CandleDown", (1.0, 0.15, 0.2), 0.3, emit=3)
TICK = mat("TickerText", (1.0, 0.8, 0.2), 0.3, emit=4)
SIGN_INK = mat("SignInk", (0.1, 0.06, 0.02), 0.5)
STALL = mat("StallGrey", (0.35, 0.4, 0.5), 0.4)


def flat(name, x0, x1, y0, y1, m, z=0.0):
    return cube(name, 1, ((x0 + x1) / 2, (y0 + y1) / 2, z), (x1 - x0, y1 - y0, 0.02), m, bevel=0, outline=False)


def wall(x0, y0, x1, y1, m=WALL, thick=0.15, h=H):
    """Solid wall segment between two floor points."""
    length = math.hypot(x1 - x0, y1 - y0)
    ang = math.atan2(y1 - y0, x1 - x0)
    return cube("Wall", 1, ((x0 + x1) / 2, (y0 + y1) / 2, h / 2), (length, thick, h), m, rot=(0, 0, ang), bevel=0.01,
                outline=False)


# ---------------------------------------------------------------- shell: floors per zone, ceiling, windows all round
cube("Slab", 1, (0, 0, -0.06), (W, L, 0.1), CARPET, bevel=0, outline=False)
flat("LobbyFloor", X0, -15, -9.8, Y1, MARBLE_FLOOR, 0.002)
flat("RestroomFloor", X0, -15, Y0, -9.8, TILE, 0.002)
flat("CafeFloor", 12.4, X1, 1.0, Y1, CAFE_FLOOR, 0.002)
flat("LoungeFloor", 12.4, X1, Y0, 1.0, LOUNGE_FLOOR, 0.002)
flat("Runner", -14, 12, -1.1, 0.4, RUNNER, 0.004)
CEILING_STUFF.append(cube("Ceiling", 1, (0, 0, H + 0.05), (W, L, 0.1), CEILING, bevel=0, outline=False))
for sy in (-1, 1):
    cube("WindowWall", 1, (0, sy * L / 2, H / 2), (W, 0.05, H), GLASSWALL, bevel=0, outline=False)
    for x in range(int(X0), int(X1) + 1, 2):
        cube("Mullion", 1, (x, sy * L / 2, H / 2), (0.08, 0.12, H), MULLION, bevel=0, outline=False)
cube("WindowWallE", 1, (X1, 0, H / 2), (0.05, L, H), GLASSWALL, bevel=0, outline=False)
for y in range(int(Y0), int(Y1) + 1, 2):
    cube("Mullion", 1, (X1, y, H / 2), (0.12, 0.08, H), MULLION, bevel=0, outline=False)
ELEVATORS = (-5.0, 0.0, 5.0)
edges = [Y0]
for ey in ELEVATORS:
    edges += [ey - 0.85, ey + 0.85]
edges.append(Y1)
for a, b in zip(edges[0::2], edges[1::2]):  # elevator core wall on the west, with a doorway per car
    wall(X0, a, X0, b, MARBLE_BLK, 0.3)
for ey in ELEVATORS:
    cube("DoorHeader", 1, (X0, ey, (H + 2.3) / 2), (0.3, 1.7, H - 2.3), MARBLE_BLK, bevel=0, outline=False)

# sunset sky + sun, soft area lights under the ceiling
w = bpy.data.worlds.new("SunsetWorld")
sc.world = w
w.use_nodes = True
bg = w.node_tree.nodes["Background"]
bg.inputs["Color"].default_value = (1.0, 0.55, 0.3, 1)
bg.inputs["Strength"].default_value = 0.9
bpy.ops.object.light_add(type="SUN", location=(0, 0, 20), rotation=(R(55), 0, R(160)))
bpy.context.object.data.energy = 3.5
bpy.context.object.data.color = (1.0, 0.8, 0.6)
for x in range(-20, 21, 8):
    for y in (-10, 0, 10):
        bpy.ops.object.light_add(type="AREA", location=(x, y, H - 0.2))
        bpy.context.object.data.energy = 700
        bpy.context.object.data.size = 5
        bpy.context.object.data.color = (1, 0.92, 0.82)
        CEILING_STUFF.append(bpy.context.object)


# ---------------------------------------------------------------- helpers for rooms
def sign(label, loc, rot=0.0):
    LAYOUT["signs"].append({"label": label, "p": tuple(loc), "r": rot})
    place("RoomSign", loc, rot, record=False)
    d = Vector((math.sin(rot) * 0.025, -math.cos(rot) * 0.025, 0))
    RECORD[0] = False
    text("SignText", label, (loc[0] + d.x, loc[1] + d.y, loc[2] + 0.12), 0.09, SIGN_INK, rot=(R(90), 0, rot))
    RECORD[0] = True


def glass_front(x0, x1, y, door_x):
    """Floor-to-ceiling glass wall along y from x0 to x1 with a door gap at door_x."""
    for x in [x0 + i * 1.2 for i in range(int((x1 - x0) / 1.2) + 1)] + [x1]:
        if abs(x - door_x) > 0.55:
            cube("GlassMullion", 1, (x, y, H / 2), (0.06, 0.08, H), MULLION, bevel=0, outline=False)
    for xa, xb in ((x0, door_x - 0.55), (door_x + 0.55, x1)):
        cube("GlassPane", 1, ((xa + xb) / 2, y, H / 2), (xb - xa, 0.03, H), GLASSWALL, bevel=0, outline=False)
        cube("FrostBand", 1, ((xa + xb) / 2, y - 0.02, 1.2), (xb - xa, 0.01, 0.12), CEILING, bevel=0, outline=False)
    cube("GlassHeader", 1, ((x0 + x1) / 2, y, H - 0.1), (x1 - x0, 0.1, 0.2), MULLION, bevel=0, outline=False)
    place("OfficeDoor", (door_x, y, 0), 0.0)


def glass_side(x, y0, y1):
    cube("GlassSide", 1, (x, (y0 + y1) / 2, H / 2), (0.03, y1 - y0, H), GLASSWALL, bevel=0, outline=False)
    cube("GlassSideMullion", 1, (x, y0, H / 2), (0.08, 0.08, H), MULLION, bevel=0, outline=False)


def candle_screen(loc, rot, width, height, n):
    """Big wall screen with a candlestick chart. rot is the direction the screen faces, like place()."""
    LAYOUT["screens"].append({"p": tuple(loc), "r": rot, "w": width, "h": height})
    RECORD[0] = False
    cube("TradeScreenFrame", 1, loc, (width + 0.12, 0.08, height + 0.12), MULLION, rot=(0, 0, rot), bevel=0.01)
    right = Vector((math.cos(rot), math.sin(rot), 0))
    fwd = Vector((math.sin(rot), -math.cos(rot), 0))
    cube("TradeScreen", 1, Vector(loc) + fwd * 0.045, (width, 0.01, height), SCREEN_BG, rot=(0, 0, rot), bevel=0,
         outline=False)
    price, step = 0.5, width * 0.9 / n
    z0 = loc[2] - height / 2
    for i in range(n):
        o = price
        c = min(0.92, max(0.08, o + rng.uniform(-0.09, 0.1)))
        hi, lo = max(o, c) + rng.uniform(0.01, 0.05), min(o, c) - rng.uniform(0.01, 0.05)
        price = c
        m = UP if c >= o else DOWN
        base = Vector(loc) + fwd * 0.06 + right * (-width * 0.45 + step * (i + 0.5))
        cube("Wick", 1, (base.x, base.y, z0 + (hi + lo) / 2 * height), (0.008, 0.005, (hi - lo) * height), m,
             rot=(0, 0, rot), bevel=0, outline=False)
        cube("CandleBody", 1, (base.x + fwd.x * 0.01, base.y + fwd.y * 0.01, z0 + (o + c) / 2 * height),
             (step * 0.6, 0.006, max(abs(c - o) * height, 0.01)), m, rot=(0, 0, rot), bevel=0, outline=False)
    RECORD[0] = True


# ---------------------------------------------------------------- west: elevator lobby + reception
for y in ELEVATORS:
    place("ElevatorDoors", (X0 + 0.2, y, 0), R(90))
    place("ElevatorPanel", (X0 + 0.2, y + 1.2, 0), R(90))
wall(-15.0, -4.5, -15.0, 4.5, WALNUT, 0.3)  # feature wall behind reception
place("WolfLetters", (-15.2, 0, 0), R(-90))
place("NeonSignMoney", (-14.8, 0, 0.4), R(90))  # trading-floor side of the feature wall
place("ReceptionDesk", (-17.6, 0, 0), R(-90))
place("OfficeChair", (-16.6, 0.5, 0), R(-90))
place("Orchid", (-17.5, -1.1, 1.14), 0)
place("DeskGlobe", (-17.5, 1.2, 1.14), 0)
place("PersianRug", (-20.5, 0, 0), R(90))
place("Chandelier", (-20.5, 0, 0.6), 0, ceiling=True)
for y in (-7.5, 7.5):
    for x in (-21.5, -17.0):
        place("Column", (x, y, 0))
place("GoldBull", (-20.5, -6.0, 0), R(60))
place("GoldWolfStatue", (-20.5, 6.2, 0), R(120))
for y in (-2.6, 2.6):
    place("VelvetRope", (-19.4, y, 0), R(90))
for pos in ((-23.0, -8.8), (-23.0, 8.8), (-15.8, -8.8), (-15.8, 5.4)):
    place("PlantPalm", (*pos, 0), rng.uniform(0, 6.28))
place("ExitSign", (X0 + 0.2, -2.5, 0.4), R(90))
place("SecurityCamera", (-15.5, -8.8, 0.9), R(-135), ceiling=True)
place("FireExtinguisher", (-15.3, -5.0, 0), R(-90))
# waiting lounge in the north-west corner
place("Sofa", (-20.0, 15.6, 0), 0.0)
place("Sofa", (-23.0, 12.5, 0), R(90))
place("CoffeeTable", (-20.0, 13.2, 0))
place("MagazineRack", (-16.0, 16.6, 0), math.pi)
place("FloorLamp", (-23.2, 16.2, 0))
place("SideTable", (-23.0, 14.6, 0))
place("TrophyCase", (-17.5, 16.5, 0), math.pi)
place("SkylineModel", (-17.5, 12.0, 0), R(30))
place("UmbrellaStand", (-23.2, 10.0, 0))
place("CoatRack", (-22.3, 10.0, 0))
place("MoneyBriefcase", (-19.7, 13.2, 0.44), 0.4)

# ---------------------------------------------------------------- south-west: restrooms
DOORS = (-20.45, -16.05)
wall(X0, -9.8, DOORS[0] - 0.55, -9.8)
wall(DOORS[0] + 0.55, -9.8, DOORS[1] - 0.55, -9.8)
wall(DOORS[1] + 0.55, -9.8, -15.0, -9.8)
wall(-19.5, Y0, -19.5, -9.8)
wall(-15.0, Y0, -15.0, -9.8)
for (x0, x1, label), door in zip(((X0 + 0.2, -19.5, "GENTS"), (-19.5, -15.0, "LADIES")), DOORS):
    place("OfficeDoor", (door, -9.8, 0), 0.0)
    sign(label, (door, -9.65, 2.35), math.pi)
    for k in range(3):
        tx = x0 + 0.9 + k * 1.3
        place("Toilet", (tx, Y0 + 0.5, 0), math.pi)
        cube("StallWall", 1, (tx + 0.65, -15.6, 1.1), (0.05, 2.4, 2.0), STALL, bevel=0.01)
    for k in range(2):
        place("VanitySink", (x0 + 0.9 + k * 1.2, -10.2, 0), 0.0)
    place("HandDryer", (x1 - 0.5, -10.2, 0), 0.0)
place("GoldToilet", (-15.6, -13.0, 0), R(-90))  # somebody installed a gold one
for x, name in ((-23.0, "PosterHustle"), (-21.7, "PosterGreed"), (-18.3, "PosterTeam")):
    place(name, (x, -9.6, 0), math.pi)

# ---------------------------------------------------------------- north: glass offices + meeting room
OFF_Y = 10.4
offices = [(-14.5, -7.5, "THE CHAIRMAN"), (-7.5, -2.0, "CEO"), (-2.0, 3.5, "SALES DIRECTOR"), (3.5, 12.4, "MEETING ROOM")]
for x0, x1, label in offices:
    door = x0 + 1.2
    glass_front(x0, x1, OFF_Y, door)
    sign(label, (door, OFF_Y - 0.1, 2.35), 0.0)
    glass_side(x0, OFF_Y, Y1)
glass_side(12.4, OFF_Y, Y1)
flat("ChairmanRug", -14.3, -7.7, 10.6, 16.8, LOUNGE_FLOOR, 0.003)


def exec_office(x0, x1, big):
    mid = (x0 + x1) / 2
    place("ExecutiveDesk", (mid, 14.2, 0), math.pi)
    place("OfficeChair", (mid, 15.2, 0), 0.0, 1.15)
    place("BankerLamp", (mid - 0.8, 14.3, 0.79), math.pi)
    place("GoldPhone", (mid + 0.8, 14.1, 0.79), math.pi + 0.3)
    place("DeskNameplate", (mid, 13.85, 0.79), math.pi)
    place("DeskCalculator", (mid + 0.4, 14.3, 0.79), math.pi)
    place("OfficeChair", (mid - 0.6, 12.7, 0), math.pi - 0.2)
    place("OfficeChair", (mid + 0.6, 12.7, 0), math.pi + 0.2)
    place("Bookshelf", (x0 + 0.5, 14.5, 0), R(90))
    place("PlantFiddle", (x1 - 0.5, 16.5, 0))
    place(rng.choice(["PaintingBull", "PaintingAbstract", "PaintingSunset"]), (x0 + 0.1, 12.5, 1.0), R(90))
    if big:
        place("AmericanFlag", (x1 - 0.8, 16.2, 0), math.pi + 0.4)
        place("VaultSafe", (x1 - 0.6, 11.6, 0), R(-90))
        place("MarbleBust", (x0 + 0.6, 16.4, 0), math.pi - 0.5)
        place("GoldBars", (mid - 0.4, 14.1, 0.79), math.pi)
        place("SingingFish", (x1 - 0.05, 13.8, 0), R(-90))
        place("Trophy", (mid + 1.0, 14.5, 0.79), math.pi)
    else:
        place("AwardPlaque", (x1 - 0.05, 13.5, 0), R(-90))
        place("ModelYacht", (mid - 0.3, 14.3, 0.79), math.pi)
        place("GoldPiggyBank", (mid + 0.9, 14.5, 0.79), math.pi)


exec_office(-14.5, -7.5, True)
exec_office(-7.5, -2.0, False)
exec_office(-2.0, 3.5, False)
# meeting room
place("MeetingTable", (8.0, 13.8, 0))
for x in (6.6, 8.0, 9.4):
    place("OfficeChair", (x, 12.8, 0), math.pi + rng.uniform(-0.2, 0.2))
    place("OfficeChair", (x, 14.8, 0), rng.uniform(-0.2, 0.2))
place("OfficeChair", (10.6, 13.8, 0), R(-90))
place("WallTV", (12.25, 13.8, 0), R(-90))
place("Podium", (4.6, 11.4, 0), R(40))
place("Whiteboard", (4.2, 16.0, 0), R(120))
place("WorldClocks", (8.0, Y1 - 0.2, 0.2), math.pi)
place("PlantSnake", (11.8, 16.6, 0))

# ---------------------------------------------------------------- center: trading floor
PODS = (-7.6, -3.1, 1.4, 5.9)
for pod_y in PODS:
    for i in range(10):
        x = -12.6 + i * 1.75
        place("DeskSet", (x, pod_y - 0.45, 0), 0.0)
        place("OfficeChair", (x, pod_y - 1.3, 0), math.pi + rng.uniform(-0.4, 0.4))
        place("DeskSet", (x, pod_y + 0.45, 0), math.pi)
        place("OfficeChair", (x, pod_y + 1.3, 0), rng.uniform(-0.4, 0.4))
    cube("PodDivider", 1, (-12.6 + 4.5 * 1.75, pod_y, 1.0), (17.4, 0.05, 0.45), bpy.data.materials["Fabric_Navy"], bevel=0.01)
    place("TrashBin", (5.0, pod_y - 1.0, 0))
    place("PlantSnake", (-14.0, pod_y, 0))
for y in (-5.35, 3.65):
    cube("TickerBar", 1, (-4.7, y, 3.15), (18, 0.08, 0.32), MULLION, bevel=0.01)
    text("TickerText", "BANANA MOON +12.4%   WOLF & CO +100%   DUCK YACHTS -3.1%   HOVERCAR +44%   GOLD TOILETS +6.6%",
         (-4.7, y - 0.05, 3.15), 0.17, TICK)
# trading rigs + the deal bell and gong between the pods and the screen wall
for y in (-6.5, -1.8, 3.0):
    place("TradingRig", (8.2, y, 0), R(-90))
    place("OfficeChair", (7.0, y, 0), R(90))
place("DealBell", (6.0, 8.0, 0), 0.4)
place("Gong", (9.5, 8.2, 0), math.pi + 0.3)
place("WaterCooler", (6.0, -9.4, 0))
place("CoffeeMachine", (7.0, -9.4, 0))
place("Printer", (-14.0, 8.6, 0), R(90))
# divider wall between the trading floor and the east side, covered in candlestick screens
wall(12.4, -9.5, 12.4, -1.8, WALL, 0.3)
wall(12.4, 1.8, 12.4, 9.8, WALL, 0.3)
for k, y in enumerate((-7.5, -4.0, 4.0, 7.6)):
    candle_screen((12.2, y, 2.0), R(-90), 3.2, 1.8, 24 + k * 4)
for x in range(-12, 12, 4):
    for y in PODS:
        place("CeilingLight", (x, y, 0), 0, ceiling=True)

# ---------------------------------------------------------------- south strip: print area, servers, phone booths
cube("PrintWall", 1, (-7.0, Y0 + 0.15, H / 2), (14, 0.1, H), WALL, bevel=0, outline=False)
place("Printer", (-13.3, -15.9, 0), math.pi)
for k in range(3):
    place("FilingCabinet", (-11.8 + k * 0.6, -16.5, 0), math.pi)
place("Shredder", (-9.4, -16.4, 0), math.pi)
place("MailCart", (-8.0, -14.8, 0), 0.4)
place("CardboardBox", (-9.5, -14.5, 0), 0.5)
place("CorkBoard", (-6.0, Y0 + 0.2, 0), math.pi)
place("NeonSignDial", (-2.0, Y0 + 0.2, 0.4), math.pi)
place("ServerRack", (-0.8, -16.4, 0), math.pi)
place("ServerRack", (-0.1, -16.4, 0), math.pi)
place("WaterBottlePallet", (1.4, -16.1, 0))
for k in range(3):
    place("PhoneBooth", (3.4 + k * 1.3, -16.2, 0), math.pi)
place("Bookshelf", (8.2, -16.5, 0), math.pi)
place("BambooPlanter", (10.3, -16.5, 0))
place("Whiteboard", (-4.0, -11.0, 0), 0.3)
place("FireExtinguisher", (-14.0, -16.6, 0))
place("RecyclingBins", (-12.5, -11.2, 0), R(90))

# ---------------------------------------------------------------- north-east: cafeteria
wall(12.4, 1.0, 16.5, 1.0, WALL, 0.2, 1.1)  # low half walls between cafe and lounge
wall(19.5, 1.0, X1, 1.0, WALL, 0.2, 1.1)
place("CafeteriaCounter", (18.2, 16.0, 0))
place("MenuBoard", (18.2, 16.8, 0))
place("CoffeeMachine", (16.9, 16.0, 0.94))
place("Microwave", (19.4, 16.0, 0.94))
place("FoodTray", (18.2, 15.4, 0.94))
place("Fridge", (23.4, 15.5, 0), R(-90))
place("VendingMachine", (23.4, 13.6, 0), R(-90))
place("VendingMachine", (23.4, 12.1, 0), R(-90))
place("EspressoBar", (21.0, 3.0, 0), math.pi)
place("JuiceBarCart", (13.3, 15.5, 0), R(90))
place("RecyclingBins", (13.3, 12.5, 0), R(90))
place("HangingPlant", (15.0, 16.4, 0.4), 0, ceiling=True)
foods = ["Burger", "PizzaSlice", "Donut", "Apple", "Sandwich", "SodaCan", "Banana", "PaperCup", "FruitBowl"]
for tx in (15.2, 18.2, 21.2):
    for ty in (6.2, 10.0):
        place("CafeTable", (tx, ty, 0))
        place("CafeChair", (tx - 0.8, ty, 0), R(90))
        place("CafeChair", (tx + 0.8, ty, 0), R(-90))
        place("PendantLamp", (tx, ty, 0.6), 0, ceiling=True)
        place(rng.choice(foods), (tx + rng.uniform(-0.2, 0.2), ty + rng.uniform(-0.15, 0.15), 0.75), rng.uniform(0, 6.28))
place("CoffeePuddle", (16.5, 8.2, 0), 0.7)
place("NeonSign", (21.5, Y1 - 0.2, 0.3), math.pi)

# ---------------------------------------------------------------- south-east: game lounge
place("PoolTable", (16.2, -3.2, 0))
place("CueRack", (12.6, -3.4, 0), R(90))
place("AirHockey", (21.6, -3.4, 0))
place("PingPongTable", (16.2, -8.4, 0))
place("GrandPiano", (21.4, -8.6, 0), R(200))
place("FishTank", (12.85, -7.2, 0), R(90))
place("Dartboard", (12.6, -5.2, 0), R(90))
place("PuttingGreen", (18.2, -14.8, 0), R(90))
for k in range(3):
    place("ArcadeCabinet", (23.5, -11.6 - k * 1.1, 0), R(-90))
place("PunchingBag", (13.6, -15.6, 0.0))
place("MassageChair", (13.4, -11.6, 0), R(90))
place("MassageChair", (13.4, -12.9, 0), R(90))
for pos in ((20.0, -11.5), (21.0, -12.3), (19.5, -12.8)):
    place("BeanBag", (*pos, 0), rng.uniform(0, 6.28))
place("PlantPalm", (23.4, -16.4, 0))
place("PlantPalm", (23.4, 0.3, 0))
place("FloorLamp", (15.0, -16.3, 0))
place("Chandelier", (16.2, -3.2, 0.6), 0, ceiling=True)
place("CashStack", (16.0, -2.8, 0.87), 0.4)

# ---------------------------------------------------------------- wall boards: LED clock, office suspicion, day goal
LED_RED = mat("LedRed", (1.0, 0.12, 0.08), 0.3, emit=5)
BOARD_WHITE = mat("BoardWhite", (1, 1, 1), 0.3, emit=1.5)
BOARD_GREEN = mat("BoardGreen", (0.3, 1.0, 0.45), 0.3, emit=3)
BOARD_GOLD = mat("BoardGold", (1.0, 0.75, 0.2), 0.3, emit=3)
BOARD_RED = mat("BoardRed", (0.25, 0.02, 0.04), 0.5)


def board(kind, loc, rot, w, h):
    """A live wall board (the game fills it in); here it gets a frame and sample text for the renders."""
    LAYOUT["boards"].append({"kind": kind, "p": tuple(loc), "r": rot, "w": w, "h": h})
    RECORD[0] = False
    fwd = Vector((math.sin(rot), -math.cos(rot), 0))
    right = Vector((math.cos(rot), math.sin(rot), 0))
    base = Vector(loc)
    cube("BoardFrame", 1, loc, (w + 0.1, 0.06, h + 0.1), MULLION, rot=(0, 0, rot), bevel=0.01)
    cube("BoardScreen", 1, base + fwd * 0.032, (w, 0.005, h), BOARD_RED if kind == "goal" else SCREEN_BG,
         rot=(0, 0, rot), bevel=0, outline=False)

    def write(body, dx, dz, size, m):
        pos = base + fwd * 0.04 + right * dx + Vector((0, 0, dz))
        text("BoardText", body, tuple(pos), size, m, rot=(R(90), 0, rot), extrude=0.001)

    if kind == "clock":
        write("9:41 AM", 0, 0, h * 0.62, LED_RED)
    elif kind == "suspicion":
        write("OFFICE SUSPICION", -w * 0.2, h * 0.28, h * 0.16, BOARD_WHITE)
        write("LOW", w * 0.36, h * 0.28, h * 0.2, BOARD_GREEN)
        cube("SuspicionBar", 1, base + fwd * 0.037 + right * (-w * 0.38) + Vector((0, 0, -0.02)),
             (w * 0.08, 0.004, h * 0.22), BOARD_GREEN, rot=(0, 0, rot), bevel=0, outline=False)
        write("Keep it down. Bad things happen at 100%.", 0, -h * 0.32, h * 0.09, BOARD_WHITE)
    elif kind == "goal":
        write("TIME LEFT IN DAY  6:12", w * 0.18, h * 0.36, h * 0.1, BOARD_GOLD)
        write("$0 OF $600", -w * 0.12, h * 0.1, h * 0.2, BOARD_GOLD)
        write("GOAL NOT REACHED", -w * 0.2, -h * 0.1, h * 0.08, BOARD_WHITE)
        write("DEPOSITED              RANK", 0, -h * 0.3, h * 0.08, BOARD_GOLD)
    RECORD[0] = True


board("goal", (-10.8, Y0 + 0.24, 2.1), math.pi, 3.2, 1.5)  # south wall, facing the trading floor
board("clock", (-6.0, Y0 + 0.24, 2.75), math.pi, 1.2, 0.45)  # above the cork board
for rot, off in ((0.0, -0.05), (math.pi, 0.05)):  # hanging over the runner, readable from both sides
    board("suspicion", (-4.7, -0.85 + off, 2.75), rot, 2.6, 0.9)
cube("SuspicionHanger", 1, (-5.9, -0.85, 3.4), (0.02, 0.02, 0.4), MULLION, bevel=0, outline=False)
cube("SuspicionHanger", 1, (-3.5, -0.85, 3.4), (0.02, 0.02, 0.4), MULLION, bevel=0, outline=False)
board("clock", (-15.3, 3.0, 2.8), R(-90), 1.0, 0.38)  # lobby, on the feature wall next to the letters

# ---------------------------------------------------------------- extra decor
# lobby: art between the elevators, planters by reception, reading lamps
for y in (-2.5, 2.5):
    place(rng.choice(["PaintingBull", "PaintingAbstract", "PaintingSunset"]), (X0 + 0.18, y, 1.0), R(90))
for y in (-2.2, 2.2):
    place("BambooPlanter", (-16.3, y, 0), R(-90))
place("FloorLamp", (-21.3, 14.0, 0))
place("Bonsai", (-20.0, 13.2, 0.44), 0.5)
place("PlantFiddle", (-15.8, 9.6, 0))
place("WallClock", (-19.6, Y1 - 0.12, 0.2), math.pi)
# along the glass offices: plants and a bench-style sofa between doors
for x in (-8.9, -3.4, 2.1):
    place("PlantFiddle", (x, 9.8, 0), rng.uniform(0, 6.28))
place("Sofa", (-5.0, 9.4, 0), 0.0, 0.9)
place("SideTable", (-3.6, 9.5, 0))
place("MagazineRack", (0.4, 10.1, 0), math.pi)
# trading floor: planters at the pod ends, a sales whiteboard, a money counter by the rigs
for pod_y in PODS:
    place("PlantPalm", (5.9, pod_y, 0), rng.uniform(0, 6.28))
place("Whiteboard", (-13.9, -9.3, 0), R(30))
place("MoneyCounter", (8.6, -6.2, 0.76), R(-90))
place("MoneyGun", (8.5, -1.5, 0.76), R(-100))
place("GoldBars", (8.6, 3.3, 0.76), R(-90))
place("FireExtinguisher", (12.1, -9.2, 0), R(-90))
place("SecurityCamera", (12.0, 9.5, 0.9), R(-135), ceiling=True)
place("SecurityCamera", (-13.8, -9.6, 0.9), R(45), ceiling=True)
# chairman: rug, globe, chandelier, money counter
place("PersianRug", (-11.0, 13.4, 0), 0.0, 0.8)
place("SideTable", (-13.8, 11.2, 0))
place("DeskGlobe", (-13.8, 11.2, 0.62))
place("MoneyCounter", (-10.2, 14.1, 0.79), math.pi)
place("Chandelier", (-11.0, 13.8, 0.6), 0, ceiling=True)
place("GoldPiggyBank", (-12.0, 14.4, 0.79), math.pi)
# meeting room: pendant lamps over the table, a plant, water
for x in (6.9, 9.1):
    place("PendantLamp", (x, 13.8, 0.7), 0, ceiling=True)
place("WaterCooler", (11.8, 11.0, 0), R(-90))
place("BambooPlanter", (4.4, 16.4, 0), math.pi)
# cafeteria: news TV, water cooler, plants, fruit on the counter
place("WallTV", (12.6, 6.0, 0.2), R(90))  # cafe side of the divider wall
place("WaterCooler", (23.4, 10.6, 0), R(-90))
place("PlantPalm", (13.2, 9.9, 0))
place("PlantSnake", (19.6, 1.5, 0))
place("FruitBowl", (17.3, 16.0, 0.94))
place("Donut", (19.0, 15.6, 0.94))
# game lounge: rug under the bean bags, TV over the arcades, lamp + juice by the massage chairs
place("PersianRug", (20.4, -12.3, 0), R(90), 0.7)
place("SideTable", (13.4, -14.2, 0))
place("JuiceBarCart", (15.8, -11.8, 0), R(90))
place("HangingPlant", (14.0, -7.0, 0.4), 0, ceiling=True)
place("HangingPlant", (23.0, -5.5, 0.4), 0, ceiling=True)
# restrooms: plants, bins, a wet floor
for x in (-23.4, -15.6):
    place("PlantSnake", (x, -10.5, 0))
    place("TrashBin", (x + (0.8 if x < -20 else -0.8), -10.4, 0))
place("CoffeePuddle", (-21.5, -12.8, 0), 0.5)
# print strip: a second cork board, a coat rack, boxes
place("CoatRack", (-12.0, -12.2, 0))
place("CardboardBox", (-2.5, -15.0, 0), 1.2)
place("CardboardBox", (-2.3, -15.0, 0.4), 0.3)

# ---------------------------------------------------------------- chaos: papers, cash, cups and food on the trading floor
RECORD[0] = False  # the game scatters its own draggable paper and cash in these areas
for y in (-5.35, -0.85, 3.65):
    LAYOUT["chaos"].append({"x": (-13.0, 4.0), "y": (y - 0.4, y + 0.4)})
LAYOUT["chaos"].append({"x": (4.8, 11.5), "y": (-9.6, 9.3)})
LAYOUT["chaos"].append({"x": (-13.5, 11.5), "y": (-9.9, -9.2)})
LAYOUT["chaos"].append({"x": (-13.5, 11.5), "y": (-14.0, -10.5)})
PAPER = bpy.data.materials["SmoothPlastic_Paper"]
CASH = bpy.data.materials["Fabric_Cash"]
for _ in range(220):
    x, y = rng.uniform(-13.5, 11.5), rng.uniform(-9.8, 9.5)
    if min(abs(y - py) for py in PODS) < 1.0 and x < 4.5:
        continue
    m = CASH if rng.random() < 0.4 else PAPER
    cube("FloorMess", 1, (x, y, 0.006), (0.3 if m == CASH else 0.21, 0.14 if m == CASH else 0.29, 0.003), m,
         rot=(0, 0, rng.uniform(0, 6.28)), bevel=0, outline=False)
for kind in ("PaperCup", "Donut", "PizzaSlice", "SodaCan", "Banana", "CashStack", "PaperCup", "Burger", "RubberChicken",
             "FoamBat", "Stapler", "PaperCup", "CashStack"):
    place(kind, (rng.uniform(-12, 4), rng.choice((-5.35, -0.85, 3.65)) + rng.uniform(-0.3, 0.3), 0), rng.uniform(0, 6.28))

RECORD[0] = True
# named spots the game needs
LAYOUT["points"] = {
    "spawn": {"p": (X0 + 2.0, 0.0, 0.0), "r": R(-90)},  # stepping out of the middle elevator
    "meetingBoard": {"p": (12.2, 13.8, 1.9), "r": R(-90), "w": 1.9, "h": 1.05},
    "meetingCenter": {"p": (8.0, 13.8, 0.0), "r": 0.0},
    "lounge": {"p": (18.0, -6.0, 0.0), "r": 0.0},
}
LAYOUT["meetingSeats"] = [{"p": (x, y, 0.0), "r": r} for x in (6.6, 8.0, 9.4) for y, r in ((12.8, 0.0), (14.8, math.pi))]
LAYOUT["floor"] = {"w": W, "l": L, "h": H}
for o in sc.objects:
    if o.type == "LIGHT" and o.data.type == "AREA":
        LAYOUT["lights"].append({"p": tuple(o.location)})


def write_layout():
    """Emit OfficeLayout.lua with the recorded layout plus a look for every material the parts use."""
    def v3(t):
        return "{%s}" % ", ".join("%.3f" % v for v in t)

    def srgb(c):
        return tuple(round(255 * (x * 12.92 if x <= 0.0031308 else 1.055 * x ** (1 / 2.4) - 0.055)) for x in c)

    scene_kinds = {"SceneCarpet": "Carpet", "SceneTile": "Marble", "SceneLoungeCarpet": "Carpet", "SceneCeiling": "Plaster",
                   "SceneMullion": "Metal", "SceneGlass": "Glass", "SceneWall": "Plaster", "SceneRunner": "Carpet",
                   "StallGrey": "SmoothPlastic", "SceneScreen": "Glass"}
    looks = {}
    for part in LAYOUT["parts"]:
        m = bpy.data.materials.get(part["m"])
        if not m or m.name in looks:
            continue
        b = m.node_tree.nodes.get("Principled BSDF") if m.use_nodes else None
        col = srgb(tuple(b.inputs["Base Color"].default_value)[:3] if b else tuple(m.diffuse_color)[:3])
        kind = scene_kinds.get(m.name) or m.name.split("_")[0]
        looks[m.name] = (kind, col, 0.7 if m.name == "SceneGlass" else 0.0)
    out = ["-- Generated by blender/office_scene.py. Do not edit by hand: move things in Blender and re-run.",
           "-- Units are Blender meters with Z up; r = rotation around the vertical axis (radians).",
           "return {"]
    f = LAYOUT["floor"]
    out.append("\tfloor = { w = %.2f, l = %.2f, h = %.2f }," % (f["w"], f["l"], f["h"]))
    out.append("\tlooks = {")
    for k, (kind, col, tr) in sorted(looks.items()):
        out.append('\t\t["%s"] = { material = "%s", color = {%d, %d, %d}, transparency = %s },' % (k, kind, *col, tr))
    out.append("\t},")
    out.append("\tparts = {")
    for pt in LAYOUT["parts"]:
        out.append('\t\t{ n = "%s", p = %s, s = %s, r = %.4f, m = "%s" },' % (pt["n"], v3(pt["p"]), v3(pt["s"]), pt["r"], pt["m"]))
    out.append("\t},")
    out.append("\tprops = {")
    for pr in LAYOUT["props"]:
        out.append('\t\t{ n = "%s", p = %s, r = %.4f, s = %.3f },' % (pr["n"], v3(pr["p"]), pr["r"], pr["s"]))
    out.append("\t},")
    out.append("\tscreens = {")
    for sc_ in LAYOUT["screens"]:
        out.append("\t\t{ p = %s, r = %.4f, w = %.2f, h = %.2f }," % (v3(sc_["p"]), sc_["r"], sc_["w"], sc_["h"]))
    out.append("\t},")
    out.append("\ttickers = {")
    for t in LAYOUT["tickers"]:
        out.append("\t\t{ p = %s, r = %.4f, len = %.2f }," % (v3(t["p"]), t["r"], t["len"]))
    out.append("\t},")
    out.append("\tsigns = {")
    for sg in LAYOUT["signs"]:
        out.append('\t\t{ label = "%s", p = %s, r = %.4f },' % (sg["label"], v3(sg["p"]), sg["r"]))
    out.append("\t},")
    out.append("\tlights = {")
    for lt in LAYOUT["lights"]:
        out.append("\t\t{ p = %s }," % v3(lt["p"]))
    out.append("\t},")
    out.append("\tchaos = {")
    for c in LAYOUT["chaos"]:
        out.append("\t\t{ x = {%.2f, %.2f}, y = {%.2f, %.2f} }," % (*c["x"], *c["y"]))
    out.append("\t},")
    out.append("\tmeetingSeats = {")
    for st in LAYOUT["meetingSeats"]:
        out.append("\t\t{ p = %s, r = %.4f }," % (v3(st["p"]), st["r"]))
    out.append("\t},")
    out.append("\tboards = {")
    for bd in LAYOUT["boards"]:
        out.append('\t\t{ kind = "%s", p = %s, r = %.4f, w = %.2f, h = %.2f },' % (bd["kind"], v3(bd["p"]), bd["r"], bd["w"], bd["h"]))
    out.append("\t},")
    out.append("\tpoints = {")
    for k, pt in LAYOUT["points"].items():
        extra = "".join(", %s = %.2f" % (kk, vv) for kk, vv in pt.items() if kk not in ("p", "r"))
        out.append("\t\t%s = { p = %s, r = %.4f%s }," % (k, v3(pt["p"]), pt["r"], extra))
    out.append("\t},")
    out.append("}")
    path = os.path.join(D, "..", "roblox", "src", "shared", "OfficeLayout.lua")
    with open(path, "w") as fh:
        fh.write("\n".join(out) + "\n")
    print("wrote", path, len(LAYOUT["parts"]), "parts", len(LAYOUT["props"]), "props", flush=True)


write_layout()
if "--layout-only" in sys.argv:
    sys.exit(0)

for tpl in TEMPLATES:  # hide the template lineup
    for o in [tpl] + kids(tpl):
        o.hide_render = True
        o.hide_set(True)

# ---------------------------------------------------------------- renders
sc.render.engine = "CYCLES"
sc.cycles.use_denoising = True
sc.view_settings.view_transform = "Standard"
os.makedirs(os.path.join(D, "renders"), exist_ok=True)
bpy.ops.object.camera_add()
cam = bpy.context.object
sc.camera = cam
only = set(sys.argv[sys.argv.index("--") + 1:]) if "--" in sys.argv else set()


def shoot(name, loc, target, lens, x, y, samples, hide_ceiling=False):
    if only and name not in only:
        return
    for o in CEILING_STUFF:
        for c in [o] + kids(o):
            c.hide_render = hide_ceiling
    cam.location = loc
    cam.data.lens = lens
    cam.rotation_mode = "QUATERNION"
    cam.rotation_quaternion = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y")
    render(os.path.join(D, "renders", name + ".png"), x=x, y=y, samples=samples)
    print("rendered", name, flush=True)


bpy.ops.wm.save_as_mainfile(filepath=os.path.join(D, "office_scene.blend"))
shoot("office_overview", (14, -44, 42), (0, -1, 0), 30, 1600, 1000, 20, hide_ceiling=True)
shoot("office_plan", (0, 0.01, 60), (0, 0, 0), 33, 1500, 1060, 16, hide_ceiling=True)
shoot("office_trading_floor", (-13.8, -9.4, 1.7), (6, 4, 1.0), 20, 1280, 720, 20)
shoot("office_lobby", (-23.2, -8.6, 1.7), (-17, 2, 1.3), 20, 1280, 720, 20)
shoot("office_chairman", (-8.4, 10.9, 1.7), (-12, 15, 1.1), 20, 1280, 720, 20)
shoot("office_lounge", (12.9, -16.4, 1.7), (20, -3, 1.0), 20, 1280, 720, 20)
shoot("office_cafeteria", (13.2, 2.0, 1.7), (20, 12, 1.1), 20, 1280, 720, 20)
print("DONE")
