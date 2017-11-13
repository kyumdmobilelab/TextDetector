//
//  ShowViewController.swift
//  TextDetector
//
//  Created by kyumd on 2017/8/21.
//  Copyright © 2017年 kyumd. All rights reserved.
//

import UIKit
import TesseractOCR


class ShowViewController: UIViewController, G8TesseractDelegate {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var textLabel: UILabel!
    
    var image: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        textLabel.layer.borderColor = UIColor.black.cgColor
        textLabel.layer.borderWidth = 1.5
        textLabel.adjustsFontSizeToFitWidth = true
        
        if let img = image {
            self.imageView.image = img
            
            let tesseract:G8Tesseract = G8Tesseract(language:"eng+chi_tra+chi_sim");
            tesseract.delegate = self
            tesseract.image = img
            tesseract.recognize();
            
            NSLog("%@", tesseract.recognizedText);
            self.textLabel.text = tesseract.recognizedText
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func clickOKButton(sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}
