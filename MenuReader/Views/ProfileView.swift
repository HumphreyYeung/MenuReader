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
    @State private var showingPaywall = false
    @State private var showingLanguageSelection = false
    @State private var showingAllergenSelection = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: - Credits Section
                creditsSection
                
                // MARK: - Settings List
                settingsListSection
                
                // MARK: - App Version
                appVersionSection
            }
        }
        .navigationTitle("Setting")
        .navigationBarTitleDisplayMode(.inline)
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
        .sheet(isPresented: $showingPaywall) {
            PaywallPlaceholderView()
        }
        .onChange(of: viewModel.userProfile.targetLanguage) { _ in
            viewModel.saveProfile()
        }
        .navigationDestination(isPresented: $showingLanguageSelection) {
            LanguageSelectionView(profileViewModel: viewModel)
        }
        .navigationDestination(isPresented: $showingAllergenSelection) {
            AllergenView(profileViewModel: viewModel)
        }
    }
    
    // MARK: - Credits Section
    private var creditsSection: some View {
        VStack(spacing: AppSpacing.s) {
            // Credits display
            VStack(spacing: AppSpacing.xxs) {
                Text("0")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primary)
                
                Text("credits remaining")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.secondaryText)
            }
            .padding(.top, AppSpacing.l)
            
            // Add more button
            Button(action: {
                showingPaywall = true
            }) {
                HStack {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                    Text("Add more")
                        .font(AppFonts.button)
                }
                .foregroundColor(AppColors.buttonText)
                .padding(.horizontal, AppSpacing.l)
                .padding(.vertical, AppSpacing.s)
                .background(AppColors.primary)
                .cornerRadius(AppSpacing.standardCorner)
            }
            .padding(.bottom, AppSpacing.xl)
        }
        .padding(.horizontal, AppSpacing.screenMargin)
    }
    
    // MARK: - Settings List Section
    private var settingsListSection: some View {
        VStack(spacing: AppSpacing.s) {
            // Language
            SettingsCardView(
                title: "Language",
                value: getLanguageDisplayValue(),
                icon: "globe",
                action: {
                    showingLanguageSelection = true
                }
            )
            
            // Allergens
            SettingsCardView(
                title: "Allergens",
                value: getAllergensDisplayValue(),
                icon: "exclamationmark.triangle",
                action: {
                    showingAllergenSelection = true
                }
            )
            
            // Privacy Policy
            SettingsCardView(
                title: "Privacy Policy",
                icon: "hand.raised",
                action: {}
            )
            
            // Terms & Conditions
            SettingsCardView(
                title: "Terms & Conditions",
                icon: "doc.text",
                action: {}
            )
            
            // Feedback
            SettingsCardView(
                title: "Feedback",
                icon: "message",
                action: {}
            )
            
            // Account
            SettingsCardView(
                title: "Account",
                icon: "person.circle",
                action: {}
            )
        }
        .padding(.horizontal, AppSpacing.screenMargin)
    }
    
    // MARK: - App Version Section
    private var appVersionSection: some View {
        VStack(spacing: AppSpacing.xxl) {
            Spacer()
            
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.secondaryText)
                .padding(.bottom, AppSpacing.l)
        }
        .frame(minHeight: 100)
    }
    
    // MARK: - Helper Methods
    private func getLanguageDisplayValue() -> String {
        if let language = SupportedLanguage.allCases.first(where: { $0.rawValue == viewModel.userProfile.targetLanguage }) {
            return language.displayName
        }
        return "English"
    }
    
    private func getAllergensDisplayValue() -> String {
        let allergens = viewModel.userProfile.allergens
        
        if allergens.isEmpty {
            return "None"
        }
        
        // 获取每个过敏原的显示名称
        let displayNames = allergens.compactMap { allergen -> String? in
            // 首先检查是否是系统内置过敏原
            if let commonAllergen = CommonAllergen.allCases.first(where: { $0.rawValue == allergen }) {
                return commonAllergen.displayName
            }
            // 如果不是系统内置的，则是自定义过敏原，直接返回名称
            return allergen
        }
        
        // 用逗号连接所有名称
        let joinedNames = displayNames.joined(separator: ", ")
        
        // 如果长度超过限制，截断并添加省略号
        let maxLength = 35
        if joinedNames.count > maxLength {
            let truncated = String(joinedNames.prefix(maxLength))
            // 找到最后一个逗号的位置，避免截断在单词中间
            if let lastCommaIndex = truncated.lastIndex(of: ",") {
                return String(truncated[..<lastCommaIndex]) + "..."
            } else {
                return truncated + "..."
            }
        }
        
        return joinedNames
    }
}

// MARK: - Settings Card View
struct SettingsCardView: View {
    let title: String
    let value: String?
    let icon: String
    let action: () -> Void
    
    init(title: String, value: String? = nil, icon: String, action: @escaping () -> Void) {
        self.title = title
        self.value = value
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: AppIcons.mediumSize))
                    .foregroundColor(AppColors.accent)
                    .frame(width: 28, height: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                if let value = value {
                    Text(value)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.secondaryText)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.trailing)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.secondaryText)
            }
            .padding(.horizontal, AppSpacing.m)
            .padding(.vertical, AppSpacing.m)
            .background(AppColors.contentBackground)
            .cornerRadius(AppSpacing.standardCorner)
            .shadow(color: AppColors.separator.opacity(0.3), radius: 2, x: 0, y: 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Paywall Placeholder View
struct PaywallPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.l) {
                Image(systemName: "creditcard")
                    .font(.system(size: 64))
                    .foregroundColor(AppColors.accent)
                
                Text("Paywall Coming Soon")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.primary)
                
                Text("Credit purchasing feature will be available soon.")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.background)
            .navigationTitle("Credits")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
        }
    }
}
