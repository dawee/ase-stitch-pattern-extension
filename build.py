from PIL import Image

ICONS_COUNT = 20

icons = []

for icon_index in range(20):
    with Image.open(f"stitch_icons/{icon_index + 1}.png") as icon:
        null_pixel = icon.getpixel((0, 0))
        icons.append([[0 if icon.getpixel((x, y)) == null_pixel else 1 for x in range(icon.width)] for y in range(icon.height)])


def format_icon_row(icon_row):
    return "{" +  ",".join([str(value) for value in icon_row]) + "}"

def format_icon(icon):
    return "{" + ",".join([format_icon_row(icon_row) for icon_row in icon]) + "}"


with open("C:\\Users\\david\\AppData\\Roaming\\Aseprite\\scripts\\aspe.lua", "w") as output_script:
    output_script.writelines(["local icons = {\n"] + [f"    {format_icon(icon)},\n" for icon in icons] + ["}\n"])
    with open("aspe/init.lua") as src:
        output_script.writelines(src.readlines())
