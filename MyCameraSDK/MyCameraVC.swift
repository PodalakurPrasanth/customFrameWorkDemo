//
//  MyCameraVC.swift
//  MyCameraSDK
//
//  Created by Prasanth Podalakur on 15/04/19.
//  Copyright © 2019 Prasanth Podalakur. All rights reserved.
//

import UIKit
import AVFoundation
@objc public  protocol MyCameraSDKDelegate {
    func didFinishCapture(capturePhoto:UIImage?)
  @objc optional func didFinishVideoCapture(outputFileURL: URL?,isError:Error?)
    
}



 public class MyCameraVC: UIViewController,AVCaptureMetadataOutputObjectsDelegate,AVCapturePhotoCaptureDelegate {

    @IBOutlet weak var previewView: UIView!
    var delegate : MyCameraSDKDelegate!
    //MARK:-PHOTOS RELATED
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var capturePhotoOutput: AVCapturePhotoOutput?
    @IBOutlet weak var previewImageView: UIImageView!
    var zoomFactor: Float = 1.0
    //MARK:-VIDEO RELATED
    
    let movieOutput = AVCaptureMovieFileOutput()
    
    var activeInput: AVCaptureDeviceInput!
    
     var outputURL: URL!
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
        self.openCamera()
//        self.setCamPreview()
    }
    
    @IBAction private func pinchToZoom(_ pinch: UIPinchGestureRecognizer) {
        
      guard let device = AVCaptureDevice.default(for: AVMediaType.video) else {
            return
        }
        
        func minMaxZoom(_ factor: CGFloat) -> CGFloat { return min(max(factor, 1.0), device.activeFormat.videoMaxZoomFactor) }
        
        func update(scale factor: CGFloat) {
            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                device.videoZoomFactor = factor
            } catch {
                debugPrint(error)
            }
        }
        
        let newScaleFactor = minMaxZoom(pinch.scale * CGFloat(zoomFactor))
        
        switch pinch.state {
        case .began: fallthrough
        case .changed: update(scale: newScaleFactor)
        case .ended:
            zoomFactor = Float(minMaxZoom(newScaleFactor))
            update(scale: CGFloat(zoomFactor))
        default: break
        }

    }

    private  func openCamera(){
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                          for: .video, position: .back) else {//default(for: AVMediaType.video)
            let noCameraAlert = UIAlertController(title: "Camera Alert", message: "No Camera Found", preferredStyle: .alert)
            let okactoion = UIAlertAction(title: "ok", style: .default, handler: nil)
            noCameraAlert.addAction(okactoion)
            self.present(noCameraAlert, animated: true, completion: nil)
            //fatalError("No video device found")
            return
        }
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous deivce object
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Initialize the captureSession object
            captureSession = AVCaptureSession()
            captureSession?.sessionPreset = .high
        
            
            // Set the input devcie on the capture session
            captureSession?.addInput(input)
            
            // Get an instance of ACCapturePhotoOutput class
            capturePhotoOutput = AVCapturePhotoOutput()
            capturePhotoOutput?.isHighResolutionCaptureEnabled = true
            
            // Set the output on the capture session
            captureSession?.addOutput(capturePhotoOutput!)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the input device
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer!.frame = self.previewView.layer.bounds
            
            videoPreviewLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
            
            previewView.layer.addSublayer(videoPreviewLayer!)
            print("preview view :\(self.previewView.layer.frame)")
            print(videoPreviewLayer!.frame)
            captureSession?.startRunning()
            
        } catch {
            //If any error occurs, simply print it out
            print(error)
            return
        }
    }
   
    //MARK: - Custom Methods
    private func compressImage(image: UIImage) -> UIImage {
        let size = image.size
        
        let widthRatio  = 1600  / image.size.width
        let heightRatio = size.height / image.size.height
        
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        let rect = CGRect(x :0, y :0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.3)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        print("New Image width and height: \(String(describing: newImage?.size.width)) \(newImage?.size.height)")
        return newImage!
    }
    
    
    //MARK:- AVCaptureMetadataOutputObjectsDelegate,AVCapturePhotoCaptureDelegate
    
    public func photoOutput(_ captureOutput: AVCapturePhotoOutput,
                            didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?,
                            previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?,
                            resolvedSettings: AVCaptureResolvedPhotoSettings,
                            bracketSettings: AVCaptureBracketedStillImageSettings?,
                            error: Error?) {
        // Make sure we get some photo sample buffer
        guard error == nil,
            let photoSampleBuffer = photoSampleBuffer else {
                print("Error capturing photo: \(String(describing: error))")
                return
        }
        
        // Convert photo same buffer to a jpeg image data by using AVCapturePhotoOutput
        guard let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer) else {
            return
        }
        
        // Initialise an UIImage with our image data
        
        let dataProvider = CGDataProvider(data: imageData as CFData)
        let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        let capturedImage = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: UIImage.Orientation.right
        )
        if let image = capturedImage as UIImage?{

            let compressedImage =  self.compressImage(image: image)
            self.delegate.didFinishCapture(capturePhoto: image)
            print("Compressed Image size: \(compressedImage.size.width) \(compressedImage.size.height)")
            print("compressedImage.scale \(compressedImage.scale)")
            print("image captured sussessfully")
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    public func metadataOutput(_ captureOutput: AVCaptureMetadataOutput,
                               didOutput metadataObjects: [AVMetadataObject],
                               from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is contains at least one object.
        if metadataObjects.count == 0 {
            //            qrCodeFrameView?.frame = CGRect.zero
            //            messageLabel.isHidden = true
            return
        }
        
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        if metadataObj.type == AVMetadataObject.ObjectType.qr {
            if metadataObj.stringValue != nil {
            }
        }
    }
    //MARK:- capture PHOTo
    @IBAction func capture(_ sender: Any) {
        
        print ("capture btn clicked")
       /* guard let capturePhotoOutput = self.capturePhotoOutput else { return }
        
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.isAutoStillImageStabilizationEnabled = true
        photoSettings.isHighResolutionPhotoEnabled = true
        photoSettings.flashMode = .off
        
        // Call capturePhoto method by passing our photo settings and a delegate implementing AVCapturePhotoCaptureDelegate
        capturePhotoOutput.capturePhoto(with: photoSettings, delegate: self)
        //        if showImage.image != nil{
        //            self.navigationController?.popViewController(animated: true)
        //        }
       
        */
        
        
        self.startRecording()
    }

}
//MARK:- @IBDesignable extension for UIView
@IBDesignable extension UIView {
    @IBInspectable var borderColor:UIColor? {
        set {
            layer.borderColor = newValue!.cgColor
        }
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor:color)
            }
            else {
                return nil
            }
        }
    }
    
    @IBInspectable var borderWidth:CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }
    
    @IBInspectable var cornerRadius:CGFloat {
        set {
            layer.cornerRadius = newValue
            clipsToBounds = newValue > 0
        }
        get {
            return layer.cornerRadius
        }
    }
}


