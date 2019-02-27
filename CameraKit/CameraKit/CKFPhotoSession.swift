//
//  CKPhotoSession.swift
//  CameraKit
//
//  Created by Adrian Mateoaea on 08/01/2019.
//  Copyright © 2019 Wonderkiln. All rights reserved.
//

import UIKit
import AVFoundation

extension CKFSession.FlashMode {
    
    var captureFlashMode: AVCaptureDevice.FlashMode {
        switch self {
        case .off: return .off
        case .on: return .on
        case .auto: return .auto
        }
    }
}

@objc public class CKFPhotoSession: CKFSession, AVCapturePhotoCaptureDelegate, AVCaptureMetadataOutputObjectsDelegate {
    
    @objc public enum CameraDetection: UInt {
        case none, faces
    }
    
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
    
    @objc public var cameraDetection = CameraDetection.none {
        didSet {
            if oldValue == self.cameraDetection { return }
            
            for output in self.session.outputs {
                if output is AVCaptureMetadataOutput {
                    self.session.removeOutput(output)
                }
            }
            
            self.faceDetectionBoxes.forEach({ $0.removeFromSuperview() })
            self.faceDetectionBoxes = []
            
            if self.cameraDetection == .faces {
                let metadataOutput = AVCaptureMetadataOutput()
                self.session.addOutput(metadataOutput)
                
                metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
                if metadataOutput.availableMetadataObjectTypes.contains(.face) {
                    metadataOutput.metadataObjectTypes = [.face]
                }
            }
        }
    }
    
    @objc public var flashMode = CKFSession.FlashMode.off
    
    var captureDeviceInput: AVCaptureDeviceInput? {
        didSet {
            self.faceDetectionBoxes.forEach({ $0.removeFromSuperview() })
            self.faceDetectionBoxes = []
            
            if let oldValue = oldValue {
                self.session.removeInput(oldValue)
            }
            
            if let captureDeviceInput = self.captureDeviceInput {
                self.session.addInput(captureDeviceInput)
            }
        }
    }
    
    let photoOutput = AVCapturePhotoOutput()
    
    var faceDetectionBoxes: [UIView] = []
    
    @objc public init(position: CameraPosition = .back, detection: CameraDetection = .none) {
        super.init()
        
        defer {
            self.cameraPosition = position
            self.cameraDetection = detection
        }
        
        self.session.sessionPreset = .high
        self.session.addOutput(self.photoOutput)
    }
    
    @objc deinit {
        self.faceDetectionBoxes.forEach({ $0.removeFromSuperview() })
    }
    
    var captureCallback: (UIImage, AVCaptureResolvedPhotoSettings) -> Void = { (_, _) in }
    var errorCallback: (Error) -> Void = { (_) in }
    
    @objc public func capture(_ callback: @escaping (UIImage, AVCaptureResolvedPhotoSettings) -> Void, _ error: @escaping (Error) -> Void) {
        self.captureCallback = callback
        self.errorCallback = error

        let settings = AVCapturePhotoSettings()
        settings.flashMode = self.flashMode.captureFlashMode

        if let connection = self.photoOutput.connection(with: .video) {
            if self.resolution.width > 0, self.resolution.height > 0 {
                connection.videoOrientation = .portrait
            } else {
                connection.videoOrientation = UIDevice.current.orientation.videoOrientation
            }
        }
        
        self.photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @objc public func togglePosition() {
        self.cameraPosition = self.cameraPosition == .back ? .front : .back
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
    
    @objc public var resolution = CGSize.zero {
        didSet {
            guard let deviceInput = self.captureDeviceInput else {
                return
            }
            
            do {
                try deviceInput.device.lockForConfiguration()
                
                if
                    self.resolution.width > 0, self.resolution.height > 0,
                    let format = CKFSession.deviceInputFormat(input: deviceInput, width: Int(self.resolution.width), height: Int(self.resolution.height))
                {
                    deviceInput.device.activeFormat = format
                } else {
                    self.session.sessionPreset = .high
                }
                
                deviceInput.device.unlockForConfiguration()
            } catch {
                //
            }
        }
    }
    
    @objc public override func focus(at point: CGPoint) {
        if let device = self.captureDeviceInput?.device, device.isFocusPointOfInterestSupported {
            do {
                try device.lockForConfiguration()
                device.focusPointOfInterest = point
                device.focusMode = .continuousAutoFocus
                device.unlockForConfiguration()
            } catch let error {
                print("Error while focusing at point \(point): \(error)")
            }
        }
    }
    
    @available(iOS 11.0, *)
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        defer {
            self.captureCallback = { (_, _) in }
            self.errorCallback = { (_) in }
        }

        if let error = error {
            self.errorCallback(error)
            return
        }

        guard let data = photo.fileDataRepresentation() else {
            self.errorCallback(CKFError.error("Cannot get photo file data representation"))
            return
        }

        self.processPhotoData(data: data, resolvedSettings: photo.resolvedSettings)
    }
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        defer {
            self.captureCallback = { (_, _) in }
            self.errorCallback = { (_) in }
        }

        if let error = error {
            self.errorCallback(error)
            return
        }

        guard
            let photoSampleBuffer = photoSampleBuffer, let previewPhotoSampleBuffer = previewPhotoSampleBuffer,
            let data = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer) else
        {
            self.errorCallback(CKFError.error("Cannot get photo file data representation"))
            return
        }

        self.processPhotoData(data: data, resolvedSettings: resolvedSettings)
    }
    
    private func processPhotoData(data: Data, resolvedSettings: AVCaptureResolvedPhotoSettings) {
        guard let image = UIImage(data: data) else {
            self.errorCallback(CKFError.error("Cannot get photo"))
            return
        }

        if
            self.resolution.width > 0, self.resolution.height > 0,
            let transformedImage = CKUtils.cropAndScale(image, width: Int(self.resolution.width), height: Int(self.resolution.height), orientation: UIDevice.current.orientation, mirrored: self.cameraPosition == .front)
        {
            self.captureCallback(transformedImage, resolvedSettings)
            return
        }

        self.captureCallback(image, resolvedSettings)
    }
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        let faceMetadataObjects = metadataObjects.filter({ $0.type == .face })
        
        if faceMetadataObjects.count > self.faceDetectionBoxes.count {
            for _ in 0..<faceMetadataObjects.count - self.faceDetectionBoxes.count {
                let view = UIView()
                view.layer.borderColor = UIColor.green.cgColor
                view.layer.borderWidth = 1
                self.overlayView?.addSubview(view)
                self.faceDetectionBoxes.append(view)
            }
        } else if faceMetadataObjects.count < self.faceDetectionBoxes.count {
            for _ in 0..<self.faceDetectionBoxes.count - faceMetadataObjects.count {
                self.faceDetectionBoxes.popLast()?.removeFromSuperview()
            }
        }
        
        for i in 0..<faceMetadataObjects.count {
            if let transformedMetadataObject = self.previewLayer?.transformedMetadataObject(for: faceMetadataObjects[i]) {
                self.faceDetectionBoxes[i].frame = transformedMetadataObject.bounds
            } else {
                self.faceDetectionBoxes[i].frame = CGRect.zero
            }
        }
    }
}
