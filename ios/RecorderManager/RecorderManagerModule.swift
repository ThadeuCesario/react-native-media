//
//  RecorderManagerModule.swift
//  RNReactNativeMedia
//
//  Created by Haroldo Shigueaki Teruya on 18/04/2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

import Foundation
import AVKit

@objc(RecorderManagerModule)
class RecorderManagerModule: NSObject, AVAudioRecorderDelegate {
    
    let TAG: String = "RecorderManager";
    
    // =============================================================================================
    // ATRIBUTES ===================================================================================
    
    struct Event {
        static let ON_STARTED = "ON_STARTED";
        static let ON_TIME_CHANGED = "ON_TIME_CHANGED";
        static let ON_ENDED = "ON_ENDED";
    }
    
    struct Response {
        static let IS_RECORDING = 0;
        static let SUCCESS = 1;
        static let FAILED = 2;
        static let UNKNOWN_ERROR = 3;
        static let INVALID_AUDIO_PATH = 4;
        static let NOTHING_TO_STOP = 5;
        static let NO_PERMISSION = 6;
    }
    
    struct AudioOutputFormat {
        static let MPEG4AAC = "mpeg_4"; // default aac
        static let LinearPCM = "lpcm";
        static let AppleIMA4 = "ima4";
        static let MACE3 = "MAC3";
        static let MACE6 = "MAC6";
        static let ULaw = "ulaw";
        static let ALaw = "alaw";
        static let MPEGLayer1 = ".mp1";
        static let MPEGLayer2 = ".mp2";
        static let MPEGLayer3 = ".mp3";
        static let AppleLossless = "alac";
    }
    
    var bridge: RCTBridge!
    var recorder: AVAudioRecorder!
    var recordingSession: AVAudioSession = AVAudioSession.sharedInstance()
    var audioTimer: Timer!
    
    // =============================================================================================
    // CONSTRUCTOR =================================================================================
    
    
    
    // =============================================================================================
    // METHODS =====================================================================================
    
