//
//  ImagePostViewController.swift
//  LambdaTimeline
//
//  Created by Spencer Curtis on 10/12/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Photos

class ImagePostViewController: ShiftableViewController {
    
    //MARK: - Outlets
    
    @IBOutlet weak var brightness: UISlider!
    @IBOutlet weak var contrast: UISlider!
    @IBOutlet weak var saturation: UISlider!
    @IBOutlet weak var blur: UISlider!
    @IBOutlet weak var distortionEffect: UISlider!
    
    @IBOutlet weak var brightnessLabel: UILabel!
    @IBOutlet weak var contrastLabel: UILabel!
    @IBOutlet weak var saturationLabel: UILabel!
    @IBOutlet weak var blurLabel: UILabel!
    @IBOutlet weak var distortionEffectLabel: UILabel!
    
    
    //MARK: - View LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setImageViewHeight(with: 1.0)
        
        updateViews()
        
        hideControls(shouldHide: true)
    }
    
    //MARK: - Custom Methods
    
    func hideControls(shouldHide state: Bool) {
        //Labels
        brightnessLabel.isHidden = state
        contrastLabel.isHidden = state
        saturationLabel.isHidden = state
        blurLabel.isHidden = state
        distortionEffectLabel.isHidden = state
        
        //Sliders
        brightness.isHidden = state
        contrast.isHidden = state
        saturation.isHidden = state
        blur.isHidden = state
        distortionEffect.isHidden = state
    }
    
    func updateViews() {
        
        guard let imageData = imageData,
            let image = UIImage(data: imageData) else {
                title = "New Post"
                return
        }
        title = post?.title
        
        setImageViewHeight(with: image.ratio)
        
        imageView.image = filterImage(image)
        
        chooseImageButton.setTitle("", for: [])
    }
    
    func updateImage() {
        
        
        guard let scaleImage = scaleImage else {
            return
        }
        
        imageView.image = filterImage(scaleImage)
    }
    
    private func filterImage(_ image: UIImage) -> UIImage? {
        //Convert: UIImage -> CGImage
        guard let cgImage = image.cgImage else { return image }
        
        //convert: CGImage -> CIImage
        let ciImage = CIImage(cgImage: cgImage)
        
        //Color filters
        ciColorFilter.setValue(ciImage, forKey: kCIInputImageKey)
        ciColorFilter.setValue(brightness.value, forKey: kCIInputBrightnessKey)
        ciColorFilter.setValue(contrast.value, forKey: kCIInputContrastKey)
        ciColorFilter.setValue(saturation.value, forKey: kCIInputSaturationKey)
 
        
        //Blur filter
        ciBlurFilter.setValue(ciColorFilter.outputImage, forKey: kCIInputImageKey)
        ciBlurFilter.setValue(blur.value, forKey: kCIInputRadiusKey)
        
 
        //Distortion effect
        ciBumpDistortion.setValue(ciBlurFilter.outputImage, forKey: kCIInputImageKey)
        ciBumpDistortion.setValue(distortionEffect.value, forKey: kCIInputRadiusKey)

        //Unwrap and Convert CIImage -> CGImage (Implement Context)
        guard let outputCIImage = ciBumpDistortion.outputImage,
            let outputCGImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else { return nil }
        
        //Convert CGImage -> UIImage and return
        return UIImage(cgImage: outputCGImage)
    }
    
    func setImageViewHeight(with aspectRatio: CGFloat) {
           
           imageHeightConstraint.constant = imageView.frame.size.width * aspectRatio
           
           view.layoutSubviews()
       }
    
    private func presentImagePickerController() {
        
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            presentInformationalAlertController(title: "Error", message: "The photo library is unavailable")
            return
        }
        
        DispatchQueue.main.async {
            
            let imagePicker = UIImagePickerController()
            
            imagePicker.delegate = self
            
            imagePicker.sourceType = .photoLibrary
            
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    //MARK: - Actions
    
    @IBAction func createPost(_ sender: Any) {
        
        view.endEditing(true)
        
        guard let originalImage = originalImage?.flattened,  let image = self.filterImage(originalImage)  else {
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.1),
            let title = titleTextField.text, title != "" else {
            presentInformationalAlertController(title: "Uh-oh", message: "Make sure that you add a photo and a caption before posting.")
            return
        }
        
        postController.createPost(with: title, ofType: .image, mediaData: imageData, dataURL: nil, ratio: imageView.image?.ratio, geoTag: location) { (success) in
            guard success else {
                DispatchQueue.main.async {
                    self.presentInformationalAlertController(title: "Error", message: "Unable to create post. Try again.")
                }
                return
            }
            
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @IBAction func chooseImage(_ sender: Any) {
        
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
        
        switch authorizationStatus {
        case .authorized:
            presentImagePickerController()
        case .notDetermined:
            
            PHPhotoLibrary.requestAuthorization { (status) in
                
                guard status == .authorized else {
                    NSLog("User did not authorize access to the photo library")
                    self.presentInformationalAlertController(title: "Error", message: "In order to access the photo library, you must allow this application access to it.")
                    return
                }
                
                self.presentImagePickerController()
            }
            
        case .denied:
            self.presentInformationalAlertController(title: "Error", message: "In order to access the photo library, you must allow this application access to it.")
        case .restricted:
            self.presentInformationalAlertController(title: "Error", message: "Unable to access the photo library. Your device's restrictions do not allow access.")
            
        @unknown default:
            print("FatalError")
        }
        presentImagePickerController()
    }

    @IBAction func brightnessSlider(_ sender: UISlider) {
       updateImage()
    }
    
    @IBAction func contrastSlider(_ sender: UISlider) {
        updateImage()
    }
    
    @IBAction func saturationSlider(_ sender: UISlider) {
        updateImage()
    }
    
    @IBAction func blurSlider(_ sender: UISlider) {
        updateImage()
    }
    
    @IBAction func distortionEffectSlider(_ sender: UISlider) {
        updateImage()
    }
    
    
    //MARK: - Properties
    
    var postController: PostController!
    var post: Post?
    var imageData: Data?
    
    var originalImage: UIImage? {
        didSet{
            guard let originalImage = originalImage else { return }
            
            var scaledSize = imageView.bounds.size
            let scale = UIScreen.main.scale
            
            scaledSize = CGSize(width: scaledSize.width * scale, height: scaledSize.height * scale)
            
            scaleImage = originalImage.imageByScaling(toSize: scaledSize)
           
        }
    }
    private var scaleImage: UIImage? {
        didSet{
            updateImage()
        }
    }
    private var context = CIContext(options: nil)
    
    private let ciColorFilter = CIFilter(name: "CIColorControls")!
    private let ciBlurFilter = CIFilter(name: "CIGaussianBlur")!
    private let ciBumpDistortion = CIFilter(name: "CIBumpDistortion")!
    var location: CLLocationCoordinate2D?
    
    //MARK: - Outlers 2
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var chooseImageButton: UIButton!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var postButton: UIBarButtonItem!
}

    //MARK: - UIImagePickerControllerDelegate - UINavigationControllerDelegate

extension ImagePostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        chooseImageButton.setTitle("", for: [])
        
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        
        originalImage = image
        
        imageView.image = filterImage(scaleImage!)
        
        hideControls(shouldHide: false)
        
        setImageViewHeight(with: image.ratio)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
