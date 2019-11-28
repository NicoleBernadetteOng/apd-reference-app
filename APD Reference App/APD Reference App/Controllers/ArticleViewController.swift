//
//  ArticleViewController.swift
//  Citation Companion
//
//  Created by Megan Ong Kailing on 10/10/19.
//  Copyright © 2019 Nicole Bernadette Ong. All rights reserved.
//

import UIKit
import Reductio
import FloatingPanel
import SwiftSoup
import AlignedCollectionViewFlowLayout
import RSLoadingView

import WebKit


class ArticleViewController: UIViewController, WKNavigationDelegate, UINavigationControllerDelegate, FloatingPanelControllerDelegate {
    
    var fpc: FloatingPanelController!
    var searchVC: SearchPanelViewController!
    
    var url: String?
    var html = ""
    
    var done = false
    var timer: Timer?
    var runCount = 0
    var counter = 0
    
    // ===== Data =====
    public var cacheTitle = ""
    public var cacheSummary = ""
    public var cacheKeywords = ""
    public var cacheAuthor = ""
    public var cacheUrl = ""
    public var cacheArticle = ""
    // ================
    var historyArray = [History]()
    
//    let dataFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("History.plist")
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    // =================
    
    @IBOutlet var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        
        let unwrappedUrl: String = self.url!
        print("unwrappedUrl: " + unwrappedUrl)
        
        let urlUrl = URL(string: unwrappedUrl)
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        let config = WKWebViewConfiguration()
        config.preferences = preferences
        webView = WKWebView(frame: CGRect(x:0, y: 44, width: view.frame.width, height: view.frame.height-44), configuration: config)
        view.addSubview(webView)
        
        webView.navigationDelegate = self

        // Load the url
        webView.load(URLRequest(url: urlUrl!))
        // ==============================================
       
        // Do any additional setup after loading the view, typically from a nib.
        // Initialize FloatingPanelController
        fpc = FloatingPanelController()
        fpc.delegate = self
        
