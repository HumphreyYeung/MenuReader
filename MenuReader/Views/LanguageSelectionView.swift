//
//  LanguageSelectionView.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 2025-07-13.
//

import SwiftUI

struct LanguageSelectionView: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    @State private var selectedLanguage: String
    @Environment(\.dismiss) private var dismiss
    
    init(profileViewModel: ProfileViewModel) {
        self.profileViewModel = profileViewModel
        self._selectedLanguage = State(initialValue: profileViewModel.userProfile.targetLanguage)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.s) {
                // Language List
                ForEach(SupportedLanguage.allCases, id: \.self) { language in
                    LanguageRowView(
                        language: language,
                        isSelected: selectedLanguage == language.rawValue
                    ) {
                        selectedLanguage = language.rawValue
                    }
                }
            }
            .padding(.horizontal, AppSpacing.m)
            .padding(.top, AppSpacing.m)
        }
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .background(AppColors.background)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    profileViewModel.updateTargetLanguage(selectedLanguage)
                    dismiss()
                }
                .font(AppFonts.body)
                .foregroundColor(AppColors.accent)
            }
        }
    }
}

// MARK: - Language Row View
struct LanguageRowView: View {
    let language: SupportedLanguage
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(language.displayName)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.primary)
                
                Spacer()
                
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? AppColors.accent : AppColors.secondaryText)
            }
            .padding(.horizontal, AppSpacing.m)
            .padding(.vertical, AppSpacing.s)
            .background(AppColors.contentBackground)
            .cornerRadius(AppSpacing.standardCorner)
            .shadow(color: AppColors.separator.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationView {
        LanguageSelectionView(profileViewModel: ProfileViewModel())
    }
} 