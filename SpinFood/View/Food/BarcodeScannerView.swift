import SwiftUI
import AVFoundation

struct BarcodeScannerView: UIViewControllerRepresentable {
    var onScan: (String) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let vc = BarcodeScannerViewController()
        vc.onScan = onScan
        vc.onCancel = onCancel
        return vc
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {}
}

final class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onScan: ((String) -> Void)?
    var onCancel: (() -> Void)?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var metadataOutput: AVCaptureMetadataOutput?
    private var hasScanned = false
    private weak var frameView: UIView?
    private var scanLineTopConstraint: NSLayoutConstraint?
    private var torchDevice: AVCaptureDevice?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupOverlay()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hasScanned = false
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateScanLine()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning {
            session.stopRunning()
        }
        setTorch(on: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        updateScanRect()
    }

    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            showUnavailable()
            return
        }

        torchDevice = device
        session.beginConfiguration()
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            showUnavailable()
            return
        }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.ean8, .ean13, .upce, .code128]
        metadataOutput = output

        session.commitConfiguration()

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.insertSublayer(layer, at: 0)
        previewLayer = layer
    }

    // Restricts barcode detection to only the visible frame area.
    private func updateScanRect() {
        guard let previewLayer, let frameView else { return }
        let frameRect = view.convert(frameView.frame, from: frameView.superview)
        metadataOutput?.rectOfInterest = previewLayer.metadataOutputRectConverted(fromLayerRect: frameRect)
    }

    private func setupOverlay() {
        let cancel = UIButton(type: .system)
        cancel.setTitle(String(localized: "Cancel"), for: .normal)
        cancel.setTitleColor(.white, for: .normal)
        cancel.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        cancel.addAction(UIAction { [weak self] _ in self?.onCancel?() }, for: .touchUpInside)
        cancel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancel)

        let symConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let torchButton = UIButton(type: .system)
        torchButton.setImage(UIImage(systemName: "bolt.slash", withConfiguration: symConfig), for: .normal)
        torchButton.setImage(UIImage(systemName: "bolt.fill", withConfiguration: symConfig), for: .selected)
        torchButton.tintColor = .white
        torchButton.addAction(UIAction { [weak self, weak torchButton] _ in
            guard let self, let torchButton else { return }
            torchButton.isSelected.toggle()
            self.setTorch(on: torchButton.isSelected)
        }, for: .touchUpInside)
        torchButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(torchButton)

        let hint = UILabel()
        hint.text = String(localized: "Align the barcode inside the frame")
        hint.textColor = .white
        hint.font = .systemFont(ofSize: 15, weight: .medium)
        hint.textAlignment = .center
        hint.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hint)

        let frameView = UIView()
        frameView.layer.borderColor = UIColor.white.withAlphaComponent(0.85).cgColor
        frameView.layer.borderWidth = 2
        frameView.layer.cornerRadius = 12
        frameView.backgroundColor = .clear
        frameView.clipsToBounds = true
        frameView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(frameView)
        self.frameView = frameView

        let scanLine = UIView()
        scanLine.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.8)
        scanLine.layer.cornerRadius = 1
        scanLine.translatesAutoresizingMaskIntoConstraints = false
        frameView.addSubview(scanLine)

        let topConstraint = scanLine.topAnchor.constraint(equalTo: frameView.topAnchor, constant: 8)
        scanLineTopConstraint = topConstraint

        NSLayoutConstraint.activate([
            cancel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            cancel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            torchButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            torchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            hint.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            hint.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            hint.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            frameView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            frameView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            frameView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.75),
            frameView.heightAnchor.constraint(equalToConstant: 160),

            topConstraint,
            scanLine.leadingAnchor.constraint(equalTo: frameView.leadingAnchor, constant: 8),
            scanLine.trailingAnchor.constraint(equalTo: frameView.trailingAnchor, constant: -8),
            scanLine.heightAnchor.constraint(equalToConstant: 2),
        ])
    }

    private func animateScanLine() {
        guard let scanLineTopConstraint, let frameView else { return }
        scanLineTopConstraint.constant = 8
        frameView.layoutIfNeeded()
        UIView.animate(
            withDuration: 2.0,
            delay: 0,
            options: [.repeat, .autoreverse, .curveEaseInOut],
            animations: {
                scanLineTopConstraint.constant = 150
                frameView.layoutIfNeeded()
            }
        )
    }

    private func setTorch(on: Bool) {
        guard let device = torchDevice, device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }

    private func showUnavailable() {
        let label = UILabel()
        label.text = String(localized: "Camera unavailable")
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !hasScanned,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue,
              !value.isEmpty else { return }

        hasScanned = true
        session.stopRunning()
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        onScan?(value)
    }
}
