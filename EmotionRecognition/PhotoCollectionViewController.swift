//
//  PhotoCollectionViewController.swift
//  EmotionRecognition
//
//  Created by Eno Reyes on 6/16/19.
//  Copyright © 2019 Eno Reyes. All rights reserved.
//

import UIKit
import Vision

class PhotoCollectionViewController: UIViewController, UICollectionViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var capturedFrames: [CGImage] = []
    var analyzedFrames: [Bool] = []
    var analyzed = false
    let CONFIDENCE_THRESHOLD = 0.8 as Float
    var counter = 0
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        collectionView.dataSource = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func analysisPressed(_ sender: Any) {
        
        for image in capturedFrames {
            analyzedFrames.append(false)
            analyzePhoto(image: image)
        }
        
        analyzed = true
        
    }
    
    func analyzePhoto(image: CGImage) {
        
        let faceLandmarksRequest = VNDetectFaceLandmarksRequest(completionHandler: self.handleFaceFeatures)
        let requestHandler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try requestHandler.perform([faceLandmarksRequest])
        } catch {
            print(error)
        }
        
    }
    
    func handleFaceFeatures(request: VNRequest, errror: Error?) {
        guard let observations = request.results as? [VNFaceObservation] else {
            fatalError("unexpected result type!")
        }
        
        DispatchQueue.main.async {
            for face in observations {
                if (face.confidence > self.CONFIDENCE_THRESHOLD) {
                    
                    self.analyzedFrames[self.counter] = true
                    self.collectionView.reloadData()
                    print("Face detected on: \(self.counter)")
                    
                } else {
                    
                    self.analyzedFrames.append(false)
                    
                }
            }
            
            self.counter += 1
        }
    }
    
    @IBAction func clearTablePressed(_ sender: Any) {
        
        capturedFrames.removeAll()
        analyzedFrames.removeAll()
        counter = 0
        analyzed = false
        collectionView.reloadData()
        
    }
}

extension PhotoCollectionViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return capturedFrames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCollectionID", for: indexPath as IndexPath) as! PhotoCollectionViewCell
        
        if (analyzed) {
            
            if (analyzedFrames[indexPath.row]) {
                cell.backgroundColor = UIColor.green
            } else {
                cell.backgroundColor = UIColor.red
            }
            
            cell.imageView.image = UIImage(cgImage: capturedFrames[indexPath.row])
            
        } else {
            cell.imageView.image = UIImage(cgImage: capturedFrames[indexPath.item])
        }
        
        
        
        return cell
    }
    
    
    
}
