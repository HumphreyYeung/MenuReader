//
//  AllergenView.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 2025-07-13.
//

import SwiftUI

struct AllergenView: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    @State private var showingAddAllergen = false
    @State private var newAllergenName = ""
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    init(profileViewModel: ProfileViewModel) {
        self.profileViewModel = profileViewModel
    }
    
    var body: some View {
        List {
            // Custom Allergens (at top)
            ForEach(profileViewModel.customAllergens, id: \.self) { allergen in
                AllergenRowView(
                    allergen: allergen,
                    isSelected: profileViewModel.hasAllergen(allergen),
                    isCustom: true,
                    onToggle: {
                        toggleAllergen(allergen)
                    },
                    onDelete: {
                        profileViewModel.removeAllergen(allergen)
                    }
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: AppSpacing.xs, leading: AppSpacing.m, bottom: AppSpacing.xs, trailing: AppSpacing.m))
            }
            
            // Common Allergens
            ForEach(CommonAllergen.allCases, id: \.self) { allergen in
                AllergenRowView(
                    allergen: allergen.displayName,
                    isSelected: profileViewModel.hasAllergen(allergen.rawValue),
                    isCustom: false,
                    onToggle: {
                        profileViewModel.toggleCommonAllergen(allergen)
                    },
                    onDelete: {
                        profileViewModel.removeAllergen(allergen.rawValue)
                    }
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: AppSpacing.xs, leading: AppSpacing.m, bottom: AppSpacing.xs, trailing: AppSpacing.m))
            }
        }
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
        .navigationTitle("Allergens")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .background(AppColors.background)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("+Add") {
                    showingAddAllergen = true
                }
                .font(AppFonts.body)
                .foregroundColor(AppColors.accent)
            }
        }
        .sheet(isPresented: $showingAddAllergen) {
            AddAllergenSheet(
                newAllergenName: $newAllergenName,
                errorMessage: $errorMessage,
                onAdd: {
                    addCustomAllergen()
                },
                onCancel: {
                    showingAddAllergen = false
                    newAllergenName = ""
                    errorMessage = ""
                }
            )
        }
    }
    
    private func toggleAllergen(_ allergen: String) {
        if profileViewModel.hasAllergen(allergen) {
            profileViewModel.userProfile.allergens.removeAll { $0 == allergen }
        } else {
            profileViewModel.userProfile.allergens.append(allergen)
        }
        profileViewModel.saveProfile()
    }
    
    private func addCustomAllergen() {
        let trimmedName = newAllergenName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            errorMessage = "请输入过敏原名称"
            return
        }
        
        if profileViewModel.hasAllergen(trimmedName) {
            errorMessage = "该过敏原已存在"
            return
        }
        
        // Add to custom allergens list at the top
        profileViewModel.customAllergens.insert(trimmedName, at: 0)
        // Add to user profile and auto-select
        profileViewModel.userProfile.allergens.append(trimmedName)
        profileViewModel.saveProfile()
        
        // Close sheet and reset
        showingAddAllergen = false
        newAllergenName = ""
        errorMessage = ""
    }
}

// MARK: - Allergen Row View
struct AllergenRowView: View {
    let allergen: String
    let isSelected: Bool
    let isCustom: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(allergen)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
            
            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24))
                .foregroundColor(isSelected ? AppColors.accent : AppColors.secondaryText)
        }
        .padding(.horizontal, AppSpacing.m)
        .padding(.vertical, AppSpacing.s)
        .background(AppColors.contentBackground)
        .cornerRadius(AppSpacing.standardCorner)
        .shadow(color: AppColors.separator.opacity(0.3), radius: 2, x: 0, y: 1)
        .onTapGesture {
            onToggle()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Add Allergen Sheet
struct AddAllergenSheet: View {
    @Binding var newAllergenName: String
    @Binding var errorMessage: String
    let onAdd: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.l) {
                VStack(spacing: AppSpacing.s) {
                    Text("Add New Allergen")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.primary)
                    
                    TextField("Enter allergen name", text: $newAllergenName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(AppFonts.body)
                        .onSubmit {
                            onAdd()
                        }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(AppFonts.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                Spacer()
            }
            .padding(AppSpacing.m)
            .navigationTitle("Add Allergen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.secondaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        onAdd()
                    }
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.accent)
                    .disabled(newAllergenName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
} 