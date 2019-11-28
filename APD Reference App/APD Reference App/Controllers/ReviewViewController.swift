//
//  ReviewViewController.swift
//  Citation Companion
//
//  Created by Nicole Ong on 16/10/19.
//  Copyright © 2019 Nicole Bernadette Ong. All rights reserved.
//

import UIKit
import Firebase
import SwiftSoup
import Reductio
import MessageUI
import WebKit
//import CropViewController

class ReviewViewController: UIViewController, UIImagePickerControllerDelegate,
UINavigationControllerDelegate, WKNavigationDelegate, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var cameraImg: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    let imagePicker = UIImagePickerController()
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var scanBtn: UIButton!
    @IBOutlet weak var searchBtn: UIButton!
    @IBOutlet weak var copyBtn: UIButton!
    @IBOutlet weak var exportBtn: UIButton!
    @IBOutlet weak var citationBtn: UIButton!
    
    @IBOutlet var webView: WKWebView!
    
    lazy var vision = Vision.vision()
    var resultsText = ""
    // array of DOIs from the scanned result text
    var doiList = [String]()
    var doiText = ""
    
    var finalDoiList = [String]()
    var finalDois = ""
    
    var article = ""
    
//    var urlList = [String]()
    var redirectedUrl = ""
    var cacheUrl = ""
    var summaryList = [String]()
    
    override func viewDidAppear(_ animated: Bool) {
        // MARK: Tutorial
        showTutorial(key: "reviewFirstTime", title: "Write a review", description: "This feature allows you to retrieve summaries from multiple research article web pages! \nTo begin, type in url(s)/DOI(s) or click on 'Scan a DOI'. \nOnce the url(s)/DOI(s) have been input, click 'Search'.", imageChosen: UIImage(named: "www.png")!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imagePicker.delegate = self
        
        self.hideKeyboardWhenTappedAround()
        
        citationBtn.isHidden = true
        copyBtn.isHidden = true
        exportBtn.isHidden = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowReview), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHideReview), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    @IBAction func scanDoiBtnTapped(_ sender: UIButton) {
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
    
    @IBAction func showNotepadTapped(_ sender: Any) {
        showNotepad()
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
        
        cameraImg.isHidden = true
        
        imageView.contentMode = .scaleAspectFit
        imageView.image = pickedImage
        self.dismiss(animated: true, completion: nil)
        
        // - 'Automatically' start the OCR
        detectDoiText(image: imageView.image)
        self.view.bringSubviewToFront(self.scanBtn)
    }
    
    
    // Text recognizer process function
    private func process(_ visionImage: VisionImage, with textRecognizer: VisionTextRecognizer?) {
        textRecognizer?.process(visionImage) { text, error in
            guard error == nil, let text = text else {
                self.resultsText = "Text recognizer failed with error."
                self.showOCRToast(titleText: "Oops!", descriptionText: "Text could not be recognised.", imageName: "dois.png")
                return
            }
            self.resultsText = ""
            self.resultsText += "\(text.text)"

            if self.resultsText.contains("10.") == false {
//                self.textView.insertText(self.resultsText)
//                self.textView.isScrollEnabled = true
                
                // alert that text was captured but it did not contain a DOI
                // alert that text does not contain a DOI
                self.showOCRToast(titleText: "Oh no!", descriptionText: "Text did not contain a DOI. Try again with another image?", imageName: "search.png")
                
            } else {
                // get the DOIs from all the text using regular expressions
                self.doiList = self.matchesDoi(for: "10.\\d+/\\w+\\W?[A-z0-9|/|.|(|)|;|:|-]+", in: self.resultsText)
                
                self.doiText = self.doiList.joined(separator: "\n")
                print(self.doiText)
            
                self.textView.insertText("\n" + self.doiText)
                self.textView.isScrollEnabled = true
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
    

    // Currently using by urls
    @IBAction func getReview(_ sender: Any) {
        print("tapped")
        self.finalDois = self.textView.text
        finalDoiList = self.matchesDoi(for: "10.\\d+/\\w+\\W?[A-z0-9|/|.|(|)|;|:|-]+", in: self.finalDois)
        
        if textView.text != "" {
            
            DispatchQueue.main.async {
                // Show loading
                self.loadingIndicator.startAnimating()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.doiList = self.matchesDoi(for: "10.\\d+/\\w+\\W?[A-z0-9|/|.|(|)|;|:|-]+", in: self.textView.text)
                // let urlList = textView.text.split(separator: "\n")
                  
                for doi in self.doiList {
                    let preferences = WKPreferences()
                    preferences.javaScriptEnabled = true
                    let config = WKWebViewConfiguration()
                    config.preferences = preferences
                    self.webView = WKWebView(frame: CGRect(x:0, y: 0, width: 0, height: 0), configuration: config)
                    self.view.addSubview(self.webView)
                
                    self.webView.navigationDelegate = self
                    
                    if doi.contains("https://") {
                        let newUrl = URL(string: String(doi))!
                        
                        // Load the url
                        self.webView.load(URLRequest(url: newUrl))
                    } else {
                        let newUrl = URL(string: String("https://dx.doi.org/"+doi))!
                        
                        // Load the url
                        self.webView.load(URLRequest(url: newUrl))
                    }
                }
            }
            
        } else {
            self.showOCRToast(titleText: "Oops!", descriptionText: "There are no DOIs in your text, it's empty!", imageName: "www.png")
        }

    }
    
    
    // When the page finishes loading
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let finalUrl = String(describing: webView.url)
        self.cacheUrl = finalUrl
        print(finalUrl)
        
        // Get the article
        self.getArticle(finalUrl: finalUrl, webView: webView) {
            (returnThis) in
            print("returnThis: " + returnThis)
            
            var myUrl = finalUrl.replacingOccurrences(of: "Optional(", with: "")
            myUrl = myUrl.replacingOccurrences(of: ")", with: "")
            
            // Append the summary to the list
            self.summaryList.append(returnThis + "\n" + "Retrieved from: " + myUrl + "\n\n")
            print(self.summaryList)
            
            if self.summaryList.count == self.doiList.count {
                self.load()
            }
            
        }
    }
    
    
    // Finally
    func load() {
        // Should do another summary of the summaries?
            
        // Show in textView
        let summaryString = self.summaryList.joined(separator: "")
        textView.text = summaryString.trimmingCharacters(in: .whitespaces)
                 
        // Handle buttons
        scanBtn.isHidden = true
        searchBtn.isHidden = true
            
        copyBtn.isHidden = false
        exportBtn.isHidden = false
        citationBtn.isHidden = false
        
        // Stop and hide loading
        self.loadingIndicator.stopAnimating()
    }
    
    // MARK: Get citations
    @IBAction func getCitations(_ sender: UIButton) {
        print("self.doiText" + self.doiText)
        performSegue(withIdentifier: "getCitations", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "getCitations" && self.doiText != "" {
            let selectDOIVC = segue.destination as! SelectDOIViewController
            selectDOIVC.finalDois = self.finalDois
        }
    }
    
    
    // For redirecting if the user uses the DOI number as the url
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
          decisionHandler(.allow) // allow the user to navigate to the requested page.
    }
         
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
          decisionHandler(.allow) // allow the webView to process the response.
    }
    
    
    // Article --> Summary + Keywords
    func getArticle(finalUrl: String, webView: WKWebView, completion: @escaping (String) -> Void) {
        
        // this is not changing
        var returnThis = ""
        var thisHtml = ""
        webView.evaluateJavaScript("document.documentElement.outerHTML.toString()", completionHandler: { (value, error) in
            thisHtml = value as! String
            
            do {
                let doc: Document = try SwiftSoup.parse(thisHtml)
                
                var articleText:String = ""
                
                // Wiley Online Library - onlinelibrary.wiley.com
                if articleText == "" {
                    let articleElement = try doc.getElementsByClass("article-section__content en main").first()
                    
                    if articleElement != nil {
                        articleText = try articleElement!.text()
                        print("Wiley Online Library: " + articleText)
                    }
                }
                
                // AAAS ScienceMag - stm.sciencemag.org/content/...
                if articleText == "" {
                    let articleElement = try doc.getElementsByClass("section editor-summary").first()
                    
                    if articleElement != nil {
                        articleText = try articleElement!.text()
                        print("ScienceMag: " + articleText)
                    }
                }
                
                // mdpi - abstract
                if articleText == "" {
                    let articleElement = try doc.getElementsByClass("art-abstract in-tab hypothesis_container").first()
                    
                    if articleElement != nil {
                        articleText = try articleElement!.text()
                        print("mdpi abstract: " + articleText)
                    }
                }
                
                // mdpi - full text
                if articleText == "" {
                    let articleElement = try doc.getElementsByClass("html-body").first()
                    
                    if articleElement != nil {
                        articleText = try articleElement!.text()
                        print("mdpi full: " + articleText)
                    }
                }
                
                // BMC & ASM & nature
                if articleText == "" {
                    let articleElement = try doc.getElementsByAttributeValueContaining("id", "Abs1-content").first()
                    
                    if articleElement != nil {
                        articleText = try articleElement!.text()
                        print("BMC / ASM / nature: " + articleText)
                    }
                }
                
                // frontiersin
                if articleText == "" {
                    let articleElement = try doc.getElementsByAttributeValueContaining("class", "JournalAbstract").first()
                    
                    if articleElement != nil {
                        articleText = try articleElement!.text()
                        print("frontiersin: " + articleText)
                    }
                }
                
                // Oxford Academic Journals
                if articleText == "" {
                    let articleElement = try doc.getElementsByAttributeValueContaining("class", "ArticleFulltext").first()
                    
                    if articleElement != nil {
                        articleText = try articleElement!.text()
                        print("Oxford Academic: " + articleText)
                    }
                }
                
                // SAGE & Taylor & Francis Online
                if articleText == "" {
                    let articleElement = try doc.getElementsByAttributeValueContaining("class", "abstractSection abstractInFull").first()
                    
                    if articleElement != nil {
                        articleText = try articleElement!.text()
                        print("SAGE / Taylor Francis: " + articleText)
                    }
                }
                
                // SSRN
                if articleText == "" {
                    let articleElement = try doc.getElementsByAttributeValueContaining("class", "abstract-text").first()
                    
                    if articleElement != nil {
                        articleText = try articleElement!.text()
                        print("abstract-text: " + articleText)
                    }
                }
                
                // eLIFE
                if articleText == "" {
                    let articleElement = try doc.getElementsByAttributeValueContaining("class", "article-section__body").first()
                    
                    if articleElement != nil {
                        articleText = try articleElement!.text()
                        print("article-section__body: " + articleText)
                    }
                }
                
                // Cell
                if articleText == "" {
                    let articleElement = try doc.getElementsByAttributeValueContaining("class", "section-paragraph").first()
                   
                    if articleElement != nil {
                        articleText = try articleElement!.text()
                        print("Cell: " + articleText)
                    }
                }
                
                // Springer & PLOS & ScienceOpen & PNAS & Semantic Scholar (but only the first part, can't click CONTINUE READING) & Aspet
                if articleText == "" {
                    let articleElement = try doc.getElementsByAttributeValueContaining("class", "Abstract").first()
                    
                    if articleElement != nil {
                        articleText = try articleElement!.text()
                        print("Abstract: " + articleText)
                    }
                }
                
                // Paperity
                if articleText == "" {
                    let articleElement = try doc.getElementsByAttributeValueContaining("class", "col-lg-9 col-md-9 col-xs-12").first()
                    
                    if articleElement != nil {
                        articleText = try articleElement!.text()
                        print("Paperity: " + articleText)
                    }
                }
                
                // NEJM
                if articleText == "" {
                    let articleElement = try doc.getElementsByAttributeValueContaining("class", "o-article-body__section").first()
                    
                    if articleElement != nil {
                        articleText = try articleElement!.text()
                        print("NEJM: " + articleText)
                    }
                }
                
                // https://link.springer.com/article/10.1186/s41070-018-0022-8
                if articleText == "" {
                    let articleElement = try doc.select("main").select("article").first()
                    
                    if articleElement != nil {
                        articleText = try articleElement!.text()
                        print("main article: " + articleText)
                    }
                }
                
                // MIT Tech Review
                if articleText == "" {
                    let articleElement = try doc.getElementsByAttributeValueContaining("class", "story").first()
                    
                    if articleElement != nil {
                        articleText = try articleElement!.text()
                        print("story: " + articleText)
                    }
                }
                
                // DOAJ - when the author list is too long
                if articleText == "" {
                    let articleElement = try doc.getElementsByAttributeValueContaining("class", "span10").first()
                    
                    if articleElement != nil {
                        articleText = try articleElement!.text()
                        print("span10: " + articleText)
                    }
                }
                
                // ScienceMag (new)
                if articleText == "" {
                    let articleElement = try doc.getElementsByAttributeValueContaining("id", "p-2").last()
                    
                    if articleElement != nil {
                        articleText = try articleElement!.text()
                        print("p-2: " + articleText)
                    }
                }
                
                // DOAJ
                if articleText == "" {
                    let articleElement = try doc.getElementsByAttributeValueContaining("class", "content").first()
                    
                    if articleElement != nil {
                        articleText = try articleElement!.text()
                        print("content: " + articleText)
                    }
                }
                
                // psycnet
                if articleText == "" {
                    let articleElement = try doc.getElementsByAttributeValueContaining("class", "col-md-12 p-0").first()
                    
                    if articleElement != nil {
                        articleText = try articleElement!.text()
                        print("psycnet: " + articleText)
                    }
                }
                
                // =================
                
                if articleText == "" {
                    let articleElement = try doc.select("article").first()
                    
                    if articleElement != nil {
                        articleText = try articleElement!.text()
                        print("cssQuery article: " + articleText)
                    }
                }
                
                if articleText == "" {
                    let articleElement = try doc.getElementsByAttributeValueContaining("class", "abstract").first()
                    
                    if articleElement != nil {
                        articleText = try articleElement!.text()
                        print("abstract: " + articleText)
                    }
                }
                
                if articleText == "" {
                    let articleElement = try doc.getElementsByAttributeValueContaining("class", "article").first()
                    
                    if articleElement != nil {
                        articleText = try articleElement!.text()
                        print("article: " + articleText)
                    }
                }
                
                if articleText == "" {
                    let articleElement = try doc.getElementsByAttributeValueContaining("class", "paper").first()
                    
                    if articleElement != nil {
                        articleText = try articleElement!.text()
                        print("paper: " + articleText)
                    }
                }
                
                if articleText == "" {
                    let articleElement = try doc.getElementsByAttributeValueContaining("class", "section").first()
                    
                    if articleElement != nil {
                        articleText = try articleElement!.text()
                        print("section: " + articleText)
                    }
                }
                
                // ========================
                
                if articleText != "" {
                    self.article = articleText
                    
                    // Get the summary
                    let summary = ArticleViewController().getSummary(articleText: self.article)
                    
                    returnThis = summary
                    completion(returnThis)
                    
                } else {
                    self.article = ""
                    
                    returnThis = "(Unable to retrieve summary)"
                    completion(returnThis)
                }
                
            } catch {
                print("error")
                returnThis = "(Unable to retrieve summary)"
                completion(returnThis)
            }
        })
    }
    
    
    @IBAction func copyBtnTapped(_ sender: UIButton) {
        print(textView.text!)
        let text = textView.text
        // copy citationList to Clipboard
        UIPasteboard.general.string = text
        self.showOCRToast(titleText: "Copied to clipboard", descriptionText: "", imageName: "search.png")
    }
    
    @IBAction func exportBtnTapped(_ sender: Any) {
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            
            mailComposer.setSubject("Review paper")
            
            let text = textView.text
            mailComposer.setMessageBody(text!, isHTML: false)
            
            self.present(mailComposer, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        // Dismiss the mail compose view controller.
        controller.dismiss(animated: true, completion: nil)
    }
    
    @objc func keyboardWillShowReview(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height - 165
            }
        }
    }

    @objc func keyboardWillHideReview(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
}
