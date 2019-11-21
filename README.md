# APD Articles Reference App

## Introduction
The reason for this project is to solve, or minimise, the pain point faced by students and researchers; it is difficult to create citations. With that problem in mind, my supervisor wanted an application that can generate citations from the Digital Object Identifier (DOI) number of research papers.
At first, the objective of the app was to be able to retrieve one citation from the one DOI number that was captured from the Optical Character Recognition (OCR feature). However, wanting to take the project a step further, several new objectives and features were added. 
I added several more objectives that I wanted to achieve with the application. The corresponding features will be explained below:
#### Objective: Get citations 
APD Articles Reference App is an Android and iOS mobile application that can generate citations from Digital Object Identifier (DOI) numbers or titles. 
APD Articles Reference App can generate multiple citations at once with the use of DOIs. The capturing of the DOI/title/keywords/sentences can be done with the use of Optical Character Recognition (OCR). The OCR will be able to capture just the DOI number even if the image contains a lot of other text. If the image contains multiple DOIs, the OCR will be able to capture all of it.
#### Objective: Ease of obtaining information 
APD Articles Reference App is also able to give research article summaries and extract keywords from the web page of the article.
The app is also able to retrieve related articles from just the DOI. With OCR, the DOI will be captured from the image and the references of that paper will be shown. The user can then pick any of the retrieved articles to browse it.
#### Objective: Provide educational value and tools 
Another feature is a review paper writer. When the user inputs a few valid DOI numbers, the app will be able to get a summary from each of the research article websites to generate a final summary. This function will be especially useful for student who must write papers on certain articles.  
The last feature is an abstract translator which has the ability to translate a text to and from 16 different languages. The abstract can be captured with OCR.

#### Some use cases are:
1. Researchers who often encounter DOI numbers and want to get a quick summary of the research article. 
2. Researchers want to get citations from a whole list of DOI numbers - they can simply take a picture of that list and a list of citations will be generated for the user. 
3. Students are in a hurry and don't have the patience to read a long text to make sure if it's relevant to their project - they can use the article summarizer to quickly see if it's what they want. Researchers can also do the same. 
4. Foreign students can translate an abstract of text from English (or any Latin-based language) to their native language using OCR.



## Dependencies (Android), CocaPods (iOS), libraries, and APIs:
- AndroidSlidingUpPanel 
- JSoup 
- Apache OpenNLP 
- JGraphT 
- Firebase ML Kit 
- Yandex.Translate API 
- Crossref REST API and Citation Formatting Service 
- Reductio (Uses the TextRank algorithm)
- SwiftSoup 
- SwiftyJSON
- FloatingPanel
- AlignedCollectionViewFlowLayout
- RSLoadingView
- PaperOnboarding
- CropViewController 
- MXParallaxHeader
- SwiftEntryKit
- EzPopup

#### Article summarizer works on research article websites like: 
- AAAS ScienceMag (https://science.sciencemag.org/) 
- American Society for Microbiology (https://www.asm.org) 
- arXiv (https://arxiv.org/)
- Aspet (https://www.aspet.org/)
- Bioscience Reports (http://www.bioscirep.org/)
- Cell (https://www.cell.com/cell) 
- BMC (https://www.biomedcentral.com/) 
- DOAJ (https://doaj.org/) 
- eLIFE (https://elifesciences.org/) 
- Elsevier Science Direct (https://www.sciencedirect.com/)
- Frontiers (https://www.frontiersin.org/)
- JBC Journal of Biological Chemistry (http://www.jbc.org/) 
- JNeurosci (https://www.jneurosci.org/)
- Life Sciences Education (https://www.lifescied.org/) 
- MDPI (https://www.mdpi.com/) 
- MIT Technology Review (https://www.technologyreview.com/) 
- MBoC Molecular Biology of the Cell (https://www.molbiolcell.org/)
- Nature (https://www.nature.com/) 
- Oxford Academic Journals (https://academic.oup.com/journals)
- Paperity (https://paperity.org/) 
- PLOS (https://www.plos.org/) 
- PNAS (https://www.pnas.org/) 
- Project Muse (https://muse.jhu.edu/)
- PubMed (https://www.ncbi.nlm.nih.gov/pubmed)
- ResearchGate (https://www.researchgate.net/press) 
- SAGE Journals (https://journals.sagepub.com/)
- ScienceOpen (https://www.scienceopen.com/)
- Springer (https://link.springer.com/)
- SSRN (https://www.ssrn.com/index.cfm/en/) 
- Taylor & Francis Online (https://www.tandfonline.com/)
- The New England Journal of Medicine (https://www.nejm.org/)
- Towards Data Science (https://towardsdatascience.com/) 
- Wiley Online Library (https://onlinelibrary.wiley.com/)
