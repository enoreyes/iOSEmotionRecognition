//
//  ViewController.swift
//  EmotionRecognition
//
//  Created by Eno Reyes on 6/16/19.
//  Copyright © 2019 Eno Reyes. All rights reserved.
//

import UIKit

class FrameViewController: UIViewController, FrameExtractorDelegate {

    var frameExtractor: FrameExtractor!
    var isPaused = true
    var framesCaptured = 0
    var capturedFrames: [CGImage] = []
    
    @IBOutlet weak var imageFeed: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        frameExtractor = FrameExtractor()
        frameExtractor.delegate = self

    }
    
    func captured(image: CGImage) {
       
        framesCaptured += 1
        
        if (!isPaused) {
            imageFeed.image = UIImage(cgImage: image)
            
            if (framesCaptured % 10 == 0) {
                capturedFrames.append(image)
            }
        }

    }
    
    @IBAction func resumeFrameCapture(_ sender: Any) {
        frameExtractor.resumeFrameSelection()
        isPaused = false
    }
    
    @IBAction func pauseFrameCapture(_ sender: Any) {
        frameExtractor.suspendFrameSelection()
        isPaused = true
        print(capturedFrames.count)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is PhotoCollectionViewController
        {
            let vc = segue.destination as? PhotoCollectionViewController
            vc?.capturedFrames = self.capturedFrames
        }
    }
    
    
}

