from PIL import Image

src = r"c:\product\tickets_album\flutter_application_1\assets\usa_map.png"
dst = r"c:\product\tickets_album\flutter_application_1\assets\usa_map_ocean.png"

img = Image.open(src).convert("RGBA")
pixels = img.load()
w, h = img.size

ocean = (70, 130, 180, 255)  # steel sea blue
changed = 0

for y in range(h):
    for x in range(w):
        r, g, b, a = pixels[x, y]
        if a > 200 and r >= 245 and g >= 245 and b >= 245:
            pixels[x, y] = ocean
            changed += 1
        elif (
            a > 200
            and r >= 235
            and g >= 235
            and b >= 235
            and min(r, g, b) >= 230
            and abs(r - g) < 8
            and abs(g - b) < 8
        ):
            pixels[x, y] = ocean
            changed += 1

img.save(dst, "PNG")
print(f"saved {dst}")
print(f"pixels changed: {changed} / {w * h}")
