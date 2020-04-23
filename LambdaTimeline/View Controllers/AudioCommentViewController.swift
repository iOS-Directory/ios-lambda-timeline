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
    
    
    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateViews()
        try? prepareAudioSession()
    }
    
    //MARK: - Actions
    @IBAction func doneButtonPressed(_ sender: UIButton) {
        audioRecorder?.stop()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func toggleRecord(_ sender: UIButton) {
        
        
        
        guard !isRecording else {
            //already recording then toggle to stop recording and return to block continuing
            audioRecorder?.stop()
            updateViews()
            return
        }
        
        
        do{
            let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)!
            audioRecorder = try AVAudioRecorder(url: newRecordingURL(), format: format)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            updateViews()
        }catch{
            NSLog("Unable to start recording: \(error)")
        }
    }
    
    //MARK: - Custom Methods
    
    private func newRecordingURL()-> URL {
        let fm = FileManager.default
        let documentsDir = try! fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
        //MAKE A Unique path using UUID, The “caf” extension stands for Core Audio Format.
        return documentsDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("caf")
    }
    
    func updateViews() {
          recordButton.isSelected = isRecording
     }
    
    func prepareAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, options: [.defaultToSpeaker])
        try session.setActive(true, options: []) // can fail if on a phone call, for instance
    }
}   
 

//MARK: - AVAudioRecorderDelegate

extension AudioCommentViewController:AVAudioRecorderDelegate{
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        updateViews()
        //get the url and save it to the var recordingURL
        recordingURL = recorder.url
        
        //Create comment
        if var postInfo = post{
               self.postController.addComment(with: nil, audioURL: recordingURL, to: &postInfo)
           }
        
        self.audioRecorder = nil
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        updateViews()
        if let error = error{
             NSLog("Error ecoder error: \(error)")
        }
    }
}
