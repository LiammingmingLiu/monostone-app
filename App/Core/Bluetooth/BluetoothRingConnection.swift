import Foundation
@preconcurrency import CoreBluetooth

/// 真实的 CoreBluetooth 戒指连接实现.
///
/// **注意**: 这个文件在没有实体 Monostone 戒指的情况下只能编译, 无法端到端
/// 测试. 所有 delegate 逻辑是按 `docs/events-protocol.md §1.1-1.4` 写的,
/// 和 firmware 团队对接后需要在真机上验证.
///
/// **架构**:
/// - `NSObject` 子类 (CoreBluetooth delegate 需要 objc)
/// - 持有 `CBCentralManager` + 单个 connected `CBPeripheral`
/// - `AsyncStream` continuations 把 callback 桥接到 Swift Concurrency
/// - 只连第一个广播名匹配的 peripheral, 简单策略 (未来可能扩成多戒指)
///
/// **已知限制**:
/// - 只扫描前台, 不支持 background scanning (需要 UIBackgroundModes 配置)
/// - 暂不处理 Audio Stream characteristic (`A005`), 音频 pipeline 是独立大 feature
/// - 没做重连退避算法, 断开后只做一次尝试
/// - 指令 write 用 `withoutResponse`, 不等 ack (低延迟优先)
final class BluetoothRingConnection: NSObject, RingConnection, @unchecked Sendable {
    // MARK: - AsyncStream plumbing

    let events: AsyncStream<RingEvent>
    let stateUpdates: AsyncStream<RingConnectionState>

    private let eventContinuation: AsyncStream<RingEvent>.Continuation
    private let stateContinuation: AsyncStream<RingConnectionState>.Continuation

    // MARK: - CoreBluetooth state

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var controlCharacteristic: CBCharacteristic?

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    // MARK: - Init

    override init() {
        var eventCont: AsyncStream<RingEvent>.Continuation!
        self.events = AsyncStream { eventCont = $0 }
        self.eventContinuation = eventCont

        var stateCont: AsyncStream<RingConnectionState>.Continuation!
        self.stateUpdates = AsyncStream { stateCont = $0 }
        self.stateContinuation = stateCont

        super.init()

        // 延迟到 start() 再初始化 CBCentralManager, 避免过早弹权限弹窗.
    }

    deinit {
        eventContinuation.finish()
        stateContinuation.finish()
    }

    // MARK: - RingConnection

    func start() async {
        if central == nil {
            central = CBCentralManager(delegate: self, queue: nil)
        }
        // CBCentralManagerDelegate.centralManagerDidUpdateState 会在 state ready
        // 后自动触发 scanForPeripherals, 这里不需要主动调.
        if central.state == .poweredOn {
            startScanning()
        }
    }

    func stop() async {
        central?.stopScan()
        if let peripheral {
            central?.cancelPeripheralConnection(peripheral)
        }
        self.peripheral = nil
        self.controlCharacteristic = nil
        stateContinuation.yield(.idle)
    }

    func send(_ command: RingCommand) async throws {
        guard let peripheral, let controlCharacteristic else {
            throw RingConnectionError.notConnected
        }
        let data: Data
        do {
            data = try command.encodeJSON()
        } catch {
            throw RingConnectionError.encodingFailed(error)
        }
        // write_without_response = 低延迟, 适合控制指令
        peripheral.writeValue(data, for: controlCharacteristic, type: .withoutResponse)
    }

    // MARK: - Private helpers

    private func startScanning() {
        stateContinuation.yield(.scanning)
        central.scanForPeripherals(
            withServices: [RingServiceSpec.primaryService],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothRingConnection: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            startScanning()
        case .poweredOff:
            stateContinuation.yield(.bluetoothOff)
        case .unauthorized:
            stateContinuation.yield(.unauthorized)
        case .unsupported:
            stateContinuation.yield(.failed(reason: "设备不支持蓝牙"))
        case .resetting:
            stateContinuation.yield(.reconnecting)
        case .unknown:
            break
        @unknown default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        // 优先用 service UUID 过滤, 再校验名字前缀
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String
            ?? peripheral.name ?? ""
        guard name.hasPrefix(RingServiceSpec.advertisingNamePrefix) else { return }

        self.peripheral = peripheral
        peripheral.delegate = self
        central.stopScan()
        stateContinuation.yield(.connecting)
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([RingServiceSpec.primaryService])
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        stateContinuation.yield(.failed(reason: error?.localizedDescription ?? "连接失败"))
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        self.peripheral = nil
        self.controlCharacteristic = nil
        stateContinuation.yield(.reconnecting)
        // 简单策略: 断开后立即重新扫描
        startScanning()
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothRingConnection: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {
        guard error == nil, let service = peripheral.services?.first else {
            stateContinuation.yield(.failed(reason: "未找到 Monostone service"))
            return
        }
        peripheral.discoverCharacteristics(RingServiceSpec.allCharacteristics, for: service)
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard error == nil, let characteristics = service.characteristics else { return }

        for char in characteristics {
            if char.uuid == RingServiceSpec.controlCommand {
                self.controlCharacteristic = char
            }
            if char.uuid == RingServiceSpec.deviceInfo {
                peripheral.readValue(for: char)
            }
            if RingServiceSpec.notifyCharacteristics.contains(char.uuid) {
                peripheral.setNotifyValue(true, for: char)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard error == nil, let data = characteristic.value else { return }

        switch characteristic.uuid {
        case RingServiceSpec.deviceInfo:
            if let info = try? decoder.decode(RingDeviceInfo.self, from: data) {
                stateContinuation.yield(.connected(info: info))
            }
        case RingServiceSpec.ringEvent:
            if let event = try? decoder.decode(RingEvent.self, from: data) {
                eventContinuation.yield(event)
            }
        case RingServiceSpec.audioStream:
            // 音频管线是 Step 10+ 后续的独立 feature, 这里先丢弃
            break
        case RingServiceSpec.sensorData:
            // Battery / accelerometer 节流数据, 待后续处理
            break
        default:
            break
        }
    }
}
