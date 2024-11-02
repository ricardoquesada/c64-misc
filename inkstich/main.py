from PIL import Image
import sys

PIXEL_WIDTH = 8
PIXEL_HEIGHT = 8

# key: color
# value: lists of neighboring pixels
pixel_groups = {}

image_pixels = []

# set of visited pixels
visited_pixels = set()


def flood_fill(image, x, y, color, pixels):
    """
    Recursively fills a contiguous region of pixels with a new color.

    Args:
        image: A 2D array representing the image.
        x: The x-coordinate of the seed pixel.
        y: The y-coordinate of the seed pixel.
        color: The new color to fill the region with.
        pixels: The original color of the region to be filled.
    """

    if x < 0 or x >= len(image) or y < 0 or y >= len(image[0]) or image[x][y] != color:
        return None

    if (x, y) in visited_pixels:
        return None

    visited_pixels.add((x, y))

    pixels.append((x, y))

    flood_fill(image, x + 1, y, color, pixels)
    flood_fill(image, x - 1, y, color, pixels)
    flood_fill(image, x, y + 1, color, pixels)
    flood_fill(image, x, y - 1, color, pixels)


def group_pixels(image, width, height):
    for x in range(width):
        for y in range(height):
            if image[x][y] == -1:
                continue
            pixels = []
            flood_fill(image, x, y, image[x][y], pixels)
            if len(pixels) > 0:
                color = image[x][y]
                if color not in pixel_groups:
                    pixel_groups[color] = []
                pixel_groups[color].append(pixels)


def write_to_svg(output_path):
    with open(output_path, "w") as f:
        f.write('<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n')
        f.write(f'<svg '
                f'width="4in" height="4in" version="1.1" id="{output_path}" '
                'xmlns:svg="http://www.w3.org/2000/svg" '
                'xmlns:inkstitch="http://inkstitch.org/namespace" '
                '>\n')

        f.write('<g id="image">\n')
        for color in pixel_groups:
            f.write(f'<!-- color #{color:06x} -->\n')

            it = 0
            for pixels in pixel_groups[color]:
                # pixels is [(1,0), (1,2)], [(3,4), (3,5)]
                f.write(f'<g id="layer_{color:06x}_{it}" inkscape:label="pixel_{color:06x}_{it}">\n')
                for pixel in pixels:
                    # pixel is (1,2)
                    x, y = pixel
                    angle = 0 if ((x + y) % 2 == 0) else 90
                    f.write(f'<rect x="{x * PIXEL_HEIGHT}" y="{y * PIXEL_HEIGHT}" '
                            f'width="{PIXEL_WIDTH}" height="{PIXEL_HEIGHT}" '
                            f'fill="#{color:06x}" '
                            f'id="pixel_{x}_{y}" '
                            f'style="display:inline;stroke:none" '
                            f'inkstitch:angle="{angle}" '
                            '/>\n')

                f.write(f'</g>\n')
                it = it + 1
        f.write('</g>\n')
        f.write('</svg>\n')


def create_svg_from_png(image_path, output_path):
    """
    Creates an SVG file from a PNG image, representing each pixel as a rectangle.

    Args:
        image_path: The path to the PNG image.
        output_path: The path to save the generated SVG file.
    """

    img = None
    try:
        img = Image.open(image_path)
    except FileNotFoundError:
        print(f"Error: Image file not found at {image_path}")
    except Exception as e:
        print(f"An error occurred: {e}")

    img = img.convert("RGBA")
    width, height = img.size

    image = [[-1 for _ in range(height)] for _ in range(width)]

    # Put all pixels in dictionary
    for y in range(height):
        for x in range(width):
            r, g, b, a = img.getpixel((x, y))
            if a != 255:
                # Skip transparent pixels
                continue
            color = (r << 16) + (g << 8) + b
            image[x][y] = color
    # Group the ones that are touching/same-color together
    group_pixels(image, width, height)
    write_to_svg(output_path)



if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <input_image.png> <output.svg>")
        sys.exit(1)

    image_path = sys.argv[1]
    output_path = sys.argv[2]
    create_svg_from_png(image_path, output_path)
