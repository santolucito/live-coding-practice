
(
s.boot;

//sometimes have problems with no free buffers - this seems to fix it...
s.options.numBuffers = 1024 * 1024;

s.waitForBoot(

    {


        ~dirt = SuperDirt.start;

        ~dirt.orbits[0].outBus = 2;


        SynthDef("reverbBus", { |reverb = 0|
            Out.ar(
                0,
                FreeVerb.ar(In.ar(2, 2),reverb)
            )
        }).add;


        x = OSCFunc( { | msg, time, addr, port |
            var newReverb;
            newReverb = msg[1].asFloat;
            ( "Setting new reverb value: " + newReverb).postln;
            ~reverber.set( \reverb, newReverb );
        }, '/butterfly' );

        OSCFunc( { | msg, time, addr, port |
            var pinch;

            pinch = msg[1].asFloat;
            ( "Pinch Strength: " + pinch).postln;

            ~reverber.set( \amp, (pinch-1).abs);
        }, '/pinch' );

        //we need to wait for the synthdefs to be added before we can start
        2.sleep();

        ~reverber = Synth.tail(s, \reverbBus);


});

)

