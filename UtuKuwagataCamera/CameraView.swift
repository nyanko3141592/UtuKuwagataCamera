//
//  SwiftUIView.swift
//  UtuKuwagataCamera
//
//  Created by 高橋直希 on 2023/10/15.
//

import SwiftUI
import UIKit

// SwiftUIとUIKitをブリッジするカスタムビューを定義
struct CameraView: UIViewControllerRepresentable {
    
    // 撮影した画像を保存するためのBindableなUIImage
    @Binding var image: UIImage?
    
    // カメラ上にオーバーレイする画像のBindableなUIImage
    @Binding var selectedImage: UIImage?
    
    // ImagePickerが表示されているかどうかを制御するBindableなBool
    @Binding var isImagePickerDisplayed: Bool

    // CoordinatorはUIImagePickerControllerのデリゲートとして機能するクラス
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        // 画像が選択または撮影されたときに呼ばれるデリゲートメソッド
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let takenImage = info[.originalImage] as? UIImage {
                parent.image = takenImage
                
                // 撮影した画像をカメラロールに保存
                UIImageWriteToSavedPhotosAlbum(takenImage, nil, nil, nil)
            }

            parent.isImagePickerDisplayed = false
        }

        // ImagePickerがキャンセルされたときに呼ばれるデリゲートメソッド
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isImagePickerDisplayed = false
        }
    }

    // SwiftUIからCoordinatorを作成するためのメソッド
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // SwiftUIから初めてUIViewControllerが要求されるときに呼ばれるメソッド
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraOverlayView = UIImageView(image: selectedImage?.withAlpha(0.5))
        return picker
    }

    // SwiftUIがUIViewControllerを更新する必要があるときに呼ばれるメソッド
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        uiViewController.cameraOverlayView = UIImageView(image: selectedImage?.withAlpha(0.5))
    }
}

// UIImageを拡張して透明度を調整するメソッドを追加
extension UIImage {
    func withAlpha(_ alpha: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: .zero, blendMode: .normal, alpha: alpha)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}
