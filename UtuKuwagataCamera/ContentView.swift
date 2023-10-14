import AVFoundation
import PhotosUI
import SwiftUI

struct TopScreen: View {
    @State private var isImagePickerDisplayed = false
    @State private var selectedImage: UIImage? = UIImage(named: "defaultImage")
    @State private var navigateToCamera = false
    
    var body: some View {
        let bounds = UIScreen.main.bounds
        let width = Int(bounds.width)
        let height = Int(bounds.height)
        NavigationView {
            VStack(spacing: 5) {
                Text("鬱クワガタカメラ").font(.title).padding()
                Group {
                    Text("使い方").font(.title2)
                    Text("1. 自分の鬱クワガタを撮影")
                    Text("2. 写真アプリでクワガタを長押しして被写体を選択")
                    Text("3. 共有から写真に保存")
                    Button("4. あなたのクワガタをカメラロールから選択") {
                        isImagePickerDisplayed.toggle()
                    }.imagePicker(isPresented: $isImagePickerDisplayed, image: $selectedImage)
                }.frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                Group {
                    Text("現在のクワガタ").font(.headline).padding()
                    if let image = selectedImage {
                        Button(action: {
                            isImagePickerDisplayed.toggle()
                        }) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: CGFloat(width) / 2, height: CGFloat(width) / 2)
                                .background(Color.blue)
                        }.imagePicker(isPresented: $isImagePickerDisplayed, image: $selectedImage)
                    } else {
                        Text("No Image Selected")
                    }
                }
                
                Spacer()
                if selectedImage != nil {
                    NavigationLink(destination: CameraScreen(blendImage: selectedImage!), isActive: $navigateToCamera) {
                        Button(action: {
                            navigateToCamera = true
                        }) {
                            Text("鬱クワガタを撮影")
                                .bold()
                                .padding()
                                .frame(height: 50)
                                .foregroundColor(Color.white)
                                .background(Color.blue)
                                .cornerRadius(25)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// Custom modifier for ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

extension View {
    func imagePicker(isPresented: Binding<Bool>, image: Binding<UIImage?>) -> some View {
        modifier(ImagePickerModifier(isPresented: isPresented, image: image))
    }
}

struct ImagePickerModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var image: UIImage?
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented, content: {
                ImagePicker(isPresented: $isPresented, image: $image)
            })
    }
}

#Preview {
    TopScreen()
}
