//
//  RelatedViewController.swift
//  Citation Companion
//
//  Created by Nicole Bernadette Ong on 24/10/19.
//  Copyright © 2019 Nicole Bernadette Ong. All rights reserved.
//

import UIKit
import Firebase
import SwiftyJSON


class CiteTableViewCell: UITableViewCell {
    @IBOutlet weak var citeLabel: UILabel!
}

class RelatedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate,
UINavigationControllerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var textView: UITextField!
    
    @IBOutlet weak var scanBtn: UIButton!
    @IBOutlet weak var searchBtn: UIButton!
    
    let imagePicker = UIImagePickerController()
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    lazy var vision = Vision.vision()
    var resultsText = ""
    var citeList = [String]()
    var doiText = ""
    var dois = "" // final editted string to send
    
    var doiList = [String]()
    var selectedDoi = ""
    var url = ""
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
        
        // MARK: Tutorial
        showTutorial(key: "relatedFirstTime", title: "Find related articles", description: "Type in a DOI or Select an image with a DOI. \nOnce the DOI text has been input, click 'Search'. \nWhen the table shows the results, click on the row of the article you want to browse.", imageChosen: UIImage(named: "www.png")!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.delegate = self
        textView.text = "Enter your DOI here"
        textView.textColor = UIColor.lightGray
        
        self.hideKeyboardWhenTappedAround()
        
        imagePicker.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    // MARK: For placeholder in textField
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.textColor == UIColor.lightGray {
            textField.text = nil
//            textField.textColor = UIColor.black
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text!.isEmpty {
            textField.text = "Enter your DOI here"
            textField.textColor = UIColor.lightGray
        }
    }
    
    
    @IBAction func showNotepadTapped(_ sender: Any) {
        showNotepad()
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return citeList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "citeCell", for: indexPath) as! CiteTableViewCell
        cell.citeLabel?.numberOfLines = 0
        cell.citeLabel?.text = citeList[indexPath.row]
        return cell
    }
    
    // When the user selects/clicks on the row, if it contains a DOI, it will be saved and the article summariser page will open for that doi
    // If it doesn't contain a DOI then a Toast message will show
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let indexPath = tableView.indexPathForSelectedRow
        let currentCell = tableView.cellForRow(at: indexPath!) as! CiteTableViewCell
        
        if currentCell.citeLabel!.text!.contains("10.") {
            print(self.selectedDoi)
            
            self.doiList = self.matchesDoi(for: "10.\\d+/\\w+\\W?[A-z0-9|/|.|(|)|;|:|-]+", in: currentCell.citeLabel!.text!)
            self.selectedDoi = self.doiList[self.doiList.count - 1] // Get the last one since the DOI is always at the end, just in case
            
            // prepare the url to be used for the article summariser
            self.url = "https://doi.org/" + self.selectedDoi
            performSegue(withIdentifier: "viewArticle", sender: self)
            
        } else {
            self.showOCRToast(titleText: "Sorry!", descriptionText: "DOI is unavailable, unable to open research article.", imageName: "www.png")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "viewArticle" {
            let articleVC = segue.destination as! ArticleViewController
            articleVC.url = self.url
        }
    }
 
    
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
        imageView.contentMode = .scaleAspectFit
        imageView.image = pickedImage
        self.dismiss(animated: true, completion: nil)
        // - 'Automatically' start the OCR
        detectDoiText(image: imageView.image)
    }
    
    
    // MARK: - OCR
    
    // Text recognizer process function
    private func process(_ visionImage: VisionImage, with textRecognizer: VisionTextRecognizer?) {
        textRecognizer?.process(visionImage) { text, error in
            guard error == nil, let text = text else {
                self.showOCRToast(titleText: "Oops!", descriptionText: "Text could not be recognised.", imageName: "dois.png")
                
                return
            }
            
            // clear the text that was already in the textView so that the results won't append
            self.textView.text = ""
            self.resultsText = ""
            self.resultsText += "\(text.text)"
            
            if self.resultsText.contains("10.") == false {
                self.textView.insertText(self.resultsText)
                self.showOCRToast(titleText: "Oh no!", descriptionText: "Text did not contain a DOI. Try again with another image?", imageName: "search.png")
               
            } else {
                var tempList = [String]()
                tempList = self.matchesDoi(for: "10.\\d+/\\w+\\W?[A-z0-9|/|.|(|)|;|:|-]+", in: self.resultsText)
                
                // Just get the first DOI captured even if multiple were in the image
                self.doiText = tempList[0]
                print(self.doiText)
                self.textView.insertText(self.doiText)
                self.showOCRToast(titleText: "Nice!", descriptionText: "DOI was cpatured. Click 'Search' to proceed.", imageName: "keywords.png")
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
    
 
    @IBAction func searchBtnTapped(_ sender: UIButton) {
        print("tapped")
        
        // Clear whatever was previously found
        citeList.removeAll()
        tableView.reloadData()
        
        if textView.text != "" && textView.text != "Enter your DOI here" {
            DispatchQueue.main.async {
                // Show loading
                self.loadingIndicator.startAnimating()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.getRelated { (success) -> Void in
                    if success {
                        self.tableView.reloadData()
                        
                        // Stop and hide loading
                        self.loadingIndicator.stopAnimating()
                    }
                }
            }
        } else {
            self.showOCRToast(titleText: "Oops!", descriptionText: "Your text is empty. Type in a DOI or select an image containing a DOI.", imageName: "www.png")
        }
        
    }
    
    // From the doi that was captured, GET a list of citations from the JSON of citations for that paper to put in tableView
    func getRelated(completion: (_ success: Bool) -> Void) {
        
        let semaphore = DispatchSemaphore(value: 0)
        var flag = false
        
        var textViewText = self.textView.text
        
        if textViewText!.contains("https://data.crossref.org/") == false {
            textViewText = "https://data.crossref.org/" + textViewText!
        }
         
        guard let reqUrl = URL(string: textViewText!) else { return }
        print(reqUrl)
        
        var request = URLRequest(url: reqUrl)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
         
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else { print(error!.localizedDescription); return }
            guard let data = data else { print("Data could not be retrieved"); return }
            
            let httpResponse = response as? HTTPURLResponse
            print(httpResponse!.statusCode)
                
            // if wrong DOI was entered or DOI could not retrieve data
            if httpResponse!.statusCode == 404 {
                self.showOCRToast(titleText: "Oh no!", descriptionText: "DOI could not retrieve any related articles.", imageName: "www.png")
                self.loadingIndicator.stopAnimating()
                
                semaphore.signal()
            } else {
                
                // if correct DOI
                do {
                    if let json = try? JSON(data: data) {
                        let jsonArr: Array = json["reference"].arrayValue
                        print(jsonArr)
                        
                        if jsonArr == [] {
                            self.citeList.append("")
                            self.showOCRToast(titleText: "Oh no!", descriptionText: "DOI could not retrieve any related articles.", imageName: "www.png")
                            self.loadingIndicator.stopAnimating()
                            
                            semaphore.signal()
                        } else {
                            for ref in jsonArr {
                                var unstructured = "(No reference information available)"
                                var doi =  "(No DOI available)"
                                
                                if (ref["unstructured"].exists()) {
                                    unstructured = ref["unstructured"].rawString()!
                                }
                                
                                if (ref["DOI"].exists()) {
                                    doi =  ref["DOI"].rawString()!
                                }
                                  
                                let info = "Reference: " + unstructured + "\nDOI: " + doi

                                // Add each result to a list and show each item in that list in the table view
                                self.citeList.append(info)
                            }

                            if self.citeList.count != 0 {
                                flag = true
                                semaphore.signal()
                            }
                            
                        }
                    }
                }
                
            }
              
         }.resume()

         semaphore.wait()
         completion(flag)
    }
    
}
