//
//  CameraViewController.swift
//  LambdaTimeline
//
//  Created by FGT MAC on 4/30/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import UIKit

class CameraViewController: UIViewController {

    
    //MARK: - Properties
    
    
    //MARK: - Oulets
    @IBOutlet weak var camaraView: CameraPreviewView!
    @IBOutlet weak var recordButton: UIButton!
    
    
    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    //MARK: - Actions
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        print("Start Recording")
    }
    

}
