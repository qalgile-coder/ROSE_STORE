import os
from PIL import Image

# المسار الرئيسي لمجلد الصور في المشروع
base_dir = r"C:\QUSAY\ROSE_STORE-main"
source_image_path = os.path.join(base_dir, "assets", "images", "image.png")

if not os.path.exists(source_image_path):
    print(f"Error: Source image not found at {source_image_path}")
    exit()

img = Image.open(source_image_path)

# المقاسات القياسية لأيقونات أندرويد
sizes = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192
}

res_dir = os.path.join(base_dir, "android", "app", "src", "main", "res")

for folder, size in sizes.items():
    folder_path = os.path.join(res_dir, folder)
    if os.path.exists(folder_path):
        resized_img = img.resize((size, size), Image.Resampling.LANCZOS)
        
        # حفظ الأيقونة بالأسماء التي يعتمدها النظام
        for icon_name in ["launcher_icon.png", "ic_launcher.png"]:
            save_path = os.path.join(folder_path, icon_name)
            resized_img.save(save_path)
            print(f"Updated: {save_path} ({size}x{size})")

print("All icons updated successfully!")