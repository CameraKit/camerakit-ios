<p align="center">
    <a href="https://camerakit.io" target="_blank">
        <img alt='CameraKit Header' src='.repo/gh-readme-header.svg' />
    </a>
</p>

<p align="center">
    <a href="https://spectrum.chat/camerakit/">
        <img alt="Join Spectrum" height="42px" src=".repo/gh-readme-spectrum-button.svg" />
    </a>
    <a href="https://buddy.works/" target="_blank">
        <img alt='Buddy.Works' height="41px" src='https://assets.buddy.works/automated-dark.svg' />
    </a>
</p>

CameraKit helps you add reliable camera to your app quickly. Our open source camera platform provides consistent capture results, service that scales, and endless camera possibilities.

With CameraKit you are able to effortlessly do the following: 

- ✅ Ability to extend and create custom sessions.
- ✅ Image and video capture seamlessly working with the same preview session.
- ✅ Automatic system permission handling.
- ✅ Automatic preview scaling.
- ✅ Automatic preview/image/video output orientation handling.
- 📷 Ability to set a custom resolution for capturing photos.
- 📹 Ability to set resolution/frame rate for capturing videos.
- 👱‍ Built-in face detection.
- 📐 Built-in overlay grid.
- 👆 Built-in tap to focus.
- 🔍 Built-in pinch to zoom.
- 📸 Built-in flash toggle for both photos and videos.
- 🤳 Built-in camera position toggle.
- 🖥 Objective-C compatible.

## Sponsored By
<a href="https://www.expensify.com/"><img alt="Expensify" src=".repo/gh-readme-expensify-logo.svg" height="45px" width="375px" align="center"></a>
<a href="https://www.buddy.works/"><img alt="Buddy.Works" src=".repo/gh-readme-buddyworks-logo.png" height="100px"  width="250px" align="center"></a>

# Installation

## Demo

If you want to test out the demo app first you can clone this repo to your local disk:

```bash
git clone https://github.com/CameraKit/camerakit-ios.git
```

and then navigate to `camerakit-ios` and open the `CameraKit.xcworkspace` file with Xcode. Near the run button select the `CameraKitDemo` scheme, resolve the signing conflicts using your Apple account and then run it on a real device. You cannot do much on a simulator, since we need an actual camera hardware.

## Cocoapods

If you don't have [Cocoapods](https://cocoapods.org/) already installed you can install it by running the code below in a terminal:

```bash
sudo gem install cocoapods
```

If you don't have any `Podfile` run:

```bash
pod init
```

Then open the `Podfile` file in your project and add this line to your app target:

```ruby
pod CameraKit-iOS
```

and it will automatically create a `Podfile` and integrate the pods into the project by creating a separate `.xcworkspace` file. You will open this file in Xcode from now on.

## Carthage

If you don't have [Carthage](https://github.com/Carthage/Carthage) installed run:

```bash
brew install carthage
```

Then create a `Cartfile` and add the following line:

```ruby
github "CameraKit/camerakit-ios"
```

# Code

Before adding our camera related code, make sure you include the permissions needed for your code to work in the app project `Info.plist` file:

```plist
<!-- Required for photos and videos -->
<key>NSCameraUsageDescription</key>
<string></string>

<!-- Optional for photos -->
<key>NSMicrophoneUsageDescription</key>
<string></string>

<!-- Optional for the demo app to copy the photos/videos to your photo library -->
<key>NSPhotoLibraryAddUsageDescription</key>
<string></string>
```

Below is a quick start code sample with session + live camera preview:

```swift
import CameraKit

...

override func viewDidLoad() {
    super.viewDidLoad()

    // Init a photo capture session
    let session = CKFPhotoSession()
    
    // Use CKFVideoSession for video capture
    // let session = CKFVideoSession()
    
    let previewView = CKFPreviewView(frame: self.view.bounds)
    previewView.session = session
}
```

For capturing a image using the `CKFPhotoSession` class use this code below:

```swift
session.capture({ (image, settings) in
    // TODO: Add your code here
}) { (error) in
    // TODO: Handle error
}
```

If you want to record a video using the `CKFVideoSession` class use this code below to start the recording:

```swift
// You can also specify a custom url for where to save the video file
session.record(url: URL(string: ""), { (url) in
    // TODO: Add your code here
}) { (error) in
    // TODO: Handle error
}
```

and end the recording:

```swift
// You can also specify a custom url for where to save the video file
session.stopRecording()
```

You can get the current record status via the `isRecording` property to determine if a recording is in progress or not.

# Session properties and methods

| CKFPhotoSession | CKFVideoSession |
|----------------|----------------|
| `zoom: Double` | `zoom: Double` |
| `resolution: CGSize` | `isRecording: Bool` |
| `cameraPosition: CameraPosition` | `cameraPosition: CameraPosition` |
| `cameraDetection: CameraDetection` | `flashMode: FlashMode` |
| `flashMode: FlashMode` | `start()` |
| `start()` | `stop()` |
| `stop()` | `togglePosition()` |
| `focus(at point: CGPoint)` | `setWidth(_ width: Int, height: Int, frameRate: Int)` |
| `togglePosition()` | `record(url: URL? = nil, _ callback: @escaping (URL) -> Void, error: @escaping (Error) -> Void)` |
| `capture(_ callback: @escaping (UIImage, AVCaptureResolvedPhotoSettings) -> Void, _ error: @escaping (Error) -> Void)` | `stopRecording()` |

# Import into Objective-C projects

Go to `Project Settings`, `Build Settings`, `Always Embed Swift Standard Libraries` and set the value to `Yes`.

Then import the CameraKit framework using:

```objc
@import CameraKit;
```

# Creating custom sessions

CameraKit can be splitted into 2 main pieces: preview and sessions. The sessions are made by extending the base `CKFSession` class. If you want a custom session you can extend the `CKFSession` class and use its static helpers to initialize yours. Or you can also extend the built-in sessions and add custom logic.

```swift
class MyCustomSession: CKFSession {

    public override init() {
        super.init()
        
        do {
            let deviceInput = try CKFSession.captureDeviceInput(type: .backCamera)
            self.session.addInput(deviceInput)
        } catch let error {
            print(error.localizedDescription)
        }
    }

    // TODO: Add your code here
}
```

# License

CameraKit is released under the [MIT License](LICENSE.md).
