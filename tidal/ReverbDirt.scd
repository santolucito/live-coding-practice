// Run the output of tidal through some reverb

(
s.boot;

s.options.numBuffers = 1024 * 1024;

s.waitForBoot {
~dirt = SuperDirt.start;

~dirt.orbits[0].outBus = 2;


SynthDef("dataFromABus", { |reverb = 0|
    Out.ar(
        0,
		FreeVerb.ar(In.ar(2, 2),reverb)
    )
}).add;


Synth.tail(s, \dataFromABus);

}
)

s.quit
