//
//  AudioManagerModule.swift
//  FalaFreud
//
//  Created by Haroldo Shigueaki Teruya on 24/01/2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer
import AudioToolbox

@objc(AudioManagerModule)
class AudioManagerModule: NSObject, AVAudioPlayerDelegate {
  
  // ATTRIBUTES =============================================================================================================
  
  var bridge: RCTBridge!
  var audioPlayer: AVAudioPlayer!  
  var audioTimer: Timer!
  var paused: Bool = false
  var timeInterval = 0.2
  
  let DEFAULTSPEAKER: Int = 0
  let EARSPEAKER: Int = 1
  
  // METHODS ================================================================================================================
  
  @objc func load(_ path: String, resolver resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
    
    if paused {
      resolve(false)
    } else if audioPlayer != nil && audioPlayer.isPlaying {
      resolve(false)
    } else {
      
      if let url = URL(string: path) {
        do {
          audioPlayer = try AVAudioPlayer(contentsOf: url)
          if audioPlayer.prepareToPlay() {
            resolve(audioPlayer.duration)
          } else {
            resolve(false)
          }
        } catch {
          resolve(false)
        }
      } else {
        resolve(false)
      }
    }
  }
  
  @objc func play(_ loop: Bool, resolver resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
    
    if paused {
      resolve(false)
    } else if( audioPlayer != nil && !audioPlayer.isPlaying ){
      
      print(loop)
      
      if loop {
        audioPlayer.numberOfLoops = -1
      } else {
        audioPlayer.numberOfLoops = 0
      }
      
      audioPlayer.delegate = self
      audioPlayer.play()
      
      bridge.eventDispatcher().sendAppEvent( withName: "onTimeChanged", body: audioPlayer.currentTime )
      
      DispatchQueue.main.async(execute: {
        self.audioTimer = Timer.scheduledTimer(timeInterval: self.timeInterval, target: self, selector: #selector(self.timeChanged), userInfo: nil, repeats: true)
      })
      
      resolve(true)
    } else {
      resolve(false);
    }
  }
  
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    bridge.eventDispatcher().sendAppEvent( withName: "onAudioFinished", body: nil )
  }
  
 func timeChanged() {
  
    if audioPlayer != nil && !paused {
      bridge.eventDispatcher().sendAppEvent( withName: "onTimeChanged", body: audioPlayer.currentTime )
    } else if ( paused ) {
  
    } else {
      audioTimer.invalidate()
    }
  }
  
  @objc func pause(_ resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
    
    if( audioPlayer != nil && audioPlayer.isPlaying ){
      paused = true
      audioPlayer.pause()
      resolve(true)
    } else {
      resolve(false);
    }
  }
  
  @objc func resume(_ resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
    
    if( audioPlayer != nil && !audioPlayer.isPlaying && paused ){
      paused = false
      audioPlayer.play()
      resolve(true)
    } else {
      resolve(false);
    }
  }
  
  @objc func stop(_ resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
    
    if( audioPlayer != nil ){
      paused = false
      audioPlayer.stop()
      audioPlayer = nil
      resolve(true)
    } else {
      resolve(false);
    }
  }
  
  @objc func seekTime(_ time: Double, resolver resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
    
    if( audioPlayer != nil ){      
      audioPlayer.currentTime = TimeInterval(Double(time))
      resolve(true)
    } else {
      resolve(false);
    }
  }
  
  @objc func setTimeInterval(_ timeInterval: Double, resolver resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
    
    if timeInterval < 0.1 {
      resolve(false)
    } else {
      self.timeInterval = timeInterval
      resolve(true)
    }
  }
  
  @objc func getVolume(_ resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
    
    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setActive(true)
      var sucess = audioSession.outputVolume
      try audioSession.setActive(false)
      resolve(sucess)
    } catch {
      resolve(false)
    }
  }
  
  @objc func setAudioOutputRoute(_ type: Int, resolver resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) {
    
    let session = AVAudioSession.sharedInstance()
    
    if type == EARSPEAKER {
      do {
        try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        try session.overrideOutputAudioPort(AVAudioSessionPortOverride.none)
        try session.setActive(true)
        resolve(true)
      } catch {
        resolve(false)
      }
    } else if type == DEFAULTSPEAKER {
      do {
        try session.setCategory(AVAudioSessionCategoryPlayback, with: AVAudioSessionCategoryOptions.defaultToSpeaker)
        try session.setActive(true)
        try session.overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
        resolve(true)
      } catch {
        resolve(false)
      }
    }
  }
}
