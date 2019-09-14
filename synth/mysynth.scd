
Quarks.install("BatLib"); //adds StageLimiter
MIDIIn.connectAll;
s.boot;

//s.waitForBoot({


(

var keys, state;
keys = Array.newClear(128);
state = Array.fill(128, 0);

SynthDef("umbSinewave",{
	arg freq=440, gate=1, amp=1, pan=0, cubFreq=440, cubMod=1, cubActive=0;
	var mainOsc, cubLFO, outAudio;
	mainOsc = SinOsc.ar(freq, 0, amp)+(Saw.ar(freq-4))*0.3;
	cubLFO = LFCub.ar(cubFreq)*SinOsc.ar(cubMod+Rand(0,4));
	outAudio = Select.ar(cubActive, [mainOsc, mainOsc+(mainOsc*cubLFO)*0.3]);
	outAudio = EnvGen.kr(Env.adsr(0.01,0.2,0.5,0.1,0.8,-4),gate,doneAction: 2) * outAudio;
	Out.ar(10, Pan2.ar(outAudio,pan));
}).add;


SynthDef("processing",{
	arg volControl=1;
	var inAudio, newW, outAudio;
	inAudio = In.ar(10,2);
	//volControl.poll;
	Out.ar(0, inAudio*volControl);
}).add;

StageLimiter.activate;
//2.sleep;

~processSynth = Synth.tail(s, \processing);

MIDIdef.noteOn(\noteOn, {
	arg vel, num, chan, src;
	var node;
	node = keys.at(num);
	if (node.notNil, {
		node.release;
		keys.put(num, nil);
	});
	node = Synth.head(nil, "umbSinewave",
		[\freq, num.midicps,
		\amp, vel.linlin(0,0.8,0,127),
		\cubActive, state.at(81),
		\cubMod, state.at(41),
		\cubFreq, (num-36).midicps]
	);
	keys.put(num, node);
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

~processMidi = {
	arg num, val, synth, keyVal;
	keyVal.postln;
	if (num == 81 && (state.at(81) == 0),
		{synth.set(\cubActive, 0);},
		{});
	if (num == 81 && (state.at(81) == 127),
		{synth.set(\cubActive, 1);},
		{});
	if ((num == 41),
		{synth.set(\cubMod, val.linlin(0,127,5,40));
		},
		{});
};

MIDIdef.cc(\ccHandler, {
	arg val, num, chan;
	state.put(num, val);
	keys.do({
		arg synth, keyVal;
		if (synth == nil,
			{},
			{keyVal.postln;
			~processMidi.value(num, val, synth, keyVal);});
	if ((num == 21),
		{~processSynth.set(\volControl, val.linlin(0,127,0,0.1));},
		{});
	});
	[val, num, chan].postln;
});
)

//});

(
MIDIdef.cc(\ccWriter, {
	arg val, num, chan;
	[val, num, chan].postln;
});
)

(
MIDIdef.freeAll;
s.freeAll;
)