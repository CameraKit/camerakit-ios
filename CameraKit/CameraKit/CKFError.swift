//
//  CKError.swift
//  CameraKit
//
//  Created by Adrian Mateoaea on 10/01/2019.
//  Copyright © 2019 Wonderkiln. All rights reserved.
//

import Foundation

public enum CKFError: Error {
    case captureDeviceNotFound
    case error(String)
}