        // Initialize FloatingPanelController and add the view
        fpc.surfaceView.backgroundColor = .clear
        if #available(iOS 11, *) {
            fpc.surfaceView.cornerRadius = 9.0
        } else {
            fpc.surfaceView.cornerRadius = 0.0
        }
        fpc.surfaceView.shadowHidden = false
        
        searchVC = storyboard?.instantiateViewController(withIdentifier: "SearchPanel") as? SearchPanelViewController
        
        // Set a content view controller
        fpc.set(contentViewController: searchVC)
        fpc.track(scrollView: searchVC.scrollView)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBAction func showNotepadTapped(_ sender: Any) {
        showNotepad()
    }
    
    
    // ============================================================
    // JavaScript to get the html documet elements from the webView
    // - Title
    // - Article (to get summary and keywords)
    // - Authors
    // - url
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("webView didFinish")
        getData()
    }
    
    func getData() {
        let finalUrl = String(describing: webView.url)
        self.cacheUrl = finalUrl
        
        self.getTitle(finalUrl: finalUrl, webView: webView)
        print(cacheTitle)
        
        self.getAuthor(finalUrl: finalUrl, webView: webView)
        print(cacheAuthor)
        
        self.getArticle(finalUrl: finalUrl, webView: webView) {
            (returnThis) in
            print(self.cacheArticle)
            
            self.load()
        }
    }
    
    
    // Run the function to show the summary on the floating panel
    func load() {
        print("loading")
        
        // Delete whatever is saved in UserDefaults
        UserDefaults.standard.removeObject(forKey: "summary")
        UserDefaults.standard.removeObject(forKey: "keywords")
        UserDefaults.standard.removeObject(forKey: "authors")

        UserDefaults.standard.set(self.cacheSummary, forKey: "summary")
        UserDefaults.standard.set(self.cacheKeywords, forKey: "keywords")
        UserDefaults.standard.set(self.cacheAuthor, forKey: "authors")
        UserDefaults.standard.synchronize()
        self.done = true
        
        // Save items to cache in this function as well
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { // wait 3 seconds
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refresh"), object: nil)
            
            // Save to Core Data (cache)
            let newHistory = History(context: self.context)
            
            newHistory.title = self.cacheTitle
            newHistory.summary = self.cacheSummary
            newHistory.authors = self.cacheAuthor
            newHistory.url = self.cacheUrl
            
            self.historyArray.append(newHistory)
            
            do {
                try self.context.save()
            } catch {
                print("Error encoding history array, \(error)")
            }
        }
    }
    
    
    // For redirecting, if needed
    // MARK: WebView Delegates
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow) // allow the user to navigate to the requested page.
    }
       
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow) // allow the webView to process the response.
    }
    

    // MARK: Get Summary
    func getSummary(articleText: String) -> String {
        var summary = ""
        
        Reductio.summarize(text: articleText, compression: 0.70) { phrases in
            print(phrases)
            summary = phrases.joined(separator: "")
            
            // If the article is too short and a summary can't be formed, the articleText will be the summary
            if phrases == [] {
                print("phrases is []")
                summary = articleText
            }
        }
        return summary
    }
    
    // MARK: - Get keywords
    func getKeywords(articleText: String) -> String {
        var keywords = ""
        
        Reductio.keywords(from: articleText, count: 8) { words in
            print(words)
            keywords = words.joined(separator: ", ")
            
            if words == [] {
                print("words is []")
                keywords = "word, word, word, word, word, word, word, word" // so that the count will still be 8 - app won't crash
            }
        }
        
        return keywords
    }
    
    
    func cleanArticleValue(value: Any) -> String {
        var value: String = value as! String
        
        value = value.replacingOccurrences(of: "</p>", with: "")
        value = value.replacingOccurrences(of: "<p id=\"p-4\">", with: "")
        value = value.replacingOccurrences(of: "<p id=\"p-5\">", with: "")
        
        value = value.replacingOccurrences(of: "<h2>Abstract</h2>", with: "")
        value = value.replacingOccurrences(of: "<h2 class=\"\">ABSTRACT</h2>", with: "")
        
        value = value.replacingOccurrences(of: "<span class=\"named-content genus-species\" id=\"named-content-4\">", with: "")
        value = value.replacingOccurrences(of: "<span class=\"named-content genus-species\" id=\"named-content-5\">", with: "")
        value = value.replacingOccurrences(of: "<span class=\"named-content genus-species\" id=\"named-content-6\">", with: "")
        value = value.replacingOccurrences(of: "<span class=\"sc\">", with: "")
        value = value.replacingOccurrences(of: "</span>", with: "")
        value = value.replacingOccurrences(of: "</sup>", with: "")
        value = value.replacingOccurrences(of: "<sup>", with: "")
        value = value.replacingOccurrences(of: "</em>", with: "")
        value = value.replacingOccurrences(of: "<em>", with: "")
        value = value.replacingOccurrences(of: "</strong>", with: "")
        value = value.replacingOccurrences(of: "<strong>", with: "")
        
        return value
    }
    
    // ============================================================
    
    func getTitle(finalUrl: String, webView: WKWebView) {
    
        var thisHtml = ""
        
        webView.evaluateJavaScript("document.documentElement.outerHTML.toString()", completionHandler: { (value, error) in
            thisHtml = value as! String
            
            do {
                let doc: Document = try SwiftSoup.parse(thisHtml)
                var titleText:String = ""
                
                if (titleText == "") {
                    let titleElement = try doc.getElementsByClass("headline").first()
                    
                    if titleElement != nil {
                        titleText = try titleElement!.text()
                    }
                }
                
                // JBC
                if (titleText == "") {
                    let titleElement = try doc.getElementsByAttributeValueContaining("id", "article-title-1").first()
                    
                    if titleElement != nil {
                        titleText = try titleElement!.text()
                    }
                }
                
                // Frontiers In
                if (titleText == "") {
                    let titleElement = try doc.getElementsByTag("title").first()
                    
                    if titleElement != nil {
                        titleText = try titleElement!.text()
                    }
                }
                
                if (titleText == "") {
                    let titleElement = try doc.getElementsByAttributeValueContaining("class", "title").first()
                    
                    if titleElement != nil {
                        titleText = try titleElement!.text()
                    }
                }

                // =====================
                
                if (titleText != "") {
                    self.cacheTitle = titleText
                } else {
                    self.cacheTitle = "Unable to retrieve title"
                }
            } catch {
                print("error")
            }
        })
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
                
                
                // Springer & PLOS & ScienceOpen & PNAS & Semantic Scholar (but only the first part, can't click CONTINUE READING)
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
                    let cleanArticle = self.cleanArticleValue(value: articleText)

                    returnThis = cleanArticle
                    print("returnThis: " + returnThis)
                    
                    self.cacheArticle = returnThis
                    self.cacheSummary = self.getSummary(articleText: returnThis)
                    self.cacheKeywords = self.getKeywords(articleText: returnThis)
                    
                    completion(returnThis)
                    
                } else {
                    self.cacheArticle = "Unable to retrieve full article text"
                    self.cacheSummary = "Unable to retrieve full article text"
                    self.cacheKeywords = "Unable to retrieve keywords from text"
                    
                    returnThis = ""
                    completion(returnThis)
                }
                
            } catch {
                print("error")
                returnThis = ""
                completion(returnThis)
            }
        })
    }
    

    func getAuthor(finalUrl: String, webView: WKWebView) {

        var thisHtml = ""
        
        webView.evaluateJavaScript("document.documentElement.outerHTML.toString()", completionHandler: { (value, error) in
            thisHtml = value as! String

            do {
                let doc: Document = try SwiftSoup.parse(thisHtml)
                var authorText: String = ""
                
                if (authorText == "") {
                    let authorElement = try doc.getElementsByAttributeValueContaining("class", "byline").first()
                    
                    if authorElement != nil {
                        authorText = try authorElement!.text()
                        print("byline in article: " + authorText)
                    }
                }
                
                // ASM
                if (authorText == "") {
                    // Make the article method return the article element to use
                    let authorElement = try doc.getElementsByAttributeValueContaining("class", "byline").first()
                    
                    if authorElement != nil {
                        authorText = try authorElement!.text()
                        print("byline in article: " + authorText)
                    }
                }
                
                // Science Open
                if (authorText == "") {
                    let authorElement = try doc.getElementsByAttributeValueContaining("class", "so-article-header-info").first()
                    
                    if authorElement != nil {
                        authorText = try authorElement!.text()
                    }
                }
                
                if (authorText == "") {
                    let authorElement = try doc.getElementsByAttributeValueContaining("class", "author").first()
                    
                    if authorElement != nil {
                        authorText = try authorElement!.text()
                    }
                }
                
                if (authorText == "") {
                    let authorElement = try doc.getElementsByAttributeValueContaining("class", "byline").first()
                    
                    if authorElement != nil {
                        authorText = try authorElement!.text()
                    }
                }
                
                if (authorText == "") {
                    let authorElement = try doc.getElementsByAttributeValueContaining("class", "contributor").first()
                    
                    if authorElement != nil {
                        authorText = try authorElement!.text()
                    }
                }
                
                if (authorText == "") {
                    let authorElement = try doc.getElementsByAttributeValueContaining("class", "authors").first()
                    
                    if authorElement != nil {
                        authorText = try authorElement!.text()
                    }
                }
                
                // PubMed
                if (authorText == "") {
                    let authorElement = try doc.getElementsByAttributeValueContaining("class", "auths").first()
                    
                    if authorElement != nil {
                        authorText = try authorElement!.text()
                    }
                }
                
                // DOAJ
                if (authorText == "") {
                    let authorElement = try doc.getElementsByAttributeValueContaining("class", "box slim").first()
                    
                    if authorElement != nil {
                        authorText = try authorElement!.text()
                    }
                }
                
                if (authorText == "") {
                    let authorElement = try doc.getElementsByAttributeValueContaining("class", "author").first()
                    
                    if authorElement != nil {
                        authorText = try authorElement!.text()
                    }
                }
                
                if (authorText == "") {
                    let authorElement = try doc.getElementsByAttributeValueContaining("class", "byline").first()
                    
                    if authorElement != nil {
                        authorText = try authorElement!.text()
                    }
                }
                
                if (authorText == "") {
                    let authorElement = try doc.getElementsByAttributeValueContaining("class", "contributor").first()
                    
                    if authorElement != nil {
                        authorText = try authorElement!.text()
                    }
                }
                
                // ========================
                
                if (authorText != "") {
                    
                    authorText = authorText.replacingOccurrences(of: "Author links open overlay panel", with: "") // Elsevier ScienceDirect
                    authorText = authorText.replacingOccurrences(of: "Authors Authors and affiliations ", with: "") // Springer
                    authorText = authorText.replacingOccurrences(of: "Authors: ", with: "") // Science Open
                    authorText = authorText.replacingOccurrences(of: "Authors:", with: "") // arXiv
                    authorText = authorText.replacingOccurrences(of: "AUTHORS ", with: ""); // DOAJ
                    
                    self.cacheAuthor = authorText
                    
                } else {
                    self.cacheAuthor = "Unable to retrieve author(s)"
                }
                
            } catch {
                print("error")
            }
        })
    }
 

    // ============================================================
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //  Add FloatingPanel to a view with animation.
        fpc.addPanel(toParent: self, animated: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        teardownWebView()
    }
    
    
    func teardownWebView() {
        // Prevent a crash
        webView.navigationDelegate = nil
        webView = nil
    }

  
    // MARK: - FloatingPanelControllerDelegate
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        switch newCollection.verticalSizeClass {
        case .compact:
            fpc.surfaceView.borderWidth = 1.0 / traitCollection.displayScale
            fpc.surfaceView.borderColor = UIColor.black.withAlphaComponent(0.2)
            return SearchPanelLandscapeLayout()
        default:
            fpc.surfaceView.borderWidth = 0.0
            fpc.surfaceView.borderColor = nil
            return nil
        }
    }
    
}


