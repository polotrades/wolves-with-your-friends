"""Interior mockup of floor 100 using the prop pack: trading-floor pods, glass-walled offices, candlestick screens,
LED ticker, gold bull, lounge, plants, and paper/cash chaos. Run after props.py:  python3 office_scene.py"""
import math
import os
import random
import sys

import bpy
from mathutils import Vector

D = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, D)
from lib import cube, mat, render, text, tube  # noqa: E402

R = math.radians
rng = random.Random(11)
bpy.ops.wm.open_mainfile(filepath=os.path.join(D, "props.blend"))
sc = bpy.context.scene
for o in list(sc.objects):  # drop the old studio set, keep the props as templates
    if o.type in {"CAMERA", "LIGHT"} or (o.type == "MESH" and o.parent is None):
        bpy.data.objects.remove(o, do_unlink=True)
TEMPLATES = [o for o in sc.objects if o.type == "EMPTY" and o.parent is None]


def kids(o):
    out = []
    for c in o.children:
        out.append(c)
        out += kids(c)
    return out


def place(name, loc, rot=0.0, scale=1.0):
    root = bpy.data.objects[name]
    bpy.ops.object.select_all(action="DESELECT")
    for o in [root] + kids(root):
        o.hide_set(False)
        o.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.object.duplicate(linked=True)
    new_root = next(o for o in bpy.context.selected_objects if o.parent is None)
    new_root.location = loc
    new_root.rotation_euler = (0, 0, rot)
    new_root.scale = (scale, scale, scale)
    return new_root


W, L, H = 30.0, 22.0, 3.6  # floor width (x), length (y), ceiling height
CARPET = mat("SceneCarpet", (0.07, 0.08, 0.16), 0.95)
CEILING = mat("SceneCeiling", (0.85, 0.82, 0.76), 0.8)
LIGHTPANEL = mat("SceneLight", (1.0, 0.95, 0.85), 0.3, emit=6)
MULLION = mat("SceneMullion", (0.03, 0.03, 0.035), 0.4, 0.8)
GLASSWALL = mat("SceneGlass", (0.8, 0.9, 0.95), 0.02)
GLASSWALL.node_tree.nodes["Principled BSDF"].inputs["Transmission Weight"].default_value = 0.95
WALNUT = bpy.data.materials["Wood_Walnut"]
GOLD = bpy.data.materials["Metal_Gold"]
RUNNER = mat("SceneRunner", (0.45, 0.05, 0.08), 0.95)
SCREEN_BG = mat("SceneScreen", (0.01, 0.015, 0.03), 0.2, emit=0.5)
UP = mat("CandleUp", (0.15, 1.0, 0.35), 0.3, emit=3)
DOWN = mat("CandleDown", (1.0, 0.15, 0.2), 0.3, emit=3)
TICK = mat("TickerText", (1.0, 0.8, 0.2), 0.3, emit=4)

# shell: carpet, runner, ceiling with light panels, windows all round
cube("Floor", 1, (0, 0, -0.05), (W, L, 0.1), CARPET, bevel=0, outline=False)
cube("Runner", 1, (0, 0, 0.005), (W - 4, 1.8, 0.01), RUNNER, bevel=0, outline=False)
cube("Ceiling", 1, (0, 0, H + 0.05), (W, L, 0.1), CEILING, bevel=0, outline=False)
for x in range(-12, 13, 4):
    for y in (-8, -3, 3, 8):
        cube("LightPanel", 1, (x, y, H - 0.01), (1.2, 0.6, 0.02), LIGHTPANEL, bevel=0, outline=False)
for sy in (-1, 1):
    cube("WindowWall", 1, (0, sy * L / 2, H / 2), (W, 0.05, H), GLASSWALL, bevel=0, outline=False)
    for x in range(-15, 16, 2):
        cube("Mullion", 1, (x, sy * L / 2, H / 2), (0.08, 0.1, H), MULLION, bevel=0, outline=False)

# the sky and the city far below come from a sunset world + a sun
w = bpy.data.worlds.new("SunsetWorld")
sc.world = w
w.use_nodes = True
bg = w.node_tree.nodes["Background"]
bg.inputs["Color"].default_value = (1.0, 0.55, 0.3, 1)
bg.inputs["Strength"].default_value = 0.9
bpy.ops.object.light_add(type="SUN", location=(0, 0, 10), rotation=(R(70), 0, R(160)))
bpy.context.object.data.energy = 3.0
bpy.context.object.data.color = (1.0, 0.75, 0.5)
for x in (-8, 0, 8):
    bpy.ops.object.light_add(type="AREA", location=(x, 0, H - 0.15))
    bpy.context.object.data.energy = 900
    bpy.context.object.data.size = 5
    bpy.context.object.data.color = (1, 0.9, 0.8)


