live coding with the leap motion, supercollider, and Tidal

# install

requires the leap motion SDK (v2.3)
update the links to the sdk in the python code
pip install pyOSC

# Startup

we need to put the leapd daemon in a loop so if it dies it comes back right away. leapd doesn't save any state, so this shouldn't be a problem.

   while true; do sudo leapd && break; done
   sclang Leap.scd
   python MusicController.py

# Video

[https://www.youtube.com/watch?v=m1hhvfcjTqE](https://www.youtube.com/watch?v=m1hhvfcjTqE)
