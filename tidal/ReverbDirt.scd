// Run the output of tidal through some reverb

(
s.boot;

s.options.numBuffers = 1024 * 1024;

s.waitForBoot {
~dirt = SuperDirt.start;

~dirt.orbits[0].outBus = 8;


SynthDef("dataFromABus", { |wetdry = 0, room=0, rmix=0.5|
    Out.ar(
        0,
			((1-rmix)*In.ar(8, 1)) + (rmix*FreeVerb.ar(In.ar(8, 2),wetdry,room))
    )
}).add;

x = Synth.tail(s, \dataFromABus);

}
StageLimiter.activate;

s.queryAllNodes;

x.set(\rmix,1);
x.set(\wetdry,0.8);
x.set(\room,0.5);

s.quit