"""Export every prop in props.blend for Roblox, one mesh per material.

Each mesh is named after its material ("Leather_Black", "Metal_Chrome", ...). In Roblox the game reads
roblox/src/shared/PropLooks.lua (written here) to give each MeshPart its real Roblox Material, color and transparency,
and each prop's bounds so it can be scaled and placed exactly like the Blender layout.

Run after props.py:  python3 export_props.py
Writes export/props/PropPack<N>.fbx (a few props per file, each prop its own group -> one Model per prop in Roblox)
and roblox/src/shared/PropLooks.lua
"""
import os
import sys

import bpy
from mathutils import Matrix, Vector

D = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(D, "export", "props")
LOOKS = os.path.join(D, "..", "roblox", "src", "shared", "PropLooks.lua")
os.makedirs(OUT, exist_ok=True)
MAX_TRIS = 19000  # per MeshPart; Roblox allows 20k

# Blender material kinds that are not Roblox Enum.Material names
KIND_MAP = {"Ceramic": "SmoothPlastic", "Pebble": "Pebble", "Ground": "Ground"}
ROBLOX_MATERIALS = {"Plastic", "SmoothPlastic", "Neon", "Wood", "WoodPlanks", "Marble", "Slate", "Concrete", "Granite",
                    "Brick", "Pebble", "Cobblestone", "Metal", "Grass", "LeafyGrass", "Sand", "Fabric", "Ice", "Glass",
                    "Cardboard", "Carpet", "Leather", "Plaster", "Rubber", "Ground", "Foil", "DiamondPlate"}

bpy.ops.wm.open_mainfile(filepath=os.path.join(D, "props.blend"))
scene = bpy.context.scene
PACKS = 4  # Studio imports one file at a time; 4 files keeps each import a reasonable size


def descendants(obj):
    for c in obj.children:
        yield c
        yield from descendants(c)


def transparency(kind, look):
    if kind != "Glass":
        return 0.0
    if "Screen" in look or look == "Backer":
        return 0.0
    if look.startswith("Juice") or look in ("Coffee", "BankerGreen"):
        return 0.2
    if look in ("Smoke", "Water"):
        return 0.4
    return 0.65


def look_of(m):
    kind, _, look = m.name.partition("_")
    b = m.node_tree.nodes.get("Principled BSDF") if m.use_nodes else None
    col = tuple(b.inputs["Base Color"].default_value)[:3] if b else tuple(m.diffuse_color)[:3]
    # Blender colors are linear; Roblox Color3 is sRGB
    srgb = tuple(round(255 * (c * 12.92 if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055)) for c in col)
    rkind = KIND_MAP.get(kind, kind)
    if rkind not in ROBLOX_MATERIALS:
        rkind = "SmoothPlastic"
    return {"material": rkind, "color": srgb, "transparency": transparency(kind, look)}


looks = {}
bounds = {}
exported = {}  # prop name -> (group empty, parts)
roots = sorted((o for o in bpy.data.objects if o.type == "EMPTY" and o.parent is None), key=lambda o: o.name)
for root in roots:
    name = root.name
    sources = [o for o in descendants(root) if o.type in {"MESH", "FONT"}]
    for o in sources:
        for m in getattr(o, "modifiers", []):
            if m.name == "Outline":
                m.show_viewport = m.show_render = False
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    offset = root.matrix_world.translation.copy()
    by_mat = {}
    for o in sources:
        ev = o.evaluated_get(dg)
        me = bpy.data.meshes.new_from_object(ev, depsgraph=dg)
        me.transform(Matrix.Translation(-offset) @ o.matrix_world)
        mats = [s for s in me.materials if s and s.name != "Outline"]
        if not mats:
            continue
        m = mats[0]
        looks.setdefault(m.name, look_of(m))
        by_mat.setdefault(m.name, []).append(me)
    parts = []
    for mname, meshes in by_mat.items():
        objs = []
        for me in meshes:
            ob = bpy.data.objects.new(mname, me)
            scene.collection.objects.link(ob)
            objs.append(ob)
        bpy.ops.object.select_all(action="DESELECT")
        for ob in objs:
            ob.select_set(True)
        bpy.context.view_layer.objects.active = objs[0]
        if len(objs) > 1:
            bpy.ops.object.join()
        ob = bpy.context.view_layer.objects.active
        ob.name = mname
        ob.data.name = mname
        ob.data.materials.clear()
        ob.data.materials.append(bpy.data.materials[mname])
        tris = sum(len(p.vertices) - 2 for p in ob.data.polygons)
        if tris > MAX_TRIS:
            dec = ob.modifiers.new("Decimate", "DECIMATE")
            dec.ratio = MAX_TRIS / tris * 0.95
            bpy.ops.object.modifier_apply(modifier=dec.name)
        parts.append(ob)
    if not parts:
        continue
    pts = [p.matrix_world @ Vector(c) for p in parts for c in p.bound_box]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    bounds[name] = (tuple(round(v, 3) for v in lo), tuple(round(v, 3) for v in hi))
    group = bpy.data.objects.new(name, None)  # becomes a Model named after the prop in Roblox
    scene.collection.objects.link(group)
    for p in parts:
        p.parent = group
    exported[name] = (group, parts)
    print(f"prepared {name}: {len(by_mat)} materials", flush=True)

names = sorted(exported)
for k in range(PACKS):
    pack = names[k::PACKS]
    bpy.ops.object.select_all(action="DESELECT")
    for n in pack:
        group, parts = exported[n]
        group.select_set(True)
        for p in parts:
            p.select_set(True)
    path = os.path.join(OUT, "PropPack%d.fbx" % (k + 1))
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, apply_unit_scale=True, object_types={"EMPTY", "MESH"},
                             mesh_smooth_type="FACE", axis_forward="-Z", axis_up="Y")
    print("exported", path, len(pack), "props", flush=True)

with open(LOOKS, "w") as f:
    f.write("-- Generated by blender/export_props.py. Do not edit by hand.\n")
    f.write("-- looks: MeshPart name (= Blender material) -> Roblox Material, Color3 and Transparency\n")
    f.write("-- bounds: each prop's box in Blender meters relative to its origin (the floor point it stands on),\n")
    f.write("--   { lo = {x, y, z}, hi = {x, y, z} } with Z up and the prop's front facing -Y\n")
    f.write("return {\n\tlooks = {\n")
    for k in sorted(looks):
        v = looks[k]
        f.write('\t\t["%s"] = { material = Enum.Material.%s, color = Color3.fromRGB(%d, %d, %d), transparency = %s },\n'
                % (k, v["material"], *v["color"], v["transparency"]))
    f.write("\t},\n\tbounds = {\n")
    for k in sorted(bounds):
        lo, hi = bounds[k]
        f.write('\t\t%s = { lo = {%s, %s, %s}, hi = {%s, %s, %s} },\n' % (k, *lo, *hi))
    f.write("\t},\n}\n")
print("DONE")
