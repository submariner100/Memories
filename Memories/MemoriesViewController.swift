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


class MemoriesViewController: UICollectionViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

	
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
	
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
