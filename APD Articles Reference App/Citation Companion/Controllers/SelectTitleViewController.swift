//
//  SelectTitleViewController.swift
//  Citation Companion
//
//  Created by Nicole Ong on 8/10/19.
//  Copyright © 2019 Nicole Bernadette Ong. All rights reserved.
//

import UIKit


class TitleTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
}


class SelectTitleViewController: UIViewController, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
 
    var finalTitle = ""
   
    var infoList = [String]()
    var infoCount:Int = 0
    
    var selectedDoiCell = ""
    var doiList = [String]()
    var doi = "" // doi string to send
    var message = ""
    
    override func viewDidAppear(_ animated: Bool) {
        // MARK: Tutorial
        showTutorial(key: "selectTitleFirstTime", title: "Select a title", description: "Great! Now click on the row with the information you tend to use to retrieve your citation.", imageChosen: UIImage(named: "titles.png")!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
   
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    @IBAction func showNotepadTapped(_ sender: Any) {
        showNotepad()
    }
    
    // ========== SHOW TITLES IN TABLE ==========
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return infoList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "titleCell", for: indexPath) as! TitleTableViewCell
        
        cell.titleLabel?.text = infoList[indexPath.row]
        
        return cell
    }
    
    // Let the user select the correct title then get the DOI from it and send to the SelectDOIViewController
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let indexPath = tableView.indexPathForSelectedRow
        let selectedCell = tableView.cellForRow(at: indexPath!) as! TitleTableViewCell
        
        let selectedDoi = selectedCell.titleLabel.text!
        
        // from the text, just extract the doi
        self.doiList = self.matchesDoi(for: "10.\\d+/\\w+\\W?[A-z0-9|/|.|(|)|;|:|-]+", in: selectedDoi)
        
        self.doi = self.doiList.joined(separator: "\n")
        
        performSegue(withIdentifier: "sendTitleDoi", sender: self)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "sendTitleDoi" {
            let selectDoiVC = segue.destination as! SelectDOIViewController
            
            selectDoiVC.finalDois = self.doi
        }
    }
    

}
