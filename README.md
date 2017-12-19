# react-native-media

![Logo](logo.png)

A react-native library to play and record audio on both iOS and android.

## Specifications

### iOS

Built with AVAudioPlayer and AvAudioRecorder.

### android

Built with MediaPlayer and MediaRecorder.

## Installation

Install the package:

```javascript
npm install react-native-media --save
```

or

```javascript
yarn add react-native-media
```

### Automatic

Link the native code with your RN application:

```javascript
react-native link react-native-media
```

### Manual

[TODO]

## Player

Description ✓ | iOS | Android
---|---|---
Load
Play
Pause
Resume
Stop
Seek Time
Track current time
Set Volume
Set Loops (-1 for infinite)
Turn speakers on/off (android only)
Set audio routes (iOS only)

## Recorder
Description ✓ | iOS | Android
---|---|---
Start
Stop


## Events
Description ✓ | iOS | Android
---|---|---
Volume changed
Wired headset
Audio focus changed
Silent mode changed (iOS only)