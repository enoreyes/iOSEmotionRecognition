//
//  FrameExtractor.swift
//  EmotionRecognition
//
//  Created by Eno Reyes on 6/16/19.
//  Copyright © 2019 Eno Reyes. All rights reserved.
//

import AVFoundation
import UIKit

protocol FrameExtractorDelegate: class {
    func captured(image: CGImage)
}

class FrameExtractor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // captureSession represent the primary AVCaptureSession
    private let captureSession = AVCaptureSession()
    
    // SessionQueue is a serial queue used to handle work related to this
    // session asynchronously.
    private let sessionQueue = DispatchQueue(label: "session queue")
    
    // permissionGranted is set to true if app has been granted camera access.
    private var permissionGranted = false;
    
    // Determines which camera is being accessed
    private var position = AVCaptureDevice.Position.front
    
    // Determines the quality of video captured.
    private let quality = AVCaptureSession.Preset.medium
    
    // Determines if the session is paused
    private var isPaused = false
    
    // Weak attributed delegate to avoid a retain cycle
    weak var delegate: FrameExtractorDelegate?
    
    private let CAPTURE_FRAMES_PER_SECOND = 20
    
    // Context for image processing
    let context = CIContext()

    override init() {
        super.init()
        checkPermission()
        sessionQueue.async { [unowned self] in
            self.configureSession()
            self.captureSession.startRunning()
        }
    }

    // Checks for permission to access AVCaptureDevice
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
           
        // The user has explicitly granted permission for media capture
        case .authorized:
            permissionGranted = true;
            break
            
        // The user has not yet granted or denied permission
        case .notDetermined:
            requestPermission()
            break
            
        // The user is not allowed to access media capture devices
        case .restricted:
            print("Restricted")
            break
         
        // The user has explicitly denied permission for media capture
        case .denied:
            print("Denied")
            break
            
        // Default case for unknown permission states
        @unknown default:
            print("Default")
            permissionGranted = false;
            break
        }
    }
    
    // Asynchronously requests permission for use of AVCaptureDevice
    private func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }
    
    // Configures the AVCaptureSession
    private func configureSession() {
        
        // Capturing permissions
        guard permissionGranted else { return }
        captureSession.sessionPreset = quality
        
        // Configuring capture device
        guard let captureDevice = selectCaptureDevice() else {
            print ("cannot capture")
            return
        }
        
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            print("Captured device cannot captured input")
            return
        }
        
        guard captureSession.canAddInput(captureDeviceInput) else { return }
        captureSession.addInput(captureDeviceInput)
        
        // Grabbing output frames
        let videoOutput = AVCaptureVideoDataOutput()
        
        // Set FrameExtractor as the SampleBufferDelegate
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer"))

        // Add video output to the session
        guard captureSession.canAddOutput(videoOutput) else { return }
        captureSession.addOutput(videoOutput)
        
        // Orient the video output properly
        guard let connection = videoOutput.connection(with: AVFoundation.AVMediaType.video) else { return }
        guard connection.isVideoOrientationSupported else { return }
        guard connection.isVideoMirroringSupported else { return }
        connection.videoOrientation = .portrait
        connection.isVideoMirrored = position == .front
    }
    
    // Function that outputs the captureOutput of the AVCaptureSession
    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    
        if (!isPaused) {
            guard let cgImage = self.imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
            
            DispatchQueue.main.async { [unowned self] in
                self.delegate?.captured(image: cgImage)
            }
        }
    }
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CGImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return cgImage
    }
    
    func selectCaptureDevice() -> AVCaptureDevice? {
        
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes:
            [.builtInDualCamera, .builtInWideAngleCamera],
                                                                mediaType: .video, position: self.position)
        
        let devices = discoverySession.devices
        guard !devices.isEmpty else { fatalError("Missing capture devices.")}
        
        return devices.first(where: { device in device.position == position })!
    }
    
    func suspendFrameSelection() {
        isPaused = true
    }
    
    func resumeFrameSelection() {
        isPaused = false
    }

}


