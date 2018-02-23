//
//  MemoriesViewController.swift
//  Memories
//
//  Created by Macbook on 18/02/2018.
//  Copyright © 2018 Lodge Farm Apps. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Speech


class MemoriesViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout {

	var memories = [URL]()
	
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
		
		loadMemories()
	
    }
	
	func checkPermissions() {
		
		// check status for all 3 permissions
		
		let photosAuthorized = PHPhotoLibrary.authorizationStatus() == .authorized
		let recordingAuthorized = AVAudioSession.sharedInstance().recordPermission() == .granted
		let transcribeAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
		
		// make a single boolean for all 3
		
		let authorized = photosAuthorized && recordingAuthorized && transcribeAuthorized
		
		// if we are missing one, show the first run screen
		
		if authorized == false {
			
			if let vc = storyboard?.instantiateViewController(withIdentifier: "First Run") {
				navigationController?.present(vc, animated: true)
			}
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		checkPermissions()
	}
	
	func getDocumentsDirectory() -> URL {
		
		let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		let documentsDirectory = paths[0]
		
		return documentsDirectory
		
	}
	
	func loadMemories() {
		
		memories.removeAll()
		
		//Attempt to load all the memories in our documents directory
		
		guard let files = try?
			FileManager.default.contentsOfDirectory(at: getDocumentsDirectory(), includingPropertiesForKeys: nil, options: []) else { return }
		
		//loop over every file found
		
		for file in files {
			let filename = file.lastPathComponent
		
			//check it ends with ".thumb" so we dont count each memory more than once
			
			if filename.hasSuffix(".thumb") {
				
				//get the root name of the memory (ie., without its path extension)
				
				let noExtension = filename.replacingOccurrences(of: ".thumb", with: "")
				
				//create a full path from the memory
				
				let memoryPath = getDocumentsDirectory().appendingPathComponent(noExtension)
				
				//add it to our array
				
				memories.append(memoryPath)
			}
		}
		
		//reload our list of memories
		collectionView?.reloadSections(IndexSet(integer: 1))
	}
	
	@objc func addTapped() {
		
		let vc = UIImagePickerController()
		vc.modalPresentationStyle = .formSheet
		vc.delegate = self
		navigationController?.present(vc, animated: true)
	}
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		dismiss(animated: true)
		
		if let possibleImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
			
			saveNewMemory(image: possibleImage)
			loadMemories()
		}
	}
	
	func saveNewMemory(image: UIImage) {
		
		//create a unique name for this memory
		let memoryName = "memory-\(Date().timeIntervalSince1970)"
		
		//use the unique name to create filenames for the full size image and the thumbnail
		let imageName = memoryName + ".jpg"
		let thumbnailName = memoryName + ".thumb"
		
		do {
			//create a URL where we can write the JPEG to
			let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
			
			//convert the UIImage into a JPEG data object
			if let jpegData = UIImageJPEGRepresentation(image, 80) {
				
				//write that data to the URL we created
				try jpegData.write(to: imagePath, options: [.atomicWrite])
			}
			//create thumbnail here
		
			if let thumbnail = resize(image: image, to: 200) {
				
				let imagePath = getDocumentsDirectory().appendingPathComponent(thumbnailName)
				
				if let jpegData = UIImageJPEGRepresentation(thumbnail, 80) {
					try jpegData.write(to: imagePath, options: [.atomicWrite])
				}
			}
			
		} catch {
			print("Failed to save to disk.")
		}
	}
		
	func resize(image: UIImage, to width: CGFloat) -> UIImage? {
			
			//calculate how much we need to bring the width down to match our target size
			
			let scale = width / image.size.width
			
			//bring the height down by the same amount so that the aspect ratio is preserved
			let height = image.size.height * scale
			
			//create a new image context we can draw into
			UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)
			
			//draw the original image into the context
			image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
			
			//pull out the resized version
			let newImage = UIGraphicsGetImageFromCurrentImageContext()
			
			//end the context so UIKit can clean up
			UIGraphicsEndImageContext()
			
			//send it back to the caller
			return newImage
		}
	
	override func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 2
	}
	
	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		if section == 0 {
			return 0
		} else {
			return memories.count
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
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Memory", for: indexPath) as! MemoryCell
		let memory = memories[indexPath.row]
		let imageName = thumbnailURL(for: memory).path
		let image = UIImage.init(contentsOfFile: imageName)
		
		cell.imageView.image = image
		return cell
	}
	
	override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath)
		
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
	
		if section == 1 {
			return CGSize.zero
		} else {
			return CGSize(width: 0, height: 50)
		}
	}
	
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
