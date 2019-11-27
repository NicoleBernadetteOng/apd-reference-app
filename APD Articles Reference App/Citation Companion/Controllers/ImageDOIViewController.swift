//  Citation Companion
//  ImageDOIViewController.swift
//
//  Created by Nicole Bernadette Ong on 4/10/19.
//  Copyright © 2019 Nicole Bernadette Ong. All rights reserved.
//

import UIKit
import Firebase
import SwiftEntryKit
import CropViewController

class ImageDOIViewController: UIViewController, CropViewControllerDelegate, UIImagePickerControllerDelegate,
UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    let imagePicker = UIImagePickerController()
    
    private var image: UIImage?
    private var croppingStyle = CropViewCroppingStyle.default
    private var croppedRect = CGRect.zero
    private var croppedAngle = 0
    
    @IBOutlet weak var cameraImg: UIImageView!
    
    @IBOutlet weak var chooseImgBtn: UIButton!
    @IBOutlet weak var confirmBtn: UIButton!
    
    @IBOutlet weak var textView: UITextView!
    
    lazy var vision = Vision.vision()
    var resultsText = ""
    // array of DOIs from the scanned result text
    var doiList = [String]()
    var doiText = ""
    var dois = "" // final editted string to send
    
    @IBOutlet weak var notepadBtn: UIBarButtonItem!
   
    override func viewDidAppear(_ animated: Bool) {
        // MARK: Tutorial
        showTutorial(key: "imageDoiFirstTime", title: "DOI(s) from Image", description: "Select an image or take a photo containing a DOI. \nCrop the image if needed. \nOnce the DOI text has been captured, click 'Confirm'.", imageChosen: UIImage(named: "dois.png")!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        textView.isHidden = true
        
        imagePicker.delegate = self
        
        self.hideKeyboardWhenTappedAround()
        
        // For cropViewController
//        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFit
        if #available(iOS 11.0, *) {
            imageView.accessibilityIgnoresInvertColors = true
        }
        view.addSubview(imageView)
        
        let tapRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(didTapImageView))
        imageView.addGestureRecognizer(tapRecognizer)
        
        // For adjusting view when keyboard is shown
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    func getTopMostViewController() -> UIViewController? {
        var topMostViewController = UIApplication.shared.keyWindow?.rootViewController

        while let presentedViewController = topMostViewController?.presentedViewController {
            topMostViewController = presentedViewController
        }

        return topMostViewController
    }
    
    // MARK: - Notepad
    @IBAction func showNotepadTapped(_ sender: Any) {
        showNotepad()
    }
    

    // MARK: - Select / Take an image button pressed
    
    // ========== IBAction ==========
    @IBAction func chooseImgBtnTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler : { _ in self.openCamera()
        }))
        
        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in self.openGallery()
        }))
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        // For iPad
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            alert.popoverPresentationController?.sourceView = sender
            alert.popoverPresentationController?.sourceRect = sender.bounds
            alert.popoverPresentationController?.permittedArrowDirections = .up
        default:
            break
        }
    
        self.present(alert, animated: true, completion: nil)
    }
    
    // ========== Functions ==========
    func openCamera() {
        if(UIImagePickerController .isSourceTypeAvailable(UIImagePickerController.SourceType.camera)) {
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            
            self.present(imagePicker, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title:"Error", message: "Unable to access camera", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func openGallery() {
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
        imagePicker.allowsEditing = false
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        
        // The selected image
        let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        
        // Crop the image
        let cropViewController = CropViewController(image: pickedImage)
        cropViewController.delegate = self
        
        DispatchQueue.main.async {
            self.getTopMostViewController()?.present(cropViewController, animated: true, completion: nil)
        }
            
        present(cropViewController, animated: true, completion: nil)
    }
    
    
    // MARK: - Crop
    // Runs after selecting the image from gallery
    public func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        print("didCropToImage")
        
        self.croppedRect = cropRect
        self.croppedAngle = angle
        updateImageViewWithImage(image, fromCropViewController: cropViewController)
    }
    
    
    public func updateImageViewWithImage(_ image: UIImage, fromCropViewController cropViewController: CropViewController) {
        print("updateImageViewWithImage")
        
        self.view.bringSubviewToFront(chooseImgBtn)
        self.cameraImg.isHidden = true
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        
        cropViewController.dismissAnimatedFrom(self, withCroppedImage: image,
                                               toView: imageView,
                                               toFrame: CGRect.zero,
                                               setup: { self.imageView.contentMode = .scaleAspectFit },
                                               completion: {
                                                // - 'Automatically' start the OCR
                                                self.detectDoiText(image: self.imageView.image)
                                                self.imageView.isUserInteractionEnabled = false
                                                self.textView.isHidden = false })
    }
    
    
    @objc public func didTapImageView() {
        // When tapping the image view, restore the image to the previous cropping state
        print("didTapImageView")
        
        let viewFrame = view.convert(imageView.frame, to: navigationController!.view)
        let cropViewController = CropViewController(croppingStyle: self.croppingStyle, image: self.image!)
        cropViewController.delegate = self
        cropViewController.presentAnimatedFrom(self,
                                               fromImage: self.imageView.image,
                                               fromView: nil,
                                               fromFrame: viewFrame,
                                               angle: self.croppedAngle,
                                               toImageFrame: self.croppedRect,
                                               setup: { self.imageView.isHidden = true },
                                               completion: nil)
    }
        

    // MARK: - OCR
    
    // Text recognizer process function
    private func process(_ visionImage: VisionImage, with textRecognizer: VisionTextRecognizer?) {
        textRecognizer?.process(visionImage) { text, error in
            guard error == nil, let text = text else {
                self.resultsText = "Text recognizer failed with error."
                
                // alert that text could not be recognized
//                self.view.makeToast("Text could not be recognized.")
                self.showOCRToast(titleText: "Oops!", descriptionText: "Text could not be recognised.", imageName: "dois.png")
                
                return
            }
            self.resultsText = ""
            self.resultsText += "\(text.text)"
            
            if self.resultsText.contains("10.") == false {
//                self.textView.insertText(self.resultsText)
//                self.textView.isScrollEnabled = true
                
                // alert that text does not contain a DOI
                self.showOCRToast(titleText: "Oh no!", descriptionText: "Text did not contain a DOI. Try again with another image?", imageName: "search.png")
                
            } else {
                // get the DOIs from all the text using regular expressions
                self.doiList = self.matchesDoi(for: "10.\\d+/\\w+\\W?[A-z0-9|/|.|(|)|;|:|-]+", in: self.resultsText)
                
                self.doiText = self.doiList.joined(separator: "\n")
                print(self.doiText)
                
                self.textView.insertText("\n" + self.doiText)
                self.textView.isScrollEnabled = true
                
                // alert that DOI was captured
                self.showOCRToast(titleText: "Nice!", descriptionText: "DOI was cpatured. Click 'Confirm' to proceed.", imageName: "keywords.png")
            }
            
        }
    }
    
    
    func detectDoiText(image: UIImage?) {
        guard let image = image else { return }
        
        // Start init text
        let textRecognizer = vision.onDeviceTextRecognizer()
        
        let imageMetadata = VisionImageMetadata()
        imageMetadata.orientation = UIUtilities.visionImageOrientation(from: image.imageOrientation)
        
        let visionImage = VisionImage(image: image)
        visionImage.metadata = imageMetadata
        
        process(visionImage, with: textRecognizer)
    }
    
    
    // MARK: - Confirm and send doiText back to the select DOI ViewController

    @IBAction func confirmBtnPressed(_ sender: UIButton) {
        
        if self.textView.text != "" {
            // send the DOIs captured to the SelectDOIViewController
            self.dois = textView.text
            performSegue(withIdentifier: "doiImageToSelect", sender: self)
        } else {
            self.showOCRToast(titleText: "Uh oh!", descriptionText: "Your text is empty! Select an image to begin.", imageName: "dois.png")
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "doiImageToSelect" && self.dois != "" {
            let selectDoiVC = segue.destination as! SelectDOIViewController
            selectDoiVC.finalDois = self.dois
        }
    }
    
    
}