// MARK: Floating Panel
// =================== FLOATING PANEL ===================
class SearchPanelViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    @IBOutlet weak var buttonCollectionView: UICollectionView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    
    @IBOutlet weak var summaryTextView: UITextView!
    
    @IBOutlet weak var authorsLabel: UILabel!
    
    @IBOutlet weak var noKeywordsLabel: UILabel!
    
    var thisSummary: String?
    var thisKeywords: String = "word, word, word, word, word, word, word, word"
    var thisAuthors: String?
    
    var timer: Timer?
    var runCount = 0
    
    // For iOS 10 only
    private lazy var shadowLayer: CAShapeLayer = CAShapeLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(showSumm), name: NSNotification.Name(rawValue: "refresh"), object: nil)
        
        buttonCollectionView.isHidden = true
        
        buttonCollectionView.delegate = self
        buttonCollectionView.dataSource = self
    
        noKeywordsLabel.isHidden = true
        
        // Show the progressbar
        showLoadingHub()
    }
    

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("in numbersOfItemsInSection: " + thisKeywords)
        return self.thisKeywords.components(separatedBy: ", ").count // will always be 8
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let buttonCell = collectionView.dequeueReusableCell(withReuseIdentifier: "buttonCell", for: indexPath) as! ButtonCollectionViewCell
        
        // Handle the button text here
        let keywordsArray = self.thisKeywords.components(separatedBy: ", ")
