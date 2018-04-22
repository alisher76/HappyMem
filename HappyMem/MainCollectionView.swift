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

class MainCollectionView: UICollectionViewController {
    
    var memories = [URL]()

    override func viewDidLoad() {
        super.viewDidLoad()
        checkPermission()
        loadMemories()
        
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

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
    
        // Configure the cell
    
        return cell
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
