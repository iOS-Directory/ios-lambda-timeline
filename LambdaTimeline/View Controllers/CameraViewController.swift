//
//  CameraViewController.swift
//  LambdaTimeline
//
//  Created by FGT MAC on 4/30/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import UIKit
import AVFoundation
import MapKit

class CameraViewController: UIViewController {
    
    
    //MARK: - Properties
    lazy private var captureSession = AVCaptureSession()
    lazy private var fileOutput = AVCaptureMovieFileOutput()
    private var outputFileURL: URL?
    private var player: AVPlayer!
    var postController: PostController!
    var location: CLLocationCoordinate2D?
    
    //MARK: - Oulets
    @IBOutlet weak var cameraView: CameraPreviewView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    
    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        setupCaptureSession()
        saveButton.isEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureSession.startRunning()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        captureSession.stopRunning()
    }
    
    //MARK: - Custom Methods
    
    private func setupCaptureSession() {
        //Get the best available camera
        let camera = bestCamera()
        
        captureSession.beginConfiguration()
        
        // Add inputs
        
        guard let cameraInput = try? AVCaptureDeviceInput(device: camera),
            captureSession.canAddInput(cameraInput) else {
                fatalError("Can't create an input from the camera, do something better than crashing")
        }
        captureSession.addInput(cameraInput)
        
        //Set video quality
        if captureSession.canSetSessionPreset(.hd1920x1080) {
            captureSession.sessionPreset = .hd1920x1080
        }
        
        //setup audio
        let microphone = bestAudio()
        guard let audioInput = try? AVCaptureDeviceInput(device: microphone), captureSession.canAddInput(audioInput) else {
            fatalError("Can't create and add input from microphone")
        }
        captureSession.addInput(audioInput)
        
        
        //Add output
        guard captureSession.canAddOutput(fileOutput) else {
            fatalError("Cannot record movie to disk")
        }
        captureSession.addOutput(fileOutput)
        
        captureSession.commitConfiguration()
        
        //Set to preview
        cameraView.session = captureSession
    }
    
    private func bestCamera() -> AVCaptureDevice {
        if let device = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) {
            //If this camera is available then we return it
            return device
        }
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            //If this camera is available then we return it
            return device
        }
        fatalError("No cameras on the device (or you are running it on the iPhone simulator")
    }
    
    private func bestAudio() -> AVCaptureDevice {
        if let device = AVCaptureDevice.default(for: .audio) {
            return device
        }
        fatalError("No audio")
    }
    
    private func toggleRecord(){
        if fileOutput.isRecording {
            fileOutput.stopRecording()
        }else{
            fileOutput.startRecording(to: newRecordingURL(), recordingDelegate: self)
        }
    }
    
    private func newRecordingURL() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        let name = formatter.string(from: Date())
        let fileURL = documentsDirectory.appendingPathComponent(name).appendingPathExtension("mov")
        return fileURL
    }
    
    private func updateView(){
        recordButton.isSelected = fileOutput.isRecording
        saveButton.isEnabled = !fileOutput.isRecording
    }
    
    private func playMovie(url: URL){
        player = AVPlayer(url: url)
        
        //To present a video we need a diferent layer than the one presenting the live video
        let playerLayer = AVPlayerLayer(player: player)
        
        //Put the vide tumbnail on the top left corner
        var topRect = view.bounds
        topRect.size.height = topRect.size.height / 4
        topRect.size.width = topRect.size.width / 4
        //Prevent the tuhbnail from going out of the safe area
        topRect.origin.y = view.layoutMargins.top
        
        playerLayer.frame = topRect
        //Added to the view
        view.layer.addSublayer(playerLayer)
        
        //Automatically play the movie
        player.play()
    }
    
    //MARK: - Actions
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        toggleRecord()
    }
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        
        //1.Create popup alert
        let alert = UIAlertController(title: "Save Video Recording", message: "Enter Title below", preferredStyle: .alert)
        
        //2.Create textfield
        var titleTextField: UITextField?
        
        alert.addTextField { (textField) in
            textField.placeholder = "Title:"
            titleTextField = textField
        }
        
        //3.Button to confirm save
        let addTitleAction = UIAlertAction(title: "Save", style: .default) { (_) in
            
            //Make sure there is a title
            guard let titleText = titleTextField?.text, titleText != "" else {
                self.presentInformationalAlertController(title: "Oops", message: "You must specify a title, please try saving the video again.")
                return
            }
            
            //Fix
            guard let url = self.outputFileURL else {
                print("Error while getting file from URL: \(self.outputFileURL!)")
                return
                
            }
            
            //FIXME: Save video to FireBase
            self.postController.createPost(with: titleText, ofType: .video, mediaData: nil, dataURL: url,ratio: nil, geoTag: self.location ){ (success) in
            
                //Handle unsuccessful post
                guard success else {
                    DispatchQueue.main.async {
                        self.presentInformationalAlertController(title: "Error", message: "Unable to create post. Try again.")
                    }
                    return
                }
                
                //Dismiss view
                DispatchQueue.main.async {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        //Add it to the alert
        alert.addAction(addTitleAction)
        alert.addAction(cancelAction)
        
        //Present it to the view
        present(alert, animated: true,completion: nil)
    }
    
}



//MARK: - AVCaptureFileOutputRecordingDelegate
extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        updateView()
    }
    
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error{
            print("Error saving video: \(error)")
        }else{
        print("Recorded link: \(outputFileURL)")
        playMovie(url: outputFileURL)
        //pass the url to be use during the save event
        self.outputFileURL = outputFileURL
        
        updateView()
    }
    }
    
    
}
