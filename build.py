import os
from zipfile import ZipFile
from PIL import Image, ImageFont, ImageDraw
from luaparser import ast


class LuaModule(ast.ASTVisitor):
    def __init__(self, file_name):
        super().__init__()

        self.requires = []
        self.file_name = file_name
        
    
    def parse(self):
        with open(self.file_name) as source:
            self.source = source.read()
            tree = ast.parse(self.source)
            self.visit(tree)

    def visit_Call(self, node):
        if isinstance(node.func, ast.Name) and node.func.id == 'require':
            self.requires.append({
                "module": resolve_module(node.args[0].s),
                "node": node,
                "expression": self.source[node.start_char:node.stop_char + 1]
            })
            
    def to_scoped_source(self):
        source = self.source

        for require in self.requires:
            file_name = require["module"].file_name
            source = source.replace(require["expression"], f"__require__('{file_name}')")

        return f"__define__('{self.file_name}', function ()\n{source}\nend)\n"


class ImageModule:
    def __init__(self, file_name):
        self.file_name = file_name    

    def parse(self):
        with Image.open(self.file_name) as image:
            null_pixel = image.getpixel((0, 0))
            self.pixels = [[0 if image.getpixel((x, y)) == null_pixel else 1 for x in range(image.width)] for y in range(image.height)]

    def format_pixels_row(self, pixels_row):
        return "{" +  ",".join([str(value) for value in pixels_row]) + "}"

    def format(self):
        return "{" + ",".join([self.format_pixels_row(pixels_row) for pixels_row in self.pixels]) + "}"

    def to_scoped_source(self):
        return f"__define__('{self.file_name}', function ()\nreturn {self.format()}\nend)\n"


class FontModule(ImageModule):
    def __init__(self, file_name, char, size):
        self.file_name = f'{file_name}@{char},{size}'
        self.base_file_name = file_name
        self.char = char
        self.size = int(size)

    def parse(self):
        font = ImageFont.truetype(self.base_file_name, self.size)
        left, top, right, bottom = font.getbbox(self.char)
        width = right - left
        height = bottom - top
        image = Image.new(mode='RGB', size=(width, height))
        draw = ImageDraw.Draw(image)
        draw.rectangle([(0, 0), (width, height)], fill=(255, 255, 255, 255))
        draw.text((-left, -top), self.char, font=font, fill=(0, 0, 0, 255))
        self.pixels = [[image.getpixel((x, y))[0] for x in range(image.width)] for y in range(image.height)]


module_mapping = {}


def resolve_module(expression: str):
    include_expression, args_str = expression.split('@') if '@' in expression else (expression, '')

    args = args_str.split(',')

    if "/" in include_expression:
        file_name = include_expression
    else:
        file_name = include_expression.replace('.', '/') + '.lua'

    if file_name not in module_mapping:
        if not os.path.exists(file_name):
            raise Exception(f'Cannot find module {file_name}')

        if file_name.endswith('.png'):
            module_mapping[expression] = ImageModule(file_name)
        elif file_name.endswith('.ttf'):
            module_mapping[expression] = FontModule(file_name, *args)
        else:
            module_mapping[expression] = LuaModule(file_name)

        module_mapping[expression].parse()
    
    return module_mapping[expression]


main_module = resolve_module('aspe.plugin')
bundler_header = None

with open("bundler_header.lua") as bundler_header_file:
    bundler_header = bundler_header_file.read()

with open("dist/aspe.lua", "w") as output:
    output.writelines([bundler_header] + [f"{module.to_scoped_source()}\n" for module in module_mapping.values()] + [f"__require__('{main_module.file_name}')"])

with ZipFile('stitch-patterns-exporter.aseprite-extension', 'w') as myzip:
    myzip.write('dist/package.json')
    myzip.write('dist/aspe.lua')
