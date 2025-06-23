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
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            // MARK: - Language Settings Section
            Section(header: Text("语言设置")) {
                languageSettingsView
            }
            
            // MARK: - Allergen Management Section
            Section(header: Text("过敏原管理")) {
                allergenManagementView
            }
            
            // MARK: - App Information Section
            Section(header: Text("应用信息")) {
                appInfoView
            }
        }
        .navigationTitle("个人设置")
        .navigationBarTitleDisplayMode(.inline)
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
        .onChange(of: viewModel.userProfile.targetLanguage) { _ in
            viewModel.saveProfile()
        }
    }
    
    // MARK: - Language Settings View
    private var languageSettingsView: some View {
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
                                .foregroundColor(viewModel.hasAllergen(allergen.rawValue) ? .blue : .secondary)
                            Text(allergen.displayName)
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
    
    // MARK: - App Information View
    private var appInfoView: some View {
        HStack {
            Label("版本", systemImage: "info.circle")
            Spacer()
            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                .foregroundColor(.secondary)
        }
    }
}
