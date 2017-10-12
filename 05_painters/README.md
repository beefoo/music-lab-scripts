Data-Driven DJ Track 5: Lee and Jackson
=================

You can listen to this track and read the full description [here](https://datadrivendj.com/tracks/painters).

## Software Required

All software required for making this song from scratch is free and open-source

* [ChucK](http://chuck.cs.princeton.edu/) - a programming language for real-time sound synthesis and music creation
* [Python](https://www.python.org/) - I am running version 2.7.3
* [Processing](https://processing.org/) - for image analysis and supporting visualization

## Instructions

### Prepare Sound And Configure Files

1. Create a paintings.csv file based on [paintings.csv.sample](data/paintings.csv.sample) file and place in folder `/data` - This file all the information about the paintings that will be analyzed
2. Create a events.csv file based on [events.csv.sample](data/events.csv.sample) file and place in folder `/data` - This file all the events that will show up in the timeline
3. Create a synesthesia.csv file based on [synesthesia.csv.sample](data/synesthesia.csv.sample) file and place in folder `/data` - This file contains the rules for mapping colors to musical notes
4. Create a instruments.csv file based on [instruments.csv.sample](data/instruments.csv.sample) file and place in folder `/data`
  * **File** is the filename of the instruments sound file
  * **Artist** is the name of the artist this instrument is associated with
  * **Size Min/Max** is the color space area range (0-100) this instrument is valid for
  * **Bri Min/Max** is the brightness range (0-100) this instrument is valid for
  * **Var Min/Max** is the color variance range (0-100) this instrument is valid for
  * **Year Min/Max** is the year range this instrument is valid for
  * **Note** is the note (on the chromatic scale) that this instrument is associated with (e.g. a, as, b, c, cs, etc)
  * **From Gain** and **To Gain** is the volume range this instrument can oscillate between. A value of 0 is silent.
  * **From Tempo** and **To Tempo** is the tempo range this instrument can oscillate bewteen. A value of 1 is standard BPM, 2 is twice as fast, 0.5 is twice as slow.
  * **Gain Phase** is the number of beats that represent a full phase of an instrument's gain range. For example, if the gain phase is 16, gain min is 0, and gain max is 1, it will take 16 beats to go from 0 gain to 1 gain back to 0 gain.
  * **Gain Tempo** is the number of beats that represent a full phase of an instrument's tempo range. For example, if the tempo phase is 16, tempo min is 1, and tempo max is 2, it will take 16 beats to go from a tempo of 1 to a tempo of 2 back to a tempo of 1.
  * **Interval Phase**, **Interval**, **Interval Offset** control at what intervals the instruments can play. For example, if interval phase is 16, interval is 2, and interval offset is 1, every 16 beats, the instrument can play on the 2nd half of the beats (8-16).
  * **Active** essentially activates or deactivates an instrument
5. Prepare all your sound files and place in folder `/instruments`. All files should be in .wav format. For best results, I'd recommend using very short clips (< 500ms).
6. Prepare all your images and place in folder `/analysis/data`. All files should be jpg or png, 300 dpi and 288px in height.

### Configure The Scripts

1. Processing script: [analysis/analysis.pde](analysis/analysis.pde)
  * **painting_segment_sample_size** is how many samples should be taken per painting
  * **color_radius_h/color_radius_s/color_radius_b** the hue/saturation/brightness sample radius
  * **msPerBeat** is the milliseconds per beat
  * **pxPerBeat** is the speed of the visualization (pixels per beat)
2. Python script: [painters.py](painters.py)
  * **BPM** is the song's beats per minute.
  * **PX_PER_BEAT** is pixels to move per beat.
  * **DIVISIONS_PER_BEAT** is how the beats are divided. For example, a value of 4 would create quarter-notes as the smallest unit, 8 would create eighth-notes, etc.
3. ChucK script: [painters.ck](painters.ck)
  * **padding** is the amount of milliseconds before and after the song.
  * **instrument_buffers** is the number of buffers each instrument has. If you hear clipping in your song, you will want to increase this number.
	* **start** is which millisecond you would like the song to start on. Useful for debugging a particular part of the song.

### Generating The Song

1. Open [analysis/analysis.pde](analysis/analysis.pde) in Processing. This script generates `data/painting_samples.csv`, which is the painting data that the subsequent scripts will use as data.
  * set `boolean SAVE_TABLE = true;` to output painting data
  * run script, this will generate the painting data and run a visualization of how the paintings were analyzed
1. Run `python painters.py` in the project's directory. This will generate two files that ChucK will use:
  * `data/ck_instruments.csv`: A manifest of instrument files
  * `data/ck_sequence.csv`: A sequence of instruments
2. Open up **painters.ck** in ChucK. You can either export the song to .ogg/.wav or start your VM and add a new shred

### Generating The Visualization

1. Open [visualization/visualization.pde](visualization/visualization.pde) in Processing. This script generates a visualization based on the painting data.
  * set `boolean captureFrames = true;` to output frames to output folder
  * run script, this will generate frames at the framerate (`fps`) in the configuration
