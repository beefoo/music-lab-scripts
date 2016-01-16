Data-Driven DJ Track 7: Too Blue
=================

You can listen to this track and read the full description [here](https://datadrivendj.com/tracks/louisiana).

## Software Required

All software required for making this song from scratch is free and open-source

* [ChucK](http://chuck.cs.princeton.edu/) - a programming language for real-time sound synthesis and music creation
* [Python](https://www.python.org/) - I am running version 2.7.3
* [Processing](https://processing.org/) - for image analysis and supporting visualization

## Instructions

### Prepare Sound And Configure Files

1. Modify [years.csv](data/years.csv) - This file contains the date ranges and the referenced image for each year. Make sure all images are placed in directory [data/img](data/img)
4. Modify [instruments.csv](data/instruments.csv)
  * **File** is the filename of the instruments sound file
  * **Min/Max Loss** is the amount of land loss this instrument is valid for. This is a normalized number between 0 and 1.
  * **Min/Max C Loss** is the cumulative amount of land loss this instrument is valid for. This is a normalized number between 0 and 1.
  * **From Gain** and **To Gain** is the volume range this instrument can oscillate between. A value of 0 is silent.
  * **From Tempo** and **To Tempo** is the tempo range this instrument can oscillate bewteen. A value of 1 is standard BPM, 2 is twice as fast, 0.5 is twice as slow.
  * **Tempo Offset** is the offset as a percentage of the instruments tempo. For example if an instrument's tempo is 1 and the tempo offset is 0.5, the instrument will on the half beat.
  * **Interval Phase**, **Interval**, **Interval Offset** control at what intervals the instruments can play. For example, if interval phase is 16, interval is 2, and interval offset is 1, every 16 beats, the instrument can play on the 2nd half of the beats (8-16).
  * **Active** essentially activates or deactivates an instrument
5. Optionally modify [instruments_stretch.csv](data/instruments_stretch.csv) - This file contains a list of sound files you would like to stetch for use in the song
6. Prepare any new sound files and place in folder [instruments](instruments). All files should be in .wav format. For best results, I'd recommend using very short clips (< 500ms).
7. Prepare any new images and place in folder [data/img](data/img). All files should be jpg or png, 300 dpi.
8. Optionally run the [sound stretching script](https://github.com/beefoo/music-lab-scripts/blob/master/util/paulstretch.py) to generate your stretched sound files: `python paulstretch.py ../07_louisiana/data/instruments_stretch.csv ../07_louisiana/instruments/ ../07_louisiana/instruments/`

### Configure The Scripts

1. Python script: [lousiana.py](lousiana.py)
  * **BPM** is the song's beats per minute.
  * **PX_PER_BEAT** is pixels to move per beat.
  * **DIVISIONS_PER_BEAT** is how the beats are divided. For example, a value of 4 would create quarter-notes as the smallest unit, 8 would create eighth-notes, etc.
2. ChucK script: [lousiana.ck](lousiana.ck)
  * **padding** is the amount of milliseconds before and after the song.
  * **instrument_buffers** is the number of buffers each instrument has. If you hear clipping in your song, you will want to increase this number.
	* **start** is which millisecond you would like the song to start on. Useful for debugging a particular part of the song.

### Generating The Song

1. Open [analysis/analysis.pde](analysis/analysis.pde) in Processing and run. This script generates `data/land_loss.json` and `visualization/data/changes.json`, which is the land/loss data for the subsequent scripts to use.
2. Run `python louisiana.py` in the project's directory. This will generate two files that ChucK will use:
  * `data/ck_instruments.csv`: A manifest of instrument files
  * `data/ck_sequence.csv`: A sequence of instruments
3. Open up [louisiana.ck](louisiana.ck) in ChucK. You can either export the song to .ogg/.wav or start your VM and add a new shred

### Generating The Visualization

1. Open [visualization/visualization.pde](visualization/visualization.pde) in Processing. This script generates a visualization based on the land loss data.
  * set `boolean captureFrames = true;` to output frames to output folder
  * run script, this will generate frames at the framerate (`fps`) in the configuration
