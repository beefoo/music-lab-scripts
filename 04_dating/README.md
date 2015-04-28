Data-Driven DJ Track 4: Mixed Attraction
=================

You can listen to this track and read the full description [here](https://datadrivendj.com/tracks/dating).

## Software Required

All software required for making this song from scratch is free and open-source

* [ChucK](http://chuck.cs.princeton.edu/) - a programming language for real-time sound synthesis and music creation
* [Python](https://www.python.org/) - I am running version 2.7.3
* [Processing](https://processing.org/) - optional, for supporting visualization

## Instructions

### Prepare Sound And Configure Files

1. Create a pairs.csv file based on [pairs.csv.sample](data/instruments.csv.sample) file and place in folder `/data` - This file contains the data found in OkCupid's article [Race and Attraction, 2009 – 2014](http://blog.okcupid.com/index.php/race-attraction-2009-2014/)
2. Create a instruments.csv file based on [instruments.csv.sample](data/instruments.csv.sample) file and place in folder `/data`
  * **File** is the filename of the instruments sound file
  * **F/M/T Attr Min/Max** is the female/male/combined attraction value range the instrument is allowed to play in. This value is normalized between 0 and 1.
  * **Max Rvb** is the maximum reverb value of the instrument. A value of 0 is no reverb.
  * **Gain** is the volume of the instrument. A value of 0 is silent.
  * **Tempo** is the tempo relative to the song's BPM. A value of 1 is standard BPM, 2 is twice as fast, 0.5 is twice as slow.
  * **Tempo Offset** is the offset as a percentage of the instruments tempo. For example if an instrument's tempo is 1 and the tempo offset is 0.5, the instrument will on the half beat.
  * **Interval Phase**, **Interval**, **Interval Offset** control at what intervals the instruments can play. For example, if interval phase is 16, interval is 2, and interval offset is 1, every 16 beats, the instrument can play on the 2nd half of the beats (8-16).
  * **Active** essentially activates or deactivates an instrument
3. Prepare all your sound files and place in folder `/instruments`. All files should be in .wav format. For best results, I'd recommend using very short clips (< 500ms).
  
### Configure The Scripts

1. Python script: [dating.py](dating.py)
  * **BPM** is the song's beats per minute.
  * **BEATS_PER_PAIR** is the number of beats each pair's year has.
  * **DIVISIONS_PER_BEAT** is how the beats are divided. For example, a value of 4 would create quarter-notes as the smallest unit, 8 would create eighth-notes, etc.
2. ChucK script: [dating.ck](dating.ck)
  * **padding** is the amount of milliseconds before and after the song.
  * **instrument_buffers** is the number of buffers each instrument has. If you hear clipping in your song, you will want to increase this number.
	* **start** is which millisecond you would like the song to start on. Useful for debugging a particular part of the song.

### Generating The Song

1. Run `python dating.py` in the project's directory. This will generate two files that ChucK will use:
  * `data/ck_instruments.csv`: A manifest of instrument files
  * `data/ck_sequence.csv`: A sequence of instruments
2. Open up **dating.ck** in ChucK. You can either export the song to .ogg/.wav or start your VM and add a new shred

### Generating The Visualization

1. Open [visualization/visualization.pde](visualization/visualization.pde) in Processing. This script generates a visualization based on the attraction data.
  * this script uses data (pairs.json) generated from previous python script
  * set `boolean captureFrames = true;` to output frames to output folder
  * run script, this will generate frames at the framerate (`fps`) in the configuration
