#!/usr/bin/env python3
"""
scripts/appicon_replace.py
Copy a single source PNG into iOS AppIcon.appiconset, Android mipmap folders,
and common web icon locations. Run this from the repo root.
Usage:
  python3 scripts/appicon_replace.py assets/app_icon.png

Important: the script will overwrite files in your repo. Commit or backup first.
"""
import sys, shutil, os

SRC = sys.argv[1] if len(sys.argv) > 1 else 'assets/app_icon.png'
if not os.path.isfile(SRC):
    print("Source file not found:", SRC)
    sys.exit(2)

# iOS appiconset folder
appiconset = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
if os.path.isdir(appiconset):
    for fn in os.listdir(appiconset):
        if fn.lower().endswith('.png'):
            dest = os.path.join(appiconset, fn)
            shutil.copy2(SRC, dest)
            print('Wrote:', dest)
else:
    print('iOS AppIcon.appiconset not found at', appiconset)

# Android mipmap folders
mipmap_base = 'android/app/src/main/res'
if os.path.isdir(mipmap_base):
    mipmap_folders = [d for d in os.listdir(mipmap_base) if d.startswith('mipmap')]
    for m in mipmap_folders:
        dest = os.path.join(mipmap_base, m, 'ic_launcher.png')
        dst_dir = os.path.join(mipmap_base, m)
        if os.path.isdir(dst_dir):
            shutil.copy2(SRC, dest)
            print('Wrote:', dest)
        # try foreground/adaptive names too
        fg = os.path.join(dst_dir, 'ic_launcher_foreground.png')
        try:
            shutil.copy2(SRC, fg)
            print('Wrote:', fg)
        except Exception:
            pass
else:
    print('Android res folder not found at', mipmap_base)

# Web favicon / icons (common places)
web_paths = ['web/favicon.png', 'web/icons/Icon-192.png', 'web/icons/Icon-512.png']
for p in web_paths:
    dirn = os.path.dirname(p)
    if dirn and not os.path.isdir(dirn):
        os.makedirs(dirn, exist_ok=True)
    try:
        shutil.copy2(SRC, p)
        print('Wrote:', p)
    except Exception as e:
        print('Failed to write', p, e)

print('Done. Please open Xcode/Android Studio if needed to refresh assets.')
