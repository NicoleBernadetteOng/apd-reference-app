//
//  ViewController.swift
//  Citation Companion
//
//  Created by Nicole Bernadette Ong on 4/10/19.
//  Copyright © 2019 Nicole Bernadette Ong. All rights reserved.
//

import UIKit
import FloatingPanel
import RSLoadingView
import paper_onboarding
import SwiftEntryKit
import EzPopup

class ViewController: UIViewController {
    
    @IBOutlet weak var startBtn: UIButton!
    
    fileprivate let items = [
        OnboardingItemInfo(informationImage: UIImage(named: "dois.png")!,
                           title: "Citation(s) by DOI",
                           description: "Want to get multiple citations from \n just an image? The DOI number(s) on \n the image will be captured to retrieve \n the citation in a style of your choice.",
                           pageIcon: UIImage(named: "dois.png")!,
                           color: UIColor(red: 0.40, green: 0.56, blue: 0.71, alpha: 1.00),
                           titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: titleFont, descriptionFont: descriptionFont),
    
        
        OnboardingItemInfo(informationImage: UIImage(named: "titles.png")!,
                           title: "Citation by title",
                           description: "Want to cite the correct paper from \n just the title? From the title, the top 5 \n articles will be given for you to select the \n right one for the retrieval of the citation.",
                           pageIcon: UIImage(named: "titles.png")!,
                           color: UIColor(red: 0.40, green: 0.69, blue: 0.71, alpha: 1.00),
                           titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: titleFont, descriptionFont: descriptionFont),
        
        
        OnboardingItemInfo(informationImage: UIImage(named: "keywords.png")!,
                           title: "Article summarizer",
                           description: "No time to read an article? \n Use this feature to extract just the most \n important information as a summary \n as well as keywords and authors.",
                           pageIcon: UIImage(named: "summs.png")!,
                           color: UIColor(red: 0.61, green: 0.56, blue: 0.74, alpha: 1.00),
                           titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: titleFont, descriptionFont: descriptionFont),
    
        
        OnboardingItemInfo(informationImage: UIImage(named: "www.png")!,
                               title: "Review paper",
                               description: "Want to get multiple summaries to compile \n an essay? Use this feature to get article \n summaries from various article by DOI(s).",
                               pageIcon: UIImage(named: "www.png")!,
                               color: UIColor(red: 0.40, green: 0.56, blue: 0.71, alpha: 1.00),
                               titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: titleFont, descriptionFont: descriptionFont),
            
        
        OnboardingItemInfo(informationImage: UIImage(named: "summs.png")!,
                           title: "Find related articles",
                           description: "Want to find articles from just a DOI? \n Use this feature to retrieve the reference o\n of the paper to browse them!",
                           pageIcon: UIImage(named: "keywords.png")!,
                           color: UIColor(red: 0.40, green: 0.69, blue: 0.71, alpha: 1.00),
                           titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: titleFont, descriptionFont: descriptionFont),
        
        
        OnboardingItemInfo(informationImage: UIImage(named: "translator.png")!,
                           title: "Abstract translator",
                           description: "Ever wanted to read an abstract in a \n journal in a foreign language? Look no \n further because this feature allows translation \n between 16 different languages",
                           pageIcon: UIImage(named: "translator.png")!,
                           color: UIColor(red: 0.61, green: 0.56, blue: 0.74, alpha: 1.00),
                           titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: titleFont, descriptionFont: descriptionFont),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startBtn.isHidden = true
        
        self.hideKeyboardWhenTappedAround()
        setupPaperOnboardingView()
        view.bringSubviewToFront(startBtn)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func setupPaperOnboardingView() {
        let onboarding = PaperOnboarding()
        onboarding.delegate = self
        onboarding.dataSource = self
        onboarding.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(onboarding)

        // Add constraints
        for attribute: NSLayoutConstraint.Attribute in [.left, .right, .top, .bottom] {
            let constraint = NSLayoutConstraint(item: onboarding,
                                                attribute: attribute,
                                                relatedBy: .equal,
                                                toItem: view,
                                                attribute: attribute,
                                                multiplier: 1,
                                                constant: 0)
            view.addConstraint(constraint)
        }
    }
    
}

// MARK: - Onboarding
extension ViewController {

    // When the onboarding is done
    @IBAction func skipButtonTapped(_: UIButton) {
        print(#function)
        
        // Go to HomeViewController
        performSegue(withIdentifier: "toHome", sender: self)
    }
}


// MARK: PaperOnboardingDelegate
extension ViewController: PaperOnboardingDelegate {

    func onboardingWillTransitonToIndex(_ index: Int) {
        startBtn.isHidden = index == 5 ? false : true
    }

    func onboardingConfigurationItem(_ item: OnboardingContentViewItem, index: Int) {
    
    }
}


// MARK: PaperOnboardingDataSource
extension ViewController: PaperOnboardingDataSource {

    func onboardingItem(at index: Int) -> OnboardingItemInfo {
        return items[index]
    }

    func onboardingItemsCount() -> Int {
        return 6
    }
}

// MARK: Constants
private extension ViewController {
    static let titleFont = UIFont(name: "Nunito-Bold", size: 36.0) ?? UIFont.boldSystemFont(ofSize: 36.0)
    static let descriptionFont = UIFont(name: "OpenSans-Regular", size: 14.0) ?? UIFont.systemFont(ofSize: 14.0)
}


// MARK: - Functions
// For all views
extension UIViewController {
    
