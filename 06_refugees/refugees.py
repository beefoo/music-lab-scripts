##
# TRACK 6
# REFUGEES
# Brian Foo (brianfoo.com)
# This file builds the sequence file for use with ChucK from the data supplied
##

# Library dependancies
import csv
import json
import math
import os
import time

REFUGEES_INPUT_FILE = 'data/refugees_processed.csv'
VISUALIZATION_OUTPUT_FILE = 'visualization/data/years_refugees.json'

WRITE_VIS = True

MS_PER_YEAR = 6000
REFUGEE_UNIT = 100000
START_YEAR = 1983
STOP_YEAR = 2012

country_codes = []
countries = []
refugees = []
years = []

# For creating pseudo-random numbers
def halton(index, base):
	result = 0.0
	f = 1.0 / base
	i = 1.0 * index
	while(i > 0):
		result += f * (i % base)	
		i = math.floor(i / base)
		f = f / base
	return result

# Read refugees from file
with open(REFUGEES_INPUT_FILE, 'rb') as f:
	lines = csv.reader(f, delimiter=',')
	next(lines, None) # remove header
	for origin,count,angle,origin_y,origin_x,year,asylum_x,asylum_y,asylum,distance in lines:
		year = int(year)
		if year >= START_YEAR and year <= STOP_YEAR:
			refugees.append({
				'origin': origin,
				'asylum': asylum,
				'count': int(count),
				'year': year,
				'origin_x': float(origin_x),
				'origin_y': float(origin_y),
				'asylum_x': float(asylum_x),
				'asylum_y': float(asylum_y),
				'distance': float(distance),
				'angle': float(angle)
			})

# Calc min/max
min_refugees = min([r['count'] for r in refugees])
max_refugees = max([r['count'] for r in refugees])
min_year = min([r['year'] for r in refugees])
max_year = max([r['year'] for r in refugees])

# Normalize data
for i,r in enumerate(refugees):
	refugees[i]['count_n'] = (1.0 * r['count'] - min_refugees) / (max_refugees - min_refugees)

# Report stats
print(str(max_year-min_year) + ' years: [' + str(min_year) + ',' + str(max_year) + ']')
print('Refugees range: [' + str(min_refugees) + ',' + str(max_refugees) + ']')

# Group by years
current_year = None
for r in refugees:
	if r['year'] != current_year:
		year = {
			'year': r['year'],
			'refugees': [r.copy()]
		}
		years.append(year)
		current_year = r['year']
	else:
		years[-1]['refugees'].append(r.copy())

# Report year stats
ms = 0
for i,y in enumerate(years):
	years[i]['max_distance'] = max([r['distance'] for r in y['refugees']])
	years[i]['start_ms'] = ms
	years[i]['stop_ms'] = ms + MS_PER_YEAR
	# Normalize distances
	for j,r in enumerate(y['refugees']):
		years[i]['refugees'][j]['year_distance_n'] = 1.0 * r['distance'] / years[i]['max_distance']
	ms += MS_PER_YEAR
	# print(str(y['year']) + ': ' + str(len(y['refugees'])) + ', ' + str(sum([r['count'] for r in y['refugees']])))

# Build visualization data
vis_data = []
for y in years:
	year = {
		'y': y['year'],
		'ms0': y['start_ms'],
		'ms1': y['stop_ms'],
		'r': []
	}
	h = 0
	for i,r in enumerate(y['refugees']):
		count = r['count']
		while count > 0:
			wavelength = halton(h, 3)
			year['r'].append({
				'ms0': y['start_ms'],
				'ms1': min([y['start_ms'] + r['year_distance_n'] * MS_PER_YEAR + wavelength * MS_PER_YEAR * 0.5, y['stop_ms']]),
				'x1': r['origin_x'],
				'y1': r['origin_y'],
				'x2': r['asylum_x'],
				'y2': r['asylum_y'],
				'd': r['distance'],
				'c': r['count_n'],
				'w': wavelength
			})
			count -= REFUGEE_UNIT
			h+=1
	vis_data.append(year)

if WRITE_VIS and len(vis_data)>0:
	with open(VISUALIZATION_OUTPUT_FILE, 'w') as outfile:
		json.dump(vis_data, outfile)
	print('Successfully wrote to JSON file: '+VISUALIZATION_OUTPUT_FILE)
