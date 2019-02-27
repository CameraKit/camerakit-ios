//
//  CKVideoSession.swift
//  CameraKit
//
//  Created by Adrian Mateoaea on 09/01/2019.
//  Copyright © 2019 Wonderkiln. All rights reserved.
//

import AVFoundation

extension CKFSession.FlashMode {
    
    var captureTorchMode: AVCaptureDevice.TorchMode {
        switch self {
        case .off: return .off
        case .on: return .on
        case .auto: return .auto
        }
    }
}

@objc public class CKFVideoSession: CKFSession, AVCaptureFileOutputRecordingDelegate {
    
    @objc public private(set) var isRecording = false
    
    @objc public var cameraPosition = CameraPosition.back {
        didSet {
            do {
                let deviceInput = try CKFSession.captureDeviceInput(type: self.cameraPosition.deviceType)
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
    
    @objc public override var zoom: Double {
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
    
    @objc public var flashMode = CKFSession.FlashMode.off {
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
    
    @objc public init(position: CameraPosition = .back) {
        super.init()
        
        defer {
            self.cameraPosition = position
            
            do {
                let microphoneInput = try CKFSession.captureDeviceInput(type: .microphone)
                self.session.addInput(microphoneInput)
            } catch let error {
                print(error.localizedDescription)
            }
        }
        
        self.session.sessionPreset = .hd1920x1080
        self.session.addOutput(self.movieOutput)
    }
    
    var recordCallback: (URL) -> Void = { (_) in }
    var errorCallback: (Error) -> Void = { (_) in }
    
    @objc public func record(url: URL? = nil, _ callback: @escaping (URL) -> Void, error: @escaping (Error) -> Void) {
        if self.isRecording { return }
        
        self.recordCallback = callback
        self.errorCallback = error
        
        let fileUrl: URL = url ?? {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let fileUrl = paths[0].appendingPathComponent("output.mov")
            try? FileManager.default.removeItem(at: fileUrl)
            return fileUrl
        }()
        
        if let connection = self.movieOutput.connection(with: .video) {
            connection.videoOrientation = UIDevice.current.orientation.videoOrientation
        }
        
        self.movieOutput.startRecording(to: fileUrl, recordingDelegate: self)
    }
    
    @objc public func stopRecording() {
        if !self.isRecording { return }
        self.movieOutput.stopRecording()
    }
    
    @objc public func togglePosition() {
        self.cameraPosition = self.cameraPosition == .back ? .front : .back
    }
    
    @objc public func setWidth(_ width: Int, height: Int, frameRate: Int) {
        guard
            let input = self.captureDeviceInput,
            let format = CKFSession.deviceInputFormat(input: input, width: width, height: height, frameRate: frameRate)
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
        
        defer {
            self.recordCallback = { (_) in }
            self.errorCallback = { (_) in }
        }
        
        if let error = error {
            self.errorCallback(error)
            return
        }
        
        self.recordCallback(outputFileURL)
    }
}
