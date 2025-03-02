//
//  ScannerView.swift
//  BarcodeScanner
//
//  Created by 陳冠甫 on 2024/8/7.
//

import SwiftUI

struct ScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String
    @Binding var alertItem: AlertItem?
    
    func makeUIViewController(context: Context) -> ScannerVC {
        ScannerVC(delegate: context.coordinator)
    }
    
    func updateUIViewController(_ uiViewController: ScannerVC, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(scannerView: self)
    }
    
    final class Coordinator: NSObject, ScannerVCDelegate {
        private let scannerView: ScannerView
        
        init(scannerView: ScannerView) {
            self.scannerView = scannerView
        }
        
        func didFind(barcode: String) {
            scannerView.scannedCode = barcode
        }
        
        func didSurface(_ error: CameraError) {
            switch error {
            case .InvalidDeviceInput:
                scannerView.alertItem = AlertContext.InvalidDeviceInput
            case .InvalidScannedValue:
                scannerView.alertItem = AlertContext.InvalidScannedValue
            }
        }
    }
}
