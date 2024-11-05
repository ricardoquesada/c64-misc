# Copyright 2024 - Ricardo Quesada
from PIL import Image
import argparse
import sys

# Pixels are not square in PAL:
# https://hitmen.c02.at/temp/palstuff/
# Aspect ratio: 0,936:1
PIXEL_WIDTH = 10
PIXEL_HEIGHT = round(PIXEL_WIDTH * (1 / 0.936))

# key: color
# value: lists of neighboring pixels
pixel_groups = {}

image_pixels = []

# set of visited pixels
visited_pixels = set()


def rotate_left_list(lst, n):
    """Rotates a list by n positions to the left.

    Args:
        lst: The list to rotate.
        n: The number of positions to rotate.

    Returns:
        The rotated list.
    """

    n = n % len(lst)
    return lst[n:] + lst[:n]


def is_valid_and_has_color(image, x, y, color):
    """
   Returns whether the pixel in x,y contains color "color"  and was not visited.
    Args:
        image:
        x:
        y:
        color:

    Returns:
    """
    if x < 0 or x >= len(image) or y < 0 or y >= len(image[0]) or image[x][y] != color:
        return None

    if (x, y) in visited_pixels:
        return False

    return True


def flood_fill(image, x, y, color, pixels, prev_offset):
    """
    Recursively fills a contiguous region of pixels with a new color.

    Args:
        image: A 2D array representing the image.
        x: The x-coordinate of the seed pixel.
        y: The y-coordinate of the seed pixel.
        color: The new color to fill the region with.
        pixels: The original color of the region to be filled.
        prev_offset: The offset used by callee function
    """

    if x < 0 or x >= len(image) or y < 0 or y >= len(image[0]) or image[x][y] != color:
        return None

    if (x, y) in visited_pixels:
        return None

    visited_pixels.add((x, y))

    pixels.append((x, y))

    # Parse diagonals as well. Clockwise (or counter-clockwise), but important to do it "contiguous".
    offsets = [
        (-1, -1), (0, -1),
        (1, -1), (1, 0),
        (1, 1), (0, 1),
        (-1, 1), (-1, 0)
    ]

    # The offsets are rotated to simulate a "fill from the edges" to prevent jump-stitches as much as possible.
    # Does not yield the possible result, but good enough
    # Prev offset should be the reverse. If it comes from the left, start with an offset pointing to the right
    inv_offset = (-prev_offset[0], -prev_offset[1])
    while inv_offset != offsets[0]:
        offsets = rotate_left_list(offsets, 1)

    for index, offset in enumerate(offsets):
        off_x, off_y = offset
        is_diagonal = (off_x + off_y) % 2 == 0
        # There are 8 possible offsets. The inverse of the current one is at position 4.
        # The previous, is at 3. And we treat that diagonal as a special case. That diagonal should
        # be skipped if there is a valid pixel in front of us. This avoids a possible jump stitch.
        if index == 3 and is_diagonal:
            valid_next_element = is_valid_and_has_color(image, x + prev_offset[0], y + prev_offset[1], color)
            if valid_next_element:
                # skip diagonal, and go straight. The diagonal will calculated in the next-next flood-fill.
                continue
        # print(f'index {len(visited_pixels)}, coord: {x, y}, prev: {prev_offset}, next:{offset}, offsets:{offsets}')
        flood_fill(image, x + off_x, y + off_y, color, pixels, offset)


def group_pixels(image, width, height):
    for x in range(width):
        for y in range(height):
            if image[x][y] == -1:
                continue
            pixels = []
            flood_fill(image, x, y, image[x][y], pixels, (1, 0))
            if len(pixels) > 0:
                color = image[x][y]
                if color not in pixel_groups:
                    pixel_groups[color] = []
                pixel_groups[color].append(pixels)


def write_to_svg(output_path, hoop_size):
    with open(output_path, "w") as f:
        f.write('<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n')
        f.write(f'<svg '
                f'width="{hoop_size[0]}in" height="{hoop_size[1]}in" version="1.1" id="{output_path}" '
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
                    f.write(f'<rect x="{x * PIXEL_WIDTH}" y="{y * PIXEL_HEIGHT}" '
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


def create_svg_from_png(image_path, output_path, hoop_size):
    """
    Creates an SVG file from a PNG image, representing each pixel as a rectangle.

    Args:
        image_path: The path to the PNG image.
        output_path: The path to save the generated SVG file.
        hoop_size: Tuple that defines the hoop size in inches.
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
    write_to_svg(output_path, hoop_size)


def main():
    parser = argparse.ArgumentParser(
        description="Convert a PNG image to an SVG file.")
    parser.add_argument("input_image", help="Path to the input PNG image.")
    parser.add_argument("output_svg", help="Path to save the output SVG file.")
    parser.add_argument("-s", "--hoop_size", metavar="WIDTHxHEIGHT",
                        help="Hoop size in the format WIDTHxHEIGHT in inches (e.g., 5x7)")
    args = parser.parse_args()

    if args.hoop_size:
        try:
            width, height = map(int, args.hoop_size.split('x'))
            hoop_size = (width, height)
        except ValueError:
            print("Invalid hoop size format. Use WIDTHxHEIGHT (e.g., 5x7)")
            sys.exit(1)
    else:
        hoop_size = (5, 7)

    create_svg_from_png(args.input_image, args.output_svg, hoop_size)


if __name__ == "__main__":
    main()
