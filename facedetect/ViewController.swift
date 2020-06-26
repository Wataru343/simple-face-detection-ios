//
//  ViewController.swift
//  facedetect
//
//  Created by mac on 2020/06/25.
//  Copyright © 2020 mac. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    var captureSession: AVCaptureSession?
    var videoDevice: AVCaptureDevice?
    var videoInput: AVCaptureDeviceInput?
    var videoDataOutput: AVCaptureVideoDataOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var rect = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        captureSession = AVCaptureSession()
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)

        videoInput = try! AVCaptureDeviceInput.init(device: videoDevice!)
        captureSession?.addInput(videoInput!)
        videoDataOutput = AVCaptureVideoDataOutput()

        videoDataOutput!.videoSettings = [kCVPixelBufferPixelFormatTypeKey : kCVPixelFormatType_32BGRA] as [String : Any]
        videoDataOutput?.alwaysDiscardsLateVideoFrames = true
        videoDataOutput?.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        captureSession!.addOutput(videoDataOutput!)

        previewLayer!.frame = self.view.bounds
        previewLayer!.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(previewLayer!)

        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession!.startRunning()
        }

        rect.backgroundColor = UIColor.clear
        rect.layer.borderColor = UIColor.white.cgColor
        rect.layer.borderWidth = 10
        self.view.addSubview(rect)
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        connection.videoOrientation = .portrait

        let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        let imageRef = context!.makeImage()

        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let image: UIImage = UIImage(cgImage: imageRef!)

        let ciimage:CIImage! = CIImage(image: image)



        let detector: CIDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options:[CIDetectorAccuracy: CIDetectorAccuracyLow])!
        let features: [CIFeature] = detector.features(in: ciimage)

        if features.count > 0 {
            for feature in features {
                let widthRatio = self.view.bounds.width / image.size.width
                let heightRatio = self.view.bounds.height / image.size.height

                let faceRect: CGRect = CGRect(x: Int((image.size.width - feature.bounds.origin.x - feature.bounds.size.width) * widthRatio),
                                              y: Int((image.size.height - feature.bounds.origin.y - feature.bounds.size.height) * heightRatio),
                                              width: Int(feature.bounds.size.width * widthRatio),
                                              height: Int(feature.bounds.size.height * heightRatio))
                self.rect.frame = faceRect
            }
        } else {
            self.rect.frame = CGRect()
        }
    }
}
