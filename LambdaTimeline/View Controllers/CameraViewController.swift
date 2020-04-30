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
    
    //MARK: - Oulets
    @IBOutlet weak var camaraView: CameraPreviewView!
    @IBOutlet weak var recordButton: UIButton!
    
    
    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    //MARK: - Custom Methods
    
    func setupCaptureSession() {
        
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
    

    //MARK: - Actions
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        print("Start Recording")
    }
    

}
