# -*- coding: utf-8 -*-

# Usage: python remove_unused_files.py ../08_body/data/instruments.csv ../08_body/instruments/

import csv
import glob
import os
import pprint
import sys

if len(sys.argv) < 2:
    print ("Usage: "+sys.argv[0]+" <inputfile> <inputdir>")
    sys.exit(1)

INPUT_FILE = sys.argv[1]
INPUT_DIR = sys.argv[2]

all_files = glob.glob(INPUT_DIR + "*.wav")
remove_files = []
valid_files = []

with open(INPUT_FILE, 'rb') as f:
    r = csv.reader(f, delimiter=',')
    header = next(r, None)
    file_index = 0
    for i, h in enumerate(header):
        if h == 'file':
            file_index = i
            break
    for row in r:
        valid_files.append(row[file_index])

for f in all_files:
    filename = f.split('/')[-1]
    if filename not in valid_files:
        remove_files.append(f)

print "Removing files..."
# pprint.pprint(remove_files)

for f in remove_files:
    print "Removing " + f
    os.remove(f)
