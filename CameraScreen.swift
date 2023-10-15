//
//  CameraView.swift
//  UtuKuwagataCamera
//
//  Created by 高橋直希 on 2023/10/15.
//

import SwiftUI
import AVFoundation
import CoreImage.CIFilterBuiltins
import Photos


struct CameraScreen: View {
    var blendImage: UIImage
    @StateObject private var cameraProvider: CameraProvider
    
    init(blendImage: UIImage) {
        self.blendImage = blendImage
        _cameraProvider = StateObject(wrappedValue: CameraProvider(blendImage: blendImage))
    }
    
    var body: some View {
        VStack {
            if let cameraImg = cameraProvider.cameraImage {
                Image(uiImage: cameraImg)
                    .resizable()
                    .scaledToFit()
            }
            
            Button(action: {
                cameraProvider.saveImageToPhotosAlbum()
            }) {
                Text("Capture")
                    .bold()
                    .padding()
                    .frame(height: 50)
                    .foregroundColor(Color.white)
                    .background(Color.blue)
                    .cornerRadius(25)
            }
        }
        .onAppear(perform: cameraProvider.startSession)
        .onDisappear(perform: cameraProvider.endSession)
    }
}


class CameraProvider: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var cameraImage: UIImage?
    
    private let captureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "CameraQueue")
    private let blendImage: UIImage
    
    init(blendImage: UIImage) {
        self.blendImage = blendImage
        super.init()
        setupCaptureSession()
    }
    
    func setupCaptureSession() {
        captureSession.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Unable to get back camera.")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            videoDataOutput.setSampleBufferDelegate(self, queue: queue)
            if captureSession.canAddOutput(videoDataOutput) {
                captureSession.addOutput(videoDataOutput)
            }
            
        } catch {
            print(error)
        }
    }
    
    func startSession() {
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }
    
    func endSession() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    
    func blendImages(ciImage: CIImage) -> UIImage? {
        let selectedCIImage = CIImage(image: blendImage)!

        // 90 degree rotation transformation
        var backgroundImage = ciImage
        backgroundImage = backgroundImage.transformed(by: CGAffineTransform(rotationAngle: -(.pi / 2)))
        var blendImage = selectedCIImage
        blendImage = blendImage.transformed(by: CGAffineTransform(scaleX: backgroundImage.extent.width / blendImage.extent.width, y: backgroundImage.extent.width / blendImage.extent.width))
        if blendImage.extent.height > ciImage.extent.height{
            blendImage = blendImage.transformed(by: CGAffineTransform(scaleX: backgroundImage.extent.height / blendImage.extent.height, y: backgroundImage.extent.height / blendImage.extent.height))
        }
        blendImage = blendImage.transformed(by:  CGAffineTransform(translationX: 0, y: -backgroundImage.extent.height))

        // Using the CISourceOverCompositing filter to blend images
        let composeFilter = CIFilter(name: "CISourceOverCompositing")
        composeFilter?.setValue(blendImage, forKey: kCIInputImageKey)
        composeFilter?.setValue(backgroundImage, forKey: kCIInputBackgroundImageKey)

        // Fetching the output after passing through the filter
        guard let outputCIImage = composeFilter?.outputImage else { return nil }
        
        // Convert CIImage to UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let cameraImage = CIImage(cvPixelBuffer: pixelBuffer)
        if let blendedImage = blendImages(ciImage: cameraImage) {
            DispatchQueue.main.async {
                self.cameraImage = blendedImage
            }
        }
    }
}

extension CameraProvider {
    func saveImageToPhotosAlbum() {
        guard let image = cameraImage else {
            print("No image available for saving.")
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { isSuccess, error in
            if let error = error {
                print("Error saving photo: \(error.localizedDescription)")
            } else {
                print("Successfully saved photo.")
            }
        }
    }
}
