/*
* Script for playing with audio gain
*/

SndBuf instrument;  
me.dir() + "/subway/instruments/survival_woodblock_01.wav" => instrument.read;
instrument.samples() => instrument.pos;
instrument => dac;

250 => int interval;
0 => float min_gain;
0.1 => float max_gain;
0.01 => float gain_step;

((max_gain-min_gain)/gain_step) $ int => int steps;

while(true) {
    for( 0 => int i; i < steps; i++ ) {
        gain_step * i + min_gain => float gain;
        0 => instrument.pos;
        gain => instrument.gain;
        1 => instrument.rate;
        interval::ms => now;
    }
}


<<< "Done." >>>;