def glass_office(x0, x1, y0, y1, door_x, label):
    """Glass-walled private office: floor-to-ceiling panes with black mullions, walnut door, brass sign, furniture."""
    front_y = y0
    for x in [x0 + 0.02 + i * 1.2 for i in range(int((x1 - x0) / 1.2) + 1)]:
        cube("OfficeMullion", 1, (min(x, x1), front_y, H / 2), (0.06, 0.08, H), MULLION, bevel=0, outline=False)
    for xa, xb in ((x0, door_x - 0.6), (door_x + 0.6, x1)):
        cube("OfficeGlass", 1, ((xa + xb) / 2, front_y, H / 2), (xb - xa, 0.03, H), GLASSWALL, bevel=0, outline=False)
    for x in (x0, x1):
        cube("OfficeSideGlass", 1, (x, (y0 + y1) / 2, H / 2), (0.03, y1 - y0, H), GLASSWALL, bevel=0, outline=False)
        cube("OfficeSideMullion", 1, (x, y0, H / 2), (0.08, 0.08, H), MULLION, bevel=0, outline=False)
    cube("OfficeHeader", 1, ((x0 + x1) / 2, front_y, H - 0.1), (x1 - x0, 0.1, 0.2), MULLION, bevel=0, outline=False)
    place("OfficeDoor", (door_x, front_y, 0), 0.0)
    place("RoomSign", (door_x, front_y - 0.1, 2.35), 0.0)
    text("SignText", label, (door_x, front_y - 0.125, 2.47), 0.09, mat("SignInk", (0.1, 0.06, 0.02), 0.5))
    mid = ((x0 + x1) / 2, (y0 + y1) / 2 + 0.6)
    place("DeskSet", (mid[0], mid[1], 0), math.pi)
    place("OfficeChair", (mid[0], mid[1] + 0.9, 0), math.pi)
    place("PlantFiddle", (x1 - 0.5, y1 - 0.5, 0))
    place(rng.choice(["PaintingBull", "PaintingAbstract", "PaintingSunset"]), (mid[0], y1 - 0.08, 1.0), 0.0)


def candle_screen(loc, rot, width, height, n):
    """Big trading screen with a live-looking candlestick chart."""
    frame = cube("TradeScreenFrame", 1, loc, (width + 0.12, 0.08, height + 0.12), MULLION, rot=(0, 0, rot), bevel=0.01)
    right = Vector((math.cos(rot), math.sin(rot), 0))
    fwd = Vector((-math.sin(rot), math.cos(rot), 0)) * -0.045
    cube("TradeScreen", 1, Vector(loc) + fwd, (width, 0.01, height), SCREEN_BG, rot=(0, 0, rot), bevel=0, outline=False)
    price, pts = 0.5, []
    for i in range(n):
        o = price
        c = min(0.92, max(0.08, o + rng.uniform(-0.09, 0.1)))
        hi, lo = max(o, c) + rng.uniform(0.01, 0.05), min(o, c) - rng.uniform(0.01, 0.05)
        pts.append((o, c, hi, lo))
        price = c
    step = width * 0.9 / n
    for i, (o, c, hi, lo) in enumerate(pts):
        px = -width * 0.45 + step * (i + 0.5)
        base = Vector(loc) + fwd * 1.6 + right * px
        z0 = loc[2] - height / 2
        m = UP if c >= o else DOWN
        cube("Wick", 1, base + Vector((0, 0, z0 + (hi + lo) / 2 * height - loc[2] + loc[2] - loc[2])) * 0 +
             Vector((0, 0, 0)) + Vector((base.x - base.x, 0, 0)), (0.008, 0.005, (hi - lo) * height), m, rot=(0, 0, rot),
             bevel=0, outline=False).location = (base.x, base.y, z0 + (hi + lo) / 2 * height)
        body = cube("CandleBody", 1, (base.x, base.y, z0 + (o + c) / 2 * height),
                    (step * 0.6, 0.006, max(abs(c - o) * height, 0.01)), m, rot=(0, 0, rot), bevel=0, outline=False)
        body.location = (base.x + fwd.x * 0.2, base.y + fwd.y * 0.2, z0 + (o + c) / 2 * height)
    return frame


# trading floor: three pods of back-to-back desks
for pod_y in (-5.5, 0.0):
    for i in range(5):
        x = -9 + i * 1.75
        place("DeskSet", (x, pod_y - 0.45, 0), 0.0)
        place("OfficeChair", (x, pod_y - 1.25, 0), 0.0 + rng.uniform(-0.3, 0.3))
        place("DeskSet", (x, pod_y + 0.45, 0), math.pi)
        place("OfficeChair", (x, pod_y + 1.25, 0), math.pi + rng.uniform(-0.3, 0.3))
    cube("PodDivider", 1, (-9 + 2 * 1.75, pod_y, 0.95), (8.6, 0.05, 0.4), bpy.data.materials["Fabric_Navy"], bevel=0.01)

