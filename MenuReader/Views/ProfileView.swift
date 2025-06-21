//
//  ProfileView.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import SwiftUI
import Combine

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingAddCustomAllergen = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Language Settings Section
                Section(header: Text("语言设置")) {
                    languageSettingsView
                }
                
                // MARK: - Allergen Management Section
                Section(header: Text("过敏原管理")) {
                    allergenManagementView
                }
                
                // MARK: - Legal Section
                Section(header: Text("法律信息")) {
                    legalLinksView
                }
                
                // MARK: - App Information Section
                Section(header: Text("应用信息")) {
                    appInfoView
                }
            }
            .navigationTitle("个人设置")
            .navigationBarTitleDisplayMode(.large)
            .alert("添加自定义过敏原", isPresented: $showingAddCustomAllergen) {
                TextField("输入过敏原名称", text: $viewModel.customAllergenInput)
                Button("添加") {
                    viewModel.addCustomAllergenFromInput()
                }
                Button("取消", role: .cancel) {}
            } message: {
                if !viewModel.validationError.isEmpty {
                    Text(viewModel.validationError)
                }
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                WebView(url: "https://example.com/privacy-policy", title: "隐私政策")
            }
            .sheet(isPresented: $showingTermsOfService) {
                WebView(url: "https://example.com/terms-of-service", title: "服务条款")
            }
        }
    }
    
    // MARK: - Language Settings View
    private var languageSettingsView: some View {
        VStack(spacing: 0) {
            // Target Language (Translation Language)
            HStack {
                Label("目标语言", systemImage: "globe")
                Spacer()
                Picker("目标语言", selection: $viewModel.userProfile.targetLanguage) {
                    ForEach(SupportedLanguage.allCases, id: \.rawValue) { language in
                        Text(language.displayName).tag(language.rawValue)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
    }
    
    // MARK: - Allergen Management View
    private var allergenManagementView: some View {
        VStack(spacing: 0) {
            // Common Allergens
            ForEach(CommonAllergen.allCases, id: \.rawValue) { allergen in
                HStack {
                    Button(action: {
                        viewModel.toggleCommonAllergen(allergen)
                    }) {
                        HStack {
                            Image(systemName: viewModel.hasAllergen(allergen.rawValue) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(viewModel.hasAllergen(allergen.rawValue) ? .blue : .gray)
                            Text(allergen.displayName)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.vertical, 2)
                
                if allergen != CommonAllergen.allCases.last {
                    Divider()
                        .padding(.leading, 40)
                }
            }
            
            // Custom Allergens
            if !viewModel.customAllergens.isEmpty {
                Divider()
                    .padding(.leading, 40)
                
                ForEach(viewModel.customAllergens, id: \.self) { allergen in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                        Text(allergen)
                        Spacer()
                        Button(action: {
                            viewModel.removeCustomAllergen(allergen)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            
            // Add Custom Allergen Button
            Divider()
                .padding(.leading, 40)
            
            Button(action: {
                showingAddCustomAllergen = true
            }) {
                HStack {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.blue)
                    Text("添加自定义过敏原")
                        .foregroundColor(.blue)
                    Spacer()
                }
            }
            .padding(.vertical, 2)
        }
    }
    
    // MARK: - Legal Links View
    private var legalLinksView: some View {
        VStack(spacing: 0) {
            Button(action: {
                showingPrivacyPolicy = true
            }) {
                HStack {
                    Label("隐私政策", systemImage: "lock.shield")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            
            Divider()
                .padding(.leading, 40)
            
            Button(action: {
                showingTermsOfService = true
            }) {
                HStack {
                    Label("服务条款", systemImage: "doc.text")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
        }
    }
    
    // MARK: - App Information View
    private var appInfoView: some View {
        VStack(spacing: 0) {
            HStack {
                Label("版本", systemImage: "info.circle")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .padding(.leading, 40)
            
            HStack {
                Label("构建版本", systemImage: "hammer")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                    .foregroundColor(.secondary)
            }
        }
    }
}



// MARK: - Web View for Legal Pages
struct WebView: View {
    let url: String
    let title: String
    
    var body: some View {
        NavigationView {
            VStack {
                Text("此页面将显示 \(title)")
                    .font(.title2)
                    .padding()
                
                Text("URL: \(url)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                
                Spacer()
                
                Text("在实际应用中，这里会加载实际的网页内容")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        // This will be handled by the parent view
                    }
                }
            }
        }
    }
}

// MARK: - Profile View Model
@MainActor
class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile
    @Published var customAllergens: [String] = []
    @Published var customAllergenInput: String = ""
    @Published var validationError: String = ""
    
    private let allergenManager: AllergenManagerProtocol
    private let storageService: StorageServiceProtocol
    
    init(allergenManager: AllergenManagerProtocol = AllergenManager.shared,
         storageService: StorageServiceProtocol = StorageService.shared) {
        self.allergenManager = allergenManager
        self.storageService = storageService
        self.userProfile = storageService.loadUserProfile()
        loadCustomAllergens()
        
        // Observe changes to userProfile and save automatically
        $userProfile
            .dropFirst() // Skip the initial value
            .sink { [weak self] profile in
                self?.storageService.saveUserProfile(profile)
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Allergen Management
    func hasAllergen(_ allergen: String) -> Bool {
        return allergenManager.hasAllergen(allergen)
    }
    
    func toggleCommonAllergen(_ allergen: CommonAllergen) {
        if hasAllergen(allergen.rawValue) {
            allergenManager.removeAllergen(allergen.rawValue)
        } else {
            allergenManager.addAllergen(allergen.rawValue)
        }
        refreshProfile()
    }
    
    func addCustomAllergen(_ name: String) -> (success: Bool, errorMessage: String) {
        let validation = allergenManager.validateAllergenName(name)
        guard validation == .valid else {
            return (false, validation.errorMessage)
        }
        
        let success = allergenManager.addCustomAllergen(name)
        if success {
            refreshProfile()
            loadCustomAllergens()
        }
        return (success, success ? "" : "添加失败")
    }
    
    func addCustomAllergenFromInput() {
        validationError = ""
        let result = addCustomAllergen(customAllergenInput)
        if result.success {
            customAllergenInput = ""
        } else {
            validationError = result.errorMessage
        }
    }
    
    func removeCustomAllergen(_ allergen: String) {
        allergenManager.removeAllergen(allergen)
        refreshProfile()
        loadCustomAllergens()
    }
    
    private func loadCustomAllergens() {
        customAllergens = allergenManager.getCustomAllergens()
    }
    
    private func refreshProfile() {
        userProfile = storageService.loadUserProfile()
    }
}

#Preview {
    ProfileView()
} 