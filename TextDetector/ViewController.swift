//
//  ViewController.swift
//  TextDetector
//
//  Created by kyumd on 2017/8/17.
//  Copyright © 2017年 kyumd. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet var myView: UIView!
    
    var videoFilter: CoreImageVideoFilter?
    var detector: CIDetector?
    var textImage: CIImage?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Create the video filter
        videoFilter = CoreImageVideoFilter(superview: myView, applyFilterCallback: nil)
        
        if let videoFilter = videoFilter {
            videoFilter.stopFiltering()
            detector = prepareTextDetector()
            
            videoFilter.applyFilter = { image in
                let (resultImage, resultImage2)  = self.performTextDetection(image)
                self.textImage = resultImage2
                return resultImage
            }
            videoFilter.startFiltering()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func clickOKButton(sender: UIButton) {
        if let img = self.textImage {
            SVProgressHUD.show()
            SVProgressHUD.setDefaultMaskType(.black)
            
            let vc: ShowViewController = ShowViewController(nibName: "ShowViewController",bundle:nil)
            let globalQueue = DispatchQueue.global()
            
            globalQueue.async {
                let context:CIContext = CIContext.init(options: nil)
                let cgImage:CGImage = context.createCGImage(img, from: img.extent)!
                vc.image = self.imageRotatedByDegrees(oldImage: UIImage.init(cgImage: cgImage), deg: 90)
                
                DispatchQueue.main.async {
                    self.present(vc, animated: true, completion: nil)
                    SVProgressHUD.dismiss()
                }
            }
        }
    }
    
    
    
    func imageRotatedByDegrees(oldImage: UIImage, deg degrees: CGFloat) -> UIImage {
        //Calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox: UIView = UIView(frame: CGRect(x: 0, y: 0, width: oldImage.size.width, height: oldImage.size.height))
        let t: CGAffineTransform = CGAffineTransform(rotationAngle: degrees * CGFloat.pi / 180)
        rotatedViewBox.transform = t
        let rotatedSize: CGSize = rotatedViewBox.frame.size
        //Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap: CGContext = UIGraphicsGetCurrentContext()!
        //Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        //Rotate the image context
        bitmap.rotate(by: (degrees * CGFloat.pi / 180))
        //Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: 1.0, y: -1.0)
        bitmap.draw(oldImage.cgImage!, in: CGRect(x: -oldImage.size.width / 2, y: -oldImage.size.height / 2, width: oldImage.size.width, height: oldImage.size.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    
    
    //MARK: Utility methods
//    func performRectangleDetection(_ image: CIImage) -> CIImage? {
//        var resultImage: CIImage?
//        if let detector = detector {
//            // Get the detections
//            let features = detector.features(in: image)
//            for feature in features as! [CIRectangleFeature] {
//                resultImage = drawHighlightOverlayForPoints(image, topLeft: feature.topLeft, topRight: feature.topRight,
//                                                            bottomLeft: feature.bottomLeft, bottomRight: feature.bottomRight)
//            }
//        }
//        return resultImage
//    }
    
    func performTextDetection(_ image: CIImage) -> (CIImage?, CIImage?) {
        var resultImage: CIImage?
        var resultImage2: CIImage?
        if let detector = detector {
            // Get the detections
            let imageOptions =  NSDictionary(object: NSNumber(value: 5) as NSNumber, forKey: CIDetectorImageOrientation as NSString)
            let features = detector.features(in: image, options: imageOptions as? [String : AnyObject])
            
            for feature in features as! [CITextFeature] {
                resultImage = drawHighlightOverlayForPoints(image, topLeft: feature.topLeft, topRight: feature.topRight,
                                                            bottomLeft: feature.bottomLeft, bottomRight: feature.bottomRight)
                
                
                resultImage2 = self.cropTextRectangleForPoints(image: image, topLeft: feature.topLeft, topRight: feature.topRight,
                                                               bottomLeft: feature.bottomLeft, bottomRight: feature.bottomRight)
            }
        }
        return (resultImage, resultImage2)
    }
    
    
//    func prepareRectangleDetector() -> CIDetector {
//        let options: [String: Any] = [CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorAspectRatio: 1.0]
//        return CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: options)!
//    }
    
    func prepareTextDetector() -> CIDetector {
        let options: [String: Any] = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        return CIDetector(ofType: CIDetectorTypeText, context: nil, options: options)!
    }
    
    func drawHighlightOverlayForPoints(_ image: CIImage, topLeft: CGPoint, topRight: CGPoint,
                                       bottomLeft: CGPoint, bottomRight: CGPoint) -> CIImage {
        var overlay = CIImage(color: CIColor(red: 1.0, green: 0, blue: 0, alpha: 0.5))
        overlay = overlay.cropping(to: image.extent)
        overlay = overlay.applyingFilter("CIPerspectiveTransformWithExtent",
                                         withInputParameters: [
                                            "inputExtent": CIVector(cgRect: image.extent),
                                            "inputTopLeft": CIVector(cgPoint: topLeft),
                                            "inputTopRight": CIVector(cgPoint: topRight),
                                            "inputBottomLeft": CIVector(cgPoint: bottomLeft),
                                            "inputBottomRight": CIVector(cgPoint: bottomRight)
            ])
        return overlay.compositingOverImage(image)
    }
    
    func cropTextRectangleForPoints(image: CIImage, topLeft: CGPoint, topRight: CGPoint,
                                    bottomLeft: CGPoint, bottomRight: CGPoint) -> CIImage {
        
        var textRectangle: CIImage
        textRectangle = image.applyingFilter(
            "CIPerspectiveTransformWithExtent",
            withInputParameters: [
                "inputExtent": CIVector(cgRect: image.extent),
                "inputTopLeft": CIVector(cgPoint: topLeft),
                "inputTopRight": CIVector(cgPoint: topRight),
                "inputBottomLeft": CIVector(cgPoint: bottomLeft),
                "inputBottomRight": CIVector(cgPoint: bottomRight)])
        textRectangle = image.cropping(to: textRectangle.extent)
        
        return textRectangle
    }
}