# glass offices along the back wall
glass_office(-14.5, -10.2, 4.6, 10.8, -12.3, "THE CHAIRMAN")
glass_office(-10.0, -5.8, 4.6, 10.8, -7.9, "OFFICE 1")
glass_office(-5.6, -1.4, 4.6, 10.8, -3.5, "MEETING ROOM")

# candlestick wall on the right, LED ticker across the floor
for k, y in enumerate((-6.5, -2.2, 2.1)):
    candle_screen((14.9, y, 2.1), R(90), 3.8, 2.0, 28 + k * 4)
cube("TickerBar", 1, (0, -2.75, 3.05), (22, 0.08, 0.32), MULLION, bevel=0.01)
t = text("TickerText", "BANANA MOON +12.4%   WOLF & CO +100%   DUCK YACHTS -3.1%   HOVERCAR +44%   GOLD TOILETS +6.6%",
         (0, -2.8, 3.05), 0.17, TICK)

# lounge corner with the gold bull, sofas, coffee table, plants, whiteboards
place("GoldBull", (6.5, 7.2, 0), R(-150), 1.0)
place("Sofa", (10.5, 8.8, 0), math.pi)
place("CoffeeTable", (10.5, 7.4, 0), 0)
place("CashStack", (10.3, 7.4, 0.44), 0.3)
place("Laptop", (10.8, 7.35, 0.44), 2.8)
place("Whiteboard", (2.0, 8.0, 0), math.pi + 0.2)
place("Whiteboard", (12.5, -9.0, 0), 0.4)
for pos, kind in (((13.8, 9.8, 0), "PlantPalm"), ((-14.0, -9.8, 0), "PlantPalm"), ((1.0, -9.8, 0), "PlantSnake"),
                  ((-0.8, 4.0, 0), "PlantFiddle"), ((13.8, 4.6, 0), "PlantFiddle")):
    place(kind, pos, rng.uniform(0, 6.28))
place("WaterCooler", (14.2, 0.2, 0), R(-90))
place("CoffeeMachine", (14.3, -0.6, 0.0), R(-90))
place("TrashBin", (-3.4, -2.8, 0), 0)
place("TrashBin", (-3.4, 2.6, 0), 0)

# chaos: papers, cash, cups and food all over the floor
PAPER = bpy.data.materials["SmoothPlastic_Paper"]
CASH = bpy.data.materials["Fabric_Cash"]
for _ in range(90):
    x, y = rng.uniform(-12, 13), rng.uniform(-9.5, 3.5)
    if abs(y + 5.5) < 1.6 or abs(y) < 1.6:
        continue
    m = CASH if rng.random() < 0.4 else PAPER
    cube("FloorMess", 1, (x, y, 0.004), (0.3 if m == CASH else 0.21, 0.14 if m == CASH else 0.29, 0.003), m,
         rot=(0, 0, rng.uniform(0, 6.28)), bevel=0, outline=False)
for kind in ("PaperCup", "Donut", "PizzaSlice", "SodaCan", "Banana", "CashStack", "PaperCup", "Burger"):
    place(kind, (rng.uniform(-11, 12), rng.uniform(-9, -7), 0), rng.uniform(0, 6.28))

for tpl in TEMPLATES:  # hide the template lineup
    for o in [tpl] + kids(tpl):
        o.hide_render = True
        o.hide_set(True)

sc.render.engine = "CYCLES"
sc.cycles.samples = 40
sc.cycles.use_denoising = True
sc.view_settings.view_transform = "Standard"
os.makedirs(os.path.join(D, "renders"), exist_ok=True)
views = {
    "office_trading_floor": ((-13.5, -9.6, 1.65), (4, 2, 1.1)),
    "office_glass_offices": ((4.0, -6.0, 1.7), (-9, 9, 1.4)),
    "office_candles_lounge": ((-4.0, 1.5, 1.7), (14, -1, 1.6)),
}
bpy.ops.object.camera_add()
cam = bpy.context.object
cam.data.lens = 24
sc.camera = cam
for name, (loc, target) in views.items():
    cam.location = loc
    cam.rotation_mode = "QUATERNION"
    cam.rotation_quaternion = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y")
    render(os.path.join(D, "renders", name + ".png"), x=1500, y=850, samples=40)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(D, "office_scene.blend"))
print("DONE")
