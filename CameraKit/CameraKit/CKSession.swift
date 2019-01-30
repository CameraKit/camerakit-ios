//
//  CKSession.swift
//  CameraKit
//
//  Created by Adrian Mateoaea on 08/01/2019.
//  Copyright © 2019 Wonderkiln. All rights reserved.
//

import AVFoundation

private extension CKSession.DeviceType {
    
    var captureDeviceType: AVCaptureDevice.DeviceType {
        switch self {
        case .frontCamera, .backCamera:
            return .builtInWideAngleCamera
        case .microphone:
            return .builtInMicrophone
        }
    }
    
    var captureMediaType: AVMediaType {
        switch self {
        case .frontCamera, .backCamera:
            return .video
        case .microphone:
            return .audio
        }
    }
    
    var capturePosition: AVCaptureDevice.Position {
        switch self {
        case .frontCamera:
            return .front
        case .backCamera:
            return .back
        case .microphone:
            return .unspecified
        }
    }
}

extension CKSession.CameraPosition {
    var deviceType: CKSession.DeviceType {
        switch self {
        case .back:
            return .backCamera
        case .front:
            return .frontCamera
        }
    }
}

public protocol CKSessionDelegate: class {
    func didChangeValue(session: CKSession, value: Any, key: String)
}

public class CKSession: NSObject {
    
    public enum DeviceType {
        case frontCamera, backCamera, microphone
    }
    
    public enum CameraPosition {
        case front, back
    }
    
    public let session: AVCaptureSession
    
    public var previewLayer: AVCaptureVideoPreviewLayer?
    public var overlayView: UIView?
    
    public var zoom = 1.0
    
    public weak var delegate: CKSessionDelegate?
    
    override init() {
        self.session = AVCaptureSession()
    }
    
    deinit {
        self.session.stopRunning()
    }
    
    public func start() {
        self.session.startRunning()
    }
    
    public func stop() {
        self.session.stopRunning()
    }
    
    public func focus(at point: CGPoint) {
        //
    }
    
    public static func captureDeviceInput(type: DeviceType) throws -> AVCaptureDeviceInput {
        let captureDevices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [type.captureDeviceType],
            mediaType: type.captureMediaType,
            position: type.capturePosition)
        
        guard let captureDevice = captureDevices.devices.first else {
            throw CKError.captureDeviceNotFound
        }
        
        return try AVCaptureDeviceInput(device: captureDevice)
    }
    
    public static func deviceInputFormat(input: AVCaptureDeviceInput, width: Int, height: Int, frameRate: Int = 30) -> AVCaptureDevice.Format? {
        for format in input.device.formats {
            let dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            if dimension.width >= width && dimension.height >= height {
                for range in format.videoSupportedFrameRateRanges {
                    if Int(range.maxFrameRate) >= frameRate && Int(range.minFrameRate) <= frameRate {
                        return format
                    }
                }
            }
        }
        
        return nil
    }
}
