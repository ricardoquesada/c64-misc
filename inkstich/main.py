from PIL import Image
import sys

PIXEL_WIDTH = 8
PIXEL_HEIGHT = 8

def create_svg_from_png(image_path, output_path):
    """
    Creates an SVG file from a PNG image, representing each pixel as a rectangle.

    Args:
        image_path: The path to the PNG image.
        output_path: The path to save the generated SVG file.
    """
    try:
        img = Image.open(image_path)
        img = img.convert("RGBA")
        width, height = img.size

        with open(output_path, "w") as f:
            f.write('<?xml version="1.0" encoding="UTF-8" standalone="no"?>')
            f.write(f'<svg '
                    f'width="4in" height="4in" version="1.1" id="{output_path}" '
                    'xmlns:svg="http://www.w3.org/2000/svg" '
                    'xmlns:inkstitch="http://inkstitch.org/namespace" '
                    '/>\n')
            f.write(f'<g id="layer1" inkscape:label="pixels">\n')
            for y in range(height):
                for x in range(width):
                    r, g, b, a = img.getpixel((x, y))
                    if a != 255:
                        # Skip transparent pixels
                        continue
                    angle = 0 if ((x+y) % 2 == 0) else 90
                    f.write(f'<rect x="{x*PIXEL_HEIGHT}" y="{y*PIXEL_HEIGHT}" '
                            f'width="{PIXEL_WIDTH}" height="{PIXEL_HEIGHT}" '
                            f'fill="rgb({r},{g},{b})" '
                            f'id="pixel_{x}_{y}" '
                            f'style="display:inline;stroke:none" '
                            f'inkstitch:angle="{angle}" '
                            '/>\n')

            f.write(f'</g>')
            f.write('</svg>')

    except FileNotFoundError:
        print(f"Error: Image file not found at {image_path}")
    except Exception as e:
        print(f"An error occurred: {e}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <input_image.png> <output.svg>")
        sys.exit(1)

    image_path = sys.argv[1]
    output_path = sys.argv[2]
    create_svg_from_png(image_path, output_path)
