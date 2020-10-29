Basic Screen Sharing Sample App
===============================

Quick Start
-----------

To use this application:

1. Install OpenTok using `pod install`

   Then you need to set values for the `kApiKey`, `kSessionId`,
   and `kToken` constants. You can get these from your [tokbox project](https://tokbox.com/account/#/).

2. When you run the application, it connects to an OpenTok session and
   publishes an audio-video stream from your device to the session.

3. Run the app on a second client. You can do this by deploying the app to an
   iOS device and testing it in the simulator at the same time. Or you can use
   the browser_demo.html file to connect in a browser (see the following
   section).

   When the second client connects, it also publishes a stream to the session,
   and both clients subscribe to (view) each other’s stream.
   
4. Press the screen share button to start sharing your screen,
the background of the screen will turn green to indicate that screen sharing is active.
Press it again to stop the screen sharing.

Configuration Notes
-------------------

*   You can test in the iOS Simulator or on a supported iOS device. However, the
    XCode iOS Simulator does not provide access to the camera. When running in
    the iOS Simulator, an OTPublisher object uses a demo video instead of the
    camera.

