//
//  CKVideoSession.swift
//  CameraKit
//
//  Created by Adrian Mateoaea on 09/01/2019.
//  Copyright © 2019 Wonderkiln. All rights reserved.
//

import AVFoundation

extension CKVideoSession.FlashMode {
    
    var captureTorchMode: AVCaptureDevice.TorchMode {
        switch self {
        case .off: return .off
        case .on: return .on
        case .auto: return .auto
        }
    }
}

public class CKVideoSession: CKSession, AVCaptureFileOutputRecordingDelegate {
    
    public enum FlashMode {
        case off, on, auto
    }
    
    public typealias RecordCallback = (URL?, CKError?) -> Void
    
    public private(set) var isRecording = false
    
    public var cameraPosition = CameraPosition.back {
        didSet {
            do {
                let deviceInput = try CKSession.captureDeviceInput(type: self.cameraPosition.deviceType)
                self.captureDeviceInput = deviceInput
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
    
    var captureDeviceInput: AVCaptureDeviceInput? {
        didSet {
            if let oldValue = oldValue {
                self.session.removeInput(oldValue)
            }
            
            if let captureDeviceInput = self.captureDeviceInput {
                self.session.addInput(captureDeviceInput)
            }
        }
    }
    
    public override var zoom: Double {
        didSet {
            guard let device = self.captureDeviceInput?.device else {
                return
            }
            
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = CGFloat(self.zoom)
                device.unlockForConfiguration()
            } catch {
                //
            }
            
            if let delegate = self.delegate {
                delegate.didChangeValue(session: self, value: self.zoom, key: "zoom")
            }
        }
    }
    
    public var flashMode = FlashMode.off {
        didSet {
            guard let device = self.captureDeviceInput?.device else {
                return
            }
            
            do {
                try device.lockForConfiguration()
                if device.isTorchModeSupported(self.flashMode.captureTorchMode) {
                    device.torchMode = self.flashMode.captureTorchMode
                }
                device.unlockForConfiguration()
            } catch {
                //
            }
        }
    }
    
    let movieOutput = AVCaptureMovieFileOutput()
    
    var recordCallback: RecordCallback?
    
    public init(position: CameraPosition = .back) {
        super.init()
        
        defer {
            self.cameraPosition = position
            
            do {
                let microphoneInput = try CKSession.captureDeviceInput(type: .microphone)
                self.session.addInput(microphoneInput)
            } catch let error {
                print(error.localizedDescription)
            }
        }
        
        self.session.sessionPreset = .hd1920x1080
        self.session.addOutput(self.movieOutput)
    }
    
    public func record(url: URL? = nil, _ callback: @escaping RecordCallback) {
        if self.isRecording { return }
        self.recordCallback = callback
        
        let fileUrl: URL = url ?? {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let fileUrl = paths[0].appendingPathComponent("output.mov")
            try? FileManager.default.removeItem(at: fileUrl)
            return fileUrl
        }()
        
        self.movieOutput.startRecording(to: fileUrl, recordingDelegate: self)
    }
    
    public func stopRecording() {
        if !self.isRecording { return }
        self.movieOutput.stopRecording()
    }
    
    public func togglePosition() {
        self.cameraPosition = self.cameraPosition == .back ? .front : .back
    }
    
    public func setWidth(_ width: Int, height: Int, frameRate: Int) {
        guard
            let input = self.captureDeviceInput,
            let format = CKSession.deviceInputFormat(input: input, width: width, height: height, frameRate: frameRate)
        else {
            return
        }
        
        do {
            try input.device.lockForConfiguration()
            input.device.activeFormat = format
            input.device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
            input.device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
            input.device.unlockForConfiguration()
        } catch {
            //
        }
    }
    
    public func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        self.isRecording = true
    }
    
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        self.isRecording = false
        
        guard let recordCallback = self.recordCallback else {
            return
        }
        
        defer { self.recordCallback = nil }
        
        if let error = error {
            recordCallback(nil, CKError.error(error.localizedDescription))
            return
        }
        
        recordCallback(outputFileURL, nil)
    }
}
