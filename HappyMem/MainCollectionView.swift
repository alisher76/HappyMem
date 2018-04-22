//
//  MainCollectionView.swift
//  HappyMem
//
//  Created by Alisher Abdukarimov on 4/22/18.
//  Copyright © 2018 Alisher Abdukarimov. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Speech


private let reuseIdentifier = "cell"
private let reuseIdentifierHeader = "header"

class MainCollectionView: UICollectionViewController, UICollectionViewDelegateFlowLayout, AVAudioRecorderDelegate {
    
    var memories = [URL]()
    var activeMemory: URL!
    // For Aduio
    var audioRecorder: AVAudioRecorder?
    var recordingURL: URL!

    override func viewDidLoad() {
        super.viewDidLoad()
        checkPermission()
        loadMemories()
        
        recordingURL = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        // adding navigation button
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 0
        } else {
            return memories.count
        }
    }

    // MARK: Cell For Item At
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? PhotoCell else { return UICollectionViewCell() }
    
        // Configure the cell
        let photoMem = memories[indexPath.row]
        let imageName = thumbnailURL(for: photoMem).path
        let image = UIImage(contentsOfFile: imageName)
        cell.imageView.image = image
        
        if cell.gestureRecognizers == nil {
            let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(memoryLongPress))
            recognizer.minimumPressDuration = 0.25
            cell.addGestureRecognizer(recognizer)
            
            cell.layer.borderColor = UIColor.white.cgColor
            cell.layer.cornerRadius = 5.0
            cell.layer.borderWidth = 2.0
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: reuseIdentifierHeader, for: indexPath)
    }
    
    // we will use the dedicated method loadMemomories()
    // this method needs several steps
    // 1 Remove existing memories not to have duplicates
    // 2 Pull out a list of all the files that are stored in our apps directory folder
    // 3 Loop over ecery file that was found and if it was a thumbnail add it to our memories array
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 1 {
            return CGSize.zero
        } else {
            return CGSize(width: 0, height: 50)
        }
    }
    
    func loadMemories() {
        memories.removeAll()
        
        // attempt to load all the mems in direc
        guard let files = try? FileManager.default.contentsOfDirectory(at: getDocumentsDirectory(), includingPropertiesForKeys: nil, options: []) else { return }
        
        // loop over every file found
        for file in files {
            let fileName = file.lastPathComponent
            
            // check it ends with ".thumb" so we dont count each mem more than once
            if fileName.hasSuffix(".thumb") {
                // get the root name of the mem without its paths extension
                let noExtension = fileName.replacingOccurrences(of: ".thumb", with: "")
                
                //create a fill path from the memory
                let memoryPath = getDocumentsDirectory().appendingPathComponent(noExtension)
                
                // add it to our array
                memories.append(memoryPath)
            }
        }
        
        // reload our list of memories
        // the reason to use section reload on collection view to avoid reloading the search box
        collectionView?.reloadSections(IndexSet(integer: 1))
    }
    
    

    func checkPermission() {
        // Check status for all three permissions
        let photosAuthorized = PHPhotoLibrary.authorizationStatus() == .authorized
        let recordingAuthorized = AVAudioSession.sharedInstance().recordPermission() == .granted
        let transcribeAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
        
        // Make a single Boolean value out of all three
        let authorized = photosAuthorized && recordingAuthorized && transcribeAuthorized
        
        // if we are missing one, show the first run screen
        if authorized == false {
            if let vc = storyboard?.instantiateViewController(withIdentifier: "firstrunVC") as? FirstVC {
                navigationController?.present(vc, animated: true)
            }
        }
    }
    
    func imageURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("jpg")
    }
    
    func thumbnailURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("thumb")
    }
    
    func audioURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("m4a")
    }
    
    func transcriptionURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("txt")
    }
    
    // MARK: Long press, figure out which cell is being pressed
    @objc func memoryLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let cell = sender.view as! PhotoCell
            
            if let index = collectionView?.indexPath(for: cell) {
                activeMemory = memories[index.row]
                recordMemomory()
            }
        } else if sender.state == .ended {
            finishRecording(success: true)
        }
    }
    
     // MARK: Recording Method
    func recordMemomory() {
        // Recording in iOS ViewController needs to confrom to AVAudioRecordDelegate
        // Step 1 set the backgroung to red to let the user know that audio is being recorded
        collectionView?.backgroundColor = UIColor(red: 0.5, green: 0, blue: 0, alpha: 1)
        
        let recordingSession = AVAudioSession.sharedInstance()
        
        do {
            // step 2 configure the session for recording and playback
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
            try recordingSession.setActive(true)
            
            // step 3 set up a high quaility recording session
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            // step 4 create the audio recording and assign ourselces as the delegate
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
        } catch let error {
            // failed to record
            print("Failed to record error: \(error)")
            finishRecording(success: false)
        }
    }
    
    func finishRecording(success: Bool) {
        
    }
    
    func transcribeAudio() {
        
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
}

extension MainCollectionView: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // AddButton tapped
    @objc func addTapped() {
        let vc = UIImagePickerController()
        vc.modalPresentationStyle = .formSheet
        vc.delegate = self
        navigationController?.present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let possobleImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            saveNewMemory(image: possobleImage)
            loadMemories()
        }
    }
    
    func saveNewMemory(image: UIImage) {
        // Saving the image steps:
        // 1  Gen new unique name for the mem - NSUUID or currentDateTime
        // 2  Use the unique name to create a file
        // 3  Try to create an absolute URL
        // 4  Convert Images it receives into JPEG
        // 5  Write the data into disk
        // 6  Create thumbnail for the image
        
        // create a unique name
        let memoryName = "memory-\(Date().timeIntervalSince1970)"
        
        // use the unique name to create a filename
        
        let imageName = memoryName + ".jpg"
        let thumbNailName = memoryName + ".thumb"
        
        do {
            // create url
            let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
            
            // convert the image into JPEG
            if let jpegData = UIImageJPEGRepresentation(image, 80) {
                // write data into disk
                try jpegData.write(to: imagePath, options: [.atomicWrite])
            }
            // create a thumbnail
            if let thumbnail = resize(image: image, to: 200) {
                let imagePath = getDocumentsDirectory().appendingPathComponent(thumbNailName)
                if let jpegData = UIImageJPEGRepresentation(thumbnail, 80) {
                    try jpegData.write(to: imagePath, options: [.atomicWrite])
                }
            }
            
        } catch {
            print("Failed to convert")
        }
    }
    
    func resize(image: UIImage, to width: CGFloat) -> UIImage? {
        
        // calculate how much we need to bring the width down to mathc our target size
        let scale = width / image.size.width
        
        // bring the height down the same amount
        let height = image.size.height * scale
        
        // create a new image context we can draw into
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)
        
        // fraw the original image int the context
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // pull out tge resuzed version
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // end the context so UIKit can clean up
        UIGraphicsEndImageContext()
        
        // send it back
        return newImage
    }
}