    @objc func start(_ path: String, audioOutputFormat: String, sampleRate: Int, channels: Int, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
        
        if self.recorder != nil {
            NSLog(TAG + " start: is recording")
            resolve(Response.IS_RECORDING);
            return;
        }
        
        // verify the path
        if path == nil || path.isEmpty {
            NSLog(TAG + " start: " + path + " is ivalid")
            resolve(Response.INVALID_AUDIO_PATH)
            return;
        }
        
        // build settings
        let settings = [
            AVFormatIDKey: self.getAudioOutputFormat(audioOutputFormat: audioOutputFormat),
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        // clean variables
        self.destroy(nil, rejecter: nil)
        
        do {
//            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() {
                
                [unowned self] allowed in
                
                DispatchQueue.main.async {
                    if allowed {
                        
                        // build recorder
                        do {
                            self.recorder = try AVAudioRecorder(url: URL(string: path)!, settings: settings)
                            self.recorder.delegate = self
                            
                            if self.recorder != nil, self.recorder.record() {
                                
                                self.emitEvent(eventName: Event.ON_STARTED, data: nil)
                                self.audioTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timeChanged), userInfo: nil, repeats: true)
                                NSLog(self.TAG + " start succesuful");
                                
                                resolve(Response.SUCCESS)
                            } else {
                                NSLog(self.TAG + " cannot start");
                                self.destroy(nil, rejecter: nil)
                                resolve(Response.FAILED)
                                return
                            }
                        } catch {
                            NSLog(self.TAG + " start error: " + error.localizedDescription);
                            self.destroy(nil, rejecter: nil)
                            resolve(Response.FAILED)
                            return
                        }
                    } else {
                        NSLog(self.TAG + " start no permission");
                        resolve(Response.NO_PERMISSION)
                        return
                    }
                }
            }
        } catch {
            NSLog(TAG + " start error: " + error.localizedDescription);
            resolve(Response.UNKNOWN_ERROR)
        }
    }
    
    @objc func timeChanged() {
        
        NSLog(self.TAG + " timeChanged")
        
        if recorder != nil {
            self.emitEvent(eventName: Event.ON_TIME_CHANGED, data: self.recorder.currentTime * 1000)
        } else if(audioTimer != nil) {
            audioTimer.invalidate()
            audioTimer = nil
        }
    }
    
    @objc func stop(_ resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
        
        NSLog(self.TAG + " stop")
        
        if self.recorder == nil {
            resolve(Response.NOTHING_TO_STOP)
        } else {
            self.emitEvent(eventName: Event.ON_ENDED, data: nil)
            resolve(Response.SUCCESS)
        }
        self.destroy(nil, rejecter: nil)
    }
    
    @objc func destroy(_ resolve: RCTPromiseResolveBlock?, rejecter reject: RCTPromiseRejectBlock?) -> Void {
        
        NSLog(self.TAG + " destroy")
        
        if ( self.recorder != nil ) {
            self.recorder.stop()
            self.recorder = nil
        }
        
        if audioTimer != nil {
            audioTimer.invalidate()
            audioTimer = nil
        }
        
        if resolve != nil {
            resolve!(Response.SUCCESS)
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        
        if error != nil {
            NSLog(self.TAG + " audioRecorderEncodeErrorDidOccur " + (error?.localizedDescription)!)
        } else {
            NSLog(self.TAG + " audioRecorderEncodeErrorDidOccur unknow error")
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
        if flag {
            NSLog(self.TAG + " audioRecorderDidFinishRecording success")
        } else {
            NSLog(self.TAG + " audioRecorderDidFinishRecording failed")
        }
        self.emitEvent(eventName: Event.ON_ENDED, data: nil)
        self.destroy(nil, rejecter: nil)
    }
    
    func getAudioOutputFormat(audioOutputFormat: String) -> Int {
        
        switch audioOutputFormat {
        case AudioOutputFormat.LinearPCM:
            return Int(kAudioFormatLinearPCM);
        case AudioOutputFormat.AppleIMA4:
            return Int(kAudioFormatAppleIMA4);
        case AudioOutputFormat.MPEG4AAC:
            return Int(kAudioFormatMPEG4AAC);
        case AudioOutputFormat.MACE3:
            return Int(kAudioFormatMACE3);
        case AudioOutputFormat.MACE6:
            return Int(kAudioFormatMACE6);
        case AudioOutputFormat.ULaw:
            return Int(kAudioFormatULaw);
        case AudioOutputFormat.ALaw:
            return Int(kAudioFormatALaw);
        case AudioOutputFormat.MPEGLayer1:
            return Int(kAudioFormatMPEGLayer1);
        case AudioOutputFormat.MPEGLayer2:
            return Int(kAudioFormatMPEGLayer2);
        case AudioOutputFormat.MPEGLayer3:
            return Int(kAudioFormatMPEGLayer3);
        case AudioOutputFormat.AppleLossless:
            return Int(kAudioFormatAppleLossless);
        default:
            return Int(kAudioFormatMPEG4AAC);
        }
    }
    
    func emitEvent(eventName: String, data: Any?) -> Void {
        print("RecorderManager - emitEvent: \(eventName) data: \(data)")
        if data != nil {
            EventEmitter.sendEvent(withName: eventName, withBody: ["data" : data!])
        }else{
            EventEmitter.sendEvent(withName: eventName, withBody: ["data": ""])
        }
//        if self.bridge != nil, self.bridge.eventDispatcher() != nil {
//            self.bridge.eventDispatcher().sendAppEvent(withName: eventName, body: data)
//        } else {
//            NSLog(self.TAG + " fail to emitEvent: " + eventName);
//        }
    }

    @objc static func requiresMainQueueSetup() -> Bool {
        return true
    }
}
