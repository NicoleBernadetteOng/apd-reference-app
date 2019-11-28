//
//  EnterDOIViewController.swift
//  Citation Companion
//
//  Created by Nicole Bernadette Ong on 6/11/19.
//  Copyright © 2019 Nicole Bernadette Ong. All rights reserved.
//

import UIKit

class EnterDOIViewController: UIViewController, UINavigationControllerDelegate, UITextViewDelegate {

    @IBOutlet weak var beforeDoiTextView: UITextView!
    @IBOutlet weak var finalDoiTextView: UITextView!
    
    @IBOutlet weak var verifyBtn: UIButton!
    @IBOutlet weak var confirmBtn: UIButton!
    
    var inputText = ""
    var doiList = [String]()
    var dois = ""
    var doiText = ""
    
    override func viewDidAppear(_ animated: Bool) {
        // MARK: Tutorial
        showTutorial(key: "enterDoiFirstTime", title: "Enter DOI(s)", description: "Enter a DOI or multiple DOIs. \nClick 'Verify format'. \nOnce the detected DOIs have been captured, click 'Confirm'.", imageChosen: UIImage(named: "dois.png")!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        beforeDoiTextView.delegate = self
        beforeDoiTextView.text = "Enter your DOI(s) here"
        beforeDoiTextView.textColor = UIColor.lightGray
        
        finalDoiTextView.isHidden = true
        confirmBtn.isHidden = true
        
        self.hideKeyboardWhenTappedAround()
    }
    
    // Show Notepad
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
            textView.text = "Enter your DOI(s) here"
            textView.textColor = UIColor.lightGray
        }
    }
    
    
    // MARK: - IBActions
    @IBAction func verifyButtonTapped(_ sender: Any) {
        self.inputText = beforeDoiTextView.text
        
        if self.inputText == "" {
            self.showOCRToast(titleText: "Oops!", descriptionText: "Your text is empty. Type in a DOI (e.g. 10.1016/j.jim.2019.112683) to start.", imageName: "dois.png")
            
        } else if self.inputText.contains("10.") == false {
            self.showOCRToast(titleText: "Oh no!", descriptionText: "Text did not contain a DOI.", imageName: "search.png")
            
        } else {
            // get the DOIs from all the text using regular expressions
            self.doiList = self.matchesDoi(for: "10.\\d+/\\w+\\W?[A-z0-9|/|.|(|)|;|:|-]+", in: self.inputText)
                        
            self.doiText = self.doiList.joined(separator: "\n")
            print(self.doiText)
            
            self.beforeDoiTextView.isScrollEnabled = true
                        
            self.finalDoiTextView.insertText(self.doiText)
            self.finalDoiTextView.isScrollEnabled = true
            
            finalDoiTextView.isHidden = false
            confirmBtn.isHidden = false
            // alert that DOI was captured
            self.showOCRToast(titleText: "Nice!", descriptionText: "DOI was cpatured. Click 'Confirm' to proceed.", imageName: "keywords.png")
        }
        
    }
    
    @IBAction func confirmButtonTapped(_ sender: Any) {
        self.dois = finalDoiTextView.text
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "doiToSelect" {
            let selectDoiVC = segue.destination as! SelectDOIViewController
            selectDoiVC.finalDois = self.dois
        }
    }
    
    
}
