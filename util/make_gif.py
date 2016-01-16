# -*- coding: utf-8 -*-

# Usage: python make_gif.py ../08_body/visualization/output/frames/ ../08_body/visualization/output/frames.gif 512 288 260 460 30 0.1

from images2gif import writeGif
import os
from PIL import Image
import pprint
import sys

if len(sys.argv) < 8:
    print ('Usage: '+sys.argv[0]+' <input dir> <output file> <resize to w> <resize to h> <start frame> <end frame> <max frames> <duration per frame in seconds>')
    sys.exit(1)

# Input
INPUT_DIR = sys.argv[1]
OUTPUT_FILE = sys.argv[2]
RESIZE_W = int(sys.argv[3])
RESIZE_H = int(sys.argv[4])
START_FRAME = int(sys.argv[5])
END_FRAME = int(sys.argv[6])
MAX_FRAMES = int(sys.argv[7])
DURATION = float(sys.argv[8])

# Config
FRAME_NUMBER_PADDING = '5'
FRAME_FORMAT = 'png'

# Init
frame_step = 1
frames = END_FRAME - START_FRAME
if (END_FRAME - START_FRAME) > MAX_FRAMES:
    frame_step = 1.0 * (END_FRAME - START_FRAME) / MAX_FRAMES
    frames = MAX_FRAMES
sequence = []

current_frame = 1.0 * START_FRAME
for i in range(frames):
    # round to nearest frame
    f = int(round(current_frame))

    # ensure we end on the end frame
    if i >= frames-1 or f > END_FRAME:
        f = END_FRAME

    # open file
    fileName = INPUT_DIR + 'frames-' + format(f, '0'+FRAME_NUMBER_PADDING) + '.' + FRAME_FORMAT
    print 'Adding ' + fileName
    im = Image.open(fileName)
    im.thumbnail((RESIZE_W, RESIZE_H), Image.NEAREST)
    sequence.append(im)

    # go to next frame
    current_frame += frame_step
    if f >= END_FRAME:
        break

writeGif(OUTPUT_FILE, sequence, duration=DURATION, dither=0)
print 'Successfully created gif: ' + OUTPUT_FILE
