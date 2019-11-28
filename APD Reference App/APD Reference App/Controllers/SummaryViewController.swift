//
//  SummaryViewController.swift
//  Citation Companion
//
//  Created by Nicole Ong on 10/10/19.
//  Copyright © 2019 Nicole Bernadette Ong. All rights reserved.
//

import UIKit
import CoreData
import CropViewController
import Firebase
import SwiftEntryKit

struct Summary {
    var summaryText : String
}

class SummaryTableViewCell: UITableViewCell {
    @IBOutlet weak var summaryLabel: UILabel!
}

class SummaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CropViewControllerDelegate, UIImagePickerControllerDelegate,
UINavigationControllerDelegate {

    var summaryList = [History]()
    var url: String = ""
 
//    let dataFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("History.plist")
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var goBtn: UIButton!
    
    @IBOutlet weak var scanBtn: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    let imagePicker = UIImagePickerController()
    private var image: UIImage?
    private var croppingStyle = CropViewCroppingStyle.default
    private var croppedRect = CGRect.zero
    private var croppedAngle = 0
    
    @IBOutlet weak var tableView: UITableView!
    
    lazy var vision = Vision.vision()
    var resultsText = ""
    // array of DOIs from the scanned result text
    var doiList = [String]()
    var doiText = ""
    var dois = "" // final editted string to send
    
    override func viewDidAppear(_ animated: Bool) {
        // MARK: Tutorial
        showTutorial(key: "summaryFirstTime", title: "Article summarizer", description: "Type in a url or click 'Scan a DOI' to get the corresponding url. \nClick 'Go'. Once a summary has been retrieved, the table will be updated. \nTo revisit that article, simply tap on the row. Happy browsing!", imageChosen: UIImage(named: "summs.png")!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        
        self.hideKeyboardWhenTappedAround()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // Fetch object from History.plist (Core Data/Cache)
        loadHistory()
        
        // For cropViewController
        imageView.isUserInteractionEnabled = true
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
    
    
    func loadHistory() {
        let request : NSFetchRequest<History> = History.fetchRequest()
        
        do {
            // Saving the results in summaryList
            summaryList = try context.fetch(request)
            summaryList = summaryList.reversed()
            
        } catch {
            print("Error fetching data from context \(error)")
        }
        
        tableView.reloadData()
    }
    
    @IBAction func showNotepadTapped(_ sender: Any) {
        showNotepad()
    }
    
    
    // MARK: - Show Citations in tableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return summaryList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "summaryCell", for: indexPath) as! SummaryTableViewCell
        
        cell.summaryLabel?.text = summaryList[indexPath.row].title
        
        return cell
    }

    // Click on the summary item in the tableView
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let indexPath = tableView.indexPathForSelectedRow

        // get the History url for the article summariser
        if let thisUrl = summaryList[indexPath!.row].url {
            var tempUrl = thisUrl
            tempUrl = tempUrl.replacingOccurrences(of: "Optional(", with: "")
            tempUrl = String(tempUrl.dropLast()) // this removes the last ")"
            urlTextField.text! = tempUrl
            self.url = urlTextField.text!
        }
        
        print(self.url)
        performSegue(withIdentifier: "goArticle", sender: self)
    }
    
    // Swipe to delete
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") {
            (action, indexPath) in
            
            self.context.delete(self.summaryList[indexPath.row])// for CoreData
            self.summaryList.remove(at: indexPath.row) // for tableView
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        return [delete]
    }
    

    // MARK: - Scan a URL
    @IBAction func scanBtnTapped(_ sender: UIButton) {
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
    
    
    // MARK: Crop
    // Runs after selecting the image from gallery
    public func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        print("didCropToImage")
        
        self.croppedRect = cropRect
        self.croppedAngle = angle
        updateImageViewWithImage(image, fromCropViewController: cropViewController)
    }
    
    
    public func updateImageViewWithImage(_ image: UIImage, fromCropViewController cropViewController: CropViewController) {
        print("updateImageViewWithImage")
        
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        
        cropViewController.dismissAnimatedFrom(self, withCroppedImage: image,
                                               toView: imageView,
                                               toFrame: CGRect.zero,
                                               setup: { self.imageView.contentMode = .scaleAspectFit },
                                               completion: {
                                                // - 'Automatically' start the OCR
                                                self.detectDoiText(image: self.imageView.image)
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
        

    // MARK: OCR
    // Text recognizer process function
    private func process(_ visionImage: VisionImage, with textRecognizer: VisionTextRecognizer?) {
        textRecognizer?.process(visionImage) { text, error in
            guard error == nil, let text = text else {
                self.resultsText = "Text recognizer failed with error."
                
                // alert that text could not be recognized
                self.showOCRToast(titleText: "Oops!", descriptionText: "Text could not be recognised.", imageName: "dois.png")
                
                return
            }
            
            self.urlTextField.text = ""
            self.resultsText = ""
            self.resultsText += "\(text.text)"
            
            if self.resultsText.contains("10.") == false {
                self.urlTextField.insertText(self.resultsText)
                
                // alert that text was captured
                self.showOCRToast(titleText: "Okay!", descriptionText: "Text was captured.", imageName: "titles.png")
                
            } else {
                // get the DOIs from all the text using regular expressions
                self.doiList = self.matchesDoi(for: "10.\\d+/\\w+\\W?[A-z0-9|/|.|(|)|;|:|-]+", in: self.resultsText)
                
                if self.doiList.indices.contains(0) {
                    self.doiText = self.doiList[0] // first one
                    print(self.doiText)
                    
                    self.urlTextField.insertText("https://doi.org/" + self.doiText)
                    
                    // alert that DOI was captured
                    self.showOCRToast(titleText: "Nice!", descriptionText: "DOI was cpatured. Click 'Confirm' to proceed.", imageName: "keywords.png")
                } else {
                    self.showOCRToast(titleText: "Oops!", descriptionText: "DOI could not be captured. Try again!", imageName: "keywords.png")
                }
                
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
    
    
    // MARK: Clear cache/history
    @IBAction func clearHistory(_ sender: Any) {
        // Show confirmation popup
        var attributes = EKAttributes.topFloat
        attributes.entryBackground = .gradient(gradient: .init(colors: [EKColor(#colorLiteral(red: 0.6246001935, green: 0.830504047, blue: 1, alpha: 1)), EKColor(.white)], startPoint: .zero, endPoint: CGPoint(x: 1, y: 1)))
        attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.3), scale: .init(from: 1, to: 0.7, duration: 0.7)))
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.5, radius: 10, offset: .zero))
        attributes.statusBar = .dark
        attributes.scroll = .enabled(swipeable: true, pullbackAnimation: .jolt)
        attributes.displayDuration = .infinity
        attributes.entryInteraction = .absorbTouches
        
        let edgeWidth = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        attributes.positionConstraints.maxSize = .init(width: .constant(value: edgeWidth), height: .intrinsic)

        // Message
        let title = EKProperty.LabelContent(text: "Are you sure you want to clear history?", style: .init(font: UIFont.systemFont(ofSize: 16.0), color: .black))
        let description = EKProperty.LabelContent(text: "Once the history has been cleared, it cannot be retrieved.", style: .init(font: UIFont.systemFont(ofSize: 14.0), color: .black))
        let image = EKProperty.ImageContent(image: UIImage(named: "alert.png")!, size: CGSize(width: 50, height: 50))
        let simpleMessage = EKSimpleMessage(image: image, title: title, description: description)
        
        // Button
        let buttonLabel = EKProperty.LabelContent(text: "CLEAR HISTORY", style: .init(font: UIFont.systemFont(ofSize: 16.0), color: .black))
        let okButton = EKProperty.ButtonContent(label: buttonLabel, backgroundColor: .white, highlightedBackgroundColor: EKColor(#colorLiteral(red: 0.6246001935, green: 0.830504047, blue: 1, alpha: 1))) {
            SwiftEntryKit.dismiss {
                print("okButton")
                // If confirmed, clear all Core Data
                for summs: AnyObject in self.summaryList {
                    self.context.delete(summs as! NSManagedObject)
                }
                self.summaryList.removeAll(keepingCapacity: false)
                self.tableView.reloadData()
            }
        }
        let barContent = EKProperty.ButtonBarContent(with: [okButton], separatorColor: .black, expandAnimatedly: true)
        
        let alertMessage = EKAlertMessage(simpleMessage: simpleMessage, buttonBarContent: barContent)
        let message = EKAlertMessageView(with: alertMessage)

        SwiftEntryKit.display(entry: message, using: attributes)
    }
    
    
    // Send the url that was keyed in to the Web View in ArticleViewController
    @IBAction func goBtnTapped(_ sender: Any) {
        print("tapped")
        
        self.url = urlTextField.text!
        
        if self.url != "" {
            if self.url.contains("https://") == false {
                self.url = "https://" + self.url
            }
            
            performSegue(withIdentifier: "goArticle", sender: self)
        } else {
            self.showOCRToast(titleText: "Uh oh!", descriptionText: "Your url is empty!", imageName: "www.png")
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goArticle" {
            let articleVC = segue.destination as! ArticleViewController
            articleVC.url = self.url
        }
    }

}
