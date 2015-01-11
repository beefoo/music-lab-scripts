// load the samples into a SndBuf.
SndBuf buf;
me.dir() + "/audio/hello_world.wav" => buf.read;

PRCRev rvb;
.2 => rvb.mix;

PitShift pt;
.9 => pt.mix;
1 => pt.shift;

// quickly set all to their last sample and initialize each processing path.
// this keeps the samples from playing immediately when opened.
buf.samples() => buf.pos;
buf => pt => rvb => dac;

// set pos of sample to 0 to play it.
fun void plyy(int d){
    0 => buf.pos;
}

fun void ply(int d, float r){
    for(0 => int i; i < (r $ int); i++){
        spork ~ plyy(d);
        (buf.samples() / (r $ float))::samp => now;
    }
}

SinOsc lfo;
.1 => lfo.freq;
lfo => blackhole;

Chorus ch;
.1 => ch.modFreq;
.5 => ch.modDepth;
.2 => ch.mix;

SawOsc lead1 => ADSR le => ch => rvb => dac;
.3 => lead1.gain;
le.set(50::ms, 200::ms, .5, 500::ms);

1 => float m;
while(1){
    Std.mtof(Std.rand2(30,40)) => lead1.freq;
    le.keyOn();
    spork ~ ply(6,2*m);
    2000::ms => now;
    spork ~ ply(5,2*m);
    spork ~ ply(1,1*m);
    2000::ms => now;
    spork ~ ply(3,2*m);
    spork ~ ply(5,1*m);
    le.keyOff();
    2000::ms => now;
    Std.mtof(Std.rand2(30,40)) => lead1.freq;
    le.keyOn();
    spork ~ ply(2,2*m);
    spork ~ ply(4,2*m);
    2000::ms => now;
    le.keyOff();
    lfo.last()/10 + pt.shift() => pt.shift;
//    0.5 +=> m;
    <<< m >>>;
}