//        print("===keywordsArray===")
//        print(keywordsArray)
        buttonCell.button.setTitle(keywordsArray[indexPath.item].uppercased(), for: .normal)
        buttonCell.button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13.0)
        
        return buttonCell
    }
    
   
    // When the button in CollectionViewCell is pressed
    
    
    
    // Load this only when the summary has been retrieved
    @objc func showSumm() {
        print("showSumm")
        
        self.thisSummary = UserDefaults.standard.string(forKey: "summary") ?? ""
        self.thisKeywords = UserDefaults.standard.string(forKey: "keywords") ?? "word, word, word, word, word, word, word, word"
        print("in showSumm(): " + thisKeywords)
        self.thisAuthors = UserDefaults.standard.string(forKey: "authors") ?? ""
        
        print("self.thisKeywords" + self.thisKeywords)
        
        if self.thisSummary != nil {
            print("self.thisSummary is not nil: " + self.thisSummary!)
            load()
        } else {
            print("self.thisSummary is nil: " + self.thisSummary!)
        }
    
    }
    
    func load() {
        // Summary
        summaryTextView?.text = self.thisSummary
        summaryTextView.sizeToFit()
        summaryTextView.layoutIfNeeded()
        let textSize = summaryTextView.contentSize;
        if (textSize != summaryTextView.frame.size) {
            summaryTextView.frame.size = textSize;
        }
            
        // Keywords
        if self.thisKeywords.components(separatedBy: ", ") == ["word", "word", "word", "word", "word", "word", "word", "word"] {
            buttonCollectionView.isHidden = true
            noKeywordsLabel.isHidden = false
        } else {
            buttonCollectionView.isHidden = false
        }
        
        let alignedFlowLayout = AlignedCollectionViewFlowLayout(horizontalAlignment: .left, verticalAlignment: .center)
        buttonCollectionView.collectionViewLayout = alignedFlowLayout
        // Enable automatic cell-sizing with Auto Layout:
        alignedFlowLayout.estimatedItemSize = .init(width: 80, height: 35)
        
        buttonCollectionView.reloadData()
        
        
        // Authors
        authorsLabel?.text = self.thisAuthors
        authorsLabel.sizeToFit()
        
        // finish progress bar
        hideLoadingHub()
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if #available(iOS 11, *) {
        } else {
            // Exmaple: Add rounding corners on iOS 10
            visualEffectView.layer.cornerRadius = 9.0
            visualEffectView.clipsToBounds = true
            
            // Exmaple: Add shadow manually on iOS 10
            view.layer.insertSublayer(shadowLayer, at: 0)
            let rect = visualEffectView.frame
            let path = UIBezierPath(roundedRect: rect,
                                    byRoundingCorners: [.topLeft, .topRight],
                                    cornerRadii: CGSize(width: 9.0, height: 9.0))
            shadowLayer.frame = visualEffectView.frame
            shadowLayer.shadowPath = path.cgPath
            shadowLayer.shadowColor = UIColor.black.cgColor
            shadowLayer.shadowOffset = CGSize(width: 0.0, height: 1.0)
            shadowLayer.shadowOpacity = 0.2
            shadowLayer.shadowRadius = 3.0
        }
    }
    
}


public class SearchPanelLandscapeLayout: FloatingPanelLayout {
    public var initialPosition: FloatingPanelPosition {
        return .tip
    }
    
    public var supportedPositions: Set<FloatingPanelPosition> {
        return [.full, .tip]
    }
    
    public func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .full: return 16.0
        case .tip: return 69.0
        default: return nil
        }
    }
    
    public func prepareLayout(surfaceView: UIView, in view: UIView) -> [NSLayoutConstraint] {
        if #available(iOS 11.0, *) {
            return [
                surfaceView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 8.0),
                surfaceView.widthAnchor.constraint(equalToConstant: 291),
            ]
        } else {
            return [
                surfaceView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8.0),
                surfaceView.widthAnchor.constraint(equalToConstant: 291),
            ]
        }
    }
    
    public func backdropAlphaFor(position: FloatingPanelPosition) -> CGFloat {
        return 0.0
    }
}


// MARK: Custom Button Cell
class ButtonCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var button: UIButton!
}


