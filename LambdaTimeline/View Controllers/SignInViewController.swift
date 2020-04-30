//
//  SignInViewController.swift
//  LambdaTimeline
//
//  Created by Spencer Curtis on 10/11/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import AVFoundation

class SignInViewController: UIViewController {
    
    //MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance()?.delegate = self
        requestPermissionAndShowCamera()
        setUpSignInButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // TODO: get permission
        
        showCamera()
        
    }
    
    //MARK: - Actions
    @IBAction func googleSignIn(_ sender: Any) {
        GIDSignIn.sharedInstance()?.signIn()
    }
    
    //MARK: - Permission
    private func requestPermissionAndShowCamera(){
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
            
        case .notDetermined:
            // First time user has seen the dialog, we don't have permission
            
            requestPermission()
        case .restricted:
            // parental controls
            
            fatalError("Video is disabled for parental controls")
        case .denied:
            // we asked for permission and they said no
            
            fatalError("Tell user they need to enable Privacy for Video/Camera/Microphone")
        case .authorized:
            // we asked for permission and they said yes
            
            showCamera()
        default:
            fatalError("A new status was added that we need to handle")
        }
    }
    
    private func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { (granted) in
            guard granted else {
                fatalError("Tell user they need to enable Privacy for Video/Camera/Microphone")
            }
            DispatchQueue.main.async { [weak self] in
                self?.showCamera()
            }
        }
    }
    
    //MARK: - Methods
    private func showCamera() {
        performSegue(withIdentifier: "ShowCamera", sender: self)
    }
}

    //MARK: - GIDSignInDelegate
extension SignInViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
        if let error = error {
            print("Error signing in with Google: \(error)")
            return
        }
        
        guard let authentication = user.authentication else { return }
        
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if let error = error {
                print("Error signing in with Google: \(error)")
                return
            }
            
            DispatchQueue.main.async {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let postsNavigationController = storyboard.instantiateViewController(withIdentifier: "PostsNavigationController")
                postsNavigationController.modalPresentationStyle = .fullScreen
                self.present(postsNavigationController, animated: true, completion: nil)
            }
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("User disconnected")
    }
    
    func setUpSignInButton() {
        
        let button = GIDSignInButton()
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(button)
        
        
        let buttonCenterXConstraint = button.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        let buttonCenterYConstraint = button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        let buttonWidthConstraint = button.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5)
        
        view.addConstraints([buttonCenterXConstraint,
                             buttonCenterYConstraint,
                             buttonWidthConstraint])
    }
}

