//
//  ContentView.swift
//  UtuKuwagataCamera
//
//  Created by 高橋直希 on 2023/10/14.
//
import SwiftUI

// 主要なビューを定義
struct ContentView: View {
    // 撮影または選択された画像を保持するためのState
    @State private var image: UIImage?
    // カメラオーバーレイとして使用する画像を保持するためのState
    @State private var selectedImage: UIImage?
    // ImagePicker表示のトグル
    @State private var isImagePickerDisplayed: Bool = false
    // CameraView表示のトグル
    @State private var isCameraDisplayed: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            // 最初に合成された画像（image）が存在するかどうかを確認
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
            }
            // 合成された画像がない場合、選択された画像を表示
            else if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
            }
            // どちらの画像も存在しない場合、テキストを表示
            else {
                Text("画像が選択されていません")
            }

            // カメラロールからの画像選択ボタン
            Button("カメラロールから画像を選択") {
                isImagePickerDisplayed = true
            }

            // カメラを起動するボタン
            Button("カメラを開く") {
                isCameraDisplayed = true
            }
        }
        // ImagePickerの表示
        .sheet(isPresented: $isImagePickerDisplayed) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
        }
        // CameraViewの表示
        .sheet(isPresented: $isCameraDisplayed) {
            CameraView(image: $image, selectedImage: $selectedImage, isImagePickerDisplayed: $isCameraDisplayed)
        }
    }
}

// カメラロールから画像を選択するためのビューを定義
struct ImagePicker: UIViewControllerRepresentable {
    // 選択された画像を保持するためのBindableなUIImage
    @Binding var image: UIImage?
    // 画像ソースのタイプ（カメラ、フォトライブラリなど）
    var sourceType: UIImagePickerController.SourceType

    // UIImagePickerControllerのデリゲートとして機能するCoordinator
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        // 画像が選択されたときに呼ばれるデリゲートメソッド
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }

            picker.dismiss(animated: true)
        }

        // ImagePickerがキャンセルされたときに呼ばれるデリゲートメソッド
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }

    // SwiftUIからCoordinatorを作成するためのメソッド
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // SwiftUIから初めてUIViewControllerが要求されるときに呼ばれるメソッド
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }

    // SwiftUIがUIViewControllerを更新する必要があるときに呼ばれるメソッド（ここでは何もしない）
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {}
}
