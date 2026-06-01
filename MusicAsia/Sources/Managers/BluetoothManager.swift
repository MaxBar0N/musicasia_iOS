import Foundation
import CoreBluetooth

/// 蓝牙连接管理器，负责扫描和连接外部音乐设备
class BluetoothManager: NSObject {
    static let shared = BluetoothManager()
    
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    
    // 模拟连接状态和当前设备 MAC 地址
    var isConnected: Bool = false
    var currentDeviceMAC: String? = "11:22:33:44:55:66" // 测试用模拟 MAC
    
    // 可以添加闭包或代理来回调状态给业务层
    var onStateChanged: ((CBManagerState) -> Void)?
    var onDeviceDiscovered: ((CBPeripheral) -> Void)?
    
    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func stopScanning() {
        centralManager.stopScan()
    }
    
    func connect(to peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: nil)
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        onStateChanged?(central.state)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        onDeviceDiscovered?(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        // 开始发现服务
        peripheral.discoverServices(nil)
    }
}
