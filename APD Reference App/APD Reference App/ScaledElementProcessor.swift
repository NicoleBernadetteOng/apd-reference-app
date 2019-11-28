//
//  ScaledElementProcessor.swift
//  Citation Companion
//
//  Created by Megan Ong Kailing on 4/10/19.
//  Copyright © 2019 Nicole Bernadette Ong. All rights reserved.
//

import Foundation
import Firebase

class ScaledElementProcessor {
    let vision = Vision.vision()
    var textRecognizer: VisionTextRecognizer!
   
    init() {
        textRecognizer = vision.onDeviceTextRecognizer()
    }
    
    
    func process(in imageView: UIImageView, callback: @escaping (_ _text: String) -> Void) {
        // 1. Let the image be the image in the imageView
        // If there's no image then return and end the function
        guard let image = imageView.image else { return }
        
        // 2.
        let visionImage = VisionImage(image: image)
        
        // 3. Returns an array of text results
        textRecognizer.process(visionImage) {
            result, error in
            guard error == nil,
            let result = result,
                !result.text.isEmptyelse else {
                    callback("")
                    return
            }
            callback(result.text)
        }
        
    }
    
    
}
