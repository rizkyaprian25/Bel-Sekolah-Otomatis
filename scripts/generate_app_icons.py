import os
from PIL import Image

src = r"C:\Users\Workmate\.gemini\antigravity-ide\brain\c582621f-f27d-4ac4-b3d9-755d471f6304\app_icon_1789300834002.jpg"
res_dir = r"e:\Mobile\Bel Sekolah Otomatis\android\app\src\main\res"

sizes = {
    "mipmap-mdpi": (48, 48),
    "mipmap-hdpi": (72, 72),
    "mipmap-xhdpi": (96, 96),
    "mipmap-xxhdpi": (144, 144),
    "mipmap-xxxhdpi": (192, 192),
}

img = Image.open(src).convert("RGBA")

for folder, size in sizes.items():
    out_dir = os.path.join(res_dir, folder)
    os.makedirs(out_dir, exist_ok=True)
    resized = img.resize(size, Image.Resampling.LANCZOS)
    out_path = os.path.join(out_dir, "ic_launcher.png")
    resized.save(out_path, "PNG")
    print(f"Saved {out_path} ({size[0]}x{size[1]})")

# Simpan juga icon 512x512
play_icon = img.resize((512, 512), Image.Resampling.LANCZOS)
play_icon.save(os.path.join(r"e:\Mobile\Bel Sekolah Otomatis\android\app\src\main", "ic_launcher-playstore.png"), "PNG")
print("All launcher icons generated successfully!")
