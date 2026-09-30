"""Office props for Wolves With Your Friends, modeled in Blender.

Every material is named "<RobloxMaterial>_<Look>" (e.g. Leather_Black, Metal_Chrome). export_props.py splits each
prop into one mesh per material so the game can put Roblox's real materials on every piece.
Orientation: front of every prop faces -Y (the direction a seated player looks). Floor is Z = 0.

Run: python3 props.py   -> props.blend + renders/props_lineup.png
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib import *  # noqa

D = os.path.dirname(os.path.abspath(__file__))
R = math.radians
rng = random.Random(7)

reset()


def M(kind, look, color, rough=0.5, metal=0.0, emit=0.0):
    return mat(f"{kind}_{look}", color, rough, metal, emit)


LEATHER = M("Leather", "Black", (0.04, 0.04, 0.045), 0.45)
LEATHER_BROWN = M("Leather", "Cognac", (0.45, 0.2, 0.08), 0.4)
CHROME = M("Metal", "Chrome", (0.8, 0.8, 0.83), 0.15, 1.0)
DARKMETAL = M("Metal", "Graphite", (0.12, 0.12, 0.14), 0.35, 0.9)
GOLD = M("Metal", "Gold", (1.0, 0.72, 0.25), 0.2, 1.0)
PLASTIC_BLK = M("Plastic", "Black", (0.03, 0.03, 0.035), 0.35)
PLASTIC_WHT = M("Plastic", "White", (0.9, 0.9, 0.9), 0.35)
PLASTIC_GRY = M("Plastic", "Grey", (0.35, 0.36, 0.4), 0.4)
RUBBER = M("Rubber", "Black", (0.02, 0.02, 0.02), 0.8)
WALNUT = M("Wood", "Walnut", (0.28, 0.14, 0.06), 0.45)
OAK = M("WoodPlanks", "Oak", (0.55, 0.36, 0.18), 0.5)
MARBLE = M("Marble", "White", (0.92, 0.9, 0.87), 0.2)
MARBLE_BLK = M("Marble", "Black", (0.05, 0.05, 0.06), 0.15)
SCREEN = M("Glass", "Screen", (0.02, 0.04, 0.08), 0.05)
GLASS = M("Glass", "Clear", (0.75, 0.85, 0.9), 0.02)
FABRIC_NAVY = M("Fabric", "Navy", (0.05, 0.07, 0.2), 0.9)
FABRIC_CREAM = M("Fabric", "Cream", (0.85, 0.78, 0.65), 0.9)
CERAMIC = M("Ceramic", "White", (0.95, 0.95, 0.95), 0.1)
TERRACOTTA = M("Ceramic", "Terracotta", (0.65, 0.3, 0.15), 0.6)
CONCRETE = M("Concrete", "Planter", (0.85, 0.84, 0.8), 0.8)
SOIL = M("Ground", "Soil", (0.12, 0.07, 0.03), 0.9)
LEAF = M("LeafyGrass", "Leaf", (0.12, 0.45, 0.12), 0.6)
LEAF2 = M("LeafyGrass", "LeafLight", (0.3, 0.6, 0.15), 0.6)
PAPER = M("SmoothPlastic", "Paper", (0.96, 0.96, 0.93), 0.7)
CASH = M("Fabric", "Cash", (0.35, 0.6, 0.3), 0.8)
CARDBOARD = M("Cardboard", "Band", (0.85, 0.75, 0.55), 0.8)
NEON_BLUE = M("Neon", "Blue", (0.2, 0.6, 1.0), 0.3, emit=4)
NEON_GREEN = M("Neon", "Green", (0.3, 1.0, 0.4), 0.3, emit=4)
WATER = M("Glass", "Water", (0.45, 0.7, 0.95), 0.02)

PROPS = []


def prop(name, x):
    e = empty(name, (x, 0, 0))
    PROPS.append(e)
    return e


# ------------------------------------------------------------------ Office chair
def office_chair(x):
    p = prop("OfficeChair", x)
    for i in range(5):  # five-star base with twin-wheel casters
        a = 2 * math.pi * i / 5
        end = (0.32 * math.cos(a), 0.32 * math.sin(a), 0.07)
        tube("StarArm", 0.022, (0, 0, 0.1), end, CHROME, p, r2=0.016)
        sphere("CasterHub", 0.022, (end[0], end[1], 0.055), (1, 1, 1), DARKMETAL, p, outline=False)
        for s in (-1, 1):
            tube("Wheel", 0.03, (end[0] - 0.012 * s * math.sin(a), end[1] + 0.012 * s * math.cos(a), 0.032),
                 (end[0] - 0.024 * s * math.sin(a), end[1] + 0.024 * s * math.cos(a), 0.032), RUBBER, p)
    tube("BaseHub", 0.05, (0, 0, 0.07), (0, 0, 0.13), CHROME, p)
    tube("GasLift", 0.028, (0, 0, 0.12), (0, 0, 0.42), CHROME, p)
    tube("LiftCover", 0.04, (0, 0, 0.3), (0, 0, 0.4), PLASTIC_BLK, p, r2=0.036)
    cube("SeatPlate", 1, (0, 0, 0.43), (0.36, 0.34, 0.03), PLASTIC_BLK, p, bevel=0.01)
    cube("Seat", 1, (0, -0.02, 0.48), (0.52, 0.5, 0.09), LEATHER, p, bevel=0.04, subsurf=1)
    for k in range(3):  # stitched quilting ridges
        cube("SeatQuilt", 1, (-0.13 + 0.13 * k, -0.02, 0.527), (0.012, 0.44, 0.012), LEATHER, p, bevel=0.004, outline=False)
    tube("BackSpine", 0.02, (0, 0.2, 0.44), (0, 0.27, 0.62), DARKMETAL, p)
    cube("Backrest", 1, (0, 0.29, 0.86), (0.48, 0.08, 0.56), LEATHER, p, rot=(R(-8), 0, 0), bevel=0.04, subsurf=1)
    sphere("Lumbar", 0.18, (0, 0.25, 0.72), (1.25, 0.28, 0.55), LEATHER, p)
    cube("Headrest", 1, (0, 0.33, 1.22), (0.32, 0.08, 0.14), LEATHER, p, rot=(R(-8), 0, 0), bevel=0.035, subsurf=1)
    tube("HeadrestPost", 0.012, (0, 0.33, 1.12), (0, 0.33, 1.16), CHROME, p)
    for s in (-1, 1):
        tube("ArmPost", 0.018, (0.24 * s, 0.02, 0.45), (0.26 * s, 0.02, 0.66), DARKMETAL, p)
        cube("ArmPad", 1, (0.26 * s, -0.02, 0.675), (0.07, 0.26, 0.03), PLASTIC_BLK, p, bevel=0.012)


# ------------------------------------------------------------------ Desk set
def desk_set(x):
    p = prop("DeskSet", x)
    # desk: walnut top, graphite frame, drawer pedestal, modesty panel, cable tray
    cube("DeskTop", 1, (0, 0, 0.74), (1.6, 0.78, 0.04), WALNUT, p, bevel=0.012)
    cube("DeskEdge", 1, (0, 0.39, 0.73), (1.6, 0.012, 0.035), DARKMETAL, p, bevel=0.003, outline=False)
    for sx in (-1, 1):
        for sy in (-1, 1):
            cube("Leg", 1, (0.76 * sx, 0.34 * sy, 0.36), (0.045, 0.045, 0.72), DARKMETAL, p, bevel=0.006)
        cube("SideRail", 1, (0.76 * sx, 0, 0.68), (0.04, 0.68, 0.04), DARKMETAL, p, bevel=0.006)
    cube("Modesty", 1, (0, -0.34, 0.5), (1.45, 0.02, 0.3), DARKMETAL, p, bevel=0.004)
    cube("CableTray", 1, (0, -0.25, 0.64), (1.0, 0.12, 0.04), DARKMETAL, p, bevel=0.004)
    cube("Pedestal", 1, (0.55, 0.02, 0.33), (0.4, 0.6, 0.62), WALNUT, p, bevel=0.01)
    for k in range(3):
        cube("DrawerLine", 1, (0.55, 0.325, 0.18 + 0.2 * k), (0.38, 0.004, 0.006), DARKMETAL, p, bevel=0, outline=False)
        cube("DrawerPull", 1, (0.55, 0.335, 0.25 + 0.2 * k), (0.12, 0.012, 0.014), CHROME, p, bevel=0.004, outline=False)
    # PC tower under the desk with a glowing strip
    cube("PCTower", 1, (-0.55, -0.05, 0.24), (0.2, 0.44, 0.46), PLASTIC_BLK, p, bevel=0.012)
    cube("PCStrip", 1, (-0.55, 0.172, 0.24), (0.012, 0.004, 0.38), NEON_BLUE, p, bevel=0, outline=False)
    tube("PowerButton", 0.012, (-0.55, 0.17, 0.44), (-0.55, 0.176, 0.44), NEON_GREEN, p, outline=False)
    # monitor: slim bezel, glass screen, arm, round foot
    cube("MonitorBack", 1, (0, -0.2, 1.08), (0.66, 0.035, 0.4), PLASTIC_BLK, p, bevel=0.01)
    cube("MonitorScreen", 1, (0, -0.221, 1.085), (0.62, 0.004, 0.36), SCREEN, p, bevel=0, outline=False)
    tube("MonitorArm", 0.022, (0, -0.17, 0.76), (0, -0.17, 1.02), DARKMETAL, p)
    tube("MonitorFoot", 0.12, (0, -0.17, 0.76), (0, -0.17, 0.772), DARKMETAL, p)
    cube("Webcam", 1, (0, -0.2, 1.305), (0.09, 0.04, 0.03), PLASTIC_BLK, p, bevel=0.008)
    # second, portrait monitor for charts
    cube("SideMonitor", 1, (-0.52, -0.16, 1.02), (0.26, 0.03, 0.42), PLASTIC_BLK, p, rot=(0, 0, R(-25)), bevel=0.008)
    cube("SideScreen", 1, (-0.512, -0.178, 1.02), (0.24, 0.004, 0.39), SCREEN, p, rot=(0, 0, R(-25)), bevel=0,
         outline=False)
    tube("SideArm", 0.016, (-0.5, -0.12, 0.76), (-0.5, -0.12, 0.84), DARKMETAL, p)
    # keyboard with real key rows, mouse, pad
    cube("Keyboard", 1, (0, 0.1, 0.77), (0.44, 0.14, 0.016), PLASTIC_GRY, p, bevel=0.004)
    for r in range(4):
        for k in range(14):
            cube("Key", 1, (-0.195 + k * 0.03, 0.05 + r * 0.032, 0.782), (0.024, 0.024, 0.01), PLASTIC_BLK, p, bevel=0.002,
                 outline=False)
    cube("SpaceBar", 1, (0, 0.165, 0.782), (0.16, 0.022, 0.01), PLASTIC_BLK, p, bevel=0.002, outline=False)
    cube("MousePad", 1, (0.34, 0.12, 0.763), (0.24, 0.2, 0.004), FABRIC_NAVY, p, bevel=0.002, outline=False)
    sphere("Mouse", 0.035, (0.34, 0.12, 0.775), (0.75, 1.1, 0.45), PLASTIC_BLK, p)
    # desk phone: body, curved handset, keypad, little screen
    cube("PhoneBase", 1, (-0.6, 0.12, 0.785), (0.2, 0.18, 0.05), PLASTIC_BLK, p, rot=(R(-10), 0, 0), bevel=0.01)
    tube("Handset", 0.02, (-0.67, 0.05, 0.825), (-0.67, 0.2, 0.825), PLASTIC_BLK, p)
    for end in (0.05, 0.2):
        sphere("HandsetEnd", 0.03, (-0.67, end, 0.822), (1, 1.2, 0.8), PLASTIC_BLK, p, outline=False)
    for r in range(4):
        for k in range(3):
            cube("PhoneKey", 1, (-0.6 + k * 0.03, 0.11 + r * 0.022, 0.815), (0.02, 0.014, 0.006), PLASTIC_GRY, p, bevel=0,
                 outline=False)
    cube("PhoneScreen", 1, (-0.545, 0.1, 0.815), (0.05, 0.06, 0.004), NEON_GREEN, p, bevel=0, outline=False)
    # clutter: mug, paper stacks, pen cup, photo frame, sticky notes
    tube("Mug", 0.04, (0.62, -0.12, 0.76), (0.62, -0.12, 0.86), CERAMIC, p)
    torus("MugHandle", 0.028, 0.008, (0.665, -0.12, 0.81), CERAMIC, p, rot=(R(90), 0, 0), outline=False)
    tube("Coffee", 0.037, (0.62, -0.12, 0.85), (0.62, -0.12, 0.852), M("SmoothPlastic", "Coffee", (0.15, 0.07, 0.03), 0.1), p,
         outline=False)
    for i in range(6):
        cube("Paper", 1, (0.28, -0.22, 0.762 + i * 0.004), (0.21, 0.29, 0.002), PAPER, p,
             rot=(0, 0, R(rng.uniform(-10, 10))), bevel=0, outline=False)
    tube("PenCup", 0.035, (0.72, 0.05, 0.76), (0.72, 0.05, 0.86), DARKMETAL, p)
    for k in range(3):
        tube("Pen", 0.006, (0.715 + 0.01 * k, 0.05, 0.8), (0.7 + 0.02 * k, 0.04, 0.92),
             [PLASTIC_BLK, M("Plastic", "Red", (0.8, 0.05, 0.05), 0.4), M("Plastic", "Blue", (0.05, 0.2, 0.8), 0.4)][k], p,
             outline=False)
    cube("PhotoFrame", 1, (0.45, -0.3, 0.82), (0.13, 0.015, 0.1), GOLD, p, rot=(R(-15), 0, R(-20)), bevel=0.004)
    for i in range(3):
        cube("StickyNote", 1, (-0.2 + 0.14 * i, -0.222, 0.94 - 0.03 * i), (0.06, 0.002, 0.06),
             M("SmoothPlastic", "Sticky", (1.0, 0.85, 0.3), 0.8), p, rot=(0, R(rng.uniform(-8, 8)), 0), bevel=0, outline=False)


# ------------------------------------------------------------------ Sofa + coffee table
def sofa(x):
    p = prop("Sofa", x)
    cube("SofaBase", 1, (0, 0, 0.22), (2.1, 0.9, 0.24), LEATHER_BROWN, p, bevel=0.05, subsurf=1)
    for k in range(3):
        cube("SeatCushion", 1, (-0.68 + 0.68 * k, -0.05, 0.42), (0.66, 0.78, 0.16), LEATHER_BROWN, p, bevel=0.06, subsurf=1)
        cube("BackCushion", 1, (-0.68 + 0.68 * k, 0.36, 0.72), (0.66, 0.2, 0.46), LEATHER_BROWN, p, rot=(R(-10), 0, 0),
             bevel=0.07, subsurf=1)
        for t in range(3):  # chesterfield buttons
            sphere("Tuft", 0.018, (-0.68 + 0.68 * k + (t - 1) * 0.18, 0.25, 0.78), (1, 0.6, 1), LEATHER_BROWN, p,
                   outline=False)
    for s in (-1, 1):
        cube("Arm", 1, (1.12 * s, 0, 0.42), (0.18, 0.9, 0.46), LEATHER_BROWN, p, bevel=0.07, subsurf=1)
        for sy in (-1, 1):
            tube("SofaLeg", 0.025, (1.0 * s, 0.38 * sy, 0.0), (1.0 * s, 0.38 * sy, 0.1), GOLD, p, r2=0.018)


def coffee_table(x):
    p = prop("CoffeeTable", x)
    cube("TableTop", 1, (0, 0, 0.42), (1.2, 0.6, 0.04), MARBLE_BLK, p, bevel=0.01)
    for sx in (-1, 1):
        for sy in (-1, 1):
            tube("TableLeg", 0.018, (0.52 * sx, 0.24 * sy, 0.0), (0.5 * sx, 0.22 * sy, 0.4), GOLD, p)
    for i in range(3):  # stack of luxury magazines
        cube("Magazine", 1, (-0.3, 0.05, 0.445 + i * 0.008), (0.22, 0.3, 0.006),
             M("Plastic", "Magazine%d" % i, [(0.8, 0.1, 0.1), (0.1, 0.1, 0.1), (0.9, 0.7, 0.2)][i], 0.3), p,
             rot=(0, 0, R(8 * i)), bevel=0, outline=False)


# ------------------------------------------------------------------ Plants
def leaves(p, center, count, spread, size, m, up=0.0):
    for i in range(count):
        a = 2 * math.pi * i / count + rng.uniform(-0.3, 0.3)
        tilt = rng.uniform(30, 65)
        cx = center[0] + math.cos(a) * spread
        cy = center[1] + math.sin(a) * spread
        cz = center[2] + rng.uniform(-0.05, 0.05) + up
        sphere("Leaf", size, (cx, cy, cz), (0.45, 1.0, 0.08), m, p, rot=(R(tilt), 0, a - math.pi / 2), width=0.004)


def plant_fiddle(x):
    p = prop("PlantFiddle", x)
    tube("Pot", 0.2, (0, 0, 0), (0, 0, 0.42), CONCRETE, p, r2=0.24)
    tube("Soil", 0.22, (0, 0, 0.39), (0, 0, 0.405), SOIL, p, outline=False)
    tube("Trunk", 0.025, (0, 0, 0.4), (0.03, 0.02, 1.5), WALNUT, p, r2=0.015)
    for k, h in enumerate([0.8, 1.0, 1.2, 1.4, 1.55]):
        leaves(p, (0.02, 0.01, h), 5, 0.14, 0.14, LEAF if k % 2 else LEAF2)


def plant_snake(x):
    p = prop("PlantSnake", x)
    tube("Pot", 0.17, (0, 0, 0), (0, 0, 0.32), TERRACOTTA, p, r2=0.2)
    tube("Soil", 0.18, (0, 0, 0.3), (0, 0, 0.315), SOIL, p, outline=False)
    for i in range(9):
        a = 2 * math.pi * i / 9
        r = rng.uniform(0.03, 0.1)
        h = rng.uniform(0.45, 0.8)
        cone("SnakeLeaf", 0.05, 0.004, h, (math.cos(a) * r, math.sin(a) * r, 0.3 + h / 2), LEAF if i % 2 else LEAF2, p,
             rot=(R(rng.uniform(-10, 10)), R(rng.uniform(-10, 10)), a), scale=(1, 0.25, 1), width=0.004)


def plant_palm(x):
    p = prop("PlantPalm", x)
    cube("Pot", 1, (0, 0, 0.25), (0.5, 0.5, 0.5), MARBLE, p, bevel=0.02)
    cube("PotTrim", 1, (0, 0, 0.49), (0.53, 0.53, 0.03), GOLD, p, bevel=0.005, outline=False)
    cube("Soil", 1, (0, 0, 0.5), (0.44, 0.44, 0.01), SOIL, p, bevel=0, outline=False)
    for k in range(6):  # ringed trunk
        tube("Trunk", 0.05 - 0.004 * k, (0.004 * k, 0, 0.5 + 0.18 * k), (0.004 * (k + 1), 0, 0.68 + 0.18 * k), OAK, p,
             r2=0.046 - 0.004 * k)
    top = (0.024, 0, 1.58)
    for s in range(3):
        sphere("Coconut", 0.045, (top[0] + 0.05 * math.cos(s * 2.1), 0.05 * math.sin(s * 2.1), 1.52), (1, 1, 1.1),
               M("Wood", "Coconut", (0.25, 0.14, 0.05), 0.7), p, outline=False)
    for i in range(10):
        a = 2 * math.pi * i / 10 + rng.uniform(-0.15, 0.15)
        reach = rng.uniform(0.5, 0.7)
        droop = rng.uniform(0.25, 0.4)
        for t in range(7):
            f = t / 6
            pos = (top[0] + math.cos(a) * reach * f, math.sin(a) * reach * f, top[2] + 0.12 * math.sin(f * math.pi) - droop * f * f)
            sphere("Frond", 0.11 - 0.008 * t, pos, (0.55, 1.3, 0.07), LEAF if (i + t) % 2 else LEAF2, p,
                   rot=(R(25 + 40 * f), 0, a - math.pi / 2), width=0.004)


# ------------------------------------------------------------------ Bin, water cooler, cash, bull, door
def trash_bin(x):
    p = prop("TrashBin", x)
    tube("Bin", 0.16, (0, 0, 0), (0, 0, 0.45), DARKMETAL, p, r2=0.19)
    torus("Rim", 0.19, 0.012, (0, 0, 0.45), CHROME, p, outline=False)
    torus("Liner", 0.185, 0.01, (0, 0, 0.44), M("Plastic", "BinBag", (0.05, 0.05, 0.06), 0.3), p, outline=False)
    cube("Pedal", 1, (0, -0.2, 0.03), (0.12, 0.06, 0.02), CHROME, p, bevel=0.005)
    sphere("CrumpledPaper", 0.07, (0.04, 0.02, 0.44), (1, 1, 0.9), PAPER, p)
    sphere("CrumpledPaper2", 0.05, (-0.06, -0.03, 0.45), (1, 1, 0.9), PAPER, p)


def water_cooler(x):
    p = prop("WaterCooler", x)
    cube("CoolerBody", 1, (0, 0, 0.5), (0.34, 0.34, 1.0), PLASTIC_WHT, p, bevel=0.03)
    cube("DripTray", 1, (0, -0.19, 0.62), (0.2, 0.06, 0.02), PLASTIC_GRY, p, bevel=0.005)
    for s, m in ((-1, M("Plastic", "Blue", (0.05, 0.2, 0.8), 0.4)), (1, M("Plastic", "Red", (0.8, 0.05, 0.05), 0.4))):
        cube("Tap", 1, (0.06 * s, -0.18, 0.78), (0.04, 0.05, 0.04), m, p, bevel=0.008)
    tube("Jug", 0.16, (0, 0, 1.0), (0, 0, 1.42), WATER, p, r2=0.14)
    sphere("JugTop", 0.14, (0, 0, 1.42), (1, 1, 0.5), WATER, p)


def cash_stack(x):
    p = prop("CashStack", x)
    for i in range(4):
        cube("Bills", 1, (0, 0, 0.03 + i * 0.062), (0.16, 0.07, 0.06), CASH, p, rot=(0, 0, R(rng.uniform(-6, 6))),
             bevel=0.004)
        cube("BillBand", 1, (0, 0, 0.03 + i * 0.062), (0.035, 0.072, 0.062), CARDBOARD, p, rot=(0, 0, R(rng.uniform(-6, 6))),
             bevel=0.002, outline=False)


def gold_bull(x):
    p = prop("GoldBull", x)
    cube("Plinth", 1, (0, 0, 0.3), (1.9, 0.9, 0.6), MARBLE_BLK, p, bevel=0.03)
    cube("PlinthTrim", 1, (0, 0, 0.61), (1.95, 0.95, 0.03), GOLD, p, bevel=0.01, outline=False)
    text("PlinthText", "WOLF & CO.", (0, -0.456, 0.3), 0.13, GOLD, p)
    # charging pose: chest high, head low, back legs pushing
    skin("BullBody", [(0.45, 0, 1.28), (0.15, 0, 1.33), (-0.2, 0, 1.25), (-0.55, 0, 1.18), (-0.68, 0, 1.12)],
         [(0, 1), (1, 2), (2, 3), (3, 4)], [(0.36, 0.3), (0.42, 0.33), (0.36, 0.29), (0.3, 0.26), (0.24, 0.22)], GOLD, p)
    sphere("Hump", 0.24, (0.25, 0, 1.55), (1.2, 0.9, 0.7), GOLD, p)
    skin("BullNeck", [(0.45, 0, 1.35), (0.7, 0, 1.18), (0.85, 0, 1.0)], [(0, 1), (1, 2)], [0.27, 0.23, 0.2], GOLD, p)
    sphere("BullHead", 0.19, (0.92, 0, 0.96), (1.25, 0.95, 0.95), GOLD, p)
    sphere("BullMuzzle", 0.12, (1.1, 0, 0.88), (1.0, 1.05, 0.85), GOLD, p)
    for s in (-1, 1):
        sphere("Nostril", 0.022, (1.2, 0.05 * s, 0.9), (1, 1, 1), M("Metal", "DarkGold", (0.45, 0.3, 0.08), 0.3, 1.0), p,
               outline=False)
        sphere("BullEye", 0.028, (1.0, 0.13 * s, 1.03), (1, 1, 1), M("Metal", "DarkGold", (0.45, 0.3, 0.08), 0.3, 1.0), p,
               outline=False)
        sphere("Ear", 0.06, (0.86, 0.2 * s, 1.08), (1.4, 0.5, 0.6), GOLD, p, rot=(0, 0, R(25 * s)))
        tube("Horn", 0.055, (0.88, 0.14 * s, 1.1), (0.92, 0.36 * s, 1.18), GOLD, p, r2=0.035)
        tube("HornTip", 0.035, (0.92, 0.36 * s, 1.18), (1.08, 0.42 * s, 1.34), GOLD, p, r2=0.004)
        for fx, knee, foot in ((0.35, (0.5, 0.95), (0.62, 0.66)), (-0.5, (-0.62, 0.92), (-0.82, 0.66))):
            skin("BullLeg", [(fx, 0.16 * s, 1.12), (knee[0], 0.17 * s, knee[1]), (foot[0], 0.17 * s, foot[1] + 0.04)],
                 [(0, 1), (1, 2)], [0.12, 0.08, 0.065], GOLD, p)
            cube("Hoof", 1, (foot[0], 0.17 * s, foot[1] + 0.03), (0.1, 0.09, 0.06), M("Metal", "DarkGold", (0.45, 0.3, 0.08), 0.3, 1.0),
                 p, bevel=0.01)
    for t in range(4):  # swishing tail
        tube("Tail", 0.025 - 0.004 * t, (-0.72 - 0.08 * t, 0, 1.25 + 0.1 * t), (-0.8 - 0.08 * t, 0.03 * t, 1.35 + 0.1 * t), GOLD, p)
    sphere("TailTuft", 0.05, (-1.06, 0.12, 1.66), (1, 1, 1.4), GOLD, p)


def office_door(x):
    p = prop("OfficeDoor", x)
    for sx in (-1, 1):
        cube("FrameSide", 1, (0.52 * sx, 0, 1.08), (0.08, 0.16, 2.16), WALNUT, p, bevel=0.01)
    cube("FrameTop", 1, (0, 0, 2.18), (1.12, 0.16, 0.08), WALNUT, p, bevel=0.01)
    cube("DoorPanel", 1, (0, 0, 1.06), (0.96, 0.05, 2.1), WALNUT, p, bevel=0.008)
    cube("DoorGlass", 1, (0, -0.028, 1.45), (0.5, 0.01, 0.9), GLASS, p, bevel=0, outline=False)
    for z in (0.35, 0.75):
        cube("DoorInset", 1, (0, -0.03, z), (0.7, 0.01, 0.3), OAK, p, bevel=0.004, outline=False)
    tube("Handle", 0.012, (0.36, -0.03, 1.05), (0.36, -0.1, 1.05), GOLD, p, outline=False)
    tube("HandleBar", 0.014, (0.36, -0.1, 0.9), (0.36, -0.1, 1.2), GOLD, p, outline=False)
    tube("Hinge", 0.012, (-0.47, -0.03, 1.8), (-0.47, -0.03, 1.9), GOLD, p, outline=False)



# ------------------------------------------------------------------ Round 2: laptop, whiteboard, coffee, cafeteria, food, art, signs
ALU = M("Metal", "Aluminium", (0.72, 0.73, 0.76), 0.3, 1.0)
WHITEBOARD = M("SmoothPlastic", "Whiteboard", (0.97, 0.97, 0.97), 0.15)
PLASTIC_RED = M("Plastic", "CafeRed", (0.8, 0.12, 0.1), 0.35)
BUN = M("SmoothPlastic", "Bun", (0.85, 0.55, 0.22), 0.6)
PATTY = M("SmoothPlastic", "Patty", (0.3, 0.15, 0.07), 0.8)
CHEESE = M("SmoothPlastic", "Cheese", (1.0, 0.75, 0.1), 0.5)
LETTUCE = M("LeafyGrass", "Lettuce", (0.35, 0.75, 0.2), 0.6)
TOMATO = M("SmoothPlastic", "Tomato", (0.85, 0.15, 0.1), 0.4)
CRUST = M("SmoothPlastic", "Crust", (0.9, 0.65, 0.3), 0.7)
PEPPERONI = M("SmoothPlastic", "Pepperoni", (0.65, 0.1, 0.08), 0.5)
DOUGH = M("SmoothPlastic", "Donut", (0.8, 0.5, 0.2), 0.6)
ICING = M("SmoothPlastic", "PinkIcing", (1.0, 0.45, 0.65), 0.3)
APPLE = M("SmoothPlastic", "AppleRed", (0.8, 0.05, 0.05), 0.25)
BREAD = M("SmoothPlastic", "Bread", (0.95, 0.85, 0.6), 0.7)
BANANA = M("SmoothPlastic", "Banana", (1.0, 0.85, 0.15), 0.4)
CANVAS = M("Fabric", "Canvas", (0.95, 0.93, 0.86), 0.9)
BRASS = M("Metal", "Brass", (0.85, 0.65, 0.3), 0.25, 1.0)


def laptop(x):
    p = prop("Laptop", x)
    cube("LaptopBase", 1, (0, 0, 0.009), (0.34, 0.24, 0.018), ALU, p, bevel=0.006)
    for r in range(5):
        for k in range(12):
            cube("LaptopKey", 1, (-0.14 + k * 0.0255, -0.02 + r * 0.021, 0.0195), (0.02, 0.017, 0.003), PLASTIC_BLK, p,
                 bevel=0, outline=False)
    cube("Trackpad", 1, (0, -0.08, 0.0185), (0.12, 0.065, 0.002), ALU, p, bevel=0.002, outline=False)
    cube("LaptopLid", 1, (0, 0.118, 0.12), (0.34, 0.012, 0.23), ALU, p, rot=(R(-12), 0, 0), bevel=0.006)
    cube("LaptopScreen", 1, (0, 0.108, 0.122), (0.31, 0.003, 0.2), SCREEN, p, rot=(R(-12), 0, 0), bevel=0, outline=False)
    text("LaptopLogo", "W", (0, 0.13, 0.12), 0.05, GOLD, p, rot=(R(-78), 0, R(180)), extrude=0.001)


def whiteboard(x):
    p = prop("Whiteboard", x)
    cube("Board", 1, (0, 0, 1.35), (1.6, 0.03, 1.0), WHITEBOARD, p, bevel=0.004)
    for z in (0.84, 1.86):
        cube("FrameH", 1, (0, 0, z), (1.64, 0.045, 0.03), ALU, p, bevel=0.006)
    for sx in (-1, 1):
        cube("FrameV", 1, (0.82 * sx, 0, 1.35), (0.03, 0.045, 1.05), ALU, p, bevel=0.006)
        tube("StandLeg", 0.018, (0.8 * sx, 0, 0.1), (0.8 * sx, 0, 1.4), ALU, p)
        cube("StandFoot", 1, (0.8 * sx, 0, 0.06), (0.06, 0.55, 0.04), ALU, p, bevel=0.008)
        for sy in (-1, 1):
            sphere("Wheel", 0.03, (0.8 * sx, 0.25 * sy, 0.03), (1, 1, 1), RUBBER, p, outline=False)
    cube("MarkerTray", 1, (0, -0.05, 0.84), (0.9, 0.08, 0.02), ALU, p, bevel=0.004)
    for i, col in enumerate([(0.05, 0.05, 0.05), (0.8, 0.05, 0.05), (0.05, 0.2, 0.8), (0.05, 0.6, 0.15)]):
        tube("Marker", 0.009, (-0.3 + i * 0.07, -0.06, 0.86), (-0.18 + i * 0.07, -0.06, 0.86),
             M("Plastic", "Marker%d" % i, col, 0.4), p, outline=False)
    cube("Eraser", 1, (0.25, -0.06, 0.87), (0.12, 0.05, 0.035), FABRIC_NAVY, p, bevel=0.006)


def coffee_machine(x):
    p = prop("CoffeeMachine", x)
    cube("CMBody", 1, (0, 0.03, 0.26), (0.34, 0.36, 0.52), CHROME, p, bevel=0.02)
    cube("CMFront", 1, (0, -0.152, 0.4), (0.3, 0.01, 0.2), PLASTIC_BLK, p, bevel=0.004)
    cube("CMDisplay", 1, (0, -0.158, 0.44), (0.12, 0.004, 0.05), NEON_GREEN, p, bevel=0, outline=False)
    for k in range(3):
        tube("CMButton", 0.014, (-0.08 + 0.08 * k, -0.155, 0.37), (-0.08 + 0.08 * k, -0.165, 0.37), CHROME, p, outline=False)
    cube("CMRecess", 1, (0, -0.1, 0.17), (0.24, 0.16, 0.2), PLASTIC_BLK, p, bevel=0.01)
    tube("Nozzle", 0.02, (0, -0.1, 0.27), (0, -0.1, 0.24), CHROME, p, outline=False)
    cube("DripGrate", 1, (0, -0.1, 0.075), (0.22, 0.15, 0.012), CHROME, p, bevel=0.003)
    tube("BeanHopper", 0.09, (0.06, 0.1, 0.52), (0.06, 0.1, 0.66), GLASS, p, r2=0.1)
    sphere("Beans", 0.08, (0.06, 0.1, 0.56), (1, 1, 0.5), M("Wood", "Beans", (0.18, 0.08, 0.03), 0.8), p, outline=False)
    tube("WaterTank", 0.07, (-0.12, 0.13, 0.1), (-0.12, 0.13, 0.48), WATER, p)


def paper_cup(x):
    p = prop("PaperCup", x)
    tube("Cup", 0.035, (0, 0, 0), (0, 0, 0.12), PAPER, p, r2=0.045)
    tube("Sleeve", 0.042, (0, 0, 0.03), (0, 0, 0.08), CARDBOARD, p, r2=0.046, outline=False)
    tube("Lid", 0.048, (0, 0, 0.12), (0, 0, 0.135), PLASTIC_WHT, p, r2=0.044)
    tube("SipTab", 0.008, (0.025, 0, 0.135), (0.025, 0, 0.145), PLASTIC_WHT, p, outline=False)


def cafe_table(x):
    p = prop("CafeTable", x)
    cube("CafeTop", 1, (0, 0, 0.74), (1.8, 0.8, 0.04), OAK, p, bevel=0.01)
    for sx in (-1, 1):
        cube("CafeLegA", 1, (0.75 * sx, 0, 0.36), (0.05, 0.6, 0.05), DARKMETAL, p, bevel=0.006)
        tube("CafeLegPost", 0.03, (0.75 * sx, 0, 0.06), (0.75 * sx, 0, 0.72), DARKMETAL, p)
        cube("CafeFoot", 1, (0.75 * sx, 0, 0.03), (0.08, 0.7, 0.05), DARKMETAL, p, bevel=0.008)
    tube("NapkinBox", 0.05, (0.5, 0, 0.76), (0.5, 0, 0.84), CHROME, p)
    for sx in (-0.05, 0.05):
        tube("Shaker", 0.015, (sx, 0, 0.76), (sx, 0, 0.83), GLASS, p)


def cafe_chair(x):
    p = prop("CafeChair", x)
    cube("CafeSeat", 1, (0, 0, 0.46), (0.42, 0.42, 0.035), PLASTIC_RED, p, bevel=0.015)
    cube("CafeBack", 1, (0, 0.2, 0.72), (0.4, 0.03, 0.34), PLASTIC_RED, p, rot=(R(-6), 0, 0), bevel=0.015)
    for sx in (-1, 1):
        for sy in (-1, 1):
            tube("CafeChairLeg", 0.013, (0.18 * sx, 0.18 * sy, 0.0), (0.17 * sx, 0.17 * sy, 0.45), CHROME, p)


def burger(x):
    p = prop("Burger", x)
    sphere("BunBottom", 0.1, (0, 0, 0.025), (1, 1, 0.3), BUN, p)
    tube("Patty", 0.1, (0, 0, 0.04), (0, 0, 0.065), PATTY, p)
    cube("CheeseSlice", 1, (0, 0, 0.07), (0.17, 0.17, 0.008), CHEESE, p, rot=(0, 0, R(45)), bevel=0.002)
    for i in range(6):
        a = i * math.pi / 3
        sphere("LettuceLeaf", 0.05, (0.07 * math.cos(a), 0.07 * math.sin(a), 0.078), (1, 1, 0.2), LETTUCE, p, outline=False)
    tube("TomatoSlice", 0.08, (0, 0, 0.082), (0, 0, 0.092), TOMATO, p, outline=False)
    sphere("BunTop", 0.105, (0, 0, 0.1), (1, 1, 0.6), BUN, p)
    for i in range(8):
        sphere("Sesame", 0.008, (0.06 * math.cos(i), 0.06 * math.sin(i * 1.7), 0.155), (1, 0.6, 0.4), PLASTIC_WHT, p,
               outline=False)


def pizza_slice(x):
    p = prop("PizzaSlice", x)
    cone("PizzaBase", 0.18, 0.0, 0.02, (0, 0, 0.01), CHEESE, p, scale=(1, 1, 1))
    bpy.context.object.scale = (0.55, 1.0, 1.0)
    tube("PizzaCrust", 0.03, (-0.1, 0.13, 0.02), (0.1, 0.13, 0.02), CRUST, p)
    for px, py in ((0, 0.05), (-0.04, -0.03), (0.03, -0.06), (0.05, 0.07)):
        tube("Pepperoni", 0.025, (px, py, 0.02), (px, py, 0.026), PEPPERONI, p, outline=False)


def donut(x):
    p = prop("Donut", x)
    torus("DonutRing", 0.07, 0.035, (0, 0, 0.035), DOUGH, p)
    torus("Icing", 0.07, 0.03, (0, 0, 0.045), ICING, p, scale=(1, 1, 0.7), outline=False)
    for i in range(14):
        a = i * 0.45
        cube("Sprinkle", 1, (0.07 * math.cos(a), 0.07 * math.sin(a), 0.07), (0.018, 0.005, 0.005),
             M("SmoothPlastic", "Sprinkle%d" % (i % 3), [(0.2, 0.6, 1.0), (1.0, 1.0, 0.3), (0.3, 1.0, 0.4)][i % 3], 0.4), p,
             rot=(0, 0, a * 3), bevel=0, outline=False)


def apple(x):
    p = prop("Apple", x)
    sphere("AppleBody", 0.05, (0, 0, 0.05), (1, 1, 0.92), APPLE, p)
    tube("AppleStem", 0.004, (0, 0, 0.09), (0.005, 0, 0.115), WALNUT, p, outline=False)
    sphere("AppleLeaf", 0.02, (0.018, 0, 0.11), (1, 0.45, 0.12), LEAF2, p, rot=(0, R(-30), 0), outline=False)


def sandwich(x):
    p = prop("Sandwich", x)
    for z, m in ((0.01, BREAD), (0.03, LETTUCE), (0.042, CHEESE), (0.055, TOMATO), (0.075, BREAD)):
        cone("SandwichLayer", 0.1, 0.1, 0.018 if m == BREAD else 0.01, (0, 0, z), m, p, rot=(0, 0, R(45)),
             outline=m == BREAD)
        bpy.context.object.data.vertices  # triangle-ish slices come from the 3-sided cones below
    tube("Toothpick", 0.003, (0, 0, 0.0), (0, 0, 0.13), OAK, p, outline=False)
    sphere("Olive", 0.012, (0, 0, 0.13), (1, 1, 1), LEAF, p, outline=False)


def soda_can(x):
    p = prop("SodaCan", x)
    tube("Can", 0.033, (0, 0, 0.005), (0, 0, 0.12), M("Metal", "SodaRed", (0.8, 0.05, 0.08), 0.3, 0.7), p)
    tube("CanTop", 0.03, (0, 0, 0.12), (0, 0, 0.125), ALU, p, outline=False)
    cube("PullTab", 1, (0.008, 0, 0.127), (0.02, 0.01, 0.002), ALU, p, bevel=0, outline=False)


def banana(x):
    p = prop("Banana", x)
    for i in range(6):
        a = R(-50 + i * 20)
        sphere("BananaSeg", 0.032 - abs(i - 2.5) * 0.004, (0.12 * math.sin(a), 0.12 * (1 - math.cos(a)), 0.03),
               (1, 1.4, 1), BANANA, p, rot=(0, 0, -a))
    tube("BananaStem", 0.008, (0.11, 0.06, 0.03), (0.13, 0.08, 0.035), WALNUT, p, outline=False)


def painting(x, name, blobs):
    p = prop(name, x)
    cube("Canvas", 1, (0, 0, 0.6), (1.0, 0.03, 0.7), CANVAS, p, bevel=0.003)
    for sx, sz, w, h in ((0, 0.26, 1.12, 0.06), (0, -0.26, 1.12, 0.06)):
        cube("FrameH", 1, (0, -0.01, 0.6 + sz / 0.26 * 0.38), (w, 0.07, h), GOLD, p, bevel=0.012)
    for sx in (-1, 1):
        cube("FrameV", 1, (0.53 * sx, -0.01, 0.6), (0.06, 0.07, 0.82), GOLD, p, bevel=0.012)
    for i, (bx, bz, r, col) in enumerate(blobs):
        sphere("Paint", r, (bx, -0.02, 0.6 + bz), (1, 0.05, 1), M("SmoothPlastic", f"{name}Paint{i}", col, 0.6), p,
               outline=False)


def room_sign(x):
    p = prop("RoomSign", x)
    cube("SignBack", 1, (0, 0, 0.12), (0.62, 0.03, 0.2), WALNUT, p, bevel=0.01)
    cube("SignPlate", 1, (0, -0.018, 0.12), (0.56, 0.006, 0.15), BRASS, p, bevel=0.004)
    for sx in (-1, 1):
        sphere("Screw", 0.01, (0.25 * sx, -0.024, 0.12), (1, 0.4, 1), CHROME, p, outline=False)


BUILDERS_2 = [laptop, whiteboard, coffee_machine, paper_cup, cafe_table, cafe_chair, burger, pizza_slice, donut, apple,
              sandwich, soda_can, banana, room_sign]



# ------------------------------------------------------------------ Round 3: office furniture
def printer(x):
    p = prop("Printer", x)
    cube("CopierBase", 1, (0, 0, 0.3), (0.62, 0.62, 0.52), PLASTIC_WHT, p, bevel=0.02)
    for k in range(3):  # paper drawers
        cube("Drawer", 1, (0, -0.315, 0.12 + 0.16 * k), (0.58, 0.01, 0.13), PLASTIC_GRY, p, bevel=0.006, outline=False)
        cube("DrawerHandle", 1, (0, -0.325, 0.16 + 0.16 * k), (0.22, 0.02, 0.02), DARKMETAL, p, bevel=0.004, outline=False)
    cube("CopierTop", 1, (0, 0, 0.72), (0.62, 0.55, 0.3), PLASTIC_WHT, p, bevel=0.02)
    cube("ScannerLid", 1, (0, 0.02, 0.9), (0.6, 0.5, 0.05), PLASTIC_BLK, p, bevel=0.01)
    cube("ControlPanel", 1, (0.12, -0.3, 0.86), (0.3, 0.12, 0.05), PLASTIC_BLK, p, rot=(R(25), 0, 0), bevel=0.01)
    cube("PanelScreen", 1, (0.08, -0.33, 0.885), (0.14, 0.004, 0.06), NEON_BLUE, p, rot=(R(25), 0, 0), bevel=0, outline=False)
    for k in range(4):
        sphere("PanelButton", 0.012, (0.2 + 0.03 * (k % 2), -0.33, 0.87 + 0.02 * (k // 2)), (1, 0.5, 1), NEON_GREEN, p,
               outline=False)
    cube("OutputTray", 1, (-0.38, -0.02, 0.62), (0.18, 0.4, 0.015), PLASTIC_GRY, p, rot=(0, R(10), 0), bevel=0.004)
    for i in range(5):
        cube("PrintedPage", 1, (-0.38, -0.02, 0.63 + 0.004 * i), (0.16, 0.26, 0.002), PAPER, p, rot=(0, R(10), R(rng.uniform(-6, 6))),
             bevel=0, outline=False)
    for sx in (-1, 1):
        for sy in (-1, 1):
            sphere("Caster", 0.025, (0.27 * sx, 0.27 * sy, 0.025), (1, 1, 1), RUBBER, p, outline=False)


def filing_cabinet(x):
    p = prop("FilingCabinet", x)
    cube("Cabinet", 1, (0, 0, 0.66), (0.46, 0.6, 1.32), DARKMETAL, p, bevel=0.01)
    for k in range(4):
        cube("CabDrawer", 1, (0, -0.302, 0.18 + 0.32 * k), (0.42, 0.01, 0.28), M("Metal", "Steel", (0.45, 0.46, 0.5), 0.35, 0.8), p,
             bevel=0.006, outline=False)
        cube("CabPull", 1, (0, -0.315, 0.24 + 0.32 * k), (0.14, 0.02, 0.02), CHROME, p, bevel=0.004, outline=False)
        cube("LabelSlot", 1, (0, -0.31, 0.3 + 0.32 * k), (0.08, 0.008, 0.035), PAPER, p, bevel=0, outline=False)


def bookshelf(x):
    p = prop("Bookshelf", x)
    for sx in (-1, 1):
        cube("ShelfSide", 1, (0.58 * sx, 0, 1.0), (0.04, 0.35, 2.0), WALNUT, p, bevel=0.006)
    for k in range(5):
        cube("Shelf", 1, (0, 0, 0.02 + k * 0.49), (1.16, 0.35, 0.03), WALNUT, p, bevel=0.004)
    cube("ShelfBack", 1, (0, 0.17, 1.0), (1.16, 0.02, 2.0), WALNUT, p, bevel=0)
    cols = [(0.5, 0.05, 0.05), (0.05, 0.15, 0.4), (0.1, 0.3, 0.12), (0.45, 0.3, 0.05), (0.08, 0.08, 0.08)]
    for k in range(4):
        xx = -0.53
        while xx < 0.5:
            w = rng.uniform(0.03, 0.06)
            h = rng.uniform(0.28, 0.4)
            cube("Book", 1, (xx + w / 2, 0.01, 0.035 + k * 0.49 + h / 2), (w, 0.25, h),
                 M("Leather", "Book%d" % rng.randrange(5), cols[rng.randrange(5)], 0.5), p, bevel=0.003, outline=False)
            xx += w + 0.004
    place_trophy = sphere("ShelfGlobe", 0.09, (0.3, 0.0, 2.1), (1, 1, 1), M("SmoothPlastic", "Globe", (0.2, 0.45, 0.8), 0.3), p)


def vending_machine(x):
    p = prop("VendingMachine", x)
    cube("VendBody", 1, (0, 0, 0.95), (0.9, 0.75, 1.9), M("Metal", "VendRed", (0.7, 0.05, 0.08), 0.35, 0.5), p, bevel=0.02)
    cube("VendGlass", 1, (-0.1, -0.378, 1.1), (0.6, 0.01, 1.3), GLASS, p, bevel=0, outline=False)
    for r in range(5):
        cube("VendShelf", 1, (-0.1, -0.2, 0.55 + r * 0.26), (0.58, 0.3, 0.01), CHROME, p, bevel=0, outline=False)
        for k in range(5):
            item = [(0.9, 0.7, 0.1), (0.2, 0.5, 0.9), (0.9, 0.2, 0.2), (0.3, 0.8, 0.3), (0.6, 0.3, 0.1)][(r + k) % 5]
            cube("Snack", 1, (-0.34 + k * 0.115, -0.25, 0.62 + r * 0.26), (0.08, 0.05, 0.12),
                 M("SmoothPlastic", "Snack%d" % ((r + k) % 5), item, 0.3), p, bevel=0.01, outline=False)
    cube("KeyPad", 1, (0.33, -0.38, 1.2), (0.16, 0.01, 0.3), PLASTIC_BLK, p, bevel=0.005, outline=False)
    cube("VendScreen", 1, (0.33, -0.387, 1.4), (0.14, 0.004, 0.07), NEON_GREEN, p, bevel=0, outline=False)
    cube("Hatch", 1, (-0.1, -0.38, 0.28), (0.6, 0.02, 0.18), PLASTIC_BLK, p, bevel=0.01)
    cube("VendSign", 1, (0, -0.38, 1.82), (0.8, 0.02, 0.14), NEON_BLUE, p, bevel=0.005, outline=False)


def fridge(x):
    p = prop("Fridge", x)
    cube("FridgeBody", 1, (0, 0, 0.9), (0.75, 0.7, 1.8), CHROME, p, bevel=0.03)
    cube("FridgeSplit", 1, (0, -0.352, 1.25), (0.74, 0.006, 0.01), DARKMETAL, p, bevel=0, outline=False)
    for z, h in ((1.55, 0.35), (0.75, 0.6)):
        tube("FridgeHandle", 0.012, (0.3, -0.38, z - h / 2), (0.3, -0.38, z + h / 2), DARKMETAL, p, outline=False)
    cube("WaterDispenser", 1, (-0.15, -0.355, 1.45), (0.18, 0.01, 0.26), PLASTIC_BLK, p, bevel=0.01, outline=False)
    for i, col in enumerate([(1, 0.85, 0.3), (0.3, 0.8, 1.0), (1.0, 0.4, 0.6)]):
        cube("FridgeMagnet", 1, (0.05 + i * 0.08, -0.356, 0.9 - i * 0.07), (0.05, 0.006, 0.05), M("Plastic", "Magnet%d" % i, col, 0.4),
             p, bevel=0, outline=False)


def microwave(x):
    p = prop("Microwave", x)
    cube("MWBody", 1, (0, 0, 0.16), (0.5, 0.36, 0.32), CHROME, p, bevel=0.015)
    cube("MWDoor", 1, (-0.06, -0.182, 0.16), (0.34, 0.01, 0.26), GLASS, p, bevel=0.004, outline=False)
    cube("MWPanel", 1, (0.18, -0.182, 0.16), (0.1, 0.01, 0.26), PLASTIC_BLK, p, bevel=0.004, outline=False)
    cube("MWDisplay", 1, (0.18, -0.19, 0.25), (0.07, 0.004, 0.03), NEON_GREEN, p, bevel=0, outline=False)


def cafeteria_counter(x):
    p = prop("CafeteriaCounter", x)
    cube("CounterBody", 1, (0, 0, 0.45), (3.0, 0.8, 0.9), M("Metal", "Steel", (0.45, 0.46, 0.5), 0.35, 0.8), p, bevel=0.015)
    cube("CounterTop", 1, (0, 0, 0.92), (3.1, 0.85, 0.04), MARBLE_BLK, p, bevel=0.008)
    cube("TrayRail", 1, (0, -0.52, 0.85), (3.0, 0.25, 0.03), CHROME, p, bevel=0.004)
    for sx in (-1, 1):
        tube("GuardPost", 0.012, (1.45 * sx, 0.1, 0.94), (1.45 * sx, 0.1, 1.4), CHROME, p, outline=False)
    cube("SneezeGuard", 1, (0, 0.05, 1.35), (2.95, 0.3, 0.01), GLASS, p, rot=(R(35), 0, 0), bevel=0, outline=False)
    for k, (food, col) in enumerate([("Mac", (1.0, 0.75, 0.15)), ("Salad", (0.3, 0.7, 0.2)), ("Stew", (0.5, 0.25, 0.1)),
                                     ("Rice", (0.95, 0.95, 0.9)), ("Peas", (0.4, 0.8, 0.3))]):
        cube("Pan", 1, (-1.2 + k * 0.6, 0.12, 0.93), (0.5, 0.35, 0.06), CHROME, p, bevel=0.006, outline=False)
        cube("Food" + food, 1, (-1.2 + k * 0.6, 0.12, 0.955), (0.46, 0.31, 0.02), M("SmoothPlastic", "Food" + food, col, 0.6), p,
             bevel=0.004, outline=False)
    tube("HeatLamp", 0.04, (-1.0, 0.1, 1.55), (1.0, 0.1, 1.55), M("Neon", "HeatLamp", (1.0, 0.45, 0.15), 0.3, emit=3), p,
         outline=False)


def food_tray(x):
    p = prop("FoodTray", x)
    cube("Tray", 1, (0, 0, 0.01), (0.45, 0.33, 0.02), M("Plastic", "Tray", (0.5, 0.2, 0.1), 0.4), p, bevel=0.01)
    tube("Plate", 0.11, (0.07, 0, 0.02), (0.07, 0, 0.03), CERAMIC, p)
    sphere("Mashed", 0.05, (0.05, 0.02, 0.035), (1, 1, 0.5), M("SmoothPlastic", "Mashed", (0.97, 0.95, 0.85), 0.6), p,
           outline=False)
    cube("Fork", 1, (-0.13, 0, 0.022), (0.02, 0.16, 0.004), CHROME, p, bevel=0, outline=False)
    tube("Cup", 0.035, (-0.08, 0.1, 0.02), (-0.08, 0.1, 0.12), GLASS, p)


def toilet(x):
    p = prop("Toilet", x)
    tube("ToiletBase", 0.14, (0, 0.02, 0), (0, 0.02, 0.34), CERAMIC, p, r2=0.18)
    sphere("Bowl", 0.21, (0, -0.02, 0.36), (0.85, 1.1, 0.35), CERAMIC, p)
    torus("Seat", 0.17, 0.025, (0, -0.03, 0.43), PLASTIC_WHT, p, scale=(0.85, 1.1, 1))
    cube("Tank", 1, (0, 0.22, 0.62), (0.44, 0.18, 0.4), CERAMIC, p, bevel=0.03)
    cube("TankLid", 1, (0, 0.22, 0.84), (0.46, 0.2, 0.04), CERAMIC, p, bevel=0.01)
    cube("FlushLever", 1, (-0.16, 0.12, 0.76), (0.08, 0.02, 0.02), CHROME, p, bevel=0.005, outline=False)


def vanity_sink(x):
    p = prop("VanitySink", x)
    cube("VanityCabinet", 1, (0, 0, 0.4), (1.2, 0.5, 0.8), WALNUT, p, bevel=0.01)
    cube("VanityTop", 1, (0, 0, 0.82), (1.24, 0.54, 0.04), MARBLE, p, bevel=0.006)
    sphere("Basin", 0.2, (0, -0.02, 0.84), (1.3, 1.0, 0.35), CERAMIC, p)
    tube("FaucetNeck", 0.015, (0, 0.18, 0.84), (0, 0.18, 1.0), CHROME, p, outline=False)
    tube("FaucetSpout", 0.013, (0, 0.18, 1.0), (0, 0.05, 0.98), CHROME, p, outline=False)
    cube("Mirror", 1, (0, 0.26, 1.5), (1.1, 0.02, 0.8), M("Glass", "Mirror", (0.85, 0.9, 0.95), 0.0, 1.0), p, bevel=0.01)
    cube("MirrorFrame", 1, (0, 0.27, 1.5), (1.18, 0.015, 0.88), GOLD, p, bevel=0.01, outline=False)
    tube("SoapDispenser", 0.035, (0.4, 0.1, 0.84), (0.4, 0.1, 0.99), PLASTIC_WHT, p, outline=False)


def hand_dryer(x):
    p = prop("HandDryer", x)
    cube("DryerBody", 1, (0, 0, 1.2), (0.3, 0.2, 0.36), CHROME, p, bevel=0.04)
    tube("DryerNozzle", 0.035, (0, -0.02, 1.02), (0, -0.05, 0.96), CHROME, p, outline=False)
    tube("DryerButton", 0.03, (0, -0.1, 1.2), (0, -0.11, 1.2), PLASTIC_BLK, p, outline=False)


def glass_wall(x):
    p = prop("GlassWall", x)
    cube("Pane", 1, (0, 0, 1.8), (1.2, 0.02, 3.52), GLASS, p, bevel=0, outline=False)
    for z in (0.02, 3.58):
        cube("Track", 1, (0, 0, z), (1.22, 0.08, 0.04), MULLION_M, p, bevel=0.004)
    for sx in (-1, 1):
        cube("Mullion", 1, (0.6 * sx, 0, 1.8), (0.04, 0.08, 3.6), MULLION_M, p, bevel=0.004)
    cube("FrostBand", 1, (0, -0.012, 1.2), (1.16, 0.004, 0.12), M("Glass", "Frost", (0.95, 0.95, 0.95), 0.4), p, bevel=0,
         outline=False)


MULLION_M = M("Metal", "Mullion", (0.03, 0.03, 0.035), 0.35, 0.8)
BUILDERS_3 = [printer, filing_cabinet, bookshelf, vending_machine, fridge, microwave, cafeteria_counter, food_tray, toilet,
              vanity_sink, hand_dryer, glass_wall]



# ------------------------------------------------------------------ Round 4: Wall Street, fun, weapons, hands
GREEN_GLASS = M("Glass", "BankerGreen", (0.05, 0.45, 0.15), 0.1)
LEATHER_GREEN = M("Leather", "DeskGreen", (0.05, 0.22, 0.1), 0.5)


def exec_desk(x):
    p = prop("ExecutiveDesk", x)
    cube("ExecTop", 1, (0, 0, 0.76), (2.4, 1.0, 0.06), WALNUT, p, bevel=0.015)
    cube("LeatherInlay", 1, (0, 0.05, 0.792), (1.6, 0.6, 0.004), LEATHER_GREEN, p, bevel=0, outline=False)
    cube("GoldTrim", 1, (0, -0.505, 0.76), (2.42, 0.012, 0.03), GOLD, p, bevel=0.003, outline=False)
    for sx in (-1, 1):
        cube("ExecPedestal", 1, (0.85 * sx, 0.02, 0.37), (0.62, 0.9, 0.74), WALNUT, p, bevel=0.015)
        for k in range(3):
            cube("ExecDrawer", 1, (0.85 * sx, -0.435, 0.14 + 0.22 * k), (0.56, 0.01, 0.19), WALNUT, p, bevel=0.006, outline=False)
            sphere("ExecKnob", 0.018, (0.85 * sx, -0.45, 0.14 + 0.22 * k), (1, 1, 1), GOLD, p, outline=False)
    cube("ExecModesty", 1, (0, 0.3, 0.45), (1.1, 0.03, 0.6), WALNUT, p, bevel=0.01)
    cube("Nameplate", 1, (0, -0.35, 0.83), (0.4, 0.08, 0.06), GOLD, p, rot=(R(-30), 0, 0), bevel=0.006)
    text("NameplateText", "THE CHAIRMAN", (0, -0.39, 0.84), 0.035, WALNUT, p, rot=(R(60), 0, 0), extrude=0.002)


def banker_lamp(x):
    p = prop("BankerLamp", x)
    cube("LampBase", 1, (0, 0, 0.015), (0.22, 0.14, 0.03), BRASS, p, bevel=0.008)
    tube("LampStem", 0.012, (0, 0.02, 0.03), (0, 0.02, 0.3), BRASS, p)
    tube("LampArm", 0.01, (0, 0.02, 0.3), (0, -0.04, 0.32), BRASS, p, outline=False)
    sphere("LampShade", 0.14, (0, -0.05, 0.33), (1.25, 0.55, 0.35), GREEN_GLASS, p)
    sphere("LampGlow", 0.1, (0, -0.05, 0.31), (1.1, 0.4, 0.2), M("Neon", "LampGlow", (1.0, 0.85, 0.5), 0.3, emit=5), p,
           outline=False)
    tube("PullChain", 0.003, (0.1, -0.05, 0.3), (0.1, -0.05, 0.22), BRASS, p, outline=False)


def meeting_table(x):
    p = prop("MeetingTable", x)
    cube("MTTop", 1, (0, 0, 0.76), (4.2, 1.4, 0.06), WALNUT, p, bevel=0.03)
    cube("MTGlassInset", 1, (0, 0, 0.793), (3.4, 0.7, 0.004), MARBLE_BLK, p, bevel=0, outline=False)
    for sx in (-1, 1):
        cube("MTBase", 1, (1.3 * sx, 0, 0.37), (0.35, 0.8, 0.74), DARKMETAL, p, bevel=0.02)
    cube("Speakerphone", 1, (0, 0, 0.81), (0.25, 0.25, 0.04), PLASTIC_BLK, p, rot=(0, 0, R(45)), bevel=0.02)
    tube("SpeakerLight", 0.03, (0, 0, 0.83), (0, 0, 0.834), NEON_BLUE, p, outline=False)


def column(x):
    p = prop("Column", x)
    tube("Shaft", 0.35, (0, 0, 0.2), (0, 0, 3.4), MARBLE, p)
    cube("ColumnBase", 1, (0, 0, 0.1), (0.9, 0.9, 0.2), MARBLE_BLK, p, bevel=0.01)
    cube("ColumnCap", 1, (0, 0, 3.5), (0.9, 0.9, 0.2), MARBLE_BLK, p, bevel=0.01)
    for z in (0.22, 3.38):
        torus("GoldRing", 0.36, 0.025, (0, 0, z), GOLD, p, outline=False)


def reception_desk(x):
    p = prop("ReceptionDesk", x)
    cube("RecFront", 1, (0, 0, 0.55), (3.0, 0.5, 1.1), WALNUT, p, bevel=0.02)
    cube("RecTop", 1, (0, 0.1, 1.12), (3.1, 0.75, 0.05), MARBLE, p, bevel=0.01)
    cube("RecLow", 1, (0, 0.45, 0.76), (3.0, 0.6, 0.04), MARBLE, p, bevel=0.008)
    cube("RecLogo", 1, (0, -0.26, 0.6), (1.4, 0.02, 0.28), GOLD, p, bevel=0.01)
    text("RecLogoText", "WOLF & CO.", (0, -0.28, 0.6), 0.16, WALNUT, p)


def elevator_doors(x):
    p = prop("ElevatorDoors", x)
    for sx in (-1, 1):
        cube("DoorLeaf", 1, (0.36 * sx, 0, 1.15), (0.7, 0.05, 2.3), GOLD, p, bevel=0.006)
    cube("ElevFrame", 1, (0, 0.02, 2.42), (1.7, 0.1, 0.24), MARBLE_BLK, p, bevel=0.01)
    for sx in (-1, 1):
        cube("ElevJamb", 1, (0.82 * sx, 0.02, 1.2), (0.12, 0.1, 2.4), MARBLE_BLK, p, bevel=0.01)
    cube("FloorDisplay", 1, (0, -0.04, 2.42), (0.3, 0.01, 0.12), PLASTIC_BLK, p, bevel=0, outline=False)
    text("FloorNum", "100", (0, -0.05, 2.42), 0.08, M("Neon", "FloorRed", (1.0, 0.2, 0.1), 0.3, emit=4), p, extrude=0.001)
    cube("CallPanel", 1, (1.05, -0.02, 1.1), (0.1, 0.02, 0.25), BRASS, p, bevel=0.005)
    for z in (1.05, 1.15):
        sphere("CallButton", 0.022, (1.05, -0.035, z), (1, 0.4, 1), M("Neon", "CallWhite", (1, 1, 0.9), 0.3, emit=2), p,
               outline=False)


def stapler(x):
    p = prop("Stapler", x)
    cube("StaplerBase", 1, (0, 0, 0.012), (0.05, 0.18, 0.024), PLASTIC_BLK, p, bevel=0.006)
    cube("StaplerTop", 1, (0, 0.01, 0.04), (0.05, 0.17, 0.03), M("Plastic", "StaplerRed", (0.8, 0.05, 0.05), 0.35), p,
         rot=(R(4), 0, 0), bevel=0.01)


def cardboard_box(x):
    p = prop("CardboardBox", x)
    cube("Box", 1, (0, 0, 0.2), (0.55, 0.4, 0.4), M("Cardboard", "Box", (0.72, 0.53, 0.3), 0.8), p, bevel=0.01)
    cube("Tape", 1, (0, 0, 0.401), (0.08, 0.41, 0.004), M("Plastic", "Tape", (0.8, 0.7, 0.45), 0.3), p, bevel=0, outline=False)
    text("BoxText", "PERSONAL ITEMS", (0, -0.202, 0.22), 0.04, M("SmoothPlastic", "Marker", (0.05, 0.05, 0.05), 0.6), p,
         extrude=0.001)


def coat_rack(x):
    p = prop("CoatRack", x)
    tube("RackPole", 0.025, (0, 0, 0.05), (0, 0, 1.8), WALNUT, p)
    for i in range(3):
        a = i * 2.094
        tube("RackFoot", 0.018, (0, 0, 0.1), (0.3 * math.cos(a), 0.3 * math.sin(a), 0.01), WALNUT, p)
        tube("RackHook", 0.012, (0, 0, 1.7), (0.15 * math.cos(a + 1), 0.15 * math.sin(a + 1), 1.82), BRASS, p, outline=False)
    cube("HangingCoat", 1, (0.12, 0.05, 1.35), (0.35, 0.12, 0.6), M("Fabric", "Coat", (0.12, 0.12, 0.18), 0.9), p, bevel=0.05)


def trading_screen(x):
    p = prop("TradingScreen", x)
    cube("TSFrame", 1, (0, 0, 1.8), (2.2, 0.08, 1.3), PLASTIC_BLK, p, bevel=0.02)
    cube("TSScreen", 1, (0, -0.042, 1.8), (2.08, 0.004, 1.18), M("Glass", "TradeScreen", (0.01, 0.015, 0.03), 0.05), p,
         bevel=0, outline=False)
    up, dn = M("Neon", "CandleUp", (0.15, 1.0, 0.35), 0.3, emit=3), M("Neon", "CandleDown", (1.0, 0.15, 0.2), 0.3, emit=3)
    price = 0.5
    for i in range(26):
        o = price
        cl = min(0.9, max(0.1, o + rng.uniform(-0.08, 0.1)))
        hi, lo = max(o, cl) + rng.uniform(0.01, 0.05), min(o, cl) - rng.uniform(0.01, 0.05)
        xx = -0.95 + i * 0.075
        m = up if cl >= o else dn
        cube("Wick", 1, (xx, -0.046, 1.25 + (hi + lo) / 2 * 1.1), (0.006, 0.002, (hi - lo) * 1.1), m, p, bevel=0, outline=False)
        cube("Candle", 1, (xx, -0.048, 1.25 + (o + cl) / 2 * 1.1), (0.045, 0.002, max(abs(cl - o) * 1.1, 0.01)), m, p, bevel=0,
             outline=False)
        price = cl
    text("TSLabel", "BANANA MOON MINING  BMM  +12.4%", (-0.45, -0.046, 2.3), 0.07, up, p, extrude=0.001)
    cube("WallMount", 1, (0, 0.06, 1.8), (0.4, 0.05, 0.3), DARKMETAL, p, bevel=0.01)


def world_clocks(x):
    p = prop("WorldClocks", x)
    for i, (city, hour) in enumerate((("NEW YORK", 9), ("LONDON", 14), ("TOKYO", 22))):
        cx = (i - 1) * 0.7
        tube("ClockFace", 0.25, (cx, 0.02, 2.2), (cx, -0.02, 2.2), PLASTIC_WHT, p)
        torus("ClockRim", 0.25, 0.025, (cx, -0.005, 2.2), GOLD, p, rot=(R(90), 0, 0), outline=False)
        for h in range(12):
            a = h / 12 * 2 * math.pi
            cube("Tick", 1, (cx + 0.2 * math.sin(a), -0.025, 2.2 + 0.2 * math.cos(a)), (0.012, 0.004, 0.04), PLASTIC_BLK, p,
                 rot=(0, -a, 0), bevel=0, outline=False)
        a = (hour % 12) / 12 * 2 * math.pi
        cube("HourHand", 1, (cx + 0.06 * math.sin(a), -0.03, 2.2 + 0.06 * math.cos(a)), (0.016, 0.004, 0.13), PLASTIC_BLK, p,
             rot=(0, -a, 0), bevel=0, outline=False)
        cube("MinuteHand", 1, (cx, -0.032, 2.29), (0.01, 0.004, 0.19), PLASTIC_BLK, p, bevel=0, outline=False)
        text("CityName", city, (cx, -0.02, 1.85), 0.07, GOLD, p, extrude=0.003)


def gold_bars(x):
    p = prop("GoldBars", x)
    k = 0
    for layer, n in enumerate((4, 3, 2, 1)):
        for i in range(n):
            cube("GoldBar", 1, ((i - (n - 1) / 2) * 0.2, 0, 0.045 + layer * 0.085), (0.18, 0.09, 0.08), GOLD, p, bevel=0.012)
            k += 1


def money_briefcase(x):
    p = prop("MoneyBriefcase", x)
    cube("CaseBottom", 1, (0, 0, 0.05), (0.5, 0.36, 0.1), M("Leather", "Case", (0.08, 0.05, 0.03), 0.4), p, bevel=0.012)
    cube("CaseLid", 1, (0, 0.19, 0.24), (0.5, 0.1, 0.36), M("Leather", "Case", (0.08, 0.05, 0.03), 0.4), p, rot=(R(-75), 0, 0),
         bevel=0.012)
    for sx in (-1, 1):
        cube("Latch", 1, (0.15 * sx, -0.18, 0.08), (0.05, 0.01, 0.03), GOLD, p, bevel=0.004, outline=False)
    for i in range(3):
        for j in range(2):
            cube("CaseCash", 1, (-0.15 + i * 0.15, -0.07 + j * 0.14, 0.11), (0.13, 0.12, 0.05), CASH, p, bevel=0.005)
            cube("CaseBand", 1, (-0.15 + i * 0.15, -0.07 + j * 0.14, 0.111), (0.03, 0.122, 0.052), CARDBOARD, p, bevel=0,
                 outline=False)
    tube("CaseHandle", 0.012, (-0.08, -0.19, 0.1), (0.08, -0.19, 0.1), GOLD, p, outline=False)


def vault_safe(x):
    p = prop("VaultSafe", x)
    cube("SafeBody", 1, (0, 0, 0.5), (0.8, 0.75, 1.0), DARKMETAL, p, bevel=0.03)
    cube("SafeDoor", 1, (0, -0.38, 0.5), (0.7, 0.03, 0.9), M("Metal", "SafeDoor", (0.2, 0.2, 0.22), 0.3, 0.9), p, bevel=0.015)
    tube("Dial", 0.11, (0, -0.4, 0.62), (0, -0.44, 0.62), CHROME, p)
    for i in range(3):
        a = i * 2.094
        tube("Spoke", 0.012, (0.1, -0.41, 0.35), (0.1 + 0.12 * math.cos(a), -0.45, 0.35 + 0.12 * math.sin(a)), CHROME, p,
             outline=False)
    for z in (0.15, 0.85):
        cube("SafeHinge", 1, (-0.37, -0.39, z), (0.05, 0.05, 0.12), CHROME, p, bevel=0.01, outline=False)


def trophy(x):
    p = prop("Trophy", x)
    cube("TrophyBase", 1, (0, 0, 0.06), (0.2, 0.2, 0.12), MARBLE_BLK, p, bevel=0.01)
    tube("TrophyStem", 0.02, (0, 0, 0.12), (0, 0, 0.24), GOLD, p, r2=0.035)
    sphere("TrophyCup", 0.1, (0, 0, 0.33), (1, 1, 1.1), GOLD, p)
    for sx in (-1, 1):
        torus("TrophyHandle", 0.045, 0.01, (0.11 * sx, 0, 0.34), GOLD, p, rot=(R(90), 0, 0), outline=False)
    cube("TrophyPlate", 1, (0, -0.102, 0.06), (0.12, 0.004, 0.05), BRASS, p, bevel=0, outline=False)


def gong(x):
    p = prop("Gong", x)
    for sx in (-1, 1):
        tube("GongPost", 0.04, (0.7 * sx, 0, 0), (0.7 * sx, 0, 1.9), WALNUT, p)
        cube("GongFoot", 1, (0.7 * sx, 0, 0.03), (0.15, 0.5, 0.06), WALNUT, p, bevel=0.01)
    cube("GongBeam", 1, (0, 0, 1.9), (1.6, 0.1, 0.1), WALNUT, p, bevel=0.02)
    tube("GongDisc", 0.55, (0, 0.02, 1.15), (0, -0.02, 1.15), GOLD, p)
    torus("GongRim", 0.55, 0.03, (0, 0, 1.15), GOLD, p, rot=(R(90), 0, 0), outline=False)
    for sx in (-1, 1):
        tube("GongRope", 0.006, (0.3 * sx, 0, 1.85), (0.35 * sx, 0, 1.62), M("Fabric", "Rope", (0.6, 0.1, 0.1), 0.9), p,
             outline=False)
    tube("MalletStick", 0.015, (0.55, -0.2, 0.3), (0.75, -0.25, 0.9), WALNUT, p, outline=False)
    sphere("MalletHead", 0.06, (0.75, -0.25, 0.93), (1, 1, 1), M("Fabric", "Mallet", (0.6, 0.1, 0.1), 0.9), p)


def arcade_cabinet(x):
    p = prop("ArcadeCabinet", x)
    cube("ArcBody", 1, (0, 0, 0.9), (0.7, 0.8, 1.8), M("Plastic", "ArcPurple", (0.2, 0.05, 0.35), 0.4), p, bevel=0.02)
    cube("ArcScreen", 1, (0, -0.35, 1.3), (0.55, 0.02, 0.42), M("Neon", "ArcScreen", (0.1, 0.9, 0.5), 0.3, emit=2.5), p,
         rot=(R(-12), 0, 0), bevel=0, outline=False)
    cube("ArcPanel", 1, (0, -0.47, 0.95), (0.66, 0.3, 0.05), PLASTIC_BLK, p, rot=(R(15), 0, 0), bevel=0.01)
    tube("Joystick", 0.01, (-0.15, -0.5, 0.97), (-0.15, -0.5, 1.07), CHROME, p, outline=False)
    sphere("JoyBall", 0.03, (-0.15, -0.5, 1.08), (1, 1, 1), PLASTIC_RED, p, outline=False)
    for k in range(3):
        tube("ArcButton", 0.025, (0.05 + k * 0.08, -0.5, 0.975), (0.05 + k * 0.08, -0.5, 0.99),
             M("Plastic", "ArcBtn%d" % k, [(1, 0.2, 0.2), (0.2, 0.6, 1), (1, 0.85, 0.2)][k], 0.3), p, outline=False)
    cube("Marquee", 1, (0, -0.36, 1.68), (0.66, 0.04, 0.2), M("Neon", "Marquee", (1.0, 0.8, 0.2), 0.3, emit=3), p, bevel=0.01,
         outline=False)
    text("MarqueeText", "WOLF RUN", (0, -0.385, 1.68), 0.1, PLASTIC_BLK, p, extrude=0.002)


def fish_tank(x):
    p = prop("FishTank", x)
    cube("TankStand", 1, (0, 0, 0.4), (1.6, 0.5, 0.8), WALNUT, p, bevel=0.01)
    cube("TankGlass", 1, (0, 0, 1.15), (1.55, 0.45, 0.7), GLASS, p, bevel=0.005, outline=False)
    cube("TankWater", 1, (0, 0, 1.12), (1.5, 0.4, 0.62), WATER, p, bevel=0, outline=False)
    cube("Gravel", 1, (0, 0, 0.84), (1.5, 0.4, 0.06), M("Pebble", "Gravel", (0.8, 0.7, 0.5), 0.8), p, bevel=0, outline=False)
    cube("TankLid", 1, (0, 0, 1.52), (1.58, 0.48, 0.04), PLASTIC_BLK, p, bevel=0.005)
    for i in range(6):
        fx, fz = rng.uniform(-0.6, 0.6), rng.uniform(0.95, 1.35)
        col = [(1.0, 0.5, 0.1), (0.2, 0.6, 1.0), (1.0, 0.9, 0.2)][i % 3]
        sphere("Fish", 0.05, (fx, rng.uniform(-0.1, 0.1), fz), (1.5, 0.5, 0.9), M("SmoothPlastic", "Fish%d" % (i % 3), col, 0.3), p,
               outline=False)
        cone("FishTail", 0.04, 0, 0.06, (fx - 0.09, 0, fz), M("SmoothPlastic", "Fish%d" % (i % 3), col, 0.3), p,
             rot=(0, R(90), 0), scale=(1, 0.3, 1), outline=False)
    for i in range(5):
        cone("Seaweed", 0.03, 0.005, rng.uniform(0.3, 0.5), (rng.uniform(-0.7, 0.7), 0.1, 1.05), LEAF, p, scale=(1, 0.3, 1),
             outline=False)


def pingpong(x):
    p = prop("PingPongTable", x)
    cube("PPTop", 1, (0, 0, 0.76), (2.74, 1.52, 0.04), M("Wood", "PPGreen", (0.05, 0.3, 0.15), 0.4), p, bevel=0.005)
    cube("PPLine", 1, (0, 0, 0.781), (2.74, 0.02, 0.002), PLASTIC_WHT, p, bevel=0, outline=False)
    for sx in (-1, 1):
        cube("PPLeg", 1, (1.0 * sx, 0, 0.37), (0.06, 1.3, 0.74), DARKMETAL, p, bevel=0.01)
    cube("PPNet", 1, (0, 0, 0.86), (0.01, 1.6, 0.16), M("Fabric", "Net", (0.95, 0.95, 0.95), 0.9), p, bevel=0)
    for sx in (-1, 1):
        tube("Paddle", 0.08, (0.8 * sx, 0.3, 0.785), (0.8 * sx, 0.3, 0.8), PLASTIC_RED, p)
        tube("PaddleGrip", 0.015, (0.8 * sx, 0.38, 0.79), (0.8 * sx, 0.48, 0.79), WALNUT, p, outline=False)


def smartphone(x):
    p = prop("Smartphone", x)
    cube("PhoneBody", 1, (0, 0, 0.005), (0.075, 0.15, 0.009), PLASTIC_BLK, p, bevel=0.004)
    cube("PhoneScreen", 1, (0, 0, 0.0098), (0.068, 0.14, 0.001), M("Neon", "PhoneScreen", (0.2, 0.5, 1.0), 0.3, emit=1.5), p,
         bevel=0, outline=False)


# weapons (cartoony, no injuries: knockback, stun stars and confetti)
def foam_bat(x):
    p = prop("FoamBat", x)
    tube("BatGrip", 0.02, (0, 0, 0), (0, 0, 0.25), M("Rubber", "Grip", (0.1, 0.1, 0.1), 0.8), p)
    tube("BatFoam", 0.035, (0, 0, 0.25), (0, 0, 0.85), M("Fabric", "Foam", (1.0, 0.5, 0.1), 0.9), p, r2=0.06)
    sphere("BatTip", 0.06, (0, 0, 0.85), (1, 1, 0.5), M("Fabric", "Foam", (1.0, 0.5, 0.1), 0.9), p)


def stapler_launcher(x):
    p = prop("StaplerLauncher", x)
    cube("SLBody", 1, (0, 0, 0.12), (0.1, 0.4, 0.1), PLASTIC_RED, p, bevel=0.02)
    tube("SLBarrel", 0.03, (0, -0.2, 0.14), (0, -0.4, 0.14), CHROME, p)
    cube("SLGrip", 1, (0, 0.08, 0.02), (0.06, 0.08, 0.16), PLASTIC_BLK, p, rot=(R(-15), 0, 0), bevel=0.01)
    cube("SLMagazine", 1, (0, -0.02, 0.2), (0.06, 0.22, 0.05), CHROME, p, bevel=0.008)


def confetti_cannon(x):
    p = prop("ConfettiCannon", x)
    tube("CCBarrel", 0.06, (0, 0.2, 0.1), (0, -0.35, 0.12), GOLD, p, r2=0.09)
    torus("CCMuzzle", 0.09, 0.015, (0, -0.35, 0.12), GOLD, p, rot=(R(90), 0, 0), outline=False)
    cube("CCGrip", 1, (0, 0.12, 0.0), (0.06, 0.08, 0.16), PLASTIC_BLK, p, rot=(R(-15), 0, 0), bevel=0.01)
    for i in range(10):
        cube("Confetti", 1, (rng.uniform(-0.06, 0.06), -0.38 - rng.uniform(0, 0.15), 0.12 + rng.uniform(-0.06, 0.06)),
             (0.02, 0.004, 0.02), M("SmoothPlastic", "Confetti%d" % (i % 4),
                                     [(1, 0.2, 0.3), (0.2, 0.7, 1), (1, 0.9, 0.2), (0.3, 1, 0.4)][i % 4], 0.4), p,
             rot=(rng.uniform(0, 3), rng.uniform(0, 3), 0), bevel=0, outline=False)


def rubber_chicken(x):
    p = prop("RubberChicken", x)
    yellow = M("Rubber", "Chicken", (1.0, 0.85, 0.2), 0.6)
    skin("ChickenBody", [(0, 0.0, 0.1), (0, -0.2, 0.12), (0, -0.33, 0.18)], [(0, 1), (1, 2)], [0.06, 0.05, 0.035], yellow, p)
    sphere("ChickenHead", 0.045, (0, -0.37, 0.22), (1, 1, 1), yellow, p)
    cone("Beak", 0.02, 0, 0.05, (0, -0.42, 0.22), M("Rubber", "Beak", (1.0, 0.5, 0.1), 0.6), p, rot=(R(90), 0, 0))
    cone("Comb", 0.025, 0, 0.04, (0, -0.37, 0.27), M("Rubber", "Comb", (0.9, 0.1, 0.1), 0.6), p, scale=(0.4, 1, 1))
    for sx in (-1, 1):
        tube("ChickenLeg", 0.008, (0.03 * sx, 0.05, 0.07), (0.03 * sx, 0.12, 0.0), M("Rubber", "Beak", (1.0, 0.5, 0.1), 0.6), p)
        sphere("ChickenEye", 0.008, (0.03 * sx, -0.4, 0.235), (1, 1, 1), PLASTIC_BLK, p, outline=False)


def taser(x):
    p = prop("Taser", x)
    cube("TaserBody", 1, (0, 0, 0.12), (0.08, 0.24, 0.1), M("Plastic", "TaserYellow", (1.0, 0.85, 0.1), 0.4), p, bevel=0.015)
    cube("TaserFront", 1, (0, -0.14, 0.12), (0.09, 0.06, 0.09), PLASTIC_BLK, p, bevel=0.01)
    cube("TaserGrip", 1, (0, 0.08, 0.03), (0.06, 0.08, 0.14), PLASTIC_BLK, p, rot=(R(-15), 0, 0), bevel=0.01)
    for sx in (-1, 1):
        cube("Prong", 1, (0.02 * sx, -0.18, 0.12), (0.008, 0.03, 0.008), CHROME, p, bevel=0, outline=False)
    cube("Arc", 1, (0, -0.19, 0.12), (0.05, 0.004, 0.02), NEON_BLUE, p, bevel=0, outline=False)


# first-person hand poses: fingers curl per pose (index, middle, ring, pinky, thumb)
HAND_SKIN = M("SmoothPlastic", "Skin", (0.95, 0.55, 0.32), 0.5)
SLEEVE = M("Fabric", "Sleeve", (0.1, 0.12, 0.25), 0.9)
CUFF = M("Fabric", "Cuff", (0.95, 0.95, 0.93), 0.8)
POSES = {
    "HandOpen": (0.05, 0.05, 0.05, 0.05, 0.0),
    "HandPoint": (0.0, 1.0, 1.0, 1.0, 0.8),
    "HandThumbsUp": (1.0, 1.0, 1.0, 1.0, -1.0),
    "HandFist": (1.0, 1.0, 1.0, 1.0, 0.9),
    "HandPeace": (0.0, 0.0, 1.0, 1.0, 0.9),
    "HandCallMe": (1.0, 1.0, 1.0, 0.0, -1.0),
    "HandGrab": (0.55, 0.55, 0.55, 0.55, 0.45),
}


def hand_pose(x, name, curls):
    p = prop(name, x)
    # forearm sleeve + shirt cuff, fingers point toward -Y (forward, away from the camera)
    tube("Sleeve", 0.07, (0, 0.55, 0.0), (0, 0.18, 0.0), SLEEVE, p, r2=0.065)
    tube("ShirtCuff", 0.062, (0, 0.2, 0.0), (0, 0.13, 0.0), CUFF, p)
    tube("Wrist", 0.045, (0, 0.15, 0.0), (0, 0.08, 0.0), HAND_SKIN, p, r2=0.05)
    cube("Palm", 1, (0, 0.0, 0.0), (0.12, 0.13, 0.05), HAND_SKIN, p, bevel=0.022, subsurf=1)
    lengths = (0.075, 0.082, 0.078, 0.062)
    for f, (xo, length, curl) in enumerate(zip((-0.045, -0.015, 0.015, 0.045), lengths, curls[:4])):
        pts = [(xo, -0.06, 0.0)]
        ang = 0.0
        seg = length / 3
        for s in range(3):
            ang += curl * R(75)
            last = pts[-1]
            pts.append((last[0], last[1] - seg * math.cos(ang), last[2] - seg * math.sin(ang)))
        skin("Finger%d" % f, pts, [(0, 1), (1, 2), (2, 3)], [0.016, 0.0145, 0.013, 0.012], HAND_SKIN, p, width=0.006)
    t = curls[4]
    if t < 0:  # thumb sticks straight up
        pts = [(-0.06, 0.02, 0.0), (-0.07, 0.0, 0.05), (-0.07, -0.005, 0.1)]
    else:  # thumb folds across the palm by t
        pts = [(-0.06, 0.02, 0.0), (-0.085 + 0.05 * t, -0.03, -0.01 * t), (-0.08 + 0.07 * t, -0.07 + 0.02 * t, -0.03 * t)]
    skin("Thumb", pts, [(0, 1), (1, 2)], [0.019, 0.017, 0.015], HAND_SKIN, p, width=0.006)


BUILDERS_4 = [exec_desk, banker_lamp, meeting_table, column, reception_desk, elevator_doors, stapler, cardboard_box,
              coat_rack, trading_screen, world_clocks, gold_bars, money_briefcase, vault_safe, trophy, gong, arcade_cabinet,
              fish_tank, pingpong, smartphone, foam_bat, stapler_launcher, confetti_cannon, rubber_chicken, taser]


# ---------------------------------------------------------------- round 5: flag, pool table, broken tank, lots of decor
FLAG_RED = M("Fabric", "FlagRed", (0.75, 0.05, 0.1), 0.9)
FLAG_WHITE = M("Fabric", "FlagWhite", (0.95, 0.95, 0.95), 0.9)
FLAG_BLUE = M("Fabric", "FlagBlue", (0.05, 0.08, 0.35), 0.9)
FELT = M("Fabric", "PoolFelt", (0.05, 0.4, 0.2), 0.95)
VELVET = M("Fabric", "VelvetRed", (0.45, 0.02, 0.05), 0.8)
BRONZE = M("Metal", "Bronze", (0.55, 0.35, 0.18), 0.35, 1.0)
PLASTER = M("SmoothPlastic", "Plaster", (0.93, 0.92, 0.9), 0.6)
CORK = M("Fabric", "Cork", (0.7, 0.52, 0.32), 0.9)
SHARD_GLASS = M("Glass", "Shard", (0.75, 0.88, 0.95), 0.02)
RUG_RED = M("Fabric", "RugRed", (0.5, 0.06, 0.08), 0.95)
RUG_GOLD = M("Fabric", "RugGold", (0.85, 0.6, 0.2), 0.95)
PIANO_BLK = M("SmoothPlastic", "PianoBlack", (0.01, 0.01, 0.012), 0.08)
IVORY = M("SmoothPlastic", "Keys", (0.97, 0.96, 0.92), 0.3)
LAMPSHADE = M("Fabric", "Shade", (0.95, 0.88, 0.72), 0.9, emit=0.6)
BULB = M("Neon", "Bulb", (1.0, 0.85, 0.55), 0.3, emit=5)
NEON_PINK = M("Neon", "Pink", (1.0, 0.2, 0.6), 0.3, emit=4)
NEON_GOLD = M("Neon", "Gold", (1.0, 0.75, 0.2), 0.3, emit=4)
BALL_COLS = [(1, 0.85, 0.1), (0.1, 0.2, 0.8), (0.85, 0.1, 0.1), (0.4, 0.1, 0.6), (1, 0.45, 0.05), (0.05, 0.45, 0.2),
             (0.5, 0.1, 0.05), (0.02, 0.02, 0.02)]


def american_flag(x):
    p = prop("AmericanFlag", x)
    cube("FlagBase", 1, (0, 0, 0.05), (0.45, 0.45, 0.1), BRASS, p, bevel=0.02)
    cone("FlagBaseTop", 0.18, 0.05, 0.15, (0, 0, 0.17), BRASS, p)
    tube("FlagPole", 0.022, (0, 0, 0.2), (0, 0, 2.55), WALNUT, p)
    sphere("PoleFinial", 0.05, (0, 0, 2.6), (1, 1, 1), GOLD, p)
    cone("PoleEagleWing", 0.09, 0, 0.06, (0, 0, 2.66), GOLD, p, scale=(1.6, 0.4, 1))
    # 13 stripes, each a row of segments on a sine wave so the flag ripples
    w, h, segs = 1.5, 0.95, 10
    top = 2.5
    for r in range(13):
        m = FLAG_RED if r % 2 == 0 else FLAG_WHITE
        z = top - (r + 0.5) * h / 13
        for k in range(segs):
            sx = 0.04 + (k + 0.5) * w / segs
            y = 0.06 * math.sin(sx * 4.2) * (sx / w)
            ang = math.atan(0.06 * 4.2 * math.cos(sx * 4.2) * (sx / w))
            cube("Stripe", 1, (sx, y, z), (w / segs + 0.004, 0.008, h / 13), m, p, rot=(0, 0, -ang), bevel=0,
                 outline=(k == 0 and r == 0))
    # canton with rows of stars
    cw, ch = w * 0.4, h * 7 / 13
    for k in range(4):
        sx = 0.04 + (k + 0.5) * cw / 4
        y = 0.06 * math.sin(sx * 4.2) * (sx / w) - 0.006
        cube("Canton", 1, (sx, y, top - ch / 2), (cw / 4 + 0.004, 0.008, ch), FLAG_BLUE, p, bevel=0, outline=False)
    for row in range(9):
        n = 6 if row % 2 == 0 else 5
        for c in range(n):
            sx = 0.04 + (c + (0.5 if row % 2 == 0 else 1.0)) * cw / 6
            y = 0.06 * math.sin(sx * 4.2) * (sx / w) - 0.012
            cone("Star", 0.018, 0, 0.006, (sx, y, top - 0.03 - row * (ch - 0.06) / 8), FLAG_WHITE, p,
                 rot=(R(90), 0, 0), outline=False)
    # gold fringe along the fly edge and a tasseled cord
    for k in range(14):
        z = top - k * h / 13
        cube("Fringe", 1, (0.04 + w + 0.02, 0.06 * math.sin((0.04 + w) * 4.2), z), (0.04, 0.006, 0.012), GOLD, p, bevel=0,
             outline=False)
    skin("FlagCord", [(0.03, 0, 2.45), (0.06, -0.03, 2.1), (0.05, -0.02, 1.8)], [(0, 1), (1, 2)], [0.006] * 3, GOLD, p,
         subsurf=1, outline=False)
    cone("Tassel", 0.025, 0.005, 0.1, (0.05, -0.02, 1.74), GOLD, p, outline=False)


def pool_table(x):
    p = prop("PoolTable", x)
    L, W = 2.5, 1.35
    cube("PoolBed", 1, (0, 0, 0.72), (L, W, 0.12), WALNUT, p, bevel=0.02)
    cube("PoolFelt", 1, (0, 0, 0.785), (L - 0.2, W - 0.2, 0.02), FELT, p, bevel=0, outline=False)
    for sx in (-1, 1):
        cube("RailLong", 1, (0, sx * (W / 2 - 0.05), 0.82), (L - 0.2, 0.1, 0.08), WALNUT, p, bevel=0.02)
        cube("CushionLong", 1, (0, sx * (W / 2 - 0.12), 0.81), (L - 0.3, 0.05, 0.05), FELT, p, bevel=0.01, outline=False)
        cube("RailShort", 1, (sx * (L / 2 - 0.05), 0, 0.82), (0.1, W - 0.2, 0.08), WALNUT, p, bevel=0.02)
        cube("CushionShort", 1, (sx * (L / 2 - 0.12), 0, 0.81), (0.05, W - 0.3, 0.05), FELT, p, bevel=0.01, outline=False)
    for px in (-1, 0, 1):
        for py in (-1, 1):
            loc = (px * (L / 2 - 0.1), py * (W / 2 - 0.1), 0.8)
            tube("Pocket", 0.065, loc, (loc[0], loc[1], 0.74), PLASTIC_BLK, p, outline=False)
            torus("PocketRim", 0.065, 0.012, (loc[0], loc[1], 0.86), BRASS, p, outline=False)
    for sx in (-1, 1):
        for sy in (-1, 1):
            tube("PoolLeg", 0.1, (sx * (L / 2 - 0.2), sy * (W / 2 - 0.2), 0.66), (sx * (L / 2 - 0.2), sy * (W / 2 - 0.2), 0.0),
                 WALNUT, p, r2=0.07)
            sphere("LegFoot", 0.08, (sx * (L / 2 - 0.2), sy * (W / 2 - 0.2), 0.05), (1, 1, 0.6), BRASS, p)
    # racked balls: a triangle of 15 plus the cue ball
    r = 0.028
    i = 0
    for row in range(5):
        for c in range(row + 1):
            col = BALL_COLS[i % 8]
            sphere("Ball%d" % (i + 1), r, (0.55 + row * r * 1.75, (c - row / 2) * r * 2.02, 0.795 + r),
                   (1, 1, 1), M("SmoothPlastic", "Ball%d" % (i % 8), col, 0.1), p, outline=False)
            i += 1
    sphere("CueBall", r, (-0.6, 0, 0.795 + r), (1, 1, 1), M("SmoothPlastic", "CueBall", (0.97, 0.97, 0.95), 0.1), p,
           outline=False)
    tube("Cue", 0.014, (-0.7, -0.05, 0.84), (-1.9, -0.5, 1.0), OAK, p, r2=0.007)
    tube("CueButt", 0.016, (-1.75, -0.44, 0.98), (-1.9, -0.5, 1.0), PLASTIC_BLK, p, outline=False)
    tube("Cue2", 0.014, (1.2, 0.62, 0.85), (0.1, 0.55, 0.85), OAK, p, r2=0.007)
    # hanging lamp above the table
    cube("PoolLampShade", 1, (0, 0, 1.9), (1.4, 0.35, 0.15), M("Plastic", "LampGreen", (0.05, 0.35, 0.15), 0.3), p,
         bevel=0.04)
    cube("PoolLampGlow", 1, (0, 0, 1.82), (1.3, 0.28, 0.01), BULB, p, bevel=0, outline=False)
    for sx in (-1, 1):
        tube("LampChain", 0.006, (sx * 0.5, 0, 1.98), (sx * 0.5, 0, 2.6), BRASS, p, outline=False)
    # diamond sights along the rails, chalk cubes, a scoring bead wire
    for sx in (-1, 1):
        for k in range(1, 8):
            if k == 4:
                continue
            cube("Sight", 1, (-L / 2 + 0.1 + k * (L - 0.2) / 8, sx * (W / 2 - 0.05), 0.862), (0.02, 0.02, 0.003), IVORY, p,
                 rot=(0, 0, R(45)), bevel=0, outline=False)
        for k in range(1, 4):
            cube("Sight", 1, (sx * (L / 2 - 0.05), -W / 2 + 0.1 + k * (W - 0.2) / 4, 0.862), (0.02, 0.02, 0.003), IVORY, p,
                 rot=(0, 0, R(45)), bevel=0, outline=False)
    for loc in ((1.0, -0.58), (-1.05, 0.58)):
        cube("Chalk", 1, (loc[0], loc[1], 0.88), (0.025, 0.025, 0.025), M("SmoothPlastic", "Chalk", (0.2, 0.45, 0.85), 0.8),
             p, bevel=0.003)
    tube("ScoreWire", 0.003, (-0.9, 0, 2.3), (0.9, 0, 2.3), BRASS, p, outline=False)
    for k in range(10):
        sphere("ScoreBead", 0.02, (-0.8 + k * 0.08 + (0.6 if k > 5 else 0), 0, 2.3), (1.3, 1, 1), WALNUT, p, rot=(0, R(90), 0),
               outline=False)
    cube("PoolApron", 1, (0, -W / 2 + 0.005, 0.64), (L - 0.3, 0.02, 0.1), WALNUT, p, bevel=0.01)
    cube("ApronPlate", 1, (0, -W / 2 - 0.006, 0.64), (0.3, 0.003, 0.05), BRASS, p, bevel=0, outline=False)


def fish_tank_broken(x):
    """Swap-in model when the tank breaks: shattered front, puddle, gasping fish, glass on the floor."""
    p = prop("FishTankBroken", x)
    cube("TankStand", 1, (0, 0, 0.4), (1.6, 0.5, 0.8), WALNUT, p, bevel=0.01)
    cube("Gravel", 1, (0, 0, 0.84), (1.5, 0.4, 0.06), M("Pebble", "Gravel", (0.8, 0.7, 0.5), 0.8), p, bevel=0, outline=False)
    cube("TankBack", 1, (0, 0.215, 1.15), (1.55, 0.02, 0.7), GLASS, p, bevel=0, outline=False)
    for sx in (-1, 1):
        cube("TankSide", 1, (sx * 0.765, 0, 1.15), (0.02, 0.45, 0.7), GLASS, p, bevel=0, outline=False)
    cube("WaterLeft", 1, (0, 0.05, 0.9), (1.5, 0.3, 0.06), WATER, p, bevel=0, outline=False)
    # jagged glass teeth still stuck in the frame
    for i in range(9):
        sx = -0.7 + i * 0.175
        hgt = rng.uniform(0.05, 0.3)
        cone("GlassTooth", 0.07, 0, hgt, (sx, -0.215, 0.87 + hgt / 2), SHARD_GLASS, p, scale=(1, 0.08, 1), outline=False)
    cube("TankLid", 1, (0.1, 0.1, 1.52), (1.58, 0.48, 0.04), PLASTIC_BLK, p, rot=(R(-8), 0, R(3)), bevel=0.005)
    # water puddle on the floor
    for i in range(6):
        cube("Puddle", 1, (rng.uniform(-0.8, 0.8), -0.7 - rng.uniform(0, 0.6), 0.004),
             (rng.uniform(0.5, 1.1), rng.uniform(0.4, 0.8), 0.008), WATER, p, rot=(0, 0, rng.uniform(0, 3)), bevel=0.2,
             outline=False)
    for i in range(14):
        cone("Shard", rng.uniform(0.03, 0.08), 0, 0.006, (rng.uniform(-1.0, 1.0), -0.5 - rng.uniform(0, 0.9), 0.006),
             SHARD_GLASS, p, rot=(0, 0, rng.uniform(0, 6)), scale=(1, rng.uniform(0.4, 1.0), 1), outline=False)
    for i in range(3):
        col = [(1.0, 0.5, 0.1), (0.2, 0.6, 1.0), (1.0, 0.9, 0.2)][i]
        fx, fy = rng.uniform(-0.6, 0.6), -0.6 - rng.uniform(0, 0.5)
        sphere("FloppingFish", 0.05, (fx, fy, 0.04), (1.5, 0.5, 0.9), M("SmoothPlastic", "Fish%d" % i, col, 0.3), p,
               rot=(R(80), 0, rng.uniform(0, 3)), outline=False)


def floor_lamp(x):
    p = prop("FloorLamp", x)
    cone("LampBase", 0.2, 0.16, 0.05, (0, 0, 0.025), BRASS, p)
    tube("LampPole", 0.015, (0, 0, 0.05), (0, 0, 1.55), BRASS, p)
    cone("LampShade", 0.28, 0.18, 0.35, (0, 0, 1.6), LAMPSHADE, p)
    sphere("LampBulb", 0.05, (0, 0, 1.5), (1, 1, 1.2), BULB, p, outline=False)
    torus("ShadeTrimTop", 0.18, 0.006, (0, 0, 1.775), GOLD, p, outline=False)
    torus("ShadeTrimBottom", 0.28, 0.006, (0, 0, 1.425), GOLD, p, outline=False)
    tube("PullChain", 0.003, (0.05, 0, 1.47), (0.05, 0, 1.3), BRASS, p, outline=False)
    sphere("PullBead", 0.012, (0.05, 0, 1.29), (1, 1, 1.4), BRASS, p, outline=False)
    torus("PoleCollar", 0.02, 0.006, (0, 0, 0.8), BRASS, p, outline=False)


def desk_globe(x):
    p = prop("DeskGlobe", x)
    tube("GlobeStand", 0.012, (0, 0, 0.0), (0, 0, 0.18), WALNUT, p)
    cone("GlobeFoot", 0.12, 0.05, 0.04, (0, 0, 0.02), WALNUT, p)
    sphere("Globe", 0.16, (0, 0, 0.37), (1, 1, 1), M("SmoothPlastic", "Ocean", (0.1, 0.35, 0.7), 0.3), p)
    for i in range(7):
        a, b = rng.uniform(0, 6.28), rng.uniform(-1.0, 1.0)
        sphere("Continent", 0.06, (0.15 * math.cos(a) * math.cos(b), 0.15 * math.sin(a) * math.cos(b), 0.37 + 0.15 * math.sin(b)),
               (rng.uniform(0.8, 1.6), rng.uniform(0.8, 1.6), 0.5), M("SmoothPlastic", "Land", (0.75, 0.65, 0.35), 0.5), p,
               rot=(0, math.pi / 2 - b, a), outline=False)
    torus("GlobeRing", 0.19, 0.008, (0, 0, 0.37), BRASS, p, rot=(R(90), R(23), 0))
    torus("Meridian", 0.175, 0.01, (0, 0, 0.37), BRASS, p, rot=(R(90), 0, 0), outline=False)
    torus("Equator", 0.161, 0.003, (0, 0, 0.37), M("SmoothPlastic", "Equator", (0.9, 0.2, 0.2), 0.4), p, outline=False)
    sphere("GlobePin", 0.015, (0.04, -0.14, 0.44), (1, 1, 1), PLASTIC_RED, p, outline=False)


def bar_cart(x):
    p = prop("JuiceBarCart", x)
    for z in (0.3, 0.75):
        cube("CartShelf", 1, (0, 0, z), (0.9, 0.45, 0.03), GLASS, p, bevel=0.005, outline=False)
        cube("CartRim", 1, (0, 0, z), (0.92, 0.47, 0.012), GOLD, p, bevel=0.003)
    for sx in (-1, 1):
        for sy in (-1, 1):
            tube("CartPost", 0.012, (sx * 0.44, sy * 0.21, 0.08), (sx * 0.44, sy * 0.21, 0.9), GOLD, p, outline=False)
            torus("CartWheel", 0.06, 0.018, (sx * 0.44, sy * 0.21, 0.06), RUBBER, p, rot=(R(90), 0, 0), outline=False)
    tube("CartHandle", 0.012, (-0.5, -0.2, 0.9), (-0.5, 0.2, 0.9), GOLD, p, outline=False)
    juices = [("Grape", (0.4, 0.05, 0.4)), ("Orange", (1.0, 0.5, 0.05)), ("Lime", (0.4, 0.9, 0.2)), ("Berry", (0.9, 0.1, 0.3))]
    for i, (n, col) in enumerate(juices):
        bx = -0.3 + i * 0.2
        tube("Bottle", 0.045, (bx, 0.05, 0.77), (bx, 0.05, 0.98), M("Glass", "Juice" + n, col, 0.05), p)
        tube("BottleNeck", 0.018, (bx, 0.05, 0.98), (bx, 0.05, 1.06), M("Glass", "Juice" + n, col, 0.05), p, outline=False)
        cube("BottleLabel", 1, (bx, 0.005, 0.87), (0.07, 0.004, 0.06), PAPER, p, bevel=0, outline=False)
    for i in range(3):
        tube("Glass", 0.03, (-0.2 + i * 0.12, -0.12, 0.77), (-0.2 + i * 0.12, -0.12, 0.87), GLASS, p, r2=0.035, outline=False)
    cube("IceBucket", 1, (0.2, -0.1, 0.4), (0.18, 0.18, 0.16), CHROME, p, bevel=0.04)


def neon_sign(x, name="NeonSign", body="BUY BUY BUY", m=None):
    p = prop(name, x)
    m = m or NEON_PINK
    bw = max(2.2, len(body) * 0.24 + 0.3)
    cube("NeonBacker", 1, (0, 0.03, 2.0), (bw, 0.03, 0.6), M("Glass", "Backer", (0.05, 0.05, 0.07), 0.1), p, bevel=0.01,
         outline=False)
    text("NeonText", body, (0, 0.0, 2.0), 0.35, m, p, extrude=0.02)
    for sx in (-1, 1):
        tube("NeonStandoff", 0.01, (sx * (bw / 2 - 0.15), 0.05, 2.0), (sx * (bw / 2 - 0.15), 0.12, 2.0), CHROME, p, outline=False)


def chandelier(x):
    p = prop("Chandelier", x)
    tube("ChanChain", 0.01, (0, 0, 3.0), (0, 0, 2.3), GOLD, p, outline=False)
    sphere("ChanHub", 0.1, (0, 0, 2.25), (1, 1, 1.3), GOLD, p)
    torus("ChanRing", 0.5, 0.02, (0, 0, 2.05), GOLD, p)
    torus("ChanRingSmall", 0.28, 0.015, (0, 0, 2.2), GOLD, p)
    for i in range(8):
        a = i * math.pi / 4
        cx, cy = 0.5 * math.cos(a), 0.5 * math.sin(a)
        tube("ChanArm", 0.012, (0, 0, 2.2), (cx, cy, 2.05), GOLD, p, outline=False)
        tube("Candle", 0.02, (cx, cy, 2.05), (cx, cy, 2.17), PLASTIC_WHT, p, outline=False)
        sphere("Flame", 0.02, (cx, cy, 2.2), (1, 1, 1.8), BULB, p, outline=False)
        for k in range(3):
            sphere("Crystal", 0.018, (cx * (0.4 + k * 0.25), cy * (0.4 + k * 0.25), 1.95 - k * 0.04), (1, 1, 1.6), GLASS, p,
                   outline=False)
    for i in range(16):
        a = i * math.pi / 8
        tube("CrystalDrop", 0.003, (0.5 * math.cos(a), 0.5 * math.sin(a), 2.03), (0.5 * math.cos(a), 0.5 * math.sin(a), 1.92),
             GLASS, p, outline=False)
        sphere("Prism", 0.02, (0.5 * math.cos(a), 0.5 * math.sin(a), 1.9), (1, 1, 1.8), GLASS, p, outline=False)
    cone("CeilingCanopy", 0.12, 0.06, 0.05, (0, 0, 2.98), GOLD, p)


def rug(x):
    p = prop("PersianRug", x)
    cube("RugBase", 1, (0, 0, 0.006), (3.0, 2.0, 0.012), RUG_RED, p, bevel=0.003, outline=False)
    for w, h in ((2.8, 1.8), (2.5, 1.5)):
        for sx in (-1, 1):
            cube("RugBorder", 1, (0, sx * h / 2, 0.013), (w, 0.05, 0.002), RUG_GOLD, p, bevel=0, outline=False)
            cube("RugBorder", 1, (sx * w / 2, 0, 0.013), (0.05, h, 0.002), RUG_GOLD, p, bevel=0, outline=False)
    cube("RugMedallion", 1, (0, 0, 0.013), (0.6, 0.6, 0.002), RUG_GOLD, p, rot=(0, 0, R(45)), bevel=0, outline=False)
    cube("RugMedallionIn", 1, (0, 0, 0.015), (0.35, 0.35, 0.002), FLAG_BLUE, p, rot=(0, 0, R(45)), bevel=0, outline=False)
    for sx in (-1, 1):
        for i in range(24):
            cube("Fringe", 1, (sx * 1.53, -0.95 + i * 1.9 / 23, 0.004), (0.06, 0.012, 0.004), FABRIC_CREAM, p, bevel=0,
                 outline=False)


def marble_bust(x):
    p = prop("MarbleBust", x)
    cube("Pedestal", 1, (0, 0, 0.55), (0.45, 0.45, 1.1), MARBLE_BLK, p, bevel=0.02)
    cube("PedestalCap", 1, (0, 0, 1.12), (0.52, 0.52, 0.05), MARBLE_BLK, p, bevel=0.01)
    skin("BustChest", [(0, 0, 1.15), (0, 0, 1.35), (-0.18, 0, 1.36), (0.18, 0, 1.36)], [(0, 1), (1, 2), (1, 3)],
         [0.14, 0.12, 0.09, 0.09], MARBLE, p)
    tube("BustNeck", 0.06, (0, 0, 1.38), (0, 0, 1.5), MARBLE, p)
    sphere("BustHead", 0.13, (0, 0, 1.6), (0.85, 0.95, 1.1), MARBLE, p)
    cone("BustNose", 0.025, 0, 0.06, (0, -0.13, 1.6), MARBLE, p, rot=(R(90), 0, 0))
    for i in range(10):
        a = -0.4 + i * 0.35
        sphere("Curl", 0.035, (0.11 * math.sin(a), 0.11 * math.cos(a) * 0.3, 1.7 + 0.02 * math.cos(a * 3)), (1, 1, 1), MARBLE,
               p, outline=False)
    torus("LaurelWreath", 0.12, 0.012, (0, 0.01, 1.68), GOLD, p, scale=(0.9, 1, 0.5), outline=False)


def wall_tv(x):
    p = prop("WallTV", x)
    cube("TVFrame", 1, (0, 0, 1.9), (2.0, 0.07, 1.15), PLASTIC_BLK, p, bevel=0.015)
    cube("TVScreen", 1, (0, -0.037, 1.9), (1.9, 0.003, 1.05), M("Glass", "NewsScreen", (0.02, 0.04, 0.12), 0.05), p, bevel=0,
         outline=False)
    cube("NewsBanner", 1, (0, -0.04, 1.5), (1.9, 0.003, 0.18), M("Neon", "NewsRed", (0.8, 0.05, 0.1), 0.3, emit=2), p, bevel=0,
         outline=False)
    text("NewsText", "BREAKING: NUMBER GO UP", (0, -0.043, 1.5), 0.09, PLASTIC_WHT, p, extrude=0.001)
    cube("Anchor", 1, (-0.45, -0.04, 1.95), (0.35, 0.003, 0.5), M("SmoothPlastic", "AnchorSuit", (0.1, 0.1, 0.2), 0.5), p,
         bevel=0, outline=False)
    sphere("AnchorHead", 0.1, (-0.45, -0.045, 2.28), (1, 0.1, 1.2), HAND_SKIN, p, outline=False)
    pts = [(0.1 + i * 0.07, -0.042, 1.75 + 0.35 * (0.2 + 0.8 * i / 11) + rng.uniform(-0.05, 0.05)) for i in range(12)]
    for a, b in zip(pts, pts[1:]):
        tube("ChartLine", 0.008, a, b, NEON_GREEN, p, outline=False)


def motivational_poster(x, name="PosterHustle", word="HUSTLE", sub="THE PHONE WON'T CALL ITSELF", col=(0.1, 0.1, 0.12)):
    p = prop(name, x)
    cube("PosterFrame", 1, (0, 0.02, 1.7), (0.9, 0.04, 1.2), PLASTIC_BLK, p, bevel=0.01)
    cube("PosterPrint", 1, (0, -0.001, 1.75), (0.8, 0.004, 0.85), M("SmoothPlastic", "Poster" + word.title(), col, 0.6), p,
         bevel=0, outline=False)
    # a lone mountain peak with a sunrise
    # a diamond whose lower half hides behind the ground strip reads as a mountain peak
    cube("Mountain", 1, (-0.05, -0.004, 1.45), (0.4, 0.004, 0.4), M("SmoothPlastic", "PosterMtn", (0.25, 0.3, 0.45), 0.6), p,
         rot=(0, R(45), 0), bevel=0, outline=False)
    cube("Mountain2", 1, (0.2, -0.003, 1.42), (0.28, 0.004, 0.28), M("SmoothPlastic", "PosterMtn2", (0.35, 0.4, 0.55), 0.6),
         p, rot=(0, R(45), 0), bevel=0, outline=False)
    cube("SnowCap", 1, (-0.05, -0.005, 1.66), (0.1, 0.004, 0.1), PLASTIC_WHT, p, rot=(0, R(45), 0), bevel=0, outline=False)
    cube("PosterGround", 1, (0, -0.006, 1.3), (0.8, 0.004, 0.3), M("SmoothPlastic", "PosterGround", (0.08, 0.08, 0.1), 0.6),
         p, bevel=0, outline=False)
    sphere("Sun", 0.1, (0.18, -0.002, 1.95), (1, 0.05, 1), NEON_GOLD, p, outline=False)
    text("PosterWord", word, (0, -0.009, 1.25), 0.1, PLASTIC_WHT, p, extrude=0.001)
    text("PosterSub", sub, (0, -0.009, 1.2), 0.03, PLASTIC_WHT, p, extrude=0.001)


def bonsai(x):
    p = prop("Bonsai", x)
    cube("BonsaiPot", 1, (0, 0, 0.04), (0.35, 0.22, 0.08), M("Ceramic", "BonsaiBlue", (0.1, 0.25, 0.5), 0.2), p, bevel=0.015)
    cube("BonsaiMoss", 1, (0, 0, 0.085), (0.32, 0.19, 0.01), LEAF, p, bevel=0, outline=False)
    skin("BonsaiTrunk", [(0, 0, 0.08), (0.04, 0, 0.18), (-0.03, 0, 0.26), (0.08, 0, 0.3), (-0.1, 0, 0.3)],
         [(0, 1), (1, 2), (2, 3), (2, 4)], [0.03, 0.025, 0.02, 0.012, 0.012], WALNUT, p)
    for loc, s in (((0.1, 0, 0.33), 0.08), ((-0.12, 0, 0.33), 0.07), ((-0.02, 0, 0.36), 0.09)):
        sphere("BonsaiCanopy", s, loc, (1.4, 1, 0.6), LEAF, p)
    for loc in ((0.12, -0.05), (-0.1, 0.04)):
        sphere("Pebble", 0.018, (loc[0], loc[1], 0.092), (1.3, 1, 0.6), M("Pebble", "Stone", (0.6, 0.6, 0.62), 0.8), p,
               outline=False)
    cube("BonsaiTray", 1, (0, 0, 0.005), (0.42, 0.28, 0.01), WALNUT, p, bevel=0.003)


def orchid(x):
    p = prop("Orchid", x)
    cone("OrchidPot", 0.07, 0.09, 0.15, (0, 0, 0.075), CERAMIC, p)
    for i in range(3):
        sphere("OrchidLeaf", 0.09, (0.05 * math.cos(i * 2.1), 0.05 * math.sin(i * 2.1), 0.17), (1.4, 0.5, 0.15), LEAF, p,
               rot=(0, 0, i * 2.1), outline=False)
    pts = [(0, 0, 0.15), (0.02, 0, 0.4), (0.1, 0, 0.55), (0.2, 0, 0.55)]
    skin("OrchidStem", pts, [(0, 1), (1, 2), (2, 3)], [0.006] * 4, M("Plastic", "Stem", (0.2, 0.35, 0.15), 0.5), p, subsurf=1,
         outline=False)
    for i in range(5):
        t = i / 4
        fx, fz = 0.05 + t * 0.15, 0.5 + 0.05 * math.sin(t * 3)
        for k in range(5):
            a = k * 1.256
            sphere("Petal", 0.025, (fx + 0.02 * math.cos(a), -0.02, fz + 0.02 * math.sin(a)), (1, 0.3, 0.7),
                   M("SmoothPlastic", "OrchidPink", (1.0, 0.6, 0.85), 0.4), p, rot=(0, -a, 0), outline=False)


def bamboo_planter(x):
    p = prop("BambooPlanter", x)
    cube("BambooBox", 1, (0, 0, 0.3), (1.2, 0.35, 0.6), MARBLE_BLK, p, bevel=0.02)
    cube("BambooSoil", 1, (0, 0, 0.58), (1.12, 0.3, 0.02), SOIL, p, bevel=0, outline=False)
    stalk = M("Plastic", "Bamboo", (0.45, 0.6, 0.2), 0.4)
    for i in range(7):
        bx = -0.5 + i / 6
        h = rng.uniform(1.6, 2.3)
        tube("BambooStalk", 0.025, (bx, 0, 0.6), (bx + rng.uniform(-0.05, 0.05), 0, 0.6 + h), stalk, p)
        for k in range(1, 5):
            torus("BambooNode", 0.026, 0.006, (bx, 0, 0.6 + k * h / 5), stalk, p, outline=False)
        leaves(p, (bx, 0, 0.6 + h), 5, 0.15, 0.08, LEAF)


def hanging_plant(x):
    p = prop("HangingPlant", x)
    for i in range(3):
        a = i * 2.1
        tube("Hanger", 0.004, (0.12 * math.cos(a), 0.12 * math.sin(a), 1.95), (0, 0, 2.4), FABRIC_CREAM, p, outline=False)
    cone("HangPot", 0.14, 0.1, 0.15, (0, 0, 1.9), TERRACOTTA, p)
    sphere("HangPotSoil", 0.13, (0, 0, 1.97), (1, 1, 0.15), SOIL, p, outline=False)
    for i in range(9):
        a = i * 0.7
        pts = [(0.1 * math.cos(a), 0.1 * math.sin(a), 1.96)]
        for k in range(4):
            last = pts[-1]
            pts.append((last[0] * 1.3, last[1] * 1.3, last[2] - rng.uniform(0.1, 0.18)))
        skin("Vine", pts, [(j, j + 1) for j in range(4)], [0.006] * 5, M("Plastic", "Vine", (0.15, 0.4, 0.1), 0.5), p, subsurf=1,
             outline=False)
        for pt in pts[1:]:
            sphere("VineLeaf", 0.03, pt, (1.2, 0.3, 0.8), LEAF, p, rot=(0, 0, a), outline=False)


def punching_bag(x):
    p = prop("PunchingBag", x)
    tube("BagChain", 0.008, (0, 0, 2.1), (0, 0, 1.75), CHROME, p, outline=False)
    tube("Bag", 0.2, (0, 0, 1.75), (0, 0, 0.75), M("Leather", "BagRed", (0.7, 0.05, 0.05), 0.4), p)
    sphere("BagTop", 0.2, (0, 0, 1.75), (1, 1, 0.3), M("Leather", "BagRed", (0.7, 0.05, 0.05), 0.4), p, outline=False)
    sphere("BagBottom", 0.2, (0, 0, 0.75), (1, 1, 0.3), M("Leather", "BagRed", (0.7, 0.05, 0.05), 0.4), p, outline=False)
    torus("BagBand", 0.205, 0.015, (0, 0, 1.25), LEATHER, p, outline=False)
    text("BagText", "THE MARKET", (0, -0.205, 1.4), 0.06, PLASTIC_WHT, p, extrude=0.002)


def massage_chair(x):
    p = prop("MassageChair", x)
    cube("MCBase", 1, (0, 0, 0.2), (0.8, 0.9, 0.4), PLASTIC_BLK, p, bevel=0.08)
    cube("MCSeat", 1, (0, -0.05, 0.47), (0.6, 0.65, 0.14), LEATHER_BROWN, p, bevel=0.05, subsurf=1)
    cube("MCBack", 1, (0, 0.35, 0.95), (0.62, 0.22, 0.95), LEATHER_BROWN, p, rot=(R(-12), 0, 0), bevel=0.08, subsurf=1)
    for sx in (-1, 1):
        cube("MCArm", 1, (sx * 0.38, -0.05, 0.6), (0.14, 0.8, 0.35), PLASTIC_BLK, p, bevel=0.06)
    cube("MCFootrest", 1, (0, -0.55, 0.22), (0.5, 0.3, 0.35), PLASTIC_BLK, p, rot=(R(20), 0, 0), bevel=0.06)
    cube("MCRemote", 1, (0.38, -0.3, 0.8), (0.06, 0.15, 0.02), PLASTIC_WHT, p, bevel=0.008)
    for sx in (-1, 1):
        for k in range(4):
            sphere("RollerBump", 0.045, (sx * 0.12, 0.25 - k * 0.02, 0.65 + k * 0.17), (1, 0.6, 1), LEATHER_BROWN, p,
                   outline=False)
        cube("ArmPanel", 1, (sx * 0.38, -0.2, 0.78), (0.1, 0.25, 0.005), PLASTIC_GRY, p, bevel=0, outline=False)
    for k in range(4):
        cube("PanelButton", 1, (0.36 + (k % 2) * 0.04, -0.28 + (k // 2) * 0.05, 0.785), (0.025, 0.025, 0.01),
             [NEON_BLUE, NEON_GREEN, NEON_PINK, NEON_GOLD][k], p, bevel=0, outline=False)
    sphere("HeadPillow", 0.14, (0, 0.33, 1.4), (1.3, 0.5, 0.6), LEATHER, p)


def bean_bag(x):
    p = prop("BeanBag", x)
    bean = M("Fabric", "BeanGold", (0.9, 0.62, 0.15), 0.9)
    # slumped teardrop: fat bottom, a raised backrest and a seat dent
    sphere("BeanBag", 0.5, (0, 0, 0.3), (1, 1.05, 0.6), bean, p)
    sphere("BeanBack", 0.38, (0, 0.2, 0.6), (1, 0.7, 0.9), bean, p)
    sphere("BeanSeat", 0.3, (0, -0.15, 0.5), (1, 0.9, 0.35), M("Fabric", "BeanSeam", (0.7, 0.45, 0.1), 0.9), p,
           outline=False)
    for k in range(6):
        a = k * math.pi / 3
        tube("BeanSeam", 0.006, (0.5 * math.cos(a) * 0.98, 0.52 * math.sin(a) * 0.98, 0.3), (0.12 * math.cos(a), 0.12 * math.sin(a), 0.55),
             M("Fabric", "BeanSeam", (0.7, 0.45, 0.1), 0.9), p, outline=False)
    sphere("BeanPatch", 0.08, (0, -0.48, 0.35), (1, 0.15, 1), GOLD, p, outline=False)
    text("BeanLogo", "W", (0, -0.5, 0.35), 0.08, PLASTIC_BLK, p, extrude=0.003)


def grand_piano(x):
    p = prop("GrandPiano", x)
    # body: a rounded wing shape from stacked boxes
    for i, (w, off) in enumerate(((1.5, 0.0), (1.4, 0.35), (1.2, 0.7), (0.9, 1.0), (0.55, 1.25))):
        cube("PianoBody", 1, (-(1.5 - w) / 2, off + 0.2, 0.85), (w, 0.4, 0.3), PIANO_BLK, p, bevel=0.03, outline=(i == 0))
    cube("PianoLid", 1, (0, 0.8, 1.35), (1.45, 1.4, 0.02), PIANO_BLK, p, rot=(R(-30), 0, 0), bevel=0.01)
    tube("LidProp", 0.01, (0.5, 0.6, 1.0), (0.5, 0.5, 1.55), BRASS, p, outline=False)
    cube("KeyBed", 1, (0, -0.1, 0.8), (1.5, 0.25, 0.1), PIANO_BLK, p, bevel=0.01)
    cube("WhiteKeys", 1, (0, -0.12, 0.86), (1.35, 0.18, 0.025), IVORY, p, bevel=0.003, outline=False)
    for i in range(36):
        if i % 7 in (2, 6):
            continue
        cube("BlackKey", 1, (-0.66 + i * 1.35 / 36 + 0.018, -0.08, 0.885), (0.018, 0.1, 0.025), PIANO_BLK, p, bevel=0.002,
             outline=False)
    for loc in ((-0.65, 0.05), (0.65, 0.05), (-0.3, 1.4)):
        tube("PianoLeg", 0.06, (loc[0], loc[1], 0.72), (loc[0], loc[1], 0.05), PIANO_BLK, p, r2=0.045)
        sphere("PianoCaster", 0.04, (loc[0], loc[1], 0.04), (1, 1, 1), BRASS, p, outline=False)
    cube("PianoBench", 1, (0, -0.65, 0.48), (0.9, 0.35, 0.08), LEATHER, p, bevel=0.03)
    for sx in (-1, 1):
        cube("BenchLeg", 1, (sx * 0.38, -0.65, 0.22), (0.05, 0.3, 0.44), PIANO_BLK, p, bevel=0.01)
    cube("MusicStand", 1, (0, 0.05, 1.0), (0.7, 0.02, 0.25), PIANO_BLK, p, rot=(R(-15), 0, 0), bevel=0.005)
    cube("SheetMusic", 1, (0, 0.035, 1.02), (0.5, 0.004, 0.2), PAPER, p, rot=(R(-15), 0, 0), bevel=0, outline=False)
    for k in range(5):
        cube("Staff", 1, (0, 0.03, 0.97 + k * 0.02), (0.44, 0.002, 0.003), PLASTIC_BLK, p, rot=(R(-15), 0, 0), bevel=0,
             outline=False)
    cube("PedalBox", 1, (0, 0.25, 0.1), (0.25, 0.08, 0.2), PIANO_BLK, p, bevel=0.01)
    for k in (-1, 0, 1):
        cube("Pedal", 1, (k * 0.06, 0.17, 0.04), (0.03, 0.12, 0.01), BRASS, p, bevel=0.003, outline=False)
    candel = M("Neon", "PianoCandle", (1.0, 0.85, 0.55), 0.3, emit=4)
    tube("Candelabra", 0.012, (0.55, 0.7, 1.0), (0.55, 0.7, 1.2), GOLD, p, outline=False)
    for k in (-1, 0, 1):
        tube("PianoCandleStick", 0.012, (0.55 + k * 0.07, 0.7, 1.2), (0.55 + k * 0.07, 0.7, 1.3), PLASTIC_WHT, p, outline=False)
        sphere("PianoFlame", 0.012, (0.55 + k * 0.07, 0.7, 1.32), (1, 1, 1.8), candel, p, outline=False)


def model_yacht(x):
    p = prop("ModelYacht", x)
    cube("YachtStand", 1, (0, 0, 0.03), (0.6, 0.15, 0.06), WALNUT, p, bevel=0.01)
    for sx in (-1, 1):
        tube("YachtPost", 0.008, (sx * 0.15, 0, 0.06), (sx * 0.15, 0, 0.14), BRASS, p, outline=False)
    skin("YachtHull", [(-0.3, 0, 0.18), (0, 0, 0.17), (0.33, 0, 0.2)], [(0, 1), (1, 2)],
         [(0.06, 0.05), (0.08, 0.06), (0.01, 0.02)], PLASTIC_WHT, p, subsurf=2)
    cube("YachtDeck", 1, (-0.02, 0, 0.25), (0.35, 0.1, 0.06), PLASTIC_WHT, p, bevel=0.02)
    cube("YachtWindows", 1, (-0.02, -0.052, 0.255), (0.3, 0.004, 0.025), SCREEN, p, bevel=0, outline=False)
    cube("YachtFlybridge", 1, (-0.05, 0, 0.3), (0.18, 0.08, 0.04), PLASTIC_WHT, p, bevel=0.015)
    cube("YachtPlaque", 1, (0, -0.076, 0.03), (0.2, 0.003, 0.035), BRASS, p, bevel=0, outline=False)


def money_counter(x):
    p = prop("MoneyCounter", x)
    cube("MCounterBody", 1, (0, 0, 0.12), (0.3, 0.28, 0.24), PLASTIC_GRY, p, bevel=0.03)
    cube("MCounterHopper", 1, (0, 0.06, 0.26), (0.18, 0.1, 0.06), PLASTIC_BLK, p, rot=(R(-25), 0, 0), bevel=0.01)
    cube("MCounterBills", 1, (0, 0.08, 0.3), (0.16, 0.07, 0.04), CASH, p, rot=(R(-25), 0, 0), bevel=0.005, outline=False)
    cube("MCounterTray", 1, (0, -0.15, 0.04), (0.2, 0.08, 0.04), PLASTIC_BLK, p, bevel=0.01)
    cube("MCounterOut", 1, (0, -0.15, 0.07), (0.16, 0.07, 0.03), CASH, p, bevel=0.003, outline=False)
    cube("MCounterDisplay", 1, (0, -0.141, 0.19), (0.16, 0.004, 0.05), NEON_GREEN, p, bevel=0, outline=False)
    for k in range(3):
        cube("MCButton", 1, (-0.08 + k * 0.08, -0.141, 0.1), (0.04, 0.006, 0.025), [NEON_GREEN, PLASTIC_RED, PLASTIC_WHT][k],
             p, bevel=0.003, outline=False)
    for k in range(5):
        cube("FlyingBill", 1, (rng.uniform(-0.2, 0.2), -0.25 - k * 0.05, 0.12 + k * 0.06), (0.08, 0.035, 0.002), CASH, p,
             rot=(rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(0, 3)), bevel=0, outline=False)


def shredder(x):
    p = prop("Shredder", x)
    cube("ShredBin", 1, (0, 0, 0.3), (0.4, 0.3, 0.6), PLASTIC_BLK, p, bevel=0.03)
    cube("ShredWindow", 1, (0, -0.152, 0.3), (0.25, 0.004, 0.3), M("Glass", "Smoke", (0.2, 0.2, 0.22), 0.1), p, bevel=0,
         outline=False)
    for i in range(12):
        cube("ShredStrip", 1, (rng.uniform(-0.1, 0.1), -0.145, rng.uniform(0.18, 0.4)), (0.006, 0.002, 0.08), PAPER, p,
             rot=(0, rng.uniform(-0.6, 0.6), 0), bevel=0, outline=False)
    cube("ShredHead", 1, (0, 0, 0.64), (0.42, 0.32, 0.08), PLASTIC_GRY, p, bevel=0.02)
    cube("ShredSlot", 1, (0, 0, 0.681), (0.3, 0.02, 0.004), PLASTIC_BLK, p, bevel=0, outline=False)
    cube("ShredPaper", 1, (0, 0, 0.75), (0.21, 0.004, 0.14), PAPER, p, bevel=0, outline=False)


def fire_extinguisher(x):
    p = prop("FireExtinguisher", x)
    red = M("Plastic", "ExtRed", (0.85, 0.05, 0.05), 0.25)
    tube("ExtTank", 0.08, (0, 0, 0.02), (0, 0, 0.5), red, p)
    sphere("ExtTop", 0.08, (0, 0, 0.5), (1, 1, 0.5), red, p, outline=False)
    tube("ExtValve", 0.025, (0, 0, 0.53), (0, 0, 0.6), CHROME, p)
    cube("ExtHandle", 1, (0, 0.03, 0.62), (0.03, 0.12, 0.015), PLASTIC_BLK, p, bevel=0.004)
    skin("ExtHose", [(0, -0.02, 0.58), (0, -0.1, 0.5), (0, -0.1, 0.25)], [(0, 1), (1, 2)], [0.012] * 3, RUBBER, p, subsurf=1)
    cube("ExtLabel", 1, (0, -0.081, 0.3), (0.1, 0.004, 0.14), PLASTIC_WHT, p, bevel=0, outline=False)


def exit_sign(x):
    p = prop("ExitSign", x)
    cube("ExitBox", 1, (0, 0, 2.6), (0.6, 0.08, 0.25), PLASTIC_WHT, p, bevel=0.01)
    text("ExitText", "EXIT", (0, -0.042, 2.6), 0.15, M("Neon", "ExitRed", (1, 0.1, 0.1), 0.3, emit=4), p, extrude=0.003)
    cone("ExitArrow", 0.04, 0, 0.06, (0.22, -0.042, 2.6), M("Neon", "ExitRed", (1, 0.1, 0.1), 0.3, emit=4), p,
         rot=(0, R(90), 0), scale=(1, 0.2, 1), outline=False)


def wall_clock(x):
    p = prop("WallClock", x)
    tube("ClockRim", 0.25, (0, 0.03, 2.2), (0, -0.03, 2.2), GOLD, p)
    tube("ClockFace", 0.22, (0, -0.031, 2.2), (0, -0.035, 2.2), PLASTIC_WHT, p, outline=False)
    for i in range(12):
        a = i * math.pi / 6
        cube("Tick", 1, (0.19 * math.sin(a), -0.037, 2.2 + 0.19 * math.cos(a)), (0.012, 0.003, 0.035), PLASTIC_BLK, p,
             rot=(0, a, 0), bevel=0, outline=False)
    cube("HourHand", 1, (0.04, -0.04, 2.24), (0.012, 0.003, 0.1), PLASTIC_BLK, p, rot=(0, R(40), 0), bevel=0, outline=False)
    cube("MinuteHand", 1, (-0.03, -0.042, 2.27), (0.008, 0.003, 0.15), PLASTIC_BLK, p, rot=(0, R(-25), 0), bevel=0,
         outline=False)
    cube("SecondHand", 1, (0.0, -0.044, 2.13), (0.004, 0.003, 0.15), PLASTIC_RED, p, rot=(0, R(170), 0), bevel=0, outline=False)


def mail_cart(x):
    p = prop("MailCart", x)
    cube("MailBin", 1, (0, 0, 0.65), (0.8, 0.5, 0.45), CANVAS, p, bevel=0.03)
    for sx in (-1, 1):
        for sy in (-1, 1):
            tube("MailPost", 0.015, (sx * 0.38, sy * 0.23, 0.9), (sx * 0.38, sy * 0.23, 0.12), CHROME, p, outline=False)
            torus("MailWheel", 0.05, 0.02, (sx * 0.38, sy * 0.23, 0.06), RUBBER, p, rot=(R(90), 0, 0), outline=False)
    for i in range(8):
        cube("Envelope", 1, (rng.uniform(-0.3, 0.3), rng.uniform(-0.15, 0.15), 0.9 + i * 0.01), (0.22, 0.12, 0.005),
             M("SmoothPlastic", "Envelope", (0.95, 0.9, 0.75), 0.6), p, rot=(rng.uniform(-0.3, 0.3), 0, rng.uniform(0, 3)),
             bevel=0, outline=False)
    cube("Parcel", 1, (0.15, 0.05, 0.98), (0.25, 0.2, 0.15), CARDBOARD, p, bevel=0.01)


def cork_board(x):
    p = prop("CorkBoard", x)
    cube("CorkFrame", 1, (0, 0.02, 1.6), (1.4, 0.04, 0.9), OAK, p, bevel=0.01)
    cube("Cork", 1, (0, -0.001, 1.6), (1.3, 0.004, 0.8), CORK, p, bevel=0, outline=False)
    notes = [(1.0, 0.95, 0.4), (1.0, 0.6, 0.8), (0.5, 0.9, 1.0), (0.6, 1.0, 0.5)]
    pts = []
    for i in range(10):
        nx, nz = rng.uniform(-0.55, 0.55), rng.uniform(1.28, 1.92)
        pts.append((nx, nz))
        cube("Note", 1, (nx, -0.005, nz), (0.14, 0.003, 0.14), M("SmoothPlastic", "Sticky%d" % (i % 4), notes[i % 4], 0.6), p,
             rot=(0, rng.uniform(-0.2, 0.2), 0), bevel=0, outline=False)
        sphere("Pin", 0.012, (nx, -0.012, nz + 0.05), (1, 1, 1), PLASTIC_RED, p, outline=False)
    # the classic red-string conspiracy web between the notes
    for a, b in zip(pts, pts[3:] + pts[:3]):
        tube("RedString", 0.002, (a[0], -0.013, a[1] + 0.05), (b[0], -0.013, b[1] + 0.05), PLASTIC_RED, p, outline=False)


def podium(x):
    p = prop("Podium", x)
    cube("PodiumBody", 1, (0, 0, 0.55), (0.7, 0.5, 1.1), WALNUT, p, bevel=0.02)
    cube("PodiumTop", 1, (0, -0.05, 1.13), (0.8, 0.6, 0.05), WALNUT, p, rot=(R(12), 0, 0), bevel=0.01)
    tube("PodiumMicArm", 0.006, (0, 0.1, 1.15), (0, -0.2, 1.4), DARKMETAL, p, outline=False)
    sphere("PodiumMic", 0.03, (0, -0.22, 1.42), (1, 1, 1.4), DARKMETAL, p)
    tube("PodiumCrest", 0.18, (0, -0.25, 0.7), (0, -0.26, 0.7), GOLD, p)
    text("PodiumText", "W&C", (0, -0.265, 0.7), 0.1, PLASTIC_BLK, p, extrude=0.002)


def deal_bell(x):
    p = prop("DealBell", x)
    cube("BellStand", 1, (0, 0, 0.5), (0.1, 0.1, 1.0), WALNUT, p, bevel=0.01)
    cube("BellFoot", 1, (0, 0, 0.03), (0.5, 0.5, 0.06), WALNUT, p, bevel=0.01)
    cube("BellArm", 1, (0.15, 0, 1.0), (0.4, 0.06, 0.06), WALNUT, p, bevel=0.01)
    cone("Bell", 0.18, 0.08, 0.25, (0.28, 0, 0.8), BRASS, p, rot=(0, 0, 0))
    torus("BellLip", 0.18, 0.015, (0.28, 0, 0.675), BRASS, p, outline=False)
    tube("BellRope", 0.012, (0.28, 0, 0.68), (0.28, 0, 0.35), FABRIC_CREAM, p, outline=False)
    sphere("BellTassel", 0.03, (0.28, 0, 0.33), (1, 1, 1.6), VELVET, p, outline=False)
    cube("BellPlaque", 1, (0, -0.052, 0.5), (0.08, 0.004, 0.2), GOLD, p, bevel=0, outline=False)


def stanchions(x):
    p = prop("VelvetRope", x)
    for sx in (-1, 1):
        cone("StanchBase", 0.15, 0.12, 0.04, (sx * 0.9, 0, 0.02), GOLD, p)
        tube("StanchPost", 0.025, (sx * 0.9, 0, 0.04), (sx * 0.9, 0, 0.95), GOLD, p)
        sphere("StanchTop", 0.045, (sx * 0.9, 0, 0.98), (1, 1, 1), GOLD, p)
    pts = [(-0.88 + i * 1.76 / 8, 0, 0.9 - 0.25 * math.sin(math.pi * i / 8)) for i in range(9)]
    skin("Rope", pts, [(i, i + 1) for i in range(8)], [0.025] * 9, VELVET, p, subsurf=1)


def award_plaque(x):
    p = prop("AwardPlaque", x)
    cube("PlaqueWood", 1, (0, 0.01, 1.6), (0.4, 0.02, 0.5), WALNUT, p, bevel=0.01)
    cube("PlaqueGold", 1, (0, -0.001, 1.6), (0.32, 0.004, 0.4), GOLD, p, bevel=0, outline=False)
    text("PlaqueText", "TOP\nCLOSER", (0, -0.005, 1.63), 0.06, PLASTIC_BLK, p, extrude=0.001)


def mounted_fish(x):
    p = prop("SingingFish", x)
    cube("FishPlaque", 1, (0, 0.02, 1.7), (0.6, 0.04, 0.3), WALNUT, p, bevel=0.03)
    fish_m = M("SmoothPlastic", "Bass", (0.35, 0.45, 0.15), 0.3)
    sphere("BassBody", 0.1, (0, -0.06, 1.7), (2.2, 0.5, 1), fish_m, p)
    cone("BassTail", 0.09, 0, 0.12, (0.25, -0.06, 1.7), fish_m, p, rot=(0, R(-90), 0), scale=(1, 0.2, 1))
    sphere("BassMouth", 0.04, (-0.2, -0.07, 1.68), (1, 0.8, 1), M("SmoothPlastic", "Mouth", (0.8, 0.3, 0.3), 0.4), p,
           outline=False)
    sphere("BassEye", 0.015, (-0.15, -0.11, 1.73), (1, 1, 1), PLASTIC_BLK, p, outline=False)
    cube("FishButton", 1, (0.22, -0.001, 1.6), (0.05, 0.02, 0.05), PLASTIC_RED, p, bevel=0.01)


def desk_nameplate(x):
    p = prop("DeskNameplate", x)
    cube("NPBase", 1, (0, 0, 0.02), (0.3, 0.06, 0.04), WALNUT, p, bevel=0.01)
    cube("NPPlate", 1, (0, 0, 0.07), (0.28, 0.01, 0.07), GOLD, p, rot=(R(-15), 0, 0), bevel=0.003)
    text("NPText", "BIG SHOT", (0, -0.012, 0.07), 0.035, PLASTIC_BLK, p, rot=(R(75), 0, 0), extrude=0.001)


def retro_phone(x):
    p = prop("GoldPhone", x)
    cube("RPBase", 1, (0, 0, 0.05), (0.22, 0.2, 0.1), GOLD, p, bevel=0.03)
    tube("RPDial", 0.06, (0, -0.05, 0.1), (0, -0.07, 0.11), PLASTIC_WHT, p, outline=False)
    for i in range(10):
        a = i * 0.55
        sphere("DialHole", 0.008, (0.04 * math.cos(a), -0.08, 0.1 + 0.04 * math.sin(a)), (1, 0.5, 1), PLASTIC_BLK, p,
               outline=False)
    skin("RPHandset", [(-0.1, 0.02, 0.14), (0, 0.02, 0.16), (0.1, 0.02, 0.14)], [(0, 1), (1, 2)], [0.03, 0.018, 0.03], GOLD, p)
    skin("RPCord", [(0.1, 0.1, 0.05)] + [(0.13 + 0.01 * math.sin(i), 0.12 + i * 0.02, 0.03) for i in range(5)],
         [(i, i + 1) for i in range(5)], [0.006] * 6, PLASTIC_BLK, p, subsurf=1, outline=False)


def dartboard(x):
    p = prop("Dartboard", x)
    tube("DartCabinet", 0.28, (0, 0.03, 1.73), (0, -0.01, 1.73), PLASTIC_BLK, p)
    for i, r in enumerate((0.23, 0.2, 0.14, 0.11, 0.04, 0.015)):
        col = [(0.05, 0.05, 0.05), (0.8, 0.1, 0.1), (0.95, 0.9, 0.75), (0.1, 0.5, 0.2), (0.1, 0.5, 0.2), (0.8, 0.1, 0.1)][i]
        tube("DartRing%d" % i, r, (0, -0.012 - i * 0.001, 1.73), (0, -0.013 - i * 0.001, 1.73),
             M("Fabric", "Dart%d" % i, col, 0.9), p, outline=False)
    # a boss photo taped in the middle, obviously
    cube("BossPhoto", 1, (0, -0.02, 1.73), (0.12, 0.002, 0.15), PAPER, p, bevel=0, outline=False)
    for i in range(3):
        a = rng.uniform(0, 6.28)
        loc = (0.12 * math.cos(a), -0.02, 1.73 + 0.12 * math.sin(a))
        tube("Dart", 0.004, loc, (loc[0], -0.12, loc[2]), CHROME, p, outline=False)
        cone("DartFlight", 0.02, 0, 0.03, (loc[0], -0.13, loc[2]), PLASTIC_RED, p, rot=(R(90), 0, 0), scale=(1, 0.1, 1),
             outline=False)


def putting_green(x):
    p = prop("PuttingGreen", x)
    cube("Green", 1, (0, 0, 0.01), (1.0, 3.0, 0.02), M("Grass", "Putting", (0.15, 0.55, 0.15), 0.9), p, bevel=0.01,
         outline=False)
    tube("Cup", 0.06, (0, 1.2, 0.022), (0, 1.2, 0.0), PLASTIC_BLK, p, outline=False)
    tube("GolfFlagPole", 0.006, (0, 1.2, 0.0), (0, 1.2, 0.6), PLASTIC_WHT, p, outline=False)
    cube("GolfFlag", 1, (0.07, 1.2, 0.55), (0.14, 0.003, 0.09), PLASTIC_RED, p, bevel=0, outline=False)
    sphere("GolfBall", 0.022, (0.1, -0.9, 0.045), (1, 1, 1), PLASTIC_WHT, p, outline=False)
    tube("Putter", 0.008, (0.25, -1.0, 0.03), (0.35, -0.4, 0.85), CHROME, p, outline=False)
    cube("PutterHead", 1, (0.25, -1.0, 0.03), (0.1, 0.03, 0.03), CHROME, p, bevel=0.005)


def umbrella_stand(x):
    p = prop("UmbrellaStand", x)
    tube("UStand", 0.12, (0, 0, 0.0), (0, 0, 0.5), BRASS, p)
    for i, col in enumerate([(0.05, 0.05, 0.05), (0.7, 0.1, 0.1), (0.1, 0.2, 0.6)]):
        a = i * 2.1
        bx, by = 0.05 * math.cos(a), 0.05 * math.sin(a)
        tube("Umbrella", 0.04, (bx, by, 0.1), (bx * 2, by * 2, 0.85), M("Fabric", "Umbrella%d" % i, col, 0.8), p, r2=0.015)
        torus("UmbHandle", 0.04, 0.01, (bx * 2 + 0.04, by * 2, 0.9), WALNUT, p, rot=(R(90), 0, 0), outline=False)


def magazine_rack(x):
    p = prop("MagazineRack", x)
    cube("MagBack", 1, (0, 0.08, 0.6), (0.5, 0.03, 1.2), WALNUT, p, bevel=0.01)
    covers = [(0.9, 0.15, 0.1), (0.1, 0.3, 0.8), (0.95, 0.8, 0.1), (0.1, 0.6, 0.3), (0.6, 0.1, 0.6), (0.95, 0.5, 0.1)]
    for i in range(3):
        z = 0.25 + i * 0.35
        cube("MagLip", 1, (0, -0.03, z - 0.1), (0.5, 0.05, 0.06), WALNUT, p, bevel=0.005)
        for k in range(2):
            cube("Magazine", 1, (-0.12 + k * 0.24, 0.0, z + 0.03), (0.2, 0.01, 0.27),
                 M("SmoothPlastic", "Mag%d" % (i * 2 + k), covers[i * 2 + k], 0.4), p, rot=(R(-10), 0, 0), bevel=0.002,
                 outline=False)


def trophy_case(x):
    p = prop("TrophyCase", x)
    cube("CaseBody", 1, (0, 0.1, 1.0), (1.5, 0.45, 2.0), WALNUT, p, bevel=0.02)
    cube("CaseInside", 1, (0, 0.05, 1.05), (1.35, 0.4, 1.8), M("Fabric", "CaseVelvet", (0.1, 0.05, 0.2), 0.9), p, bevel=0,
         outline=False)
    cube("CaseGlass", 1, (0, -0.13, 1.05), (1.38, 0.01, 1.82), GLASS, p, bevel=0, outline=False)
    for z in (0.5, 1.0, 1.5):
        cube("CaseShelf", 1, (0, 0.05, z), (1.35, 0.35, 0.02), GLASS, p, bevel=0, outline=False)
        for k in range(3):
            tx = -0.45 + k * 0.45
            cone("MiniCup", 0.06, 0.03, 0.12, (tx, 0.05, z + 0.12), GOLD, p, rot=(R(180), 0, 0), outline=False)
            tube("MiniStem", 0.012, (tx, 0.05, z + 0.02), (tx, 0.05, z + 0.06), GOLD, p, outline=False)
            cube("MiniBase", 1, (tx, 0.05, z + 0.02), (0.08, 0.08, 0.03), MARBLE_BLK, p, bevel=0.003, outline=False)
    tube("CaseLight", 0.01, (-0.6, -0.05, 1.93), (0.6, -0.05, 1.93), BULB, p, outline=False)


def cafeteria_menu(x):
    p = prop("MenuBoard", x)
    cube("MenuFrame", 1, (0, 0.02, 2.4), (2.0, 0.04, 0.9), WALNUT, p, bevel=0.01)
    cube("MenuChalk", 1, (0, -0.001, 2.4), (1.9, 0.004, 0.8), M("SmoothPlastic", "Chalk", (0.1, 0.12, 0.1), 0.9), p,
         bevel=0, outline=False)
    text("MenuText", "WOLF CAFE\nBURGER $$  PIZZA $\nDONUT $  CEO SALAD $$$$", (0, -0.005, 2.4), 0.1, PLASTIC_WHT, p,
         extrude=0.001)


def water_puddle(x):
    p = prop("CoffeePuddle", x)
    for i in range(5):
        cube("CoffeeSpill", 1, (rng.uniform(-0.25, 0.25), rng.uniform(-0.2, 0.2), 0.003), (rng.uniform(0.25, 0.5),) * 2 + (0.006,),
             M("Glass", "Coffee", (0.25, 0.12, 0.05), 0.05), p, rot=(0, 0, rng.uniform(0, 3)), bevel=0.2, outline=False)
    for sy in (-1, 1):
        cube("WetSignPanel", 1, (0.55, 0.3 + sy * 0.08, 0.3), (0.3, 0.02, 0.6), M("Plastic", "WetYellow", (1.0, 0.85, 0.1), 0.3),
             p, rot=(R(sy * 15), 0, 0), bevel=0.02)
    text("WetText", "CAUTION\nWET", (0.55, 0.19, 0.35), 0.06, PLASTIC_BLK, p, rot=(R(75), 0, 0), extrude=0.002)


def city_model(x):
    p = prop("SkylineModel", x)
    cube("ModelBase", 1, (0, 0, 0.4), (1.2, 0.8, 0.8), MARBLE_BLK, p, bevel=0.02)
    cube("ModelCase", 1, (0, 0, 1.2), (1.1, 0.7, 0.8), GLASS, p, bevel=0.005, outline=False)
    for i in range(14):
        bx, by = rng.uniform(-0.45, 0.45), rng.uniform(-0.25, 0.25)
        h = rng.uniform(0.1, 0.6)
        cube("MiniTower", 1, (bx, by, 0.8 + h / 2), (0.08, 0.08, h),
             M("SmoothPlastic", "Tower%d" % (i % 3), [(0.8, 0.8, 0.82), (0.4, 0.5, 0.65), (0.9, 0.75, 0.4)][i % 3], 0.3), p,
             bevel=0.005, outline=False)
    cube("TheTower", 1, (0, 0, 1.15), (0.1, 0.1, 0.7), GOLD, p, bevel=0.005, outline=False)


BUILDERS_5 = [american_flag, pool_table, fish_tank_broken, floor_lamp, desk_globe, bar_cart, neon_sign, chandelier, rug,
              marble_bust, wall_tv, motivational_poster, bonsai, orchid, bamboo_planter, hanging_plant, punching_bag,
              massage_chair, bean_bag, grand_piano, model_yacht, money_counter, shredder, fire_extinguisher, exit_sign,
              wall_clock, mail_cart, cork_board, podium, deal_bell, stanchions, award_plaque, mounted_fish, desk_nameplate,
              retro_phone, dartboard, putting_green, umbrella_stand, magazine_rack, trophy_case, cafeteria_menu,
              water_puddle, city_model]



# ---------------------------------------------------------------- round 6: more Wall Street decor and office life
SERVER_M = M("Metal", "ServerRack", (0.08, 0.08, 0.1), 0.4, 0.6)
LED_RED = M("Neon", "LedRed", (1.0, 0.1, 0.1), 0.3, emit=4)
CEIL_PANEL = M("Neon", "CeilingPanel", (1.0, 0.97, 0.9), 0.3, emit=2)


def trading_rig(x):
    """Six-monitor trading desk rig: the classic Wall Street wall of charts."""
    p = prop("TradingRig", x)
    tube("RigPole", 0.03, (0, 0.2, 0.75), (0, 0.2, 1.75), DARKMETAL, p)
    cube("RigClamp", 1, (0, 0.2, 0.76), (0.12, 0.12, 0.04), DARKMETAL, p, bevel=0.01)
    cube("RigDesk", 1, (0, 0, 0.72), (2.2, 0.9, 0.05), MARBLE_BLK, p, bevel=0.01)
    for sx in (-1, 1):
        cube("RigLeg", 1, (sx * 1.0, 0, 0.36), (0.06, 0.8, 0.72), CHROME, p, bevel=0.01)
    up, dn = M("Neon", "CandleUp", (0.15, 1.0, 0.35), 0.3, emit=3), M("Neon", "CandleDown", (1.0, 0.15, 0.2), 0.3, emit=3)
    for row in range(2):
        for col in (-1, 0, 1):
            cx, cz = col * 0.62, 1.1 + row * 0.4
            ang = -col * R(12)
            cube("RigBezel", 1, (cx, 0.12 + abs(col) * 0.08, cz), (0.6, 0.03, 0.37), PLASTIC_BLK, p, rot=(0, 0, ang), bevel=0.008)
            cube("RigScreen", 1, (cx, 0.1 + abs(col) * 0.08, cz), (0.56, 0.003, 0.33),
                 M("Glass", "TradeScreen", (0.01, 0.015, 0.03), 0.05), p, rot=(0, 0, ang), bevel=0, outline=False)
            price = 0.5
            for k in range(10):
                o = price
                price = min(0.9, max(0.1, o + rng.uniform(-0.12, 0.13)))
                m = up if price >= o else dn
                lx = cx + (-0.22 + k * 0.048) * math.cos(ang)
                ly = 0.097 + abs(col) * 0.08 + (-0.22 + k * 0.048) * math.sin(ang)
                cube("RigCandle", 1, (lx, ly, cz - 0.13 + (o + price) / 2 * 0.26), (0.022, 0.002, max(abs(price - o) * 0.26, 0.01)),
                     m, p, rot=(0, 0, ang), bevel=0, outline=False)
            tube("RigArm", 0.012, (0, 0.2, cz), (cx, 0.15 + abs(col) * 0.08, cz), DARKMETAL, p, outline=False)
    cube("RigKeyboard", 1, (0, -0.25, 0.76), (0.55, 0.18, 0.02), PLASTIC_BLK, p, bevel=0.005)
    cube("RigKeys", 1, (0, -0.25, 0.772), (0.5, 0.14, 0.004), PLASTIC_GRY, p, bevel=0, outline=False)
    sphere("RigMouse", 0.03, (0.42, -0.25, 0.76), (1, 1.5, 0.6), PLASTIC_BLK, p)
    cube("RigPhone", 1, (-0.7, -0.2, 0.78), (0.25, 0.2, 0.07), PLASTIC_GRY, p, bevel=0.02)
    cube("RigPhoneKeys", 1, (-0.7, -0.24, 0.816), (0.12, 0.08, 0.003), NEON_GREEN, p, bevel=0, outline=False)


def gold_wolf(x):
    p = prop("GoldWolfStatue", x)
    cube("WolfPlinth", 1, (0, 0, 0.3), (0.9, 0.6, 0.6), MARBLE_BLK, p, bevel=0.02)
    cube("WolfPlaque", 1, (0, -0.302, 0.3), (0.4, 0.004, 0.12), GOLD, p, bevel=0, outline=False)
    text("WolfPlaqueText", "HOWL AT THE MARKET", (0, -0.306, 0.3), 0.03, PLASTIC_BLK, p, extrude=0.001)
    # sitting wolf howling at the sky, built as one skin mesh
    verts = [(0, 0.1, 0.62), (0, 0.05, 0.85), (0, -0.05, 1.05), (0, -0.1, 1.22), (0, -0.18, 1.32),  # hips -> snout
             (-0.1, -0.08, 0.62), (0.1, -0.08, 0.62), (-0.08, -0.1, 0.85), (0.08, -0.1, 0.85),  # front legs
             (0, 0.3, 0.62), (0, 0.42, 0.66)]  # tail
    edges = [(0, 1), (1, 2), (2, 3), (3, 4), (1, 7), (7, 5), (1, 8), (8, 6), (0, 9), (9, 10)]
    radii = [0.16, 0.13, 0.09, 0.07, 0.035, 0.04, 0.04, 0.045, 0.045, 0.06, 0.03]
    skin("WolfBody", verts, edges, radii, GOLD, p)
    # long snout pointing at the sky, open jaw, fluffy chest ruff
    cone("WolfSnout", 0.05, 0.02, 0.18, (0, -0.2, 1.4), GOLD, p, rot=(R(-35), 0, 0))
    cone("WolfJaw", 0.03, 0.012, 0.12, (0, -0.22, 1.3), GOLD, p, rot=(R(-70), 0, 0))
    sphere("WolfNose", 0.02, (0, -0.25, 1.48), (1, 1, 1), PLASTIC_BLK, p, outline=False)
    for k in range(5):
        cone("Ruff", 0.05, 0, 0.1, (-0.08 + k * 0.04, -0.12, 0.95), GOLD, p, rot=(R(160), 0, 0), outline=False)
    for sx in (-1, 1):
        cone("WolfEar", 0.03, 0, 0.09, (sx * 0.05, -0.05, 1.3), GOLD, p, rot=(R(-30), sx * R(15), 0))
        sphere("HindLeg", 0.1, (sx * 0.12, 0.1, 0.66), (0.7, 1.2, 0.6), GOLD, p)


def big_letters(x):
    p = prop("WolfLetters", x)
    cube("LetterWall", 1, (0, 0.06, 2.2), (4.2, 0.04, 1.0), WALNUT, p, bevel=0.01)
    for k in range(9):
        cube("WallSlat", 1, (-2.0 + k * 0.5, 0.035, 2.2), (0.04, 0.02, 1.0), M("Wood", "SlatDark", (0.15, 0.07, 0.03), 0.5), p,
             bevel=0, outline=False)
    text("Letters", "WOLF & CO.", (0, -0.02, 2.2), 0.55, GOLD, p, extrude=0.05)
    tube("LetterLight", 0.01, (-2.0, -0.2, 2.8), (2.0, -0.2, 2.8), BULB, p, outline=False)


def server_rack(x):
    p = prop("ServerRack", x)
    cube("RackBody", 1, (0, 0, 1.0), (0.65, 0.8, 2.0), SERVER_M, p, bevel=0.01)
    cube("RackDoor", 1, (0, -0.405, 1.0), (0.58, 0.01, 1.9), M("Glass", "Smoke", (0.2, 0.2, 0.22), 0.1), p, bevel=0,
         outline=False)
    for k in range(14):
        z = 0.2 + k * 0.125
        cube("ServerUnit", 1, (0, -0.39, z), (0.54, 0.02, 0.1), PLASTIC_BLK, p, bevel=0.003, outline=False)
        for j in range(4):
            cube("ServerLed", 1, (0.18 + j * 0.02, -0.402, z), (0.008, 0.004, 0.008),
                 [NEON_GREEN, NEON_GREEN, NEON_BLUE, LED_RED][rng.randint(0, 3)], p, bevel=0, outline=False)
    tube("RackHandle", 0.008, (0.25, -0.42, 0.8), (0.25, -0.42, 1.2), CHROME, p, outline=False)


def phone_booth(x):
    p = prop("PhoneBooth", x)
    cube("BoothFloor", 1, (0, 0, 0.05), (1.1, 1.1, 0.1), M("Carpet", "Booth", (0.1, 0.1, 0.15), 0.9), p, bevel=0.01)
    cube("BoothRoof", 1, (0, 0, 2.3), (1.1, 1.1, 0.12), PLASTIC_BLK, p, bevel=0.02)
    cube("BoothBack", 1, (0, 0.53, 1.18), (1.1, 0.04, 2.15), M("Fabric", "Acoustic", (0.2, 0.35, 0.3), 0.95), p, bevel=0.01)
    for sx in (-1, 1):
        cube("BoothSide", 1, (sx * 0.53, 0, 1.18), (0.04, 1.02, 2.15), M("Fabric", "Acoustic", (0.2, 0.35, 0.3), 0.95), p,
             bevel=0.01)
    cube("BoothDoor", 1, (0, -0.53, 1.18), (1.0, 0.03, 2.1), GLASS, p, bevel=0.005, outline=False)
    tube("BoothHandle", 0.012, (0.4, -0.57, 1.0), (0.4, -0.57, 1.4), CHROME, p, outline=False)
    cube("BoothShelf", 1, (0, 0.35, 1.05), (0.9, 0.3, 0.04), OAK, p, bevel=0.01)
    cube("BoothStool", 1, (0, 0.05, 0.65), (0.4, 0.4, 0.06), LEATHER, p, bevel=0.02)
    tube("StoolPost", 0.03, (0, 0.05, 0.1), (0, 0.05, 0.62), CHROME, p, outline=False)
    cube("BoothLight", 1, (0, 0, 2.23), (0.6, 0.6, 0.01), CEIL_PANEL, p, bevel=0, outline=False)
    text("BoothSign", "QUIET CALLS", (0, -0.6, 2.3), 0.07, NEON_GOLD, p, extrude=0.003)


def espresso_bar(x):
    p = prop("EspressoBar", x)
    cube("BarCounter", 1, (0, 0, 0.5), (2.4, 0.7, 1.0), WALNUT, p, bevel=0.02)
    cube("BarTop", 1, (0, 0, 1.02), (2.5, 0.75, 0.05), MARBLE, p, bevel=0.01)
    for k in range(6):
        cube("BarPanel", 1, (-1.0 + k * 0.4, -0.352, 0.5), (0.36, 0.004, 0.85), M("Wood", "SlatDark", (0.15, 0.07, 0.03), 0.5),
             p, bevel=0, outline=False)
    cube("Espresso", 1, (-0.6, 0.1, 1.27), (0.6, 0.45, 0.45), CHROME, p, bevel=0.04)
    for k in (-1, 1):
        tube("GroupHead", 0.04, (-0.6 + k * 0.15, -0.12, 1.22), (-0.6 + k * 0.15, -0.12, 1.12), CHROME, p, outline=False)
        tube("Portafilter", 0.01, (-0.6 + k * 0.15, -0.14, 1.12), (-0.6 + k * 0.15, -0.35, 1.12), PLASTIC_BLK, p, outline=False)
    cone("BeanHopper", 0.1, 0.07, 0.2, (-0.3, 0.15, 1.6), GLASS, p, outline=False)
    sphere("Beans", 0.07, (-0.3, 0.15, 1.56), (1, 1, 0.8), M("SmoothPlastic", "Beans", (0.25, 0.12, 0.05), 0.6), p,
           outline=False)
    for k in range(4):
        tube("Cup", 0.035, (0.2 + k * 0.12, 0, 1.045), (0.2 + k * 0.12, 0, 1.12), CERAMIC, p, r2=0.04)
    cube("Grinder", 1, (0.9, 0.15, 1.2), (0.2, 0.2, 0.3), PLASTIC_BLK, p, bevel=0.02)
    for k in range(3):
        sphere("Pastry", 0.06, (0.3 + k * 0.15, 0.2, 1.08), (1.5, 1, 0.6), BUN, p)
    for k in range(3):
        cube("BarStool", 1, (-0.8 + k * 0.8, -0.8, 0.75), (0.35, 0.35, 0.06), LEATHER, p, bevel=0.03)
        tube("BarStoolPost", 0.03, (-0.8 + k * 0.8, -0.8, 0.05), (-0.8 + k * 0.8, -0.8, 0.72), CHROME, p, outline=False)
        torus("FootRing", 0.15, 0.01, (-0.8 + k * 0.8, -0.8, 0.3), CHROME, p, outline=False)
        cone("StoolBase", 0.2, 0.18, 0.03, (-0.8 + k * 0.8, -0.8, 0.015), CHROME, p)


def money_gun(x):
    p = prop("MoneyGun", x)
    green = M("Plastic", "GunGreen", (0.2, 0.7, 0.3), 0.3)
    cube("MGBody", 1, (0, 0, 0.14), (0.12, 0.3, 0.14), green, p, bevel=0.03)
    cube("MGGrip", 1, (0, 0.1, 0.02), (0.07, 0.08, 0.18), PLASTIC_BLK, p, rot=(R(-15), 0, 0), bevel=0.01)
    cube("MGMag", 1, (0, -0.02, 0.26), (0.1, 0.18, 0.08), CASH, p, bevel=0.005)
    cube("MGMouth", 1, (0, -0.16, 0.14), (0.14, 0.03, 0.06), PLASTIC_BLK, p, bevel=0.01)
    text("MGLogo", "$", (0.062, 0, 0.14), 0.08, GOLD, p, rot=(R(90), 0, R(90)), extrude=0.003)
    for k in range(6):
        cube("MGBill", 1, (rng.uniform(-0.1, 0.1), -0.22 - k * 0.07, 0.14 + rng.uniform(-0.05, 0.08)), (0.08, 0.035, 0.002), CASH,
             p, rot=(rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(0, 3)), bevel=0, outline=False)


def gold_toilet(x):
    p = prop("GoldToilet", x)
    cube("GTTank", 1, (0, 0.22, 0.65), (0.45, 0.2, 0.4), GOLD, p, bevel=0.03)
    cube("GTTankLid", 1, (0, 0.22, 0.87), (0.48, 0.22, 0.04), GOLD, p, bevel=0.01)
    cube("GTHandle", 1, (-0.2, 0.11, 0.78), (0.08, 0.02, 0.02), CHROME, p, bevel=0.005)
    cone("GTBase", 0.15, 0.2, 0.4, (0, -0.05, 0.2), GOLD, p, scale=(1, 1.3, 1))
    torus("GTSeat", 0.18, 0.04, (0, -0.1, 0.43), GOLD, p, scale=(1, 1.3, 1))
    cube("GTLid", 1, (0, 0.13, 0.7), (0.4, 0.04, 0.45), GOLD, p, rot=(R(-10), 0, 0), bevel=0.05)
    sphere("GTJewel", 0.03, (0, 0.105, 0.72), (1, 0.5, 1), M("Glass", "Ruby", (0.8, 0.02, 0.1), 0.05), p, outline=False)
    cube("GTRug", 1, (0, -0.35, 0.005), (0.8, 0.6, 0.01), VELVET, p, bevel=0.005, outline=False)
    tube("TPHolder", 0.012, (0.35, 0.1, 0.6), (0.45, 0.1, 0.6), GOLD, p, outline=False)
    tube("TPRoll", 0.05, (0.37, 0.1, 0.6), (0.45, 0.1, 0.6), M("Fabric", "TPCash", (0.35, 0.6, 0.3), 0.8), p)


def security_camera(x):
    p = prop("SecurityCamera", x)
    cube("CamMount", 1, (0, 0.1, 2.5), (0.1, 0.05, 0.14), PLASTIC_WHT, p, bevel=0.01)
    tube("CamArm", 0.015, (0, 0.08, 2.5), (0, -0.05, 2.45), PLASTIC_WHT, p, outline=False)
    cube("CamBody", 1, (0, -0.15, 2.42), (0.1, 0.25, 0.1), PLASTIC_WHT, p, rot=(R(-15), 0, 0), bevel=0.02)
    tube("CamLens", 0.035, (0, -0.27, 2.39), (0, -0.29, 2.385), SCREEN, p, outline=False)
    sphere("CamLed", 0.008, (0.035, -0.27, 2.43), (1, 1, 1), LED_RED, p, outline=False)


def desk_fan(x):
    p = prop("DeskFan", x)
    cone("FanBase", 0.1, 0.08, 0.03, (0, 0, 0.015), CHROME, p)
    tube("FanNeck", 0.012, (0, 0, 0.03), (0, 0, 0.25), CHROME, p, outline=False)
    tube("FanMotor", 0.05, (0, 0.05, 0.28), (0, 0.13, 0.28), CHROME, p)
    for k in range(4):
        a = k * math.pi / 2
        sphere("FanBlade", 0.06, (0.06 * math.cos(a), 0.0, 0.28 + 0.06 * math.sin(a)), (1, 0.1, 0.5),
               M("Plastic", "FanBlade", (0.3, 0.7, 0.9), 0.3), p, rot=(0, -a + 0.3, 0), outline=False)
    torus("FanCage", 0.13, 0.004, (0, -0.01, 0.28), CHROME, p, rot=(R(90), 0, 0), outline=False)
    for k in range(8):
        a = k * math.pi / 4
        tube("CageWire", 0.002, (0, -0.03, 0.28), (0.13 * math.cos(a), -0.01, 0.28 + 0.13 * math.sin(a)), CHROME, p,
             outline=False)


def newspaper_stack(x):
    p = prop("NewspaperStack", x)
    for k in range(8):
        cube("Paper", 1, (rng.uniform(-0.02, 0.02), rng.uniform(-0.02, 0.02), 0.012 + k * 0.024), (0.3, 0.42, 0.022),
             M("SmoothPlastic", "Newsprint", (0.9, 0.88, 0.8), 0.8), p, rot=(0, 0, rng.uniform(-0.1, 0.1)), bevel=0.003)
    text("Masthead", "WALL ST. DAILY", (0, -0.05, 0.2), 0.04, PLASTIC_BLK, p, rot=(0, 0, 0), extrude=0.001)
    text("Headline", "STONKS ONLY GO UP", (0, 0.05, 0.2), 0.03, PLASTIC_BLK, p, rot=(0, 0, 0), extrude=0.001)
    tube("Twine", 0.004, (0, -0.22, 0.1), (0, 0.22, 0.1), FABRIC_CREAM, p, outline=False)


def fruit_bowl(x):
    p = prop("FruitBowl", x)
    sphere("Bowl", 0.18, (0, 0, 0.1), (1, 1, 0.5), CERAMIC, p)
    cols = [(0.85, 0.05, 0.05), (1.0, 0.55, 0.05), (0.5, 0.8, 0.1), (0.4, 0.05, 0.4), (1.0, 0.85, 0.15)]
    for k in range(9):
        a = k * 0.7
        r = 0.08 if k < 6 else 0.02
        sphere("Fruit", 0.05, (r * math.cos(a), r * math.sin(a), 0.16 + (0.05 if k >= 6 else 0)), (1, 1, 1),
               M("SmoothPlastic", "Fruit%d" % (k % 5), cols[k % 5], 0.3), p, outline=False)
    tube("Stem", 0.004, (0, 0, 0.26), (0.01, 0, 0.29), WALNUT, p, outline=False)


def recycling_bins(x):
    p = prop("RecyclingBins", x)
    for k, (n, col, label) in enumerate((("Paper", (0.1, 0.35, 0.8), "PAPER"), ("Cans", (1.0, 0.8, 0.1), "CANS"),
                                         ("Trash", (0.15, 0.15, 0.17), "LOSSES"))):
        bx = -0.45 + k * 0.45
        cube("Bin" + n, 1, (bx, 0, 0.4), (0.4, 0.4, 0.8), M("Plastic", "Bin" + n, col, 0.4), p, bevel=0.03)
        cube("BinLid" + n, 1, (bx, 0, 0.82), (0.42, 0.42, 0.04), PLASTIC_BLK, p, bevel=0.01)
        cube("BinSlot" + n, 1, (bx, -0.1, 0.843), (0.25, 0.06, 0.003), PLASTIC_GRY, p, bevel=0, outline=False)
        text("BinLabel" + n, label, (bx, -0.205, 0.55), 0.06, PLASTIC_WHT, p, extrude=0.002)


def fire_alarm(x):
    p = prop("FireAlarm", x)
    cube("AlarmBox", 1, (0, 0.02, 1.3), (0.14, 0.05, 0.2), M("Plastic", "ExtRed", (0.85, 0.05, 0.05), 0.25), p, bevel=0.01)
    cube("AlarmHandle", 1, (0, -0.01, 1.3), (0.08, 0.03, 0.05), PLASTIC_WHT, p, bevel=0.005)
    text("AlarmText", "PULL", (0, -0.006, 1.37), 0.025, PLASTIC_WHT, p, extrude=0.001)
    tube("Strobe", 0.05, (0, 0.03, 1.7), (0, -0.02, 1.7), M("Plastic", "ExtRed", (0.85, 0.05, 0.05), 0.25), p)
    cube("StrobeLens", 1, (0, -0.025, 1.7), (0.05, 0.01, 0.03), PLASTIC_WHT, p, bevel=0.003, outline=False)


def elevator_panel(x):
    p = prop("ElevatorPanel", x)
    cube("EPPlate", 1, (0, 0.01, 1.2), (0.15, 0.02, 0.35), CHROME, p, bevel=0.005)
    for k, z in enumerate((1.28, 1.12)):
        tube("EPButton", 0.03, (0, 0.0, z), (0, -0.01, z), [NEON_GOLD, PLASTIC_WHT][k], p, outline=False)
        cone("EPArrow", 0.012, 0, 0.02, (0, -0.012, z), PLASTIC_BLK, p, rot=(R(90) if k == 0 else R(-90), 0, 0),
             scale=(1, 1, 0.2), outline=False)
    cube("FloorDisplay", 1, (0, 0.01, 2.4), (0.3, 0.02, 0.12), PLASTIC_BLK, p, bevel=0.005)
    text("FloorNum", "100", (0, -0.002, 2.4), 0.07, LED_RED, p, extrude=0.001)


def gold_piggy(x):
    p = prop("GoldPiggyBank", x)
    sphere("PiggyBody", 0.12, (0, 0, 0.14), (1, 1.3, 0.95), GOLD, p)
    tube("PiggySnout", 0.04, (0, -0.15, 0.15), (0, -0.19, 0.15), GOLD, p)
    for sx in (-1, 1):
        sphere("Nostril", 0.008, (sx * 0.015, -0.192, 0.15), (1, 1, 1), PLASTIC_BLK, p, outline=False)
        cone("PiggyEar", 0.03, 0, 0.05, (sx * 0.06, -0.08, 0.26), GOLD, p, rot=(R(-20), sx * R(20), 0))
        sphere("PiggyEye", 0.012, (sx * 0.04, -0.14, 0.2), (1, 1, 1), PLASTIC_BLK, p, outline=False)
        for sy in (-1, 1):
            tube("PiggyLeg", 0.03, (sx * 0.07, sy * 0.08, 0.06), (sx * 0.07, sy * 0.08, 0.0), GOLD, p)
    cube("CoinSlot", 1, (0, 0.02, 0.254), (0.05, 0.008, 0.004), PLASTIC_BLK, p, bevel=0, outline=False)
    tube("Coin", 0.025, (0, 0.02, 0.27), (0, 0.025, 0.27), GOLD, p, outline=False)


def bull_bear_bookends(x):
    p = prop("BullBearBookends", x)
    for sx, m in ((-1, BRONZE), (1, M("Metal", "Silver", (0.7, 0.7, 0.72), 0.3, 1.0))):
        cube("BookendBase", 1, (sx * 0.3, 0, 0.02), (0.15, 0.15, 0.04), MARBLE_BLK, p, bevel=0.005)
        cube("BookendBack", 1, (sx * 0.23, 0, 0.12), (0.02, 0.15, 0.2), MARBLE_BLK, p, bevel=0.005)
        sphere("BeastBody", 0.07, (sx * 0.32, 0, 0.11), (1.3, 0.7, 0.8), m, p)
        sphere("BeastHead", 0.04, (sx * 0.4, 0, 0.15), (1, 0.9, 1), m, p)
        if sx < 0:  # bull horns point up
            for sy in (-1, 1):
                cone("Horn", 0.012, 0, 0.05, (-0.42, sy * 0.03, 0.2), IVORY, p, rot=(sy * R(-30), 0, 0))
        else:  # bear ears
            for sy in (-1, 1):
                sphere("BearEar", 0.015, (0.4, sy * 0.025, 0.19), (1, 1, 1), m, p, outline=False)
    colors = [(0.6, 0.1, 0.1), (0.1, 0.2, 0.5), (0.1, 0.4, 0.2), (0.4, 0.3, 0.1), (0.1, 0.1, 0.1), (0.5, 0.4, 0.2)]
    for k, col in enumerate(colors):
        cube("Book", 1, (-0.18 + k * 0.07, 0, 0.14), (0.06, 0.14, 0.2 + rng.uniform(-0.02, 0.03)),
             M("Leather", "Book%d" % k, col, 0.6), p, bevel=0.005)


def ceiling_light(x):
    p = prop("CeilingLight", x)
    cube("LightHousing", 1, (0, 0, 3.0), (1.2, 0.3, 0.06), ALU, p, bevel=0.01)
    cube("LightDiffuser", 1, (0, 0, 2.965), (1.15, 0.26, 0.01), CEIL_PANEL, p, bevel=0, outline=False)
    for sx in (-1, 1):
        tube("LightCable", 0.003, (sx * 0.5, 0, 3.03), (sx * 0.5, 0, 3.6), DARKMETAL, p, outline=False)


def pendant_lamp(x):
    p = prop("PendantLamp", x)
    tube("PendantCord", 0.005, (0, 0, 3.0), (0, 0, 2.2), PLASTIC_BLK, p, outline=False)
    cone("PendantShade", 0.25, 0.05, 0.25, (0, 0, 2.08), M("Metal", "Copper", (0.85, 0.45, 0.25), 0.25, 1.0), p)
    sphere("PendantBulb", 0.06, (0, 0, 1.96), (1, 1, 1.2), BULB, p, outline=False)
    cone("PendantCanopy", 0.06, 0.04, 0.03, (0, 0, 2.99), PLASTIC_BLK, p)


def air_hockey(x):
    p = prop("AirHockey", x)
    cube("AHBody", 1, (0, 0, 0.45), (1.2, 2.2, 0.35), M("Plastic", "AHBlue", (0.1, 0.25, 0.7), 0.3), p, bevel=0.03)
    cube("AHTop", 1, (0, 0, 0.63), (1.05, 2.05, 0.01), PLASTIC_WHT, p, bevel=0, outline=False)
    for sx in (-1, 1):
        cube("AHRail", 1, (sx * 0.56, 0, 0.66), (0.06, 2.2, 0.06), PLASTIC_BLK, p, bevel=0.01)
        cube("AHGoal", 1, (0, sx * 1.08, 0.64), (0.35, 0.04, 0.03), PLASTIC_BLK, p, bevel=0.005, outline=False)
        tube("Mallet", 0.06, (0, sx * 0.7, 0.64), (0, sx * 0.7, 0.67), PLASTIC_RED, p)
        tube("MalletKnob", 0.025, (0, sx * 0.7, 0.67), (0, sx * 0.7, 0.72), PLASTIC_RED, p, outline=False)
    cube("AHCenter", 1, (0, 0, 0.637), (1.05, 0.02, 0.003), PLASTIC_RED, p, bevel=0, outline=False)
    torus("AHCircle", 0.2, 0.008, (0, 0, 0.637), PLASTIC_RED, p, scale=(1, 1, 0.1), outline=False)
    tube("Puck", 0.04, (0.2, 0.3, 0.635), (0.2, 0.3, 0.65), PLASTIC_BLK, p, outline=False)
    for sx in (-1, 1):
        for sy in (-1, 1):
            cube("AHLeg", 1, (sx * 0.45, sy * 0.9, 0.14), (0.1, 0.1, 0.28), PLASTIC_BLK, p, bevel=0.01)
    cube("AHScore", 1, (0.56, 0, 0.9), (0.06, 0.5, 0.25), PLASTIC_BLK, p, bevel=0.01)
    text("AHScoreText", "7  3", (0.595, 0, 0.9), 0.08, LED_RED, p, rot=(R(90), 0, R(90)), extrude=0.001)


def cue_rack(x):
    p = prop("CueRack", x)
    cube("CueRackBack", 1, (0, 0.03, 1.4), (0.8, 0.04, 1.4), WALNUT, p, bevel=0.01)
    cube("CueRackTop", 1, (0, -0.03, 1.95), (0.8, 0.1, 0.04), WALNUT, p, bevel=0.01)
    cube("CueRackBottom", 1, (0, -0.03, 0.75), (0.8, 0.12, 0.06), WALNUT, p, bevel=0.01)
    for k in range(6):
        cx = -0.3 + k * 0.12
        tube("RackedCue", 0.012, (cx, -0.04, 0.78), (cx, -0.04, 2.0), OAK, p, r2=0.006, outline=False)
        tube("CueWrap", 0.014, (cx, -0.04, 0.95), (cx, -0.04, 1.2), PLASTIC_BLK, p, outline=False)
    cube("ChalkShelf", 1, (0, -0.06, 1.3), (0.5, 0.06, 0.02), WALNUT, p, bevel=0.005)
    for k in range(3):
        cube("RackChalk", 1, (-0.15 + k * 0.15, -0.06, 1.325), (0.025, 0.025, 0.025),
             M("SmoothPlastic", "Chalk", (0.2, 0.45, 0.85), 0.8), p, bevel=0.003, outline=False)


def side_table(x):
    p = prop("SideTable", x)
    tube("STTop", 0.3, (0, 0, 0.58), (0, 0, 0.62), MARBLE, p)
    tube("STStem", 0.03, (0, 0, 0.05), (0, 0, 0.58), GOLD, p, outline=False)
    cone("STBase", 0.2, 0.15, 0.05, (0, 0, 0.025), GOLD, p)
    cone("STLampShade", 0.12, 0.08, 0.15, (0.1, 0.05, 0.95), LAMPSHADE, p)
    tube("STLampBody", 0.06, (0.1, 0.05, 0.62), (0.1, 0.05, 0.85), CERAMIC, p, r2=0.03)
    sphere("STLampGlow", 0.03, (0.1, 0.05, 0.88), (1, 1, 1), BULB, p, outline=False)
    cube("STBook", 1, (-0.1, -0.08, 0.64), (0.18, 0.24, 0.03), M("Leather", "Book0", (0.6, 0.1, 0.1), 0.6), p, bevel=0.005)
    cube("STBook2", 1, (-0.1, -0.08, 0.67), (0.16, 0.22, 0.025), M("Leather", "Book1", (0.1, 0.2, 0.5), 0.6), p,
         rot=(0, 0, R(10)), bevel=0.005)


def water_pallet(x):
    p = prop("WaterBottlePallet", x)
    cube("Pallet", 1, (0, 0, 0.06), (1.0, 0.8, 0.12), OAK, p, bevel=0.005)
    for k in range(3):
        cube("PalletSlat", 1, (0, -0.3 + k * 0.3, 0.13), (1.0, 0.12, 0.02), OAK, p, bevel=0.003, outline=False)
    blue = M("Glass", "WaterJug", (0.3, 0.55, 0.95), 0.05)
    for i in range(3):
        for j in range(2):
            for lvl in range(2):
                bx, by, bz = -0.33 + i * 0.33, -0.18 + j * 0.36, 0.3 + lvl * 0.38
                tube("Jug", 0.14, (bx, by, bz - 0.15), (bx, by, bz + 0.12), blue, p, outline=False)
                tube("JugCap", 0.04, (bx, by, bz + 0.12), (bx, by, bz + 0.18), NEON_BLUE if lvl else blue, p, outline=False)


def calculator(x):
    p = prop("DeskCalculator", x)
    cube("CalcBody", 1, (0, 0, 0.015), (0.16, 0.22, 0.03), PLASTIC_GRY, p, bevel=0.008)
    cube("CalcDisplay", 1, (0, -0.07, 0.031), (0.13, 0.05, 0.002), M("SmoothPlastic", "LCD", (0.6, 0.7, 0.55), 0.3), p,
         bevel=0, outline=False)
    text("CalcNum", "1000000", (0, -0.07, 0.033), 0.03, PLASTIC_BLK, p, rot=(0, 0, 0), extrude=0.001)
    for r in range(4):
        for c in range(4):
            cube("CalcKey", 1, (-0.05 + c * 0.033, -0.02 + r * 0.03, 0.033), (0.025, 0.022, 0.008),
                 PLASTIC_RED if (r, c) == (3, 3) else PLASTIC_BLK, p, bevel=0.003, outline=False)
    cube("TapeRoll", 1, (0, 0.13, 0.05), (0.08, 0.05, 0.05), PAPER, p, bevel=0.02)


BUILDERS_6 = [trading_rig, gold_wolf, big_letters, server_rack, phone_booth, espresso_bar, money_gun, gold_toilet,
              security_camera, desk_fan, newspaper_stack, fruit_bowl, recycling_bins, fire_alarm, elevator_panel, gold_piggy,
              bull_bear_bookends, ceiling_light, pendant_lamp, air_hockey, cue_rack, side_table, water_pallet, calculator]


def extra_decor(x):
    """Variants of the parametric builders so the office has more than one of each look."""
    neon_sign(x, "NeonSignMoney", "MONEY NEVER SLEEPS", NEON_GOLD)
    neon_sign(x + 4, "NeonSignDial", "PICK UP THE PHONE", M("Neon", "Cyan", (0.2, 0.9, 1.0), 0.3, emit=4))
    motivational_poster(x + 8, "PosterGreed", "AMBITION", "SELL ME THIS PEN", (0.3, 0.05, 0.08))
    motivational_poster(x + 12, "PosterTeam", "TEAMWORK", "SPLIT THE COMMISSION (NOT REALLY)", (0.05, 0.15, 0.35))
    return x + 16

BUILDERS = [office_chair, desk_set, sofa, coffee_table, plant_fiddle, plant_snake, plant_palm, trash_bin, water_cooler,
            cash_stack, gold_bull, office_door]

if __name__ == "__main__":
    x = 0.0
    for b in BUILDERS + BUILDERS_2 + BUILDERS_3 + BUILDERS_4 + BUILDERS_5 + BUILDERS_6:
        b(x)
        x += 4.0
    x = extra_decor(x)
    for pose, curls in POSES.items():
        hand_pose(x, pose, curls)
        x += 4.0
    painting(x, "PaintingBull", [(0, 0, 0.22, (0.9, 0.6, 0.1)), (-0.28, 0.12, 0.12, (0.1, 0.1, 0.1)),
                                 (0.3, -0.15, 0.1, (0.85, 0.1, 0.1))])
    painting(x + 4, "PaintingAbstract", [(-0.25, 0.08, 0.2, (0.1, 0.3, 0.8)), (0.2, -0.05, 0.25, (1.0, 0.8, 0.1)),
                                         (0.05, 0.18, 0.1, (0.9, 0.2, 0.4)), (-0.35, -0.2, 0.08, (0.1, 0.7, 0.4))])
    painting(x + 8, "PaintingSunset", [(0, -0.1, 0.3, (1.0, 0.45, 0.1)), (-0.3, 0.2, 0.12, (0.9, 0.2, 0.5)),
                                       (0.3, 0.15, 0.1, (1.0, 0.9, 0.4))])
    studio(cam_loc=(0, -10, 2.5), target=(0, 0, 0.8), lens=36)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(D, "props.blend"))
    print("DONE")
