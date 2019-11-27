//
//  SelectDOIViewController.swift
//  
//
//  Created by Nicole Bernadette Ong on 7/10/19.
//

import UIKit

class SelectDOIViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let styles = ["apa", "chicago-fullnote-bibliography", "council-of-science-editors", "elsevier-harvard", "ieee", "turabian-fullnote-bibliography"]
    
    let locales = ["af-ZA", "bg-BG","de-DE", "en-GB", "en-US", "es-CL", "fr-FR", "it-IT", "ja-JP", "ko-KR", "ru-RU", "sv-SE"]
    let countries = ["Afrikaans (South Africa)", "Bulgarian (Bulgaria)", "German (Germany)", "English (United Kingdom)", "English (United States)", "Spanish (Chile)", "French (France)", "Italian (Italy)", "Japanese (Japan)", "Korean (Korea)", "Russian (Russia)", "Swedish (Sweden)"]
    
    // Locale dictionary
    var localeDict: Dictionary = [
        "Afrikaans (South Africa)": "af-ZA",
        "Bulgarian (Bulgaria)": "bg-BG",
        "German (Germany)": "de-DE",
        "English (United Kingdom)": "en-GB",
        "English (United States)": "en-US",
        "Spanish (Chile)": "es-CL",
        "French (France)": "fr-FR",
        "Italian (Italy)": "it-IT",
        "Japanese (Japan)": "ja-JP",
        "Korean (Korea)": "ko-KR",
        "Russian (Russia)": "ru-RU",
        "Swedish (Sweden)": "sv-SE"
    ]
    
    var country = ""
    
    var style = ""
    var locale = ""
    
    var finalDois = ""
    var doiList = [String]()
    
    var citationList = [String]()
    var citationCount:Int = 0
    
    var message = ""
  
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var stylePicker: UIPickerView!
    @IBOutlet weak var localePicker: UIPickerView!
    
    @IBOutlet weak var getCitationBtn: UIButton!
    
    var isDone = false
    var partiallyDone = false
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    override func viewDidAppear(_ animated: Bool) {
        // MARK: Tutorial
        showTutorial(key: "selectDoiFirstTime", title: "Select a citation style", description: "Choose a formatting style and language (country). \nClick 'Get citation'. \nYour citation(s) will be generated in just seconds!", imageChosen: UIImage(named: "dois.png")!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.hideKeyboardWhenTappedAround()
        
        // If the textView is empty, the "Get Citation" button willl be hidden
        if self.finalDois == "" {
            self.getCitationBtn.isHidden = true
        } else {
            self.getCitationBtn.isHidden = false
        }
        
        self.textView.text = self.finalDois
        
        stylePicker.delegate = self
        stylePicker.dataSource = self
        localePicker.delegate = self
        localePicker.dataSource = self
    }
    
    // Show Notepad
    @IBAction func showNotepadTapped(_ sender: Any) {
        showNotepad()
    }
    
    // ========== SELECT FORMATTING STYLE & LANGUAGE/LOCALE ==========
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        // differentiate the two pickers
        var countrows : Int = styles.count
        
        if pickerView == localePicker {
            countrows = self.locales.count
        }
        return countrows
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == stylePicker {
            let titleRow = styles[row]
            return titleRow
            
        } else if pickerView == localePicker {
            let titleRow = countries[row]
            return titleRow
        }
        
        return ""
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == stylePicker {
            self.style = self.styles[row]
            
        } else if pickerView == localePicker {
            // Get the value from the key in the localeDict
            self.country = self.countries[row]
            print(localeDict[self.country]!)
            self.locale = localeDict[self.country] ?? ""
        }
    }
    
 
    // CURL REQUEST TO GET THE CITATIONS BY DOI
    @IBAction func getCitation(_ sender: UIButton) {
        print("tapped")
        DispatchQueue.main.async {
            // Show loading
            self.loadingIndicator.startAnimating()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.getCitations { (success) -> Void in
                if success {
                    self.goCitationVC()
                    // Finish loading
                    self.loadingIndicator.stopAnimating()
                }
            }
        }
    }

    
    func getCitations(completion: (_ success: Bool) -> Void) {
        let group = DispatchGroup()
        
        self.doiList = self.matchesDoi(for: "10.\\d+/\\w+\\W?[A-z0-9|/|.|(|)|;|:|-]+", in: self.textView.text)
        
            // Loop through the DOIs, do each cURL in a loop, the number of times there is a DOI
            for doi in doiList {
                group.enter()
                
                guard let reqUrl = URL(string: "https://data.crossref.org/" + doi) else { continue }
                var request = URLRequest(url: reqUrl)
                request.httpMethod = "GET"
                
                let header:String = "text/bibliography; style=" + self.style + "; locale=" + self.locale
                print(header)
                request.setValue(header, forHTTPHeaderField: "Accept")
             
                URLSession.shared.dataTask(with: request) { (data, response, error) in
                    guard error == nil else { print(error!.localizedDescription); return }
                    guard let data = data else { print("Citation could not be retrieved"); return }
                    
                    if let result = String(data: data, encoding: .utf8) {
                        print(result)
                        self.citationList.append(result)
                        self.citationCount += 1
                        
                        group.leave()
                    }
                }.resume()
                
            }
        
        group.wait()
        completion(true)
    }

    
    func goCitationVC() {
        if citationCount == doiList.count {
            self.message = "All citations have been retrieved."
            performSegue(withIdentifier: "showCitations", sender: self)
        } else {
            self.message = "Not all citations were retrieved."
            performSegue(withIdentifier: "showCitations", sender: self)
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCitations" {
            let citationVC = segue.destination as! CitationViewController
            
            // sort in alphabetical order
            let sortedCitationList = citationList.sorted(by: <)
            
            citationVC.citationList = sortedCitationList
            citationVC.message = self.message
        }
    }


}


// MARK: - DOI Uploading Method View Controller
class UploadingMethodDOIViewController: UIViewController, UINavigationControllerDelegate {
    @IBOutlet weak var manualBtn: UIButton!
    @IBOutlet weak var imageBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manualBtn.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        
        imageBtn.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
    }
}

