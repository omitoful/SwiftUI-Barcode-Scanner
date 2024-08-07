//
//  ScannerVC.swift
//  BarcodeScanner
//
//  Created by 陳冠甫 on 2024/8/7.
//

import UIKit
import AVFoundation

enum CameraError: String {
    case InvalidDeviceInput     = "Something is wrong with the camera. We are unable to capture the input."
    case InvalidScannedValue    = "The value scanned is not valid. This app scans EAN-8 and EAN-13."
}

protocol ScannerVCDelegate: AnyObject {
    func didFind(barcode: String)
    func didSurface(_ error: CameraError)
}

final class ScannerVC: UIViewController {
    let captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    weak var delegate: ScannerVCDelegate?
    
    init(delegate: ScannerVCDelegate) {
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let previewLayer = previewLayer else {
            delegate?.didSurface(.InvalidDeviceInput)
            return
        }
        previewLayer.frame = view.layer.bounds
    }
    
    func setupCaptureSession() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            delegate?.didSurface(.InvalidDeviceInput)
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            try videoInput = AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            delegate?.didSurface(.InvalidDeviceInput)
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            delegate?.didSurface(.InvalidDeviceInput)
            return
        }
        
        let metaDataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metaDataOutput) {
            captureSession.addOutput(metaDataOutput)
            metaDataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metaDataOutput.metadataObjectTypes = [.ean8, .ean13]
        } else {
            delegate?.didSurface(.InvalidDeviceInput)
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer!.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer!)
        
        captureSession.startRunning()
    }
}

extension ScannerVC: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let object = metadataObjects.first else {
            delegate?.didSurface(.InvalidScannedValue)
            return
        }
        guard let machineReadableObject = object as? AVMetadataMachineReadableCodeObject else {
            delegate?.didSurface(.InvalidScannedValue)
            return
        }
        guard let barcode = machineReadableObject.stringValue else {
            delegate?.didSurface(.InvalidScannedValue)
            return
        }
        
        captureSession.stopRunning()
        delegate?.didFind(barcode: barcode)
    }
}
