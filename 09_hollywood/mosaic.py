# -*- coding: utf-8 -*-

# Description: generates a mosaic image
# Example usage:
#   python mosaic.py 50 25

import json
import math
import os
from PIL import Image
import sys

# input
if len(sys.argv) < 2:
    print "Usage: %s <cell width> <cells per row>" % sys.argv[0]
    sys.exit(1)
CELL_W = int(sys.argv[1])
CELLS_PER_ROW = int(sys.argv[2])
CELL_H = CELL_W

# config
movieFile = "data/top_10_movies_2006-2015.json"
imageFolder = "visualization/data/people/"
outputFile = "output/mosaic_%s_%s.jpg" % (CELL_W, CELLS_PER_ROW)

# init
movies = []
images = []

# load movies
with open(movieFile) as data_file:
    movies = json.load(data_file)

# load images
for m in movies:
    for p in m['people']:
        filename = "%s%s_%s.jpg" % (imageFolder, p['imdb_id'], p['movie_imdb_id'])
        images.append(filename)

print "Loaded %s images" % len(images)

# Create blank image
imageW = CELL_W * CELLS_PER_ROW
imageH = int(CELL_H * math.ceil(1.0 * len(images) / CELLS_PER_ROW))
print "Creating blank image at (%s x %s)" % (imageW, imageH)
imageBase = Image.new("RGB", (imageW, imageH), "black")

x = 0
y = 0
h = CELL_H
w = CELL_W
for fileName in images:

    try:
        im = Image.open(fileName)

        if x >= imageW:
            y += h
            x = 0

        im.thumbnail((CELL_W, CELL_H), Image.ANTIALIAS)
        imageBase.paste(im, (x, y))

        x += w

    except IOError:
        print "Cannot read file: " + fileName
    except:
        print "Unexpected error:", sys.exc_info()[0]
        raise

# Save image
print "Saving stiched image..."
imageBase.save(outputFile)
print "Saved image: %s" % outputFile
