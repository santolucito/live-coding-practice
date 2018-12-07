(
Quarks.install("BatLib"); //adds StageLimiter
include("SuperDirt");

)

s.quit

s.boot
//sometimes have problems with no free buffers - this seems to fix it...
//s.options.numBuffers = 1024 * 1024;


(
~sndBuf = Buffer.readChannel(s, "bellpad-harmonics.wav", channels:0);
~winenv = Env([0, 1, 0], [0.5, 0.5], [8, -8]);
~grainEnvBuf = Buffer.sendCollection(s, ~winenv.discretize, 1);

SynthDef("reverbBus", { |wetdry = 0, room=0, rmix=0.5, sndbuf, envbuf|

	~grainEnv = EnvGen.kr(
		Env([0, 1, 0], [1, 1], \sin, 1),
		1,
		levelScale: 1,
		doneAction: Done.freeSelf);
	~grainDur = MouseX.kr(0.2, 1);
	~grainDurY = MouseY.kr(0.2, 1);
	~grain = GrainBuf.ar(2,  Impulse.kr(~grainDurY*100), ~grainDur, sndbuf, ~grainDur,LFNoise2.kr(0.1).range(0, 1), 2, 0, ~grainEnvBuf);

	Out.ar(
		0, ~grain)
}).add;

)

x = Synth(\reverbBus, [\sndbuf, ~sndBuf]);


(

~dirt = SuperDirt.start;

s.waitForBoot(

	{
		"waiting for something...".postln;
		2.sleep();
		~dirt.orbits[0].outBus = 8;

		~sndBuf = Buffer.readChannel(s, "bellpad-harmonics.wav", channels:0);
		~winenv = Env([0, 1, 0], [0.5, 0.5], [8, -8]);
		~grainEnvBuf = Buffer.sendCollection(s, ~winenv.discretize, 1);

		SynthDef("reverbBus", { |wetdry = 0, room=0, rmix=0.5, grainX=0, grainY=0, sndbuf|

			~inSig = In.ar(8, 2);
			~reverb = ((1-rmix)*~inSig) + (rmix*FreeVerb.ar(~inSig,wetdry,room));

			~grainEnv = EnvGen.kr(
				Env([0, 1, 0], [1, 1], \sin, 1),
				1,
				levelScale: 1,
				doneAction: Done.freeSelf);
			~pan = MouseX.kr(-1, 1);
			~grain = LFTri.ar(grainX,mul:GrainBuf.ar(2,  Impulse.kr(grainX*10), grainY, sndbuf, grainY*3,
				LFNoise2.kr(0.1).range(0, 1), 2, ~pan, ~grainEnvBuf) * ~grainEnv);
			Out.ar(
				0, ~reverb + (~grain))

		}).add;

		~wetdryListener = OSCFunc( { | msg, time, addr, port |
			var newReverb;
			newReverb = msg[1].asFloat;
			( "Setting new wetdry value: " + newReverb).postln;
			~reverber.set( \wetdry, newReverb );
		}, '/butterfly', recvPort: 57122 );

		~rmixListener = OSCFunc( { | msg, time, addr, port |
			var rmix;
			rmix = msg[1].asFloat;
			( "Setting new rmix value " + rmix).postln;

			~reverber.set( \rmix, rmix);
		}, '/lotus' , recvPort: 57122);


		~grainListener = OSCFunc( { | msg, time, addr, port |
			var grainX, grainY;
			grainX = msg[1].asFloat;
			( "Setting new grainDur value " + grainX).postln;
			grainY = msg[2].asFloat;
			( "Setting new grainDur value " + grainY).postln;

			~reverber.set( \grainX, grainX);
			~reverber.set( \grainY, grainX);
		}, '/bigoh' , recvPort: 57122);

		//we need to wait for the synthdefs to be added before we can start
		2.sleep();

		~reverber = Synth.tail(s, \reverbBus, [\sndbuf,~sndBuf]);

		StageLimiter.activate;

});

)

s.quit
