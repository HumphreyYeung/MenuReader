//
//  HistoryView.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import SwiftUI

struct HistoryView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                Image(systemName: "clock.circle")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)
                
                Text("扫描历史")
                    .font(.title2)
                    .padding()
                
                Text("此功能将在任务12中实现")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("历史记录")
        }
    }
}

#Preview {
    HistoryView()
} 