//
//  SwiftUIView.swift
//  UtuKuwagataCamera
//
//  Created by 高橋直希 on 2023/10/15.
//
import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var selectedImage: UIImage?
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let takenImage = info[.originalImage] as? UIImage {
                parent.image = takenImage
                
                if let selectedImage = parent.selectedImage {
                    parent.image = takenImage.composed(with: selectedImage)
                }
                
                UIImageWriteToSavedPhotosAlbum(parent.image!, nil, nil, nil)
            }

            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        
        if let selectedImage = selectedImage {
            let overlayImageView = UIImageView(image: selectedImage)
            overlayImageView.contentMode = .scaleAspectFit
            overlayImageView.alpha = 0.5
            
            let screenBounds = UIScreen.main.bounds
            let overlayBounds = CGRect(x: 0, y: (screenBounds.height - screenBounds.width) / 2, width: screenBounds.width, height: screenBounds.width)
            overlayImageView.frame = overlayBounds
            
            picker.cameraOverlayView = overlayImageView
        }
        
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        if let selectedImage = selectedImage {
            let overlayImageView = UIImageView(image: selectedImage)
            overlayImageView.contentMode = .scaleAspectFit
            overlayImageView.alpha = 0.5
            
            let screenBounds = UIScreen.main.bounds
            let overlayBounds = CGRect(x: 0, y: (screenBounds.height - screenBounds.width) / 2, width: screenBounds.width, height: screenBounds.width)
            overlayImageView.frame = overlayBounds
            
            uiViewController.cameraOverlayView = overlayImageView
        }
    }
}


class CameraViewCoordinator: NSObject, AVCapturePhotoCaptureDelegate {
    var parent: CameraView
    var output = AVCapturePhotoOutput()

    init(_ parent: CameraView) {
        self.parent = parent
        super.init()
        if parent.captureSession.canAddOutput(output) {
            parent.captureSession.addOutput(output)
        }
    }

    @objc func takePhoto() {
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(), let uiImage = UIImage(data: imageData) {
            let finalImage = uiImage.composed(with: parent.selectedImage)
            if let finalImageData = finalImage?.jpegData(compressionQuality: 0.8) {
                UIImageWriteToSavedPhotosAlbum(UIImage(data: finalImageData)!, nil, nil, nil)
            }
        }
    }
}

extension UIImage {
    func composed(with overlay: UIImage?) -> UIImage? {
        guard let overlay = overlay else { return self }

        let baseImage = CIImage(image: self)
        let overlayImage = CIImage(image: overlay)

        guard let filter = CIFilter(name: "CIMinimumCompositing") else {
            return nil
        }
        filter.setValue(overlayImage, forKey: kCIInputImageKey)
        filter.setValue(baseImage, forKey: kCIInputBackgroundImageKey)

        guard let outputImage = filter.outputImage, let cgImage = CIContext().createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
