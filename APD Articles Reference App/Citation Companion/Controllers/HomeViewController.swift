//
//  HomeViewController.swift
//  Citation Companion
//
//  Created by Nicole Bernadette Ong on 5/11/19.
//  Copyright © 2019 Nicole Bernadette Ong. All rights reserved.
//

import UIKit
import MXParallaxHeader
import ImageSlideshow

class HomeTableViewCell: UITableViewCell {
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    
    @IBOutlet weak var description1: UILabel!
    @IBOutlet weak var description2: UILabel!
    
    @IBOutlet weak var title1: UILabel!
    @IBOutlet weak var title2: UILabel!
}


class HomeViewController: UIViewController, MXParallaxHeaderDelegate, UITableViewDelegate, UITableViewDataSource, ImageSlideshowDelegate {

    let navNameListLeft = ["Citation", "Article summarizer", "Find related articles"]
    let navNameListRight = ["Citation", "Review paper", "Abstract translator"]
    
    let imgListLeft = ["dois.png", "keywords.png", "summs.png"]
    let imgListRight = ["titles.png", "www.png", "translator.png"]
    
    let descListLeft = ["Get citation(s) by DOI", "Get article summary", "Get related articles"]
    let descListRight = ["Get citation by title", "Get multiple summaries", "Translate an abstract"]
    
    let tagLeft = [0, 2, 4]
    let tagRight = [1, 3, 5]
    
    @IBOutlet weak var questionBtn: UIButton!
    @IBOutlet weak var aboutbtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var scrollView: MXScrollView!
    @IBOutlet weak var slideshow: ImageSlideshow!
    
    let localSource = [BundleImageSource(imageString: "spamd1"), BundleImageSource(imageString: "trove")]
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        scrollView.parallaxHeader.minimumHeight = view.safeAreaInsets.top + 68
        
        // MARK: Tutorial
//        showTutorial(key: "homeFirstTime", title: "Welcome!", description: "Click on 'Notepad' in the navigation bar.", imageChosen: UIImage(named: "keywords.png")!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInset.bottom = 75
        
        // Parallax Header
        scrollView = MXScrollView()
        
        scrollView.parallaxHeader.load(withNibName: "Header", bundle: nil, options: nil)
        scrollView.parallaxHeader.height = 300
        scrollView.parallaxHeader.mode = .fill
        view.addSubview(scrollView)
    
//        tableView.delegate = self
        tableView.rowHeight = 250
        tableView.dataSource = self
        scrollView.addSubview(tableView)
        
        view.bringSubviewToFront(questionBtn)
        view.bringSubviewToFront(aboutbtn)
        
        // 'Carousel'
        slideshow.slideshowInterval = 5.0
        slideshow.pageIndicatorPosition = .init(horizontal: .center, vertical: .under)
        slideshow.contentScaleMode = UIViewContentMode.scaleAspectFill

        let pageControl = UIPageControl()
        pageControl.currentPageIndicatorTintColor = UIColor.lightGray
        pageControl.pageIndicatorTintColor = UIColor.black
        slideshow.pageIndicator = pageControl

        // optional way to show activity indicator during image load (skipping the line will show no activity indicator)
        slideshow.activityIndicator = DefaultActivityIndicator()
        slideshow.delegate = self

        // can be used with other sample sources as `afNetworkingSource`, `alamofireSource` or `sdWebImageSource` or `kingfisherSource`
        slideshow.setImageInputs(localSource)
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        var frame = view.bounds
        
        view.backgroundColor = #colorLiteral(red: 0.9635079339, green: 0.9635079339, blue: 0.9635079339, alpha: 0.8470588235)
//        scrollView.backgroundColor = #colorLiteral(red: 0.9635079339, green: 0.9635079339, blue: 0.9635079339, alpha: 0.8470588235)
        tableView.backgroundColor = #colorLiteral(red: 0.9635079339, green: 0.9635079339, blue: 0.9635079339, alpha: 0.8470588235)
        
        scrollView.frame = frame
        scrollView.contentSize = frame.size

        frame.size.width = frame.size.width
        frame.size.height -= scrollView.parallaxHeader.minimumHeight
        tableView.frame = frame

        frame.origin.x = frame.size.width
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    // MARK: - Table view data source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "homeCell", for: indexPath) as! HomeTableViewCell
        
        cell.selectionStyle = .none
        
        // Styles
        cell.button1.layer.cornerRadius = 5.0
        cell.button2.layer.cornerRadius = 5.0
        
        cell.button1.setTitleColor(.black, for: .normal)
        cell.button2.setTitleColor(.black, for: .normal)
        
        cell.button1.imageView?.contentMode = .scaleAspectFit
        cell.button2.imageView?.contentMode = .scaleAspectFit
        
        // Tags
        cell.button1.tag = tagLeft[indexPath.row]
        cell.button2.tag = tagRight[indexPath.row]
        
        // Set images
        cell.button1.setImage(UIImage(named: imgListLeft[indexPath.row]), for: .normal)
        cell.button2.setImage(UIImage(named: imgListRight[indexPath.row]), for: .normal)
        
        // Set titles
        cell.title1.text = navNameListLeft[indexPath.row]
        cell.title2.text = navNameListRight[indexPath.row]
//        cell.button1.setTitle(navNameListLeft[indexPath.row], for: .normal)
//        cell.button2.setTitle(navNameListRight[indexPath.row], for: .normal)
//
//        cell.button1.titleEdgeInsets = UIEdgeInsets(top: 40, left: -500, bottom: 0, right: 16)
//        cell.button2.titleEdgeInsets = UIEdgeInsets(top: 40, left: -495, bottom: 0, right: 16)
        
        
        // Set descriptions
        cell.description1.text = descListLeft[indexPath.row]
        cell.description2.text = descListRight[indexPath.row]
        
        
        // Actions
        cell.button1.addTarget(self, action: #selector(button1Tapped), for: .touchUpInside)
        cell.button2.addTarget(self, action: #selector(button2Tapped), for: .touchUpInside)
     
        return cell
    }
    
    
    // MARK: - Button navigation
    
    @objc func button1Tapped(_ sender: UIButton) {
        let intTag = sender.tag
        print(intTag)
        
        switch intTag {
            case 0:
                print("0 tapped")
                performSegue(withIdentifier: "toCitationByDOI", sender: self)
            case 2:
                print("2 tapped")
                performSegue(withIdentifier: "toArticleSumm", sender: self)
            case 4:
                print("4 tapped")
                performSegue(withIdentifier: "toRelated", sender: self)
            default:
                print("default")
        }
    }
    
    @objc func button2Tapped(_ sender: UIButton) {
        let intTag = sender.tag
        print(intTag)
        
        switch intTag {
            case 1:
                print("1 tapped")
                performSegue(withIdentifier: "toCitationByTitle", sender: self)
            case 3:
                print("3 tapped")
                performSegue(withIdentifier: "toReview", sender: self)
            case 5:
                print("5 tapped")
                performSegue(withIdentifier: "toTranslator", sender: self)
            default:
                print("default")
        }
    }
    
    func goToAbout() {
        self.performSegue(withIdentifier: "AboutVC", sender: self)
    }
    
    // MARK: - Scroll view delegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        NSLog("progress %f", scrollView.parallaxHeader.progress)
        print(scrollView.parallaxHeader.progress)
    }
    
}

