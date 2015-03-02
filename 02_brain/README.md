Data-Driven DJ Track 2: Rhapsody In Grey
=================

You can listen to this track and read the full description [here](https://datadrivendj.com/tracks/brain).

## Software Required

All software required for making this song from scratch is free and open-source

* [ChucK](http://chuck.cs.princeton.edu/) - a programming language for real-time sound synthesis and music creation
* [Python](https://www.python.org/) - I am running version 2.7.3
* [Processing](https://processing.org/) - optional, for supporting visualization

## Instructions

### Select And Process Data

1. Download an .edf file from [PhysioNet](http://www.physionet.org/pn6/chbmit/). In my piece, I selected [chb01_15.edf](http://www.physionet.org/pn6/chbmit/chb01/chb01_15.edf), which is the fifteenth hour of the [first patient's session](http://www.physionet.org/pn6/chbmit/chb01/). Files that contain seizures are marked with .seizures. You can also look at a patient's [summary file](http://www.physionet.org/pn6/chbmit/chb01/chb01-summary.txt) for more details about when the seizures occur.
2. Open the file [preprocess_data.py](preprocess_data.py) and update the config at the top:
  * **INPUT_FILE**: the file that you downloaded from the previous step
  * **SEIZURE_START/SEIZURE_END**: when the seizure starts/ends in seconds (found in the patient's [summary file](http://www.physionet.org/pn6/chbmit/chb01/chb01-summary.txt))
  * **SONG_START/SONG_END**: when the song starts/ends; the song should start before the seizure start and end after the seizure end
3. Run `python preprocess_data.py` from the command line in this directory
4. This generates `data/eeg.csv` which will be used to generate your song later steps

### Prepare Sound And Configure Files

1. Create a tab-delimited instruments.csv file based on [instruments.csv.sample](data/instruments.csv.sample) file and place in folder `/data`
  * **Channel** is the electrode associated with this instrument. A value of "all" will be applied to all channels
  * **Amp Min** and **Amp Max** are the amplitude range the instrument is allowed to play in. This value is normalized between 0 and 1.
	* **Freq Min** and **Freq Max** are the frequency range the instrument is allowed to play in. This value is normalized between 0 and 1.
	* **Sync Min** and **Sync Max** are the syncrony range the instrument is allowed to play in. This value is normalized between 0 and 1.
  * **File** is the filename of the instruments sound file
  * **From Gain** and **To Gain** is the volume range this instrument can oscillate between. A value of 0 is silent.
  * **Tempo** is the relative tempo of the instrument. A value of 1 is standard BPM, 2 is twice as fast, 0.5 is twice as slow.
  * **Tempo Offset** is the offset as a percentage of the instruments tempo. For example if an instrument's tempo is 1 and the tempo offset is 0.5, the instrument will on the half beat.
  * **Interval Phase**, **Interval**, **Interval Offset** control at what intervals the instruments can play. For example, if interval phase is 16, interval is 2, and interval offset is 1, every 16 beats, the instrument can play on the 2nd half of the beats (8-16).
  * **Active** essentially activates or deactivates an instrument
2. Prepare all your sound files and place in folder `/instruments`. All files should be in .wav format. For best results, I'd recommend using very short clips (< 500ms).

### Configure The Scripts

1. Python script: [brain.py](brain.py)
  * **BPM** is the song's beats per minute. I'd recommend using 60, 75, 100, 120, or 150. You will otherwise run the risk of having rounding errors caused by flaws in this script--sorry!
  * **DIVISIONS_PER_BEAT** is how the beats are divided. For example, a value of 4 would create quarter-notes as the smallest unit, 8 would create eighth-notes, etc.
2. ChucK script: [brain.ck](brain.ck)
  * **padding** is the amount of milliseconds before and after the song.
  * **instrument_buffers** is the number of buffers each instrument has. If you hear clipping in your song, you will want to increase this number.
	* **start** is which millisecond you would like the song to start on. Useful for debugging a particular part of the song.

### Generating The Song

1. Run `python brain.py` in the project's directory. This will generate two files that ChucK will use:
  * `data/ck_instruments.csv`: A manifest of instrument files
  * `data/ck_sequence.csv`: A sequence of instruments
2. Open up **brain.ck** in ChucK. You can either export the song to .ogg/.wav or start your VM and add a new shred

### Generating The Visualization

1. Open [visualization/visualization.pde](visualization/visualization.pde) in Processing. This script generates a scrolling EEG brain wave visualization.
  * this script uses data (eeg.json) generated from previous python script
  * set `boolean captureFrames = true;` to output frames to output folder
  * run script, this will generate frames at the framerate (`fps`) in the configuration.
