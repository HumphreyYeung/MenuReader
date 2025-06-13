//
//  ProfileView.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                Image(systemName: "person.circle")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)
                
                Text("用户设置")
                    .font(.title2)
                    .padding()
                
                Text("此功能将在任务10中实现")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("个人设置")
        }
    }
}

#Preview {
    ProfileView()
} 