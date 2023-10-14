//
//  ContentView.swift
//  UtuKuwagataCamera
//
//  Created by 高橋直希 on 2023/10/14.
//
import SwiftUI

struct ContentView: View {
    @State private var image: UIImage?
    @State private var selectedImage: UIImage?
    @State private var isImagePickerDisplayed: Bool = false
    @State private var isCameraDisplayed: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
            } else {
                Text("画像が選択されていません")
            }

            Button("カメラロールから画像を選択") {
                isImagePickerDisplayed = true
            }

            Button("カメラを開く") {
                isCameraDisplayed = true
            }
        }
        .sheet(isPresented: $isImagePickerDisplayed) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $isCameraDisplayed) {
            CameraView(image: $image, selectedImage: $selectedImage, isImagePickerDisplayed: $isCameraDisplayed)
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
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
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
    }
}
