import os
from PIL import Image
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


module_mapping = {}


def resolve_module(expression: str):
    if "/" in expression:
        file_name = expression
    else:
        file_name = expression.replace('.', '/') + '.lua'

    if file_name not in module_mapping:
        if not os.path.exists(file_name):
            raise Exception(f'Cannot find module {file_name}')

        if file_name.endswith('.png'):
            module_mapping[file_name] = ImageModule(file_name)
        else:
            module_mapping[file_name] = LuaModule(file_name)

        module_mapping[file_name].parse()
    
    return module_mapping[file_name]


main_module = resolve_module('aspe.init')

bundler_header = None

with open("bundler_header.lua") as bundler_header_file:
    bundler_header = bundler_header_file.read()


with open("C:\\Users\\david\\AppData\\Roaming\\Aseprite\\scripts\\aspe.lua", "w") as output:
    output.writelines([bundler_header] + [f"{module.to_scoped_source()}\n" for module in module_mapping.values()] + [f"__require__('{main_module.file_name}')"])
