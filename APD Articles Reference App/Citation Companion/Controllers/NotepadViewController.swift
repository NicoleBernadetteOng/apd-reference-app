//
//  NotepadViewController.swift
//  Citation Companion
//
//  Created by Nicole Bernadette Ong on 8/11/19.
//  Copyright © 2019 Nicole Bernadette Ong. All rights reserved.
//

import UIKit

class NotepadViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var textView: UITextView!
    
    static func instantiate() -> NotepadViewController? {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "\(NotepadViewController.self)") as? NotepadViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowNotepad), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHideNotepad), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        if let savedNotepad = UserDefaults.standard.string(forKey: "notepadString") {
            print(savedNotepad)
            textView.text = savedNotepad
        }
        
        textView.delegate = self
        self.hideKeyboardWhenTappedAround()
    }
    
    // Everytime there is a change in the textView, the UserDefaults will get updated
    func textViewDidChange(_ textView: UITextView) {
        let notepadText = textView.text
        UserDefaults.standard.set(notepadText, forKey: "notepadString")
    }
    
    @objc func keyboardWillShowNotepad(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height - 80
            }
        }
    }

    @objc func keyboardWillHideNotepad(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
}
