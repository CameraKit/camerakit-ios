//
//  VideoViewController.swift
//  CameraKitDemo
//
//  Created by Adrian Mateoaea on 17/01/2019.
//  Copyright © 2019 Wonderkiln. All rights reserved.
//

import UIKit
import CameraKit
import AVKit

class VideoPreviewViewController: UIViewController {
    
    var url: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let url = self.url {
            let player = AVPlayerViewController()
            player.player = AVPlayer(url: url)
            player.view.frame = self.view.bounds
            
            self.view.addSubview(player.view)
            self.addChild(player)
            
            player.player?.play()
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBAction func handleCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func handleSave(_ sender: Any) {
        if let url = self.url {
            UISaveVideoAtPathToSavedPhotosAlbum(url.path, self, #selector(handleDidCompleteSavingToLibrary(path:error:contextInfo:)), nil)
        }
    }
    
    @objc func handleDidCompleteSavingToLibrary(path: String?, error: Error?, contextInfo: Any?) {
        self.dismiss(animated: true, completion: nil)
    }
}

class VideoSettingsViewController: UITableViewController {
    
    var previewView: CKFPreviewView!
    
    @IBOutlet weak var cameraSegmentControl: UISegmentedControl!
    @IBOutlet weak var flashSegmentControl: UISegmentedControl!
    @IBOutlet weak var gridSegmentControl: UISegmentedControl!
    
    @IBAction func handleCamera(_ sender: UISegmentedControl) {
        if let session = self.previewView.session as? CKFVideoSession {
            session.cameraPosition = sender.selectedSegmentIndex == 0 ? .back : .front
        }
    }
    
    @IBAction func handleFlash(_ sender: UISegmentedControl) {
        if let session = self.previewView.session as? CKFVideoSession {
            let values: [CKFVideoSession.FlashMode] = [.auto, .on, .off]
            session.flashMode = values[sender.selectedSegmentIndex]
        }
    }
    
    @IBAction func handleGrid(_ sender: UISegmentedControl) {
        self.previewView.showGrid = sender.selectedSegmentIndex == 1
    }
    
    @IBAction func handleMode(_ sender: UISegmentedControl) {
        if let session = self.previewView.session as? CKFVideoSession {
            let modes = [(1920, 1080, 30), (1920, 1080, 60), (3840, 2160, 30)]
            let mode = modes[sender.selectedSegmentIndex]
            session.setWidth(mode.0, height: mode.1, frameRate: mode.2)
        }
    }
}

class VideoViewController: UIViewController, CKFSessionDelegate {
    
    @IBOutlet weak var zoomLabel: UILabel!
    @IBOutlet weak var captureButton: UIButton!
    
    func didChangeValue(session: CKFSession, value: Any, key: String) {
        if key == "zoom" {
            self.zoomLabel.text = String(format: "%.1fx", value as! Double)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? VideoSettingsViewController {
            vc.previewView = self.previewView
        } else if let nvc = segue.destination as? UINavigationController, let vc = nvc.children.first as? VideoPreviewViewController {
            vc.url = sender as? URL
        }
    }
    
    @IBOutlet weak var previewView: CKFPreviewView! {
        didSet {
            let session = CKFVideoSession()
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
    
    @IBAction func handleCapture(_ sender: UIButton) {
        if let session = self.previewView.session as? CKFVideoSession {
            if session.isRecording {
                sender.backgroundColor = UIColor.red.withAlphaComponent(0.5)
                session.stopRecording()
            } else {
                sender.backgroundColor = UIColor.red
                session.record({ (url) in
                    self.performSegue(withIdentifier: "Preview", sender: url)
                }) { (_) in
                    //
                }
            }
        }
    }
    
    @IBAction func handlePhoto(_ sender: Any) {
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Photo")
        UIView.transition(with: window, duration: 0.5, options: .transitionFlipFromLeft, animations: {
            window.rootViewController = vc
        }, completion: nil)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
