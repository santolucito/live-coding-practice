
Quarks.install("BatLib"); //adds StageLimiter
MIDIIn.connectAll;
s.boot;

s.waitForBoot(
	{
		var keys;
		keys = Array.newClear(128);


		(
			SynthDef("umbSinewave",{
				arg freq=440, gate=1, amp=1, pan=0;
				var x;
				x = SinOsc.ar(freq, 0, amp);
				x = PitchShift.ar(x, pitchRatio: 3.9);
				x = EnvGen.kr(Env.adsr(0.01,0.3,0.5,1,0.6,-4),gate,doneAction: 2) * x;
				Out.ar(10, Pan2.ar(x,pan));
			}).add;


			SynthDef("processing",{
				arg shift=0, saw=10;
				var inAudio, newW;
				inAudio = In.ar(10,2);
				newW = Saw.ar(saw);
				Out.ar(0, inAudio*newW);
			}).add;

			StageLimiter.activate;

			2.sleep;

			~processSynth = Synth.tail(s, \processing);

			MIDIdef.noteOn(\noteOn, {
				arg vel, num, chan, src;
				var node;
				node = keys.at(num);
				if (node.notNil, {
					node.release;
					keys.put(num, nil);
				});
				(num.midicps).postln;
				node = Synth.head(nil, "umbSinewave", [\freq, num.midicps, \amp, (vel)/527]);
				keys.put(num, node);
				[num,vel/127].postln;
			});


			MIDIdef.noteOff(\noteOff, {
				arg vel, num, chan, src;
				var node;
				node = keys.at(num);
				if (node.notNil, {
					node.release;
					keys.put(num, nil);
				});
			});

			MIDIdef.bend(\bendPipe, {
				arg val, num, chan;
				~processSynth.set(\saw, val.linlin(0,16000,2,20));
				[val, num, chan].postln;
			});
		)

});



//MIDIdef.freeAll;
