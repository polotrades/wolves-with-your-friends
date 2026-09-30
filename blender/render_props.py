"""Render every prop in props.blend on its own and tile them into renders/props_sheet.png."""
import os
import sys
import bpy
from mathutils import Vector

D = os.path.dirname(os.path.abspath(__file__))
bpy.ops.wm.open_mainfile(filepath=os.path.join(D, "props.blend"))
sc = bpy.context.scene
cam = sc.camera
names = [o.name for o in bpy.data.objects if o.type == "EMPTY" and o.parent is None]
roots = {n: bpy.data.objects[n] for n in names}
# optional: python3 render_props.py Name1 Name2 ... renders only those props
only = set(sys.argv[1:])


def kids(o):
    out = []
    for c in o.children:
        out.append(c)
        out += kids(c)
    return out


out = []
for n, root in roots.items():
    if only and n not in only:
        continue
    for m, r in roots.items():
        for o in [r] + kids(r):
            o.hide_render = m != n
    pts = [o.matrix_world @ Vector(c) for o in kids(root) if o.type == "MESH" for c in o.bound_box]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    center, size = (lo + hi) / 2, max((hi - lo).length, 0.4)
    loc = center + Vector((size * 0.55, -size * 1.35, size * 0.55))
    cam.location = loc
    cam.data.lens = 45
    cam.rotation_mode = "QUATERNION"
    cam.rotation_quaternion = (center - loc).to_track_quat("-Z", "Y")
    sc.render.resolution_x, sc.render.resolution_y = 500, 420
    sc.cycles.samples = 12 if only else 24
    path = os.path.join(D, "renders", f"prop_{n}.png")
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)
    out.append(path)
print("DONE")
