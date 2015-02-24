##
# This file takes raw data from the U.S. Department of State Air Quality Monitoring Program (http://www.stateair.net/web/historical/1/1.html)
# and creates a normalized CSV file for the main script (smog.py) to use
##

# Library dependancies
import csv
import json
import math
import os

INPUT_DIR = 'data/raw'
OUTPUT_FILE = 'data/pm25_readings.csv'
GROUP_BY = 'yyyy-mm-dd' # options: yyyy, yyyy-mm, yyyy-mm-dd, yyyy-mm-dd hh:mm
WRITE_FILE = True

pm25_readings = []
min_value = None
max_value = None

# Mean of list
def mean(data):
    if iter(data) is data:
			data = list(data)
    n = len(data)
    if n < 1:
			return 0
    else:
			return sum(data)/n
			
def addData(group, data):
	global pm25_readings
	global min_value
	global max_value	
	group_value = mean(data)					
	if group_value < min_value or min_value is None:
		min_value = group_value
	if group_value > max_value or max_value is None:
		max_value = group_value				
	pm25_readings.append({
		'date': group,
		'value': group_value
	})

# Retrieve files in directory
for file in os.listdir(INPUT_DIR):
	# Read data from file
	with open(INPUT_DIR + '/' + file, 'rb') as f:
		r = csv.reader(f, delimiter=',')
		current_group = None
		queue = []
		# remove intro lines and header
		for skip in range(4):
			next(r, None)
		for _site,_parameter,_date,_year,_month,_day,_hour,_value,_unit,_duration,_qc in r:
			value = int(_value)
			date_group = _date[:len(GROUP_BY)]
			if value >= 0:				
				if current_group is None:
					current_group = date_group
					queue.append(value)
				elif current_group != date_group:
					addData(current_group, queue)
					queue = []
					current_group = date_group
				else:
					queue.append(value)
		if len(queue) > 0:
			addData(current_group, queue)

# Sort list
pm25_readings = sorted(pm25_readings, key=lambda k: k['date'])
readings_count = len(pm25_readings)

# Write PM2.5 data to csv
if WRITE_FILE:
	with open(OUTPUT_FILE, 'wb') as f:
		w = csv.writer(f)
		w.writerow(['Date','PM2.5 Value'])
		w.writerow(['Min', min_value])
		w.writerow(['Max', max_value])
		w.writerow(['Count', readings_count])
		for reading in pm25_readings:
			w.writerow([reading['date'], reading['value']])
		f.seek(-2, os.SEEK_END) # remove newline
		f.truncate()
		print('Successfully wrote '+str(readings_count)+' rows PM2.5 data to file: '+OUTPUT_FILE)

