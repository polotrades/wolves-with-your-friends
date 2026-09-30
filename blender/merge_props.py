"""Join props_part*.blend (from `props.py --part i n`) into props.blend, de-duplicating shared materials.

Run: python3 merge_props.py
"""
import glob
import os
import re
import sys

import bpy

D = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, D)
from lib import studio  # noqa: E402

parts = sorted(glob.glob(os.path.join(D, "props_part*.blend")))
bpy.ops.wm.open_mainfile(filepath=parts[0])
sc = bpy.context.scene
for path in parts[1:]:
    with bpy.data.libraries.load(path, link=False) as (src, dst):
        dst.objects = list(src.objects)
    for o in dst.objects:
        if o is not None:
            sc.collection.objects.link(o)
# each part created its own copy of every shared material ("Leather_Black.001"); point everything at one copy
for m in list(bpy.data.materials):
    base = re.sub(r"\.\d{3}$", "", m.name)
    if base != m.name and base in bpy.data.materials:
        m.user_remap(bpy.data.materials[base])
        bpy.data.materials.remove(m)
dupes = [o.name for o in sc.objects if o.type == "EMPTY" and o.parent is None and re.search(r"\.\d{3}$", o.name)]
if dupes:
    print("WARNING duplicate prop names:", dupes)
studio(cam_loc=(0, -10, 2.5), target=(0, 0, 0.8), lens=36)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(D, "props.blend"))
print("DONE", len([o for o in sc.objects if o.type == "EMPTY" and o.parent is None]), "props")
