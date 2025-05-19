import SwiftUI
import CloudKit

struct ICloudLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isSigningIn = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var onLoginSuccess: () -> Void
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 20) {
                        Spacer()
                            .frame(height: geometry.size.height * 0.1)
                        
                        Image(systemName: "icloud")
                            .font(.system(size: min(geometry.size.width * 0.15, 60)))
                            .foregroundColor(.blue)
                            .padding()
                        
                        Text("iCloud 同步")
                            .font(.system(size: min(geometry.size.width * 0.08, 28), weight: .bold))
                        
                        Text("登录您的 Apple ID 以启用 iCloud 同步功能")
                            .font(.system(size: min(geometry.size.width * 0.04, 16)))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .frame(maxWidth: min(geometry.size.width * 0.8, 400))
                        
                        Button(action: signInWithICloud) {
                            if isSigningIn {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("使用 Apple ID 登录")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: min(geometry.size.width * 0.8, 400))
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .disabled(isSigningIn)
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding()
                                .frame(maxWidth: min(geometry.size.width * 0.8, 400))
                        }
                        
                        Spacer()
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
            .navigationTitle("iCloud 登录")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func signInWithICloud() {
        isSigningIn = true
        errorMessage = nil
        
        CKContainer.default().accountStatus { status, error in
            DispatchQueue.main.async {
                isSigningIn = false
                
                if let error = error {
                    errorMessage = "登录失败：\(error.localizedDescription)"
                    showError = true
                    return
                }
                
                switch status {
                case .available:
                    onLoginSuccess()
                    dismiss()
                case .noAccount:
                    errorMessage = "未找到 Apple ID 账号"
                    showError = true
                case .restricted:
                    errorMessage = "iCloud 访问受限"
                    showError = true
                case .couldNotDetermine:
                    errorMessage = "无法确定 iCloud 状态"
                    showError = true
                @unknown default:
                    errorMessage = "未知错误"
                    showError = true
                }
            }
        }
    }
} 