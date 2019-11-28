//
//  TutorialViewController.swift
//  Citation Companion
//
//  Created by Nicole Bernadette Ong on 8/11/19.
//  Copyright © 2019 Nicole Bernadette Ong. All rights reserved.
//

import UIKit

class TutorialViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var image: UIImage?
    var titleString: String?
    var descriptionString: String?
    
    static func instantiate() -> TutorialViewController? {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "\(TutorialViewController.self)") as? TutorialViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.image = image
        titleLabel.text = titleString
        descriptionLabel.text = descriptionString
    }

}
