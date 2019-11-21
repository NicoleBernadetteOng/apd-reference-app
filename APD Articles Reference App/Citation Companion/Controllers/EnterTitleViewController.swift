//
//  EnterTitleViewController.swift
//  Citation Companion
//
//  Created by Nicole Bernadette Ong on 6/11/19.
//  Copyright © 2019 Nicole Bernadette Ong. All rights reserved.
//

import UIKit
import SwiftyJSON

class EnterTitleViewController: UIViewController, UINavigationControllerDelegate, UITextViewDelegate {

    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var confirmBtn: UIButton!
    
    var resultsText = ""
    var titleText = ""
    var authorsText = ""
    var doiText = ""
    
    var infoList = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleTextView.delegate = self
        titleTextView.text = "Enter your title here"
        titleTextView.textColor = UIColor.lightGray
        
        self.hideKeyboardWhenTappedAround()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowEnterTitle), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHideEnterTitle), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @IBAction func showNotepadTapped(_ sender: Any) {
        showNotepad()
    }
    
    // MARK: For placeholder in textView
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Enter your title here"
            textView.textColor = UIColor.lightGray
        }
    }
    
    
    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        if titleTextView.text != "Enter your title here" && titleTextView.text != "" {
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
        
        var textViewText = self.titleTextView.text
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
    
    @objc func keyboardWillShowEnterTitle(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height - 50
            }
        }
    }

    @objc func keyboardWillHideEnterTitle(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }

}

