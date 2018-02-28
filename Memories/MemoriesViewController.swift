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
import CoreSpotlight
import MobileCoreServices


class MemoriesViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout, AVAudioRecorderDelegate {

	var memories = [URL]()
	var activeMemory: URL!
	var audioRecorder: AVAudioRecorder?
	var recordingURL: URL!
	var audioPlayer: AVAudioPlayer?
	var filteredMemories = [URL]()
	var searchQuery:CSSearchQuery?
	
	
	
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
		recordingURL = getDocumentsDirectory().appendingPathComponent("recording.m4a")
		
		
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
		filteredMemories = memories
		
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
			return filteredMemories.count
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
		let memory = filteredMemories[indexPath.row]
		let imageName = thumbnailURL(for: memory).path
		let image = UIImage.init(contentsOfFile: imageName)
		
		cell.imageView.image = image
		
		if cell.gestureRecognizers == nil {
			let recognizer = UILongPressGestureRecognizer(target: self, action: #selector (memoryLongPress))
			recognizer.minimumPressDuration = 0.25
			cell.addGestureRecognizer(recognizer)
			cell.layer.borderColor = UIColor.white.cgColor
			cell.layer.borderWidth = 3
			cell.layer.cornerRadius = 10
			
		}
		
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
	
	@objc func memoryLongPress(sender: UILongPressGestureRecognizer) {
		
		if sender.state == .began {
			let cell = sender.view as! MemoryCell
			
			if let index = collectionView?.indexPath(for: cell) {
				activeMemory = filteredMemories[index.row]
				recordMemory()
			}
		} else if sender.state == .ended {
			finishRecording(success: true)
		}
	}
	
	func recordMemory() {
		
		audioPlayer?.stop()
		
		//1 - the easy bit!
		
		collectionView?.backgroundColor = UIColor(red: 0.5, green: 0, blue: 0, alpha: 1)
		
		//this just saves writing AVAudioSession.sharedIntance() everywhere
		
		let recordingSession = AVAudioSession.sharedInstance()
		
		do {
		//2 - configure the session for recording and playback through the speaker
			
			try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
			
		//3 - set up a high quality recording session
			
			let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 44100, AVNumberOfChannelsKey: 2, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
			
		//4 - create the audio recording, and assign ourselves as the delegate
			
			audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
			audioRecorder?.delegate = self
			audioRecorder?.record()
			
		} catch let error {
			//failed to record
			print("Failed to record: \(error)")
			
			finishRecording(success: false)
		}
	}
	
	func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
		if !flag {
			finishRecording(success: false)
		}
	}
	
	func finishRecording(success: Bool) {
		//1 - change BG color
		collectionView?.backgroundColor = UIColor.darkGray
		
		//2- stop the recording
		audioRecorder?.stop()
		
		if success {
			do {
				//3 - create a URL out of the activeMemory URL + m4a
				let memoryAudioURL = activeMemory.appendingPathExtension("m4a")
				let fm = FileManager.default
				
				//4 - Delete existing recordings
				if fm.fileExists(atPath: memoryAudioURL.path) {
				try fm.removeItem(at: memoryAudioURL)
			}
			//5 - move recorded file into the memories audio URL
			try fm.moveItem(at: recordingURL, to: memoryAudioURL)
				
			//6 - start transciption
			transcribeAudio(memory: activeMemory)
				
			} catch let error {
				print("Failure finishing recording: \(error)")
			}
		}
	}
	
	func transcribeAudio(memory: URL) {
		
		//get paths to where the audio is, and where the transcription should be
		let audio = audioURL(for: memory)
		let transcription = transcriptionURL(for: memory)
		
		//create a new recognizer and point it at our audio
		let recognizer = SFSpeechRecognizer()
		let request = SFSpeechURLRecognitionRequest(url: audio)
		
		//start recognition
		recognizer?.recognitionTask(with: request) { [ unowned self] (result, error) in
			
			//abort if we didnt get any transcription back
			guard let result = result else {
				print("There was an error: \(error!)")
				return
			}
			//if we got the final transcription back, we need to write it to disk
			if result.isFinal {
				
				// pull out the best transcription ...
				let text = result.bestTranscription.formattedString
				
				//...and write it to disk at the correct filename for this memory
				do {
					try text.write(to: transcription, atomically: true, encoding: String.Encoding.utf8)
					self.indexMemory(memory: memory, text: text)
					
				} catch {
					print("Failed to save transcription")
				}
			}
		}
	}
	
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		
		let memory =  filteredMemories[indexPath.row]
		let fm = FileManager.default
		
		do {
			let audioName = audioURL(for: memory)
			let transcriptionName = transcriptionURL(for: memory)
			
			if fm.fileExists(atPath: audioName.path) {
				audioPlayer = try AVAudioPlayer(contentsOf: audioName)
				audioPlayer?.play()
			}
			
			if fm.fileExists(atPath: transcriptionName.path) {
				let contents = try String(contentsOf: transcriptionName)
				
				print(contents)
				
			}
		} catch {
			print("Error loading audio")
		}
	}
	
	func indexMemory(memory: URL, text: String) {
		
		//create a basic attribute set
		let attributeset = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
		
		attributeset.title = "Memories"
		attributeset.contentDescription = text
		attributeset.thumbnailURL = thumbnailURL(for: memory)
		
		
		//wrap it in a searchable item, using the memory's full path as its unique identifier
		let item = CSSearchableItem(uniqueIdentifier: memory.path, domainIdentifier: "com.FarmLodgeApps", attributeSet: attributeset)
		
		//make it never expire
		item.expirationDate = Date.distantFuture
		
		//asl spotlight to index the item
		
		CSSearchableIndex.default().indexSearchableItems([item]) { error in
			
			if let error = error {
				print("Indexing error: \(error.localizedDescription)")
			} else {
				print("Search item successfully indexed: \(text)")
			}
		}
	}
	
	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		
		filteredMemories(text: searchText)
	}
	
	func searchBarButtonClicked(_ searchBar: UISearchBar) {
		
		searchBar.resignFirstResponder()
	}
	
	func filteredMemories(text: String) {
		
		guard text.isEmpty else {
			
			filteredMemories = memories

			UIView.performWithoutAnimation {
				collectionView?.reloadSections(IndexSet(integer: 1))
			}
			return
		}
		
		var allItems = [CSSearchableItem]()
		
		searchQuery?.cancel()
		
		let queryString = "contentDescription == \"*\(text)*\"c"
		
		searchQuery = CSSearchQuery(queryString: queryString, attributes: nil)
		
		searchQuery?.foundItemsHandler = { items in
			allItems.append(contentsOf: items)
		}
		searchQuery?.completionHandler = { error in
			DispatchQueue.main.async { [unowned self] in
				self.activateFilter(matches: allItems)
			}
		}
		
		searchQuery?.start()
	}
	
	func activateFilter(matches:[CSSearchableItem]) {
		
		filteredMemories = matches.map { item in
			
			return URL(fileURLWithPath: item.uniqueIdentifier)
			
		}
		
		UIView.performWithoutAnimation {
			collectionView?.reloadSections(IndexSet(integer: 1))
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
