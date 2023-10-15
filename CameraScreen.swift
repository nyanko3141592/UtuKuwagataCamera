import AVFoundation
import CoreImage.CIFilterBuiltins
import Photos
import SwiftUI

struct CameraScreen: View {
    var blendImage: UIImage
    @State private var dragOffset: CGSize = .zero
    @State private var zoomScale: CGFloat = 1.0
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    @StateObject private var cameraProvider: CameraProvider
    
    init(blendImage: UIImage) {
        self.blendImage = blendImage
        _cameraProvider = StateObject(wrappedValue: CameraProvider(blendImage: blendImage))
    }
    
    var body: some View {
        let dragGesture = DragGesture()
            .onChanged { value in
                dragOffset = value.translation
                cameraProvider.updateZoomAndOffset(zoom: zoomScale * gestureZoomScale, offset: dragOffset)
            }
            
               
        let pinchGesture = MagnificationGesture()
            .updating($gestureZoomScale) { value, state, _ in
                state = value
            }
            .onEnded { value in
                zoomScale *= value
            }
        let combinedGesture = dragGesture.simultaneously(with: pinchGesture)
               
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack {
                if let cameraImg = cameraProvider.cameraImage(for: zoomScale * gestureZoomScale, offset: dragOffset) {
                    Image(uiImage: cameraImg)
                        .resizable()
                        .scaledToFit()
                        .gesture(combinedGesture)
                }

                
                Button(action: {
                    cameraProvider.saveImageToPhotosAlbum()
                }) {
                    ZStack {
                        // 外側の円
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 5)
                            .background(Circle().fill(Color.clear))
                            .frame(width: 80, height: 80)
                                    
                        // 中心の円
                        Circle()
                            .fill(Color.white)
                            .frame(width: 65, height: 65)
                    }
                }
            }
            .onAppear(perform: cameraProvider.startSession)
            .onDisappear(perform: cameraProvider.endSession)
        }
    }
}

class CameraProvider: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var cameraImage: UIImage?
    
    private var currentZoom: CGFloat = 1.0
    private var currentOffset: CGSize = .zero
    private let captureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "CameraQueue")
    private let blendImage: UIImage
    private var currentCIImage: CIImage?
    
    init(blendImage: UIImage) {
        self.blendImage = blendImage
        super.init()
        setupCaptureSession()
    }
    
    func updateZoomAndOffset(zoom: CGFloat, offset: CGSize) {
        self.currentZoom = zoom
        self.currentOffset = offset
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
    
    func blendImages(ciImage: CIImage, zoom: CGFloat, offset: CGSize) -> UIImage? {
        let selectedCIImage = CIImage(image: blendImage)!
        var backgroundImage = ciImage
        backgroundImage = backgroundImage.transformed(by: CGAffineTransform(rotationAngle: -(.pi / 2)))
        
        var blendImage = selectedCIImage
        blendImage = blendImage.transformed(by: CGAffineTransform(scaleX: backgroundImage.extent.width / blendImage.extent.width, y: backgroundImage.extent.width / blendImage.extent.width))
        blendImage = blendImage.transformed(by: CGAffineTransform(scaleX: zoom, y: zoom))
        if blendImage.extent.height > ciImage.extent.height {
            blendImage = blendImage.transformed(by: CGAffineTransform(scaleX: backgroundImage.extent.height / blendImage.extent.height, y: backgroundImage.extent.height / blendImage.extent.height))
        }
        // Apply the drag offset
        blendImage = blendImage.transformed(by: CGAffineTransform(translationX: offset.width, y: -offset.height))
        blendImage = blendImage.transformed(by: CGAffineTransform(translationX: 0, y: -backgroundImage.extent.height))

        let composeFilter = CIFilter(name: "CISourceOverCompositing")
        composeFilter?.setValue(blendImage, forKey: kCIInputImageKey)
        composeFilter?.setValue(backgroundImage, forKey: kCIInputBackgroundImageKey)
        
        guard let outputCIImage = composeFilter?.outputImage else { return nil }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    func cameraImage(for zoom: CGFloat, offset: CGSize) -> UIImage? {
        guard let ciImage = self.currentCIImage else { return nil }
        return blendImages(ciImage: ciImage, zoom: zoom, offset: offset)
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        self.currentCIImage = CIImage(cvPixelBuffer: pixelBuffer)
        if let blendedImage = blendImages(ciImage: self.currentCIImage!, zoom: currentZoom, offset: currentOffset) {
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
        }) { _, error in
            if let error = error {
                print("Error saving photo: \(error.localizedDescription)")
            } else {
                print("Successfully saved photo.")
            }
        }
    }
}

#Preview{
        CameraScreen(blendImage: UIImage(named: "defaultImage")!)
}
