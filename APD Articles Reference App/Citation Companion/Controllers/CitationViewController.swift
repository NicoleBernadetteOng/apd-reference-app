//
//  CitationViewController.swift
//  Citation Companion
//
//  Created by Nicole Ong on 7/10/19.
//  Copyright © 2019 Nicole Bernadette Ong. All rights reserved.
//

import UIKit
import MessageUI

struct Citation {
    var citaionText : String
}


class CitationTableViewCell: UITableViewCell {
    @IBOutlet weak var citationLabel: UILabel!
}


class CitationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate {

    var citationList = [String]()
    var message = ""
    
    @IBOutlet weak var citationTable: UITableView!
    
    @IBOutlet weak var copyBtn: UIButton!
    @IBOutlet weak var shareBtn: UIButton!
    @IBOutlet weak var anotherCitationBtn: UIButton!
    
    override func viewDidAppear(_ animated: Bool) {
        // MARK: Tutorial
        showTutorial(key: "citationFirstTime", title: "Citations retrieved!", description: "Swipe left on the row to delete it. \nCongratulations on retrieving your first citation!", imageChosen: UIImage(named: "titles.png")!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        citationTable.delegate = self
        citationTable.dataSource = self
        
        if message != "" {
            self.showOCRToast(titleText: "Yay!", descriptionText: self.message, imageName: "keywords.png")
        }
        
    }
    
    @IBAction func showNotepadTapped(_ sender: Any) {
        showNotepad()
    }
    
    // ========== SHOW CITATIONS IN TABLE ==========
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return citationList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = citationTable.dequeueReusableCell(withIdentifier: "citationCell", for: indexPath) as! CitationTableViewCell

        cell.citationLabel?.text = citationList[indexPath.row]

        return cell
    }
    
    // Swipe to delete
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") {
            (action, indexPath) in
            self.citationList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            print(self.citationList)
        }
        
        return [delete]
    }

    
    // =========== COPY TO CLIPBOARD ===========
    @IBAction func copyBtnPressed(_ sender: Any) {
        print(self.citationList)
        let citations = citationList.joined(separator: "\n")
        // copy citationList to Clipboard
        UIPasteboard.general.string = citations
        
        self.showOCRToast(titleText: "Copied to clipboard", descriptionText: "", imageName: "search.png")
    }
    
    
    // =========== SHARE / EXPORT ===========
    @IBAction func shareBtnPressed(_ sender: Any) {
        
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            
            mailComposer.setSubject("Citations")
            
            let citations = citationList.joined(separator: "\n")
            mailComposer.setMessageBody(citations, isHTML: false)
            
            self.present(mailComposer, animated: true, completion: nil)
        }
        
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        // Dismiss the mail compose view controller.
        controller.dismiss(animated: true, completion: nil)
    }
    
}


