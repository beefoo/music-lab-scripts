// data files
me.sourceDir() + "/data/ck_instruments.csv" => string instruments_file;
me.sourceDir() + "/data/ck_sequence.csv" => string sequence_file;

// read data files
FileIO instruments_fio;
FileIO sequence_fio;
instruments_fio.open( instruments_file, FileIO.READ );
sequence_fio.open( sequence_file, FileIO.READ );

// check if files are valid
if( !instruments_fio.good() || !sequence_fio.good() )
{
    cherr <= "can't open instrument and/or sequence files for reading..."
          <= IO.newline();
    me.exit();
}

// create instruments from file
SndBuf instruments[120];
while( instruments_fio.more() )
{
    Std.atoi(instruments_fio.readLine()) => int instrument_index;
    me.sourceDir() + "/" + instruments_fio.readLine() => string filename;    
    filename => instruments[instrument_index].read;
    // set position to end, so it won't play immediately upon open
    instruments[instrument_index].samples() => instruments[instrument_index].pos;
    instruments[instrument_index] => dac;
}

class Beat { 
    -1 => int instrument_index;
    0 => int position;
    0.5 => float gain;
    1 => int rate;
    0 => int milliseconds;
}

Beat beats[4000];
0 => int i;

// read sequence from file
while( sequence_fio.more() ) {  
    Std.atoi(sequence_fio.readLine()) => beats[i].instrument_index;
    Std.atoi(sequence_fio.readLine()) => beats[i].position;
    Std.atof(sequence_fio.readLine()) => beats[i].gain;
    Std.atoi(sequence_fio.readLine()) => beats[i].rate;
    Std.atoi(sequence_fio.readLine()) => beats[i].milliseconds;
    
    i++;
    
	
}

while(true) {
    for( 0 => int i; i < beats.cap(); i++ ) {
        beats[i].instrument_index => int instrument_index;
        
        if (instrument_index < 0) 
        {
            break;
        }
        
        if (beats[i].milliseconds > 0)
        {
            beats[i].milliseconds::ms => now;
        }	
        
        beats[i].position => instruments[instrument_index].pos;
        beats[i].gain => instruments[instrument_index].gain;
        beats[i].rate => instruments[instrument_index].rate;
    }
}


<<< "Done." >>>;

