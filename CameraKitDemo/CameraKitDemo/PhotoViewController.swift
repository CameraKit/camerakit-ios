//
//  PhotoViewController.swift
//  CameraKitDemo
//
//  Created by Adrian Mateoaea on 08/01/2019.
//  Copyright © 2019 Wonderkiln. All rights reserved.
//

import UIKit
import CameraKit

class PhotoPreviewViewController: UIViewController, UIScrollViewDelegate {
    
    var image: UIImage?
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var imageView: UIImageView!
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.image = self.image
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBAction func handleCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func handleSave(_ sender: Any) {
        if let image = self.image {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(handleDidCompleteSavingToLibrary(image:error:contextInfo:)), nil)
        }
    }
        
    @objc func handleDidCompleteSavingToLibrary(image: UIImage?, error: Error?, contextInfo: Any?) {
        self.dismiss(animated: true, completion: nil)
    }
}

class PhotoSettingsViewController: UITableViewController {
    
    var squareLayoutConstraint: NSLayoutConstraint!
    var wideLayoutConstraint: NSLayoutConstraint!
    var previewView: CKFPreviewView!
    
    @IBOutlet weak var cameraSegmentControl: UISegmentedControl!
    @IBOutlet weak var flashSegmentControl: UISegmentedControl!
    @IBOutlet weak var faceSegmentControl: UISegmentedControl!
    @IBOutlet weak var gridSegmentControl: UISegmentedControl!
    @IBOutlet weak var modeSegmentControl: UISegmentedControl!
    
    @IBAction func handleCamera(_ sender: UISegmentedControl) {
        if let session = self.previewView.session as? CKFPhotoSession {
            session.cameraPosition = sender.selectedSegmentIndex == 0 ? .back : .front
        }
    }
    
    @IBAction func handleFlash(_ sender: UISegmentedControl) {
        if let session = self.previewView.session as? CKFPhotoSession {
            let values: [CKFPhotoSession.FlashMode] = [.auto, .on, .off]
            session.flashMode = values[sender.selectedSegmentIndex]
        }
    }
    
    @IBAction func handleFace(_ sender: UISegmentedControl) {
        if let session = self.previewView.session as? CKFPhotoSession {
            session.cameraDetection = sender.selectedSegmentIndex == 0 ? .none : .faces
        }
    }
    
    @IBAction func handleGrid(_ sender: UISegmentedControl) {
        self.previewView.showGrid = sender.selectedSegmentIndex == 1
    }
    
    @IBAction func handleMode(_ sender: UISegmentedControl) {
        if let session = self.previewView.session as? CKFPhotoSession {
            if sender.selectedSegmentIndex == 0 {
                session.resolution = CGSize(width: 3024, height: 4032)
                self.squareLayoutConstraint.priority = .defaultLow
                self.wideLayoutConstraint.priority = .defaultHigh
            } else {
                session.resolution = CGSize(width: 3024, height: 3024)
                self.squareLayoutConstraint.priority = .defaultHigh
                self.wideLayoutConstraint.priority = .defaultLow
            }
        }
    }
}

class PhotoViewController: UIViewController, CKFSessionDelegate {
    
    @IBOutlet weak var squareLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var wideLayoutConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var zoomLabel: UILabel!
    @IBOutlet weak var captureButton: UIButton!
    
    func didChangeValue(session: CKFSession, value: Any, key: String) {
        if key == "zoom" {
            self.zoomLabel.text = String(format: "%.1fx", value as! Double)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? PhotoSettingsViewController {
            vc.previewView = self.previewView
            vc.squareLayoutConstraint = self.squareLayoutConstraint
            vc.wideLayoutConstraint = self.wideLayoutConstraint
        } else if let nvc = segue.destination as? UINavigationController, let vc = nvc.children.first as? PhotoPreviewViewController {
            vc.image = sender as? UIImage
        }
    }
    
    @IBOutlet weak var previewView: CKFPreviewView! {
        didSet {
            let session = CKFPhotoSession()
            session.resolution = CGSize(width: 3024, height: 4032)
            session.delegate = self
            
            self.previewView.autorotate = true
            self.previewView.session = session
            self.previewView.previewLayer?.videoGravity = .resizeAspectFill
        }
    }
    
    @IBOutlet weak var panelView: UIVisualEffectView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.panelView.transform = CGAffineTransform(translationX: 0, y: self.panelView.frame.height + 5)
        self.panelView.isUserInteractionEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.previewView.session?.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.previewView.session?.stop()
    }
    
    @IBAction func handleSwipeDown(_ sender: Any) {
        self.panelView.isUserInteractionEnabled = false
        self.captureButton.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.2) {
            self.panelView.transform = CGAffineTransform(translationX: 0, y: self.panelView.frame.height)
        }
    }
    
    @IBAction func handleSwipeUp(_ sender: Any) {
        self.panelView.isUserInteractionEnabled = true
        self.captureButton.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.2) {
            self.panelView.transform = CGAffineTransform(translationX: 0, y: 0)
        }
    }
    
    @IBAction func handleCapture(_ sender: Any) {
        if let session = self.previewView.session as? CKFPhotoSession {
            session.capture({ (image, _) in
                self.performSegue(withIdentifier: "Preview", sender: image)
            }) { (_) in
                //
            }
        }
    }
    
    @IBAction func handleVideo(_ sender: Any) {
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Video")
        UIView.transition(with: window, duration: 0.5, options: .transitionFlipFromLeft, animations: {
            window.rootViewController = vc
        }, completion: nil)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
