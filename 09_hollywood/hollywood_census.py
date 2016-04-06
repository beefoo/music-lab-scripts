# -*- coding: utf-8 -*-

# Library dependancies
import csv
import json
import math
import os
import sys

# Files
MOVIES_INPUT_FILE = 'data/top_10_movies_2006-2015.json'
CENSUS_INPUT_FILE = 'data/census_2014.json'
REPORT_OUTPUT_FILE = 'data/hollywood_census_report.csv'

# Init
races = []
people = []
census = []
hollywood = []

# Read movies from file
with open(MOVIES_INPUT_FILE) as data_file:
    movies = json.load(data_file)
    for m in movies:
        for p in m["people"]:
            for race in p["races"]:
                people.append({
                    "race": race,
                    "gender": p["gender"]
                })

# Read census from file
with open(CENSUS_INPUT_FILE) as data_file:
    census = json.load(data_file)

# Generate hollywood numbers
for category in census:
    hollywood.append({
        "label": category["label"],
        "gender": category["gender"],
        "race": category["race"],
        "value": len([p for p in people if p["race"]==category["race"] and p["gender"]==category["gender"]])
    })

with open(REPORT_OUTPUT_FILE, 'wb') as f:
    w = csv.writer(f)
    w.writerow(['', 'Census', 'Hollywood', 'Difference'])
    census_total = sum([c['value'] for c in census])
    hollywood_total = sum([c['value'] for c in hollywood])
    for c in census:
        c_value = 1.0 * c["value"] / census_total * 100
        h =  next(iter([h for h in hollywood if h["gender"]==c["gender"] and h["race"]==c["race"]]), None)
        h_value = 1.0 * h["value"] / hollywood_total * 100
        w.writerow([c["label"], c_value, h_value, h_value - c_value])
    print "Successfully wrote report to file: %s" % REPORT_OUTPUT_FILE
