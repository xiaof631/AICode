import Foundation
import CloudKit

class ICloudSyncManager: ObservableObject {
    private let container: CKContainer
    private let database: CKDatabase
    private let recordType = "TodoLog"
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    init() {
        container = CKContainer.default()
        database = container.privateCloudDatabase
    }
    
    // 同步数据到 iCloud
    func syncToCloud(logs: [DailyLog]) async throws {
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            // 获取现有记录
            let existingRecords = try await fetchExistingRecords()
            
            // 准备要保存的记录
            let recordsToSave = try logs.map { log -> CKRecord in
                let recordID = CKRecord.ID(recordName: log.id.uuidString)
                let record = CKRecord(recordType: recordType, recordID: recordID)
                
                // 将 DailyLog 转换为可存储的数据
                let encoder = JSONEncoder()
                let logData = try encoder.encode(log)
                record["logData"] = logData
                record["date"] = log.date
                
                return record
            }
            
            // 准备要删除的记录
            let existingIDs = Set(existingRecords.map { $0.recordID.recordName })
            let currentIDs = Set(logs.map { $0.id.uuidString })
            let recordsToDelete = existingRecords.filter { !currentIDs.contains($0.recordID.recordName) }
            
            // 执行批量操作
            let operation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordsToDelete.map { $0.recordID })
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        self.lastSyncDate = Date()
                        self.syncError = nil
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.syncError = error.localizedDescription
                    }
                }
            }
            
            database.add(operation)
        } catch {
            syncError = error.localizedDescription
            throw error
        }
    }
    
    // 从 iCloud 获取数据
    func fetchFromCloud() async throws -> [DailyLog] {
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            let records = try await fetchExistingRecords()
            
            // 将记录转换回 DailyLog 对象
            let decoder = JSONDecoder()
            let logs = try records.compactMap { record -> DailyLog? in
                guard let logData = record["logData"] as? Data else { return nil }
                return try decoder.decode(DailyLog.self, from: logData)
            }
            
            DispatchQueue.main.async {
                self.lastSyncDate = Date()
                self.syncError = nil
            }
            
            return logs
        } catch {
            syncError = error.localizedDescription
            throw error
        }
    }
    
    // 获取现有记录
    private func fetchExistingRecords() async throws -> [CKRecord] {
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        let result = try await database.records(matching: query)
        return result.matchResults.compactMap { try? $0.1.get() }
    }
    
    // 检查 iCloud 状态
    func checkICloudStatus() async -> Bool {
        do {
            let status = try await container.accountStatus()
            return status == .available
        } catch {
            return false
        }
    }
} 