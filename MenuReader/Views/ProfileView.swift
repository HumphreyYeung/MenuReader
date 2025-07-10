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
            .listRowBackground(AppColors.contentBackground)
            
            // MARK: - Allergen Management Section
            Section(header: Text("过敏原管理")) {
                allergenManagementView
            }
            .listRowBackground(AppColors.contentBackground)
            
            // MARK: - App Information Section
            Section(header: Text("应用信息")) {
                appInfoView
            }
            .listRowBackground(AppColors.contentBackground)
        }
        .navigationTitle("个人设置")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(AppColors.background)
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
                .foregroundColor(AppColors.primary)
            Spacer()
            Picker("目标语言", selection: $viewModel.userProfile.targetLanguage) {
                ForEach(SupportedLanguage.allCases, id: \.rawValue) { language in
                    Text(language.displayName).tag(language.rawValue)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .tint(AppColors.accent)
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
                                .foregroundColor(viewModel.hasAllergen(allergen.rawValue) ? AppColors.accent : AppColors.secondaryText)
                            Text(allergen.displayName)
                                .foregroundColor(AppColors.primary)
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
                            .foregroundColor(AppColors.accent)
                        Text(allergen)
                            .foregroundColor(AppColors.primary)
                        Spacer()
                        Button(action: {
                            viewModel.removeCustomAllergen(allergen)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(AppColors.error)
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
                        .foregroundColor(AppColors.accent)
                    Text("添加自定义过敏原")
                        .foregroundColor(AppColors.accent)
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
                .foregroundColor(AppColors.primary)
            Spacer()
            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                .foregroundColor(AppColors.secondaryText)
        }
    }
}
