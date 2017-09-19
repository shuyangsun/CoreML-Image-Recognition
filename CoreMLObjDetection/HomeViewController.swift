//
//  ViewController.swift
//  CoreMLObjDetection
//
//  Created by Shuyang Sun on 9/15/17.
//  Copyright © 2017 Shuyang Sun. All rights reserved.
//

import UIKit
import AVKit
import Vision
import SnapKit

internal class HomeViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    private var captureSession:AVCaptureSession!
    private var previewLayer:AVCaptureVideoPreviewLayer!
    private var dataOutput:AVCaptureVideoDataOutput!
    private let label = UILabel()

    // MARK: VC Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black

        setupCaptureSession()
        setupDataOutput()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupPreviewLayer()
        layoutPreviewLayer()
        setupLabel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if previewLayer != nil {
            layoutPreviewLayer()
        }
    }

    // MARK: Setup

    private func setupLabel() {
        view.addSubview(label)
        label.textColor = UIColor.white
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.backgroundColor = UIColor(white: 0, alpha: 0.75)
        label.textAlignment = .center
        label.snp.makeConstraints { (make) in
            make.bottom.equalTo(view)
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.height.equalTo(75.0)
        }
    }

    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        guard let cameraDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let cameraInput = try? AVCaptureDeviceInput(device: cameraDevice) else { return }
        captureSession.addInput(cameraInput)
        captureSession.startRunning()
    }

    private func setupDataOutput() {
        dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "Video Data Output"))
        captureSession.addOutput(dataOutput)
    }

    private func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.cornerRadius = 10.0
    }

    private func layoutPreviewLayer() {
        previewLayer.frame = view.frame
        if view.frame.width > view.frame.height {
            let rotation = CATransform3DMakeRotation(CGFloat.pi * -0.5, 0, 0, 1)
            previewLayer.transform = rotation
        } else {
            previewLayer.transform = CATransform3DIdentity
        }
    }

    // MARK: Video Data Output Delegate

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        guard let model = try? VNCoreMLModel(for: VGG16().model) else { return }
        let req = VNCoreMLRequest(model: model) { (request:VNRequest?, err:Error?) in
            guard let results = request?.results as? [VNClassificationObservation] else { return }
            var resultStr = ""
            for res in results {
                resultStr.append("\(res.identifier): \(round(res.confidence * 1000.0)/10.0)%\n")
            }
            DispatchQueue.main.async {
                self.label.text = resultStr
            }
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([req])
    }
}

