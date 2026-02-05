from PIL import Image

# Load and resize image to 1024x768
img = Image.open("SourceImage4.jpg").convert("RGB").resize((640, 480))

with open("../Quartus/SourceImage4.hex", "w") as f:
    for y in range(480):
        for x in range(640):
            r, g, b = img.getpixel((x, y))
            f.write(f"{r:02X}{g:02X}{b:02X}\n")
