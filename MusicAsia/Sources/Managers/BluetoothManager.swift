import Foundation
import AVFoundation
import CoreBluetooth

/// 蓝牙连接管理器
class BluetoothManager: NSObject {
    static let shared = BluetoothManager()
    
    // 用于强制唤醒音频路由的静音播放器
    private var dummyAudioPlayer: AVAudioPlayer?
    
    // CoreBluetooth 相关
    private var centralManager: CBCentralManager!
    private var scannedPeripherals: [CBPeripheral] = []
    
    // 当前缓存的可用蓝牙名称
    private var cachedBluetoothName: String?
    
    override private init() {
        super.init()
        setupAudioSession()
        prepareDummyAudio()
        
        // 初始化 CoreBluetooth
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // 强制激活 AVAudioSession，确保能够读取到真实的系统音频路由
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("AVAudioSession 激活失败: \(error.localizedDescription)")
        }
    }
    
    // 准备一段静音的音频数据用于唤醒路由
    private func prepareDummyAudio() {
        let silentWavBase64 = "UklGRiQAAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQAAAAA="
        if let data = Data(base64Encoded: silentWavBase64) {
            do {
                dummyAudioPlayer = try AVAudioPlayer(data: data)
                dummyAudioPlayer?.prepareToPlay()
            } catch {
                print("初始化静音播放器失败: \(error.localizedDescription)")
            }
        }
    }
    
    // 唤醒路由并执行检查
    private func forceWakeupAudioRoute() {
        setupAudioSession()
        dummyAudioPlayer?.play()
        Thread.sleep(forTimeInterval: 0.05)
    }
    
    // 返回当前 CoreBluetooth 的状态是否可用
    var isBluetoothPoweredOn: Bool {
        return centralManager.state == .poweredOn
    }
    
    // 返回当前 CoreBluetooth 的状态是否处于未知或正在重置（需要等待）
    var isBluetoothStateUnknown: Bool {
        return centralManager.state == .unknown || centralManager.state == .resetting
    }
    
    // 获取当前可用的蓝牙设备名称（双重保险）
    func getAvailableBluetoothName(completion: @escaping (String?) -> Void) {
        // 如果状态还是未知，稍微等一下让底层初始化完成
        if isBluetoothStateUnknown {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.performGetBluetoothName(completion: completion)
            }
        } else {
            performGetBluetoothName(completion: completion)
        }
    }
    
    private func performGetBluetoothName(completion: @escaping (String?) -> Void) {
        // 1. 先尝试从系统音频路由获取
        forceWakeupAudioRoute()
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        for output in currentRoute.outputs {
            if output.portType == .bluetoothA2DP ||
               output.portType == .bluetoothHFP ||
               output.portType == .bluetoothLE {
                cachedBluetoothName = output.portName
                completion(output.portName)
                return
            }
        }
        
        // 2. 如果系统路由没拿到，看 CoreBluetooth 之前是否扫描到了设备
        if let firstScanned = scannedPeripherals.first(where: { $0.name != nil }) {
            cachedBluetoothName = firstScanned.name
            completion(firstScanned.name)
            return
        }
        
        // 3. 如果什么都没拿到，启动扫描等一会儿 (0.5秒)，然后再检查一次
        if centralManager.state == .poweredOn {
            scannedPeripherals.removeAll()
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.centralManager.stopScan()
                if let firstScanned = self?.scannedPeripherals.first(where: { $0.name != nil }) {
                    self?.cachedBluetoothName = firstScanned.name
                    completion(firstScanned.name)
                } else {
                    completion(nil)
                }
            }
        } else {
            completion(nil)
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // 只要蓝牙打开了，就一直在后台慢慢扫，缓存着周围的设备
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        } else {
            scannedPeripherals.removeAll()
            cachedBluetoothName = nil
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // 只保存有名字的设备
        if let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            if !scannedPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
                scannedPeripherals.append(peripheral)
                // 缓存最新发现的设备名
                cachedBluetoothName = name
            }
        }
    }
}
