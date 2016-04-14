Data-Driven DJ Track 9: Color Balance
=================

You can listen to this track and read the full description [here](https://datadrivendj.com/tracks/hollywood).

## Software Required

All software required for making this song from scratch is free and open-source

* [ChucK](http://chuck.cs.princeton.edu/) - a programming language for real-time sound synthesis and music creation
* [Python](https://www.python.org/) - I am running version 2.7.3
* [Processing](https://processing.org/) - for image analysis and supporting visualization

## Instructions

### Prepare Sound And Data

1. [top_10_movies_2006-2015.csv](data/top_10_movies_2006-2015.csv) contains the list of movies that should be analyzed
2. [top_10_movies_2011-2015_people.csv](data/top_10_movies_2011-2015_people.csv) contains the featured actors and actresses in those movies above
3. [races.json](data/races.json) contains the categories of race and ethnicity
4. [instruments.csv](data/instruments.csv) contains the sounds that will be used in the song
  * **File** is the filename of the instruments sound file
  * **POC** restrict instrument based on whether person is white (value: *0*), person of color (value: *1*), either (value: *-1*)
  * **Gender** restrict instrument based on gender: *m*, *f*, or *any*
  * **Race** restrict instrument based on race/ethnicity: White (*w*), Black (*b*), Hispanic/Latino (*h*), Asian/Pacific Islander (*a*), American Indian/Native (*o*), or *any*
  * **Min/Max Gender** restrict instrument based on gender diversity (0: least diverse, 1: most diverse)
  * **Min/Max POC** restrict instrument based on race/ethnicity diversity (0: least diverse, 1: most diverse)
  * **From Gain** and **To Gain** is the volume range this instrument can oscillate between. A value of 0 is silent.
  * **From Tempo** and **To Tempo** is the tempo range this instrument can oscillate bewteen. A value of 1 is standard BPM, 2 is twice as fast, 0.5 is twice as slow.
  * **Tempo Offset** is the offset as a percentage of the instruments tempo. For example if an instrument's tempo is 1 and the tempo offset is 0.5, the instrument will on the half beat.
  * **Interval Phase**, **Interval**, **Interval Offset** control at what intervals the instruments can play. For example, if interval phase is 16, interval is 2, and interval offset is 1, every 16 beats, the instrument can play on the 2nd half of the beats (8-16).
  * **Active** essentially activates or deactivates an instrument
5. Prepare any new sound files and place in folder [instruments](instruments). All files should be in .wav format. For best results, I'd recommend using very short clips (< 500ms).

### Configure The Scripts

1. Python script: [hollywood.py](hollywood.py)
  * **BPM** is the song's beats per minute.
  * **BEATS_PER_MOVIE** is number of beats that should play per movie
2. ChucK script: [hollywood.ck](hollywood.ck)
  * **padding** is the amount of milliseconds before and after the song.
  * **instrument_buffers** is the number of buffers each instrument has. If you hear clipping in your song, you will want to increase this number.
	* **start** is which millisecond you would like the song to start on. Useful for debugging a particular part of the song.

### Generating The Song

1. Run `python csv_to_json.py data/top_10_movies_2006-2015.csv data/top_10_movies_2006-2015_people.csv data/top_10_movies_2006-2015.json data/races.json` in the project's directory to generate the `data/top_10_movies_2006-2015.json` file that will be used to generate the song and visualization
2. Run `python hollywood.py` in the project's directory. This will generate two files that ChucK will use:
  * `data/ck_instruments.csv`: A manifest of instrument files
  * `data/ck_sequence.csv`: A sequence of instruments
3. Open up [hollywood.ck](hollywood.ck) in ChucK. You can either export the song to .ogg/.wav or start your VM and add a new shred

### Generating The Visualization

1. Open [visualization/visualization.pde](visualization/visualization.pde) in Processing. This script generates a visualization based on the data from the previous steps.
  * set `boolean captureFrames = true;` to output frames to output folder
  * run script, this will generate frames at the framerate (`fps`) in the configuration
