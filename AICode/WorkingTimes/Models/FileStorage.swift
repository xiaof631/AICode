import Foundation

// 负责处理文件存储和加载的工具类
class FileStorage {
    // 单例实例
    static let shared = FileStorage()
    
    // 文件管理相关
    private let fileManager = FileManager.default
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // 私有初始化方法，确保单例模式
    private init() {}
    
    // 获取指定文件名的完整URL
    func getFileURL(fileName: String) -> URL {
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    // 保存数据到文件
    func saveData<T: Encodable>(_ data: T, toFile fileName: String) throws {
        let fileURL = getFileURL(fileName: fileName)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let encodedData = try encoder.encode(data)
        
        // 写入文件
        try encodedData.write(to: fileURL, options: .atomic)
        print("数据已保存到: \(fileURL.path)")
    }
    
    // 从文件加载数据
    func loadData<T: Decodable>(fromFile fileName: String, as type: T.Type) throws -> T {
        let fileURL = getFileURL(fileName: fileName)
        
        // 检查文件是否存在
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw NSError(domain: "FileStorageError", code: 404, userInfo: [NSLocalizedDescriptionKey: "文件不存在: \(fileName)"])
        }
        
        // 读取文件数据
        let data = try Data(contentsOf: fileURL)
        
        // 解码JSON数据
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }
    
    // 检查文件是否存在
    func fileExists(fileName: String) -> Bool {
        let fileURL = getFileURL(fileName: fileName)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    // 删除文件
    func deleteFile(fileName: String) throws {
        let fileURL = getFileURL(fileName: fileName)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
            print("文件已删除: \(fileURL.path)")
        }
    }
}