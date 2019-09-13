(
Quarks.install("BatLib"); //adds StageLimiter
include("SuperDirt");

)

s.quit

s.boot

//sometimes have problems with no free buffers - this seems to fix it...
s.options.numBuffers = 1024 * 1024;

//Use this to test audio routing
{SinOsc.ar()}.play

//--------------------------//
//                          //
//   Testing grain synth    //
//                          //
//--------------------------//

(
~sndBuf = Buffer.readChannel(s, "grainSource.wav", channels:0);
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
	~grain = GrainBuf.ar(2, SinOsc.kr(~grainDurY*20), ~grainDur, sndbuf, ~grainDur,LFNoise2.kr(0.1).range(0, 1), 2, 0, ~grainEnvBuf);

	Out.ar(
		0, ~grain)
}).add;

)

x = Synth(\reverbBus, [\sndbuf, ~sndBuf]);

(
s.quit;
s.freeAll;
)
//--------------------------//
//                          //
//   MAIN FOR LIVE CODING   //
//                          //
//--------------------------//
(
~dirt = SuperDirt.start;

s.waitForBoot(

	{
		"waiting for something...".postln;
		2.sleep();
		~dirt.orbits[0].outBus = 8;

		SynthDef("reverbBus", { |wetdry = 0, room=0, synthVol=0.9, myFreq=0, sndbuf|

			~inSig = In.ar(8, 2);
			~reverb = MouseY.kr(0, 1) * ~inSig * 10;

			~grainEnv = EnvGen.kr(
				Env([0, 1, 0], [1, 1], \sin, 1),
				1,
				levelScale: 1,
				doneAction: Done.freeSelf);
			~newSynthVol = synthVol min: MouseX.kr(0, 1);
			~env = EnvGen.ar(Env.circle([0.7, 1, 0.8], [0.01, 0.5, 0.2]), timeScale:WhiteNoise.ar(2,1));

			~snd = Splay.ar(SinOsc.ar((myFreq)*Array.geom(4,1,2)));
			~snd = ~snd + SinOsc.ar((myFreq)/2, mul:SinOsc.ar(myFreq))!2;
			~snd = ~snd * ~env * ~newSynthVol;
			Out.ar(
				0, FreeVerb.ar(~reverb + ~snd,0.1))

		}).add;


		~mySynthListener = OSCFunc( { | msg, time, addr, port |
			var freqSetter, volSetter;
			freqSetter = msg[1].asFloat;
			( "Setting new freq value " + freqSetter).postln;
			freqSetter = freqSetter.midicps;
			volSetter = msg[2].asFloat;
			( "Setting new vol value " + volSetter).postln;

			~reverber.set( \myFreq, freqSetter);
			~reverber.set( \synthVol, volSetter);

		}, '/bigoh' , recvPort: 57122);

		//we need to wait for the synthdefs to be added before we can start
		2.sleep();

		~reverber = Synth.tail(s, \reverbBus, [\sndbuf,~sndBuf]);

		StageLimiter.activate;

});

)

s.quit
