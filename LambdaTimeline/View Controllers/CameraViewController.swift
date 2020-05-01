//
//  CameraViewController.swift
//  LambdaTimeline
//
//  Created by FGT MAC on 4/30/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {

    
    //MARK: - Properties
    lazy private var captureSession = AVCaptureSession()
    
    lazy private var fileOutput = AVCaptureMovieFileOutput()
    
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
            
            //FIXME: Save video to FireBase
            
            print("Pressed saved: \(titleText)")
            
            //Dismiss view
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
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
        }
        updateView()
        //TODO: Save url to firebase to retrive video later
        if outputFileURL.isFileURL{
            
            print(outputFileURL.absoluteString)
        }else{
            saveButton.isEnabled = false
        }
        
    }
    

}
