videoTrigger
AKA 2011
akamediasystem.com

videoTrigger is a generic Processing application for triggering events based on motion detection within regions of a video stream.
The user defines polygonal regions within a video image (such as a webcam or video file) and a threshold of motion: when the video inside the region changes beyond that threshold, a trigger is fired.

There are three sketches here:

* gregVid is for Greg Gagnon, who needed it for an installation at the museum where he works. It is a sound-triggering application, with specifics described in the comments
* videoTrigger_OSC is a simple OSC-to-region mapping: each region fires a trigger on a dedicated OSC channel; filedrops are also sent along, for example to load samples into Pd, Max, etc
* videoTrigger_to_Pachube is a simple region-to-datastream mapping: the whole application is one feed, and each polygon fires a "1.0" on every trigger and a "0.0" at regular intervals during which there is no action.


To use:
* Start Sketch
* Click "Draw"
* Draw polygons. You must "close off" each polygon by clicking on the first point of the polygon (the point with he circle that shows up when you're near it)
* When you're done drawing polygons, click "Draw" again to turn off Draw Mode
* Click "Analyze" to start analyzing incoming video and doing triggers.

For the sound demo, an extra step:
* when you're done drawing polygons, you can drop sound files on each polygon's origin point - it's the point with the square around it.

any questions, improvements, etc, please see http://github.com/AKAMEDIASYSTEM/videoTrigger