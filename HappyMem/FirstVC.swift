//
//  ViewController.swift
//  HappyMem
//
//  Created by Alisher Abdukarimov on 4/22/18.
//  Copyright © 2018 Alisher Abdukarimov. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Speech

class FirstVC: UIViewController {

    @IBOutlet weak var helpLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }

    @IBAction func permissonBtnTapped(_ sender: Any) {
        requestPhotosPermissions()
    }
    
    // To get photos authorization we need to call requestAuthorization() on the PHPhotoLibrary class.
    
    func requestPhotosPermissions() {
        PHPhotoLibrary.requestAuthorization { [unowned self] (authstatus) in
            DispatchQueue.main.async {
                if authstatus == .authorized {
                    self.requestRecordPermissions()
                } else {
                    self.helpLabel.text = "Please Permission was declined click the thumbs up again to give us permission."
                }
            }
        }
    }
    
    func requestRecordPermissions() {
        AVAudioSession.sharedInstance().requestRecordPermission { [unowned self] (allowed) in
            DispatchQueue.main.async {
                if allowed {
                    self.requestTranscribePermission()
                } else {
                    self.helpLabel.text = "Please Permission was declined click the thumbs up again to give us permission."
                }
            }
        }
    }
    
    func requestTranscribePermission() {
        SFSpeechRecognizer.requestAuthorization { [unowned self] (authStatus) in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.authorizationComplete()
                } else {
                    self.helpLabel.text = "Please Permission was declined click the thumbs up again to give us permission."
                }
            }
        }
    }
    
    func authorizationComplete() {
        dismiss(animated: true)
    }
}