//MARK:- video recording

extension MyCameraVC{
    func setCamPreview(){
//        if setupSession() {
            setupPreview()
            startSession()
//        }
    }
    
    func setupPreview() {
        // Configure previewLayer
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        videoPreviewLayer?.frame = self.previewView.bounds
        videoPreviewLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.previewView.layer.addSublayer(videoPreviewLayer!)
    }
    
    //MARK:- Setup Camera
    
//    func setupSession() -> Bool {
//
//        captureSession?.sessionPreset = AVCaptureSession.Preset.high
//
//        // Setup Camera
//        let camera = AVCaptureDevice.default(for: AVMediaType.video)!
//
//        do {
//
//            let input = try AVCaptureDeviceInput(device: camera)
//
//            if (captureSession?.canAddInput(input))! {
//                captureSession?.addInput(input)
//                activeInput = input
//            }
//        } catch {
//            print("Error setting device video input: \(error)")
//            return false
//        }
//
//        // Setup Microphone
//        let microphone = AVCaptureDevice.default(for: AVMediaType.audio)!
//
//        do {
//            let micInput = try AVCaptureDeviceInput(device: microphone)
//            if (captureSession?.canAddInput(micInput))! {
//                captureSession?.addInput(micInput)
//            }
//        } catch {
//            print("Error setting device audio input: \(error)")
//            return false
//        }
//
//
//        // Movie output
//        if (captureSession?.canAddOutput(movieOutput))! {
//            captureSession?.addOutput(movieOutput)
//        }
//
//        return true
//    }
    func setupCaptureMode(_ mode: Int) {
        // Video Mode
        
    }
    //MARK:- Camera Session
    func startSession() {
        
        if !(captureSession?.isRunning)! {
            videoQueue().async {
                self.captureSession?.startRunning()
            }
        }
    }
    
    func stopSession() {
        if captureSession!.isRunning {
            videoQueue().async {
                self.captureSession!.stopRunning()
            }
        }
    }
    
    func videoQueue() -> DispatchQueue {
        return DispatchQueue.main
    }
    
    func currentVideoOrientation() -> AVCaptureVideoOrientation {
        var orientation: AVCaptureVideoOrientation
        
        switch UIDevice.current.orientation {
        case .portrait:
            orientation = AVCaptureVideoOrientation.portrait
        case .landscapeRight:
            orientation = AVCaptureVideoOrientation.landscapeLeft
        case .portraitUpsideDown:
            orientation = AVCaptureVideoOrientation.portraitUpsideDown
        default:
            orientation = AVCaptureVideoOrientation.landscapeRight
        }
        
        return orientation
    }
    
    @objc func startCapture() {
        
        startRecording()
        
    }
    
    //EDIT 1: I FORGOT THIS AT FIRST
    
    func tempURL() -> URL? {
        let directory = NSTemporaryDirectory() as NSString
        
        if directory != "" {
            let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
            return URL(fileURLWithPath: path)
        }
        
        return nil
    }
    func startRecording() {
        
        if movieOutput.isRecording == false {
            
            let connection = movieOutput.connection(with: AVMediaType.video)
            
            if (connection?.isVideoOrientationSupported)!  {
                connection?.videoOrientation = currentVideoOrientation()
            }
            
            if (connection?.isVideoStabilizationSupported)! {
                connection?.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
            }
            
            let device = activeInput.device
            
            if (device.isSmoothAutoFocusSupported) {
                
                do {
                    try device.lockForConfiguration()
                    device.isSmoothAutoFocusEnabled = false
                    device.unlockForConfiguration()
                } catch {
                    print("Error setting configuration: \(error)")
                }
                
            }
            
            //EDIT2: And I forgot this
            outputURL = tempURL()
            movieOutput.startRecording(to: outputURL, recordingDelegate: self)
            
        }
        else {
            stopRecording()
        }
        
    }
    
    func stopRecording() {
        
        if movieOutput.isRecording == true {
            movieOutput.stopRecording()
        }
    }
    
}

extension MyCameraVC:AVCaptureFileOutputRecordingDelegate{
    
   public func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        
    }
    
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        if (error != nil) {
            
            print("Error recording movie: \(error!.localizedDescription)")
            
        } else {
            
            let videoRecorded = outputURL! as URL
            print(videoRecorded)
            
            //  performSegue(withIdentifier: "showVideo", sender: videoRecorded)
            
        }
        
    }
    
}
