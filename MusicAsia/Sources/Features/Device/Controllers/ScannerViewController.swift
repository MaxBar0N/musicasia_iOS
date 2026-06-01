import UIKit
import AVFoundation
import SnapKit

class ScannerViewController: BaseViewController {
    
    var onScanSuccess: ((String) -> Void)?
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    private let overlayView = UIView()
    private let scanFrameView = UIView()
    private let promptLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "扫描设备码"
        view.backgroundColor = .black
        
        setupScanner()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
    }
    
    private func setupScanner() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            showAlert(message: "无法获取摄像头")
            return
        }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            showAlert(message: "摄像头初始化失败")
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            showAlert(message: "无法添加摄像头输入")
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr, .ean8, .ean13, .pdf417, .code128]
        } else {
            showAlert(message: "无法添加元数据输出")
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }
    
    private func setupUI() {
        // 半透明遮罩层
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.addSubview(overlayView)
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 扫描框
        scanFrameView.layer.borderColor = UIColor(hex: "#16E0BF").cgColor
        scanFrameView.layer.borderWidth = 2
        scanFrameView.backgroundColor = .clear
        view.addSubview(scanFrameView)
        
        scanFrameView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-50)
            make.width.height.equalTo(260)
        }
        
        // 扫码动画线
        let scanLine = UIView()
        scanLine.backgroundColor = UIColor(hex: "#16E0BF")
        scanFrameView.addSubview(scanLine)
        scanLine.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(10)
            make.height.equalTo(2)
            make.top.equalToSuperview().offset(10)
        }
        
        // 动画
        UIView.animate(withDuration: 2.0, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut]) {
            scanLine.transform = CGAffineTransform(translationX: 0, y: 240)
        }
        
        // 提示文字
        promptLabel.text = "将设备码/二维码放入框内，即可自动扫描"
        promptLabel.textColor = .white
        promptLabel.font = .systemFont(ofSize: 14)
        promptLabel.textAlignment = .center
        view.addSubview(promptLabel)
        
        promptLabel.snp.makeConstraints { make in
            make.top.equalTo(scanFrameView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }
        
        // 挖空遮罩层，形成扫描窗口
        DispatchQueue.main.async {
            self.setupMaskLayer()
        }
    }
    
    private func setupMaskLayer() {
        let path = UIBezierPath(rect: view.bounds)
        let scanPath = UIBezierPath(rect: scanFrameView.frame)
        path.append(scanPath)
        path.usesEvenOddFillRule = true
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd
        overlayView.layer.mask = maskLayer
        
        // 限制扫描区域
        if let metadataOutput = captureSession.outputs.first as? AVCaptureMetadataOutput {
            let rectOfInterest = previewLayer.metadataOutputRectConverted(fromLayerRect: scanFrameView.frame)
            metadataOutput.rectOfInterest = rectOfInterest
        }
    }
}

extension ScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            DispatchQueue.main.async { [weak self] in
                self?.navigationController?.popViewController(animated: true)
                self?.onScanSuccess?(stringValue)
            }
        }
    }
}
