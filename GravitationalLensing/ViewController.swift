//
//  ViewController.swift
//  GravitationalLensing
//
//  Created by Mason Bartle on 6/1/16.
//  Copyright © 2016 Mason Bartle. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    // MARK: Properties
    
    let captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    var facingCamera: AVCaptureDevice?
    
    // MARK: Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Opening the camera, according to process outlined by http://jamesonquave.com/blog/taking-control-of-the-iphone-camera-in-ios-8-with-swift-part-1/
        captureSession.sessionPreset = AVCaptureSessionPresetLow
        
        let devices = AVCaptureDevice.devices()
        
        // Loop through all capture devices
        for device in devices{
            if device.hasMediaType(AVMediaTypeVideo){
                if device.position == AVCaptureDevicePosition.Back {
                    facingCamera = device as? AVCaptureDevice
                    if facingCamera != nil {
                        print("Capture device found")
                        beginSession()
                    }
                }
            }
        }
        
        // TODO: Handle case where there is no camera
        if facingCamera == nil {
            
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Camera Initiation
    
    func beginSession() {
        do {
            try captureSession.addInput(AVCaptureDeviceInput(device: facingCamera))
        } catch {
            print ("Error in beginSession")
        }
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.view.layer.addSublayer(previewLayer!)
        previewLayer?.frame = self.view.frame
        captureSession.startRunning()
    }

}

