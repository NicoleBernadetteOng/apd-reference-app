//
//  TranslatorViewController.swift
//  Citation Companion
//
//  Created by Nicole Ong on 16/10/19.
//  Copyright © 2019 Nicole Bernadette Ong. All rights reserved.
//

import UIKit
import Firebase
import SwiftyJSON
import CropViewController

class TranslatorViewController: UIViewController, CropViewControllerDelegate, UIImagePickerControllerDelegate,
UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var langPicker: UIPickerView!
    @IBOutlet weak var imgBtn: UIButton!
    @IBOutlet weak var translateBtn: UIButton!
    @IBOutlet weak var cameraImg: UIImageView!
    
    var timer: Timer?
    var runCount = 0
    
    private var image: UIImage?
    private var croppingStyle = CropViewCroppingStyle.default
    private var croppedRect = CGRect.zero
    private var croppedAngle = 0
    
    let imagePicker = UIImagePickerController()
    lazy var vision = Vision.vision()
    var resultsText = ""
    var langToLang = ""
    
    let languages = ["ar", "zh", "de", "en", "es", "tl", "fr", "it", "ja", "ko", "ms", "ru", "sv", "ta", "th", "vi"]
    let fullLanguages = ["Arabic", "Chinese", "German", "English", "Spanish", "Tagalog", "French", "Italian", "Japanese", "Korean", "Malay", "Russian", "Swedish", "Tamil", "Thai", "Vietnamese"]
    
    var languageDict: Dictionary = [
        "Arabic": "ar",
        "Chinese": "zh",
        "German": "de",
        "English": "en",
        "Spanish": "es",
        "Tagalog": "tl",
        "French": "fr",
        "Italian": "it",
        "Japanese": "ja",
        "Korean": "ko",
        "Malay": "ms",
        "Russian": "ru",
        "Swedish": "sv",
        "Tamil": "ta",
        "Thai": "th",
        "Vietnamese": "vi"
    ]
    
    var language = ""
    
    override func viewDidAppear(_ animated: Bool) {
        // MARK: Tutorial
        showTutorial(key: "translateFirstTime", title: "Abstract translator", description: "Type in a text or Select an image with the text you want to translate. \nOnce the text has been input, select the language you want to translate to and click 'Translate'.", imageChosen: UIImage(named: "translator.png")!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imagePicker.delegate = self
        langPicker.delegate = self
        langPicker.dataSource = self
        
        self.hideKeyboardWhenTappedAround()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // For cropViewController
//        imageView.isUserInteractionEnabled = true
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
    
    // ========== SELECT LANGUAGE ==========
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        let countrows : Int = fullLanguages.count
        return countrows
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let titleRow = fullLanguages[row]
        return titleRow
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // Get the value from the key in the languageDict
        let tempLang = self.fullLanguages[row]
        print(languageDict[tempLang]!)
        self.language = languageDict[tempLang] ?? ""
    }
    // =======================================
    
    
    @IBAction func imgBtnTapped(_ sender: UIButton) {
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
    
    
    func openCamera() {
        if(UIImagePickerController .isSourceTypeAvailable(UIImagePickerController.SourceType.camera)) {
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            imagePicker.allowsEditing = false
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
        
        self.view.bringSubviewToFront(imgBtn)
        self.cameraImg.isHidden = true
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        
        cropViewController.dismissAnimatedFrom(self, withCroppedImage: image,
                                               toView: imageView,
                                               toFrame: CGRect.zero,
                                               setup: { self.imageView.contentMode = .scaleAspectFit },
                                               completion: {
                                                // - 'Automatically' start the OCR
                                                self.detectText(image: self.imageView.image)
                                                self.imageView.isUserInteractionEnabled = false })
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
                self.showOCRToast(titleText: "Oops!", descriptionText: "Text could not be recognised.", imageName: "dois.png")
                return
            }
            
            // clear the text that was already in the textView so that the results won't append
            self.resultsText = ""
            self.resultsText += "\(text.text)"
            self.textView.insertText(self.resultsText)
            self.textView.isScrollEnabled = true
            self.showOCRToast(titleText: "Okay!", descriptionText: "Text was captured.", imageName: "translator.png")
        }
    }
    
    func detectText(image: UIImage?) {
        guard let image = image else { return }
        let textRecognizer = vision.onDeviceTextRecognizer()
        let imageMetadata = VisionImageMetadata()
        imageMetadata.orientation = UIUtilities.visionImageOrientation(from: image.imageOrientation)
        let visionImage = VisionImage(image: image)
        visionImage.metadata = imageMetadata
        process(visionImage, with: textRecognizer)
    }
    
    
    // MARK: - Translate button tapped
    @IBAction func translate(_ sender: UIButton) {
        print("tapped")
        
        if textView.text != "" {
            DispatchQueue.main.async {
                // Show loading
                self.loadingIndicator.startAnimating()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.getTranslation { (success) -> Void in
                    if success {
                        self.showResult()
                        
                        // Hide loading
                        self.loadingIndicator.stopAnimating()
                    }
                }
            }
        } else {
            self.showOCRToast(titleText: "Oops!", descriptionText: "Your text is empty!", imageName: "www.png")
        }
        
    }
    
    func getTranslation(completion: (_ success: Bool) -> Void) {
        let semaphore = DispatchSemaphore(value: 0)
        
        let reqUrl = URL(string: "https://translate.yandex.net/api/v1.5/tr.json/translate")!
        var request = URLRequest(url: reqUrl)
        request.httpMethod = "POST"

        let key:String = "trnsl.1.1.20190822T064247Z.c606bd27994bdc90.405f1c0864de8bb881358a57e5346c513f511437"
        let lang:String = self.language
        let text:String = textView.text
        let body:String = "key=" + key + "&lang=" + lang + "&text=" + text
        let data:Data = NSMutableData(data: body.data(using: String.Encoding.utf8)!) as Data
        
        let host:String = "YandexTranslatezakutynskyV1.p.rapidapi.com"
        let apiKey:String = "133c9a3831msh63cfab2f18410b1p1b554ejsn3d773efa07c9"
        let content:String = "application/x-www-form-urlencoded"
        
        request.httpBody = data
        request.setValue(host, forHTTPHeaderField: "x-rapidapi-host")
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
        request.setValue(content, forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else { print(error!.localizedDescription); return }
            guard let data = data else { print("Citation could not be retrieved"); return }
            
            if let result = String(data: data, encoding: .utf8) {
                print(result)
                let backToData = result.data(using: .utf8)
                let json = try? JSON(data: backToData!)
                self.resultsText = json!["text"][0].stringValue
                
                var langText = json!["lang"].stringValue
                langText = langText.replacingOccurrences(of: "-", with: " to ")
                self.langToLang = langText
                
                semaphore.signal()
            }
        }.resume()
        
        semaphore.wait()
        completion(true)
    }
    
    func showResult() {
        self.textView.text = self.resultsText
        // Toast converted from what language to what language
        self.showOCRToast(titleText: "Great!", descriptionText: "You translated from " + self.langToLang, imageName: "translator.png")
    }
    
    
}
