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
    
    
    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        setupCaptureSession()
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
    
    func setupCaptureSession() {
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
    
    func bestCamera() -> AVCaptureDevice {
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
    

    //MARK: - Actions
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        print("Start Recording")
    }
    

}
