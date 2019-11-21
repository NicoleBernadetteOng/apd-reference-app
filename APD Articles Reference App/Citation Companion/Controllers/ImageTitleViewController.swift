//
//  ImageTitleViewController.swift
//  Citation Companion
//
//  Created by Nicole Ong on 8/10/19.
//  Copyright © 2019 Nicole Bernadette Ong. All rights reserved.
//

import UIKit
import Firebase
import SwiftyJSON
import CropViewController

class ImageTitleViewController: UIViewController, CropViewControllerDelegate, UIImagePickerControllerDelegate,
UINavigationControllerDelegate {
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var imageView: UIImageView!
    let imagePicker = UIImagePickerController()
    
    private var image: UIImage?
    private var croppingStyle = CropViewCroppingStyle.default
    private var croppedRect = CGRect.zero
    private var croppedAngle = 0
    
    @IBOutlet weak var textView: UITextView!
   
    @IBOutlet weak var chooseImgBtn: UIButton!
    @IBOutlet weak var confirmBtn: UIButton!
    
    @IBOutlet weak var cameraImg: UIImageView!
    
    var done = false
    
    lazy var vision = Vision.vision()
    var resultsText = ""
    
    var titleText = ""
    var authorsText = ""
    var doiText = ""
    
    var infoList = [String]()
    
    override func viewDidAppear(_ animated: Bool) {
        // MARK: Tutorial
        showTutorial(key: "imageTitleFirstTime", title: "Title from Image", description: "Click on the '+' to select an image or take a photo containing your title. \nCrop the image if needed. \nOnce the title text has been captured, click 'Confirm'.", imageChosen: UIImage(named: "titles.png")!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
//        textView.isHidden = true
        
        imagePicker.delegate = self
        
        self.hideKeyboardWhenTappedAround()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // For cropViewController
//       imageView.isUserInteractionEnabled = true
       imageView.contentMode = .scaleAspectFit
       if #available(iOS 11.0, *) {
           imageView.accessibilityIgnoresInvertColors = true
       }
       view.addSubview(imageView)
       
       let tapRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(didTapImageView))
       imageView.addGestureRecognizer(tapRecognizer)
    }
    
    func getTopMostViewController() -> UIViewController? {
        var topMostViewController = UIApplication.shared.keyWindow?.rootViewController

        while let presentedViewController = topMostViewController?.presentedViewController {
            topMostViewController = presentedViewController
        }

        return topMostViewController
    }
 
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
                                                self.detectTitleText(image: self.imageView.image)
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
                self.showOCRToast(titleText: "Oops!", descriptionText: "Text could not be recognised.", imageName: "titles.png")
                
                return
            }
            
            // clear the text that was already in the textView so that the results won't append
            self.textView.text = ""
            self.resultsText = ""
            self.resultsText += "\(text.text)"
            self.textView.insertText(self.resultsText)
            self.textView.isScrollEnabled = true
            self.showOCRToast(titleText: "Nice!", descriptionText: "Text was cpatured. Click 'Confirm' to proceed.", imageName: "keywords.png")
            
        }
    }
    
    
    func detectTitleText(image: UIImage?) {
        guard let image = image else { return }
        let textRecognizer = vision.onDeviceTextRecognizer()
        let imageMetadata = VisionImageMetadata()
        imageMetadata.orientation = UIUtilities.visionImageOrientation(from: image.imageOrientation)
        let visionImage = VisionImage(image: image)
        visionImage.metadata = imageMetadata
        process(visionImage, with: textRecognizer)
    }

    // ==============================================================================
    // Get top 5 titles from the HTTP request
    @IBAction func confirmBtnTapped(_ sender: Any) {
        print("tapped")
        
        if textView.text != "" {
            DispatchQueue.main.async {
                // Show loading
                self.loadingIndicator.startAnimating()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.getTitles { (success) -> Void in
                    if success {
                        // Hide loading
                        self.loadingIndicator.stopAnimating()
                        self.showTable()
                    }
                }
            }
        } else {
            self.showOCRToast(titleText: "Oops!", descriptionText: "Your text is empty!", imageName: "www.png")
        }
        
    }
    
    
    func getTitles(completion: (_ success: Bool) -> Void) {
                
        let semaphore = DispatchSemaphore(value: 0)
        
        var textViewText = self.textView.text
        print("textViewText: " + (textViewText ?? ""))
        textViewText = textViewText?.replacingOccurrences(of: "\n", with: " ")
        textViewText = textViewText!.trimmingCharacters(in: .whitespacesAndNewlines)
        textViewText = textViewText?.replacingOccurrences(of: " ", with: "+")
        
        guard let reqUrl = URL(string: "https://api.crossref.org/works?rows=5&query.bibliographic=" + textViewText!) else { return }
        var request = URLRequest(url: reqUrl)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else { print(error!.localizedDescription); return }
            guard let data = data else { print("Data could not be retrieved"); return }

            let httpResponse = response as? HTTPURLResponse
            print(httpResponse!.statusCode)
            
            if httpResponse!.statusCode == 404 {
                self.showOCRToast(titleText: "Yikes!", descriptionText: "DOI could not retrieve any titles.", imageName: "www.png")
                
                semaphore.signal()
            }
            
            if httpResponse!.statusCode == 503 {
                self.showOCRToast(titleText: "Sorry!", descriptionText: "DOI service is currently unavailable.", imageName: "summs.png")
                
                semaphore.signal()
            }
            
            do {
                
                let json = try? JSON(data: data)
                let jsonObj = json!["message"]["items"]
                
                for i in 0...4 {
                    let title = jsonObj[i]["title"].rawString()
                    var authors = "(No author information available)"
                    let doi = jsonObj[i]["DOI"].stringValue
                    
                    if (jsonObj[i]["author"].exists()) {
                        authors = jsonObj[i]["author"].rawString()!
                    }
       
                    let info = "Title: " + title! + "\nAuthor(s): " + authors + "\nDOI: " + doi + "\n"

                    let cleanInfo = self.cleanTitleInfo(info: info)
                    
                    // Add each result to a list and show each item in that list in the table view
                    self.infoList.append(cleanInfo)
                    print(self.infoList)
                    
                    print("infoList.count: " + String(self.infoList.count))
                    if self.infoList.count == 5 {
                        semaphore.signal()
                    }
                    
                }
                
            }
            
        }.resume()

        semaphore.wait()
        completion(true)
    }

    
    func showTable() {
        performSegue(withIdentifier: "showTable", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTable" {
            let selectTitleVC = segue.destination as! SelectTitleViewController
            
            selectTitleVC.infoList = self.infoList
        }
    }

}
    