    // =============== DISMISS KEYBOARD ===============
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    
    // =============== REGULAR EXPRESSION MATCH DOI ===============
    func matchesDoi(for regex: String, in text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch _ {
            print("Invalid regex")
            return []
        }
    }
    
    
    // =========== FUNCTION TO CLEAN TITLE INFO ===========
    func cleanTitleInfo(info: String) -> String {
        var cleanInfo = info.replacingOccurrences(of: "null", with: "")
        cleanInfo = cleanInfo.replacingOccurrences(of: "[", with: "")
        cleanInfo = cleanInfo.replacingOccurrences(of: "]", with: "")
        cleanInfo = cleanInfo.replacingOccurrences(of: "{", with: "")
        cleanInfo = cleanInfo.replacingOccurrences(of: "}", with: "")
        cleanInfo = cleanInfo.replacingOccurrences(of: "\"", with: "")
        cleanInfo = cleanInfo.replacingOccurrences(of: ",", with: "")
        cleanInfo = cleanInfo.replacingOccurrences(of: "given : ", with: "")
        cleanInfo = cleanInfo.replacingOccurrences(of: "family : ", with: "")
        cleanInfo = cleanInfo.replacingOccurrences(of: "suffix : ", with: "")
        cleanInfo = cleanInfo.replacingOccurrences(of: "sequence : first", with: "")
        cleanInfo = cleanInfo.replacingOccurrences(of: "sequence : additional", with: "")
        cleanInfo = cleanInfo.replacingOccurrences(of: "affiliation : ", with: "")
        cleanInfo = cleanInfo.replacingOccurrences(of: "\n  ", with: "")
        cleanInfo = cleanInfo.replacingOccurrences(of: "   ", with: " ")
        cleanInfo = cleanInfo.replacingOccurrences(of: "  \n  \n  ", with: ", ")
        cleanInfo = cleanInfo.replacingOccurrences(of: " \n  ", with: " ")
        cleanInfo = cleanInfo.replacingOccurrences(of: "\n\n", with: "\n")
        
        return cleanInfo
    }
    
    
    // MARK: - SwiftEntryKit Toasts
    // =========== FUNCTION TO DISPLAY TOAST RELATED TO OCR ===========
    func showOCRToast(titleText: String, descriptionText: String, imageName: String) {
        var attributes = EKAttributes.bottomFloat
        attributes.entryBackground = .gradient(gradient: .init(colors: [EKColor(#colorLiteral(red: 0.750326294, green: 0.8894403989, blue: 1, alpha: 1)), EKColor(.white)], startPoint: .zero, endPoint: CGPoint(x: 1, y: 1)))
        attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.3), scale: .init(from: 1, to: 0.7, duration: 0.7)))
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.5, radius: 10, offset: .zero))
        attributes.statusBar = .dark
        attributes.scroll = .enabled(swipeable: true, pullbackAnimation: .jolt)
        
        let edgeWidth = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        attributes.positionConstraints.maxSize = .init(width: .constant(value: edgeWidth), height: .intrinsic)

        let title = EKProperty.LabelContent(text: titleText, style: .init(font: UIFont.systemFont(ofSize: 16.0), color: .black))
        let description = EKProperty.LabelContent(text: descriptionText, style: .init(font: UIFont.systemFont(ofSize: 14.0), color: .black))
        let image = EKProperty.ImageContent(image: UIImage(named: imageName)!, size: CGSize(width: 45, height: 45))
        let simpleMessage = EKSimpleMessage(image: image, title: title, description: description)
        let notificationMessage = EKNotificationMessage(simpleMessage: simpleMessage)

        let contentView = EKNotificationMessageView(with: notificationMessage)
        SwiftEntryKit.display(entry: contentView, using: attributes)
    }
    
    
    // MARK: - Notepad Popup
    func showNotepad() {
        // Need a ViewController
        guard let notepadVC = NotepadViewController.instantiate() else { return }
        
        let popupVC = PopupViewController(contentController: notepadVC, popupWidth: 340, popupHeight: 500)
        popupVC.cornerRadius = 5
        present(popupVC, animated: true, completion: nil)
    }
    
    
    // MARK: - Tutorial Popup
    
    func showTutorial(key: String, title: String, description: String, imageChosen: UIImage) {
        if UserDefaults.standard.object(forKey: key) == nil { // Change back to == nil when done testing
            UserDefaults.standard.set("No", forKey: key)
            
            guard let tutorialVC = TutorialViewController.instantiate() else { return }
            tutorialVC.titleString = title
            tutorialVC.descriptionString = description
            tutorialVC.image = imageChosen
            
            let popupVC = PopupViewController(contentController: tutorialVC, popupWidth: 340, popupHeight: 300)
            popupVC.cornerRadius = 5
            present(popupVC, animated: true, completion: nil)
        }
    }
    
    
    // MARK: - Loading Functions
    @IBAction func showLoadingHub() {
        let loadingView = RSLoadingView()
        loadingView.show(on: view)
    }
    
    func hideLoadingHub() {
        RSLoadingView.hide(from: view)
    }
    
    
    // MARK: - Adjusting View with Keyboard 
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }

}
