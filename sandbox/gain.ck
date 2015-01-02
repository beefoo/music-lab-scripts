/*
* Script for playing with audio gain
*/

// config
4 => int instrument_count;

// instrument object
class Instrument { 
    string filename;
    SndBuf buf;
    float gain;
}

// define instrument filenames
Instrument instruments[instrument_count];
me.dir() + "/instruments/diner_vocals_05.wav" => instruments[0].filename;
me.dir() + "/instruments/nocturne_horn_02.wav" => instruments[1].filename;
me.dir() + "/instruments/counterpoint_clarinet_01.wav" => instruments[2].filename;
me.dir() + "/instruments/rhapsody_piano_01.wav" => instruments[3].filename;

// config instrument gains
0.5 => instruments[0].gain;
0.5 => instruments[2].gain;
1.5 => instruments[1].gain;
0.1 => instruments[3].gain;

// load instruments into sound buffers
for( 0 => int i; i < instrument_count; i++ )
{    
    instruments[i].filename => instruments[i].buf.read;
    // set position to end, so it won't play immediately upon open
    instruments[i].buf.samples() => instruments[i].buf.pos;
    instruments[i].buf => dac;
}

0 => int counter;

// loop and play instruments
while(true) {
    for( 0 => int i; i < instrument_count; i++ ) {   
        0 => instruments[i].buf.pos;
        instruments[i].gain => instruments[i].buf.gain;
        1 => instruments[i].buf.rate;
    }
    1000::ms => now;
    counter++;
}


<<< "Done." >>>;

