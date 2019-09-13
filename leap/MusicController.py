################################################################################
# Copyright (C) 2012-2013 Leap Motion, Inc. All rights reserved.               #
# Leap Motion proprietary and confidential. Not for distribution.              #
# Use subject to the terms of the Leap Motion SDK Agreement available at       #
# https://developer.leapmotion.com/sdk_agreement, or another agreement         #
# between Leap Motion and you, your company or other organization.             #
################################################################################

import sys, thread, time
sys.path.append("/usr/lib/Leap") #not even sure what this is here for...
sys.path.append("/home/mark/LeapDeveloperKit_2.3.1+31549_linux/LeapSDK/lib/")
sys.path.append("/home/mark/LeapDeveloperKit_2.3.1+31549_linux/LeapSDK/lib/x64")
sys.path.append("/home/mark/LEAPMotion/LeapDeveloperKit_2.3.1+31549_linux/LeapSDK/lib/")
sys.path.append("/home/mark/LEAPMotion/LeapDeveloperKit_2.3.1+31549_linux/LeapSDK/lib/x64")

import Leap
from Leap import Finger, Bone

import OSC

ampState = 0
ampStateSetAt = 0
enable_osc = True

class SampleListener(Leap.Listener):
    finger_names = ['Thumb', 'Index', 'Middle', 'Ring', 'Pinky']
    bone_names = ['Metacarpal', 'Proximal', 'Intermediate', 'Distal']
    state_names = ['STATE_INVALID', 'STATE_START', 'STATE_UPDATE', 'STATE_END']
    lotusVal = 0
    butterflyVal = 0
    bigOhVal = 0
    osc_client = None

    def on_init(self, controller):
        print "Initialized"

    def add_osc_connect(self, client_connection):
        self.osc_client = client_connection
        print (self.osc_client)

    def on_connect(self, controller):
        print "Connected"

        # Enable gestures
        controller.enable_gesture(Leap.Gesture.TYPE_CIRCLE);
        controller.enable_gesture(Leap.Gesture.TYPE_KEY_TAP);
        controller.enable_gesture(Leap.Gesture.TYPE_SCREEN_TAP);
        controller.enable_gesture(Leap.Gesture.TYPE_SWIPE);

    def on_disconnect(self, controller):
        # Note: not dispatched when running in a debugger.
        print "Disconnected"

    def on_exit(self, controller):
        print "Exited"

    def sendOSC(self, header, content):
        if enable_osc:
            msg = OSC.OSCMessage()
            msg.setAddress("/"+header)
            for c in content:
                msg.append(c)
            self.osc_client.send(msg)

    def on_frame(self, controller):
        # Get the most recent frame and report some basic information
        frame = controller.frame()
        def getFBVector(whichHand,whichFinger,whichBone):
            if whichHand=="left":
                return frame.hands.leftmost.fingers.finger_type(whichFinger)[0].bone(whichBone).next_joint
            if whichHand=="right":
                return frame.hands.rightmost.fingers.finger_type(whichFinger)[0].bone(whichBone).next_joint

        def matchingDist(whichFinger, whichBone):
            return getFBVector("left", whichFinger, whichBone).distance_to(getFBVector("right", whichFinger, whichBone))
   
        def moveVal(toMove, moveAmount):
            return min(1,max(0,toMove + ((moveAmount-0.5)/100)))

        max_pinch = 0
        max_dist_y = 0
        max_dist_x = 0
        for hand in frame.hands:
            #self.sendOSC("pinch", hand.pinch_strength)
            if (hand.pinch_strength > max_pinch):
                max_pinch = hand.pinch_strength
            if (hand.palm_position.y > max_dist_y):
                max_dist_y = hand.palm_position.y
            if (hand.palm_position.x > max_dist_x):
                max_dist_x = hand.palm_position.x


        max_dist_y = 1-max(0,min(1,(max_dist_y/350)-0.2))
        max_dist_x = max(0,min(1,(max_dist_x/350)+0.2))

        if len(frame.hands) == 2:
            print("T",matchingDist(Finger.TYPE_THUMB, Bone.TYPE_DISTAL))
            print("D",matchingDist(Finger.TYPE_INDEX, Bone.TYPE_DISTAL))
            print("P",matchingDist(Finger.TYPE_INDEX, Bone.TYPE_PROXIMAL))

            if (matchingDist(Finger.TYPE_THUMB,Bone.TYPE_DISTAL) < 45 and
                matchingDist(Finger.TYPE_INDEX, Bone.TYPE_DISTAL) > 90 and
                matchingDist(Finger.TYPE_INDEX, Bone.TYPE_PROXIMAL) > 90):
                self.butterflyVal = moveVal(self.butterflyVal, max_dist_y)
                self.sendOSC("butterfly",[self.butterflyVal])
                print ("ELEGANT BUTTERFLY",self.butterflyVal)

            elif (matchingDist(Finger.TYPE_THUMB,Bone.TYPE_DISTAL) < 45 and
                matchingDist(Finger.TYPE_INDEX, Bone.TYPE_DISTAL) < 45 and
                matchingDist(Finger.TYPE_INDEX, Bone.TYPE_PROXIMAL) > 50):
                self.sendOSC("bigoh",[max_dist_x,max_dist_y])
                print ("BIGOH",max_dist_x," ",max_dist_y)

            elif (matchingDist(Finger.TYPE_INDEX, Bone.TYPE_DISTAL) < 55 and
                matchingDist(Finger.TYPE_INDEX, Bone.TYPE_INTERMEDIATE) < 55 and
                matchingDist(Finger.TYPE_INDEX, Bone.TYPE_PROXIMAL) < 55 and
                matchingDist(Finger.TYPE_INDEX, Bone.TYPE_METACARPAL) < 55):
                self.lotusVal = moveVal(self.lotusVal, max_dist_y)
                self.sendOSC("lotus",[self.lotusVal])
                print ("FLYING LOTUS",self.lotusVal)
            
        #if not (frame.hands.is_empty and frame.gestures().is_empty):
            #print ""

    def state_string(self, state):
        if state == Leap.Gesture.STATE_START:
            return "STATE_START"

        if state == Leap.Gesture.STATE_UPDATE:
            return "STATE_UPDATE"

        if state == Leap.Gesture.STATE_STOP:
            return "STATE_STOP"

        if state == Leap.Gesture.STATE_INVALID:
            return "STATE_INVALID"

def main():
    # Setup a connection between SC and Py wtih OSC
    c = OSC.OSCClient()
    c.connect(('127.0.0.1', 57122))

    # Create a sample listener and controller
    listener = SampleListener()
    listener.add_osc_connect(c)

    controller = Leap.Controller()

    # Have the sample listener receive events from the controller
    controller.add_listener(listener)

    # Keep this process running until Enter is pressed
    print "Press Enter to quit..."
    try:
        sys.stdin.readline()
    except KeyboardInterrupt:
        pass
    finally:
        # Remove the sample listener when done
        controller.remove_listener(listener)


if __name__ == "__main__":
    main()
