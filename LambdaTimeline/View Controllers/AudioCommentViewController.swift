//
//  AudioCommentViewController.swift
//  LambdaTimeline
//
//  Created by FGT MAC on 4/23/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import UIKit
import AVFoundation

class AudioCommentViewController: UIViewController {
    
    //MARK: - Properties
    
    var post: Post?
    
    private var postController = PostController()
    private var recordingURL: URL?
    private var audioRecorder: AVAudioRecorder?
    private var isRecording: Bool {
        //Check if is currently recoding and give a default value of false
        return audioRecorder?.isRecording ?? false
    }
 
    
    //MARK: - Outlets
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    
    //MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        updateViews()
        saveButton.isHidden = true
        try? prepareAudioSession()
    }
    
    //MARK: - Actions
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        saveRecording()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelButton(_ sender: UIButton) {
        stopRecording()
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func toggleRecord(_ sender: UIButton) {
        if isRecording{
            stopRecording()
        }else{
            requestPermissionOrStartRecording()
        }
    }
    
    //MARK: - Custom Methods
    
    func startRecording() {
        
        let recordingURL = newRecordingURL()
        
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        
        do{
            audioRecorder = try AVAudioRecorder(url: recordingURL, format: format)
        }catch{
            NSLog("Error recording Audio: \(error)")
        }
        audioRecorder?.record()
        audioRecorder?.delegate = self
        updateViews()
        
        self.recordingURL = recordingURL
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        updateViews()
    }
    
    func saveRecording() {
        //Create comment
        print(recordingURL!)
        if var postInfo = post{
            self.postController.addComment(with: nil, audioURL: recordingURL, to: &postInfo)
        }
   
    }
    
    private func newRecordingURL()-> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let name = ISO8601DateFormatter.string(from: Date(), timeZone: .current, formatOptions: .withInternetDateTime)
        let file = documents.appendingPathComponent(name, isDirectory: false).appendingPathExtension("caf")
        return file
    }
    
    func updateViews() {
        recordButton.isSelected = isRecording
    }
    
    func prepareAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, options: [.defaultToSpeaker])
        try session.setActive(true, options: []) // can fail if on a phone call, for instance
    }
    
    func requestPermissionOrStartRecording() {
        self.audioRecorder = nil
        saveButton.isHidden = true
        
        switch AVAudioSession.sharedInstance().recordPermission {
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                guard granted == true else {
                    print("We need microphone access")
                    return
                }
                
                print("Recording permission has been granted!")
                // NOTE: Invite the user to tap record again, since we just interrupted them, and they may not have been ready to record
            }
        case .denied:
            print("Microphone access has been blocked.")
            
            let alertController = UIAlertController(title: "Microphone Access Denied", message: "Please allow this app to access your Microphone.", preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: "Open Settings", style: .default) { (_) in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            })
            
            alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
            
            present(alertController, animated: true, completion: nil)
        case .granted:
            startRecording()
        @unknown default:
            break
        }
    }
    
}   

//MARK: - AVAudioRecorderDelegate

extension AudioCommentViewController:AVAudioRecorderDelegate{
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
   
        saveButton.isHidden = false
        self.audioRecorder = nil
        updateViews()
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        updateViews()
        if let error = error{
            NSLog("Error ecoder error: \(error)")
        }
    }
}
