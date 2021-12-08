//
//  ViewController.swift
//  DocumentScanner
//
//  Created by Canry on 2021/12/8.
//

import UIKit
import Vision
import VisionKit

class ViewController: UIViewController {

    private var scanButton = ScanButton(frame: .zero)
    private var scanImageView = ScanImageView(frame: .zero)
    private var scanTextView = ScanTextView(frame: .zero, textContainer: nil)
    private var scanRequest = VNRecognizeTextRequest(completionHandler: nil)
        
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        configureOCR()
    }

        
    private func configure() {
        view.addSubview(scanImageView)
        view.addSubview(scanTextView)
        view.addSubview(scanButton)
        
        let padding: CGFloat = 16
        NSLayoutConstraint.activate([
            scanButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: padding),
            scanButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -padding),
            scanButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -padding),
            scanButton.heightAnchor.constraint(equalToConstant: 50),
            
            scanTextView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: padding),
            scanTextView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -padding),
            scanTextView.bottomAnchor.constraint(equalTo: scanButton.topAnchor, constant: -padding),
            scanTextView.heightAnchor.constraint(equalToConstant: 200),
            
            scanImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: padding),
            scanImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: padding),
            scanImageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -padding),
            scanImageView.bottomAnchor.constraint(equalTo: scanTextView.topAnchor, constant: -padding)
        ])
        
        scanButton.addTarget(self, action: #selector(scanDocument), for: .touchUpInside)
    }
        
        
    @objc private func scanDocument() {
        let scanVC = VNDocumentCameraViewController()
        scanVC.delegate = self
        present(scanVC, animated: true)
    }
        
        
    private func processImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        scanTextView.text = ""
        scanButton.isEnabled = false
            
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try requestHandler.perform([self.scanRequest])
        } catch {
            print(error)
        }
    }

        
    private func configureOCR() {
        scanRequest = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
                
            var ocrText = ""
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { return }
                    
                ocrText += topCandidate.string + "\n"
            }
                
                
            DispatchQueue.main.async {
                self.scanTextView.text = ocrText
                self.scanButton.isEnabled = true
            }
        }
            
        scanRequest.recognitionLevel = .accurate
        scanRequest.recognitionLanguages = ["zh-Hant", "en-US"]
        scanRequest.usesLanguageCorrection = true
    }
}


extension ViewController: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        guard scan.pageCount >= 1 else {
            controller.dismiss(animated: true)
            return
        }
        
        scanImageView.image = scan.imageOfPage(at: 0)
        processImage(scan.imageOfPage(at: 0))
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        //Handle properly error
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true)
    }
}
