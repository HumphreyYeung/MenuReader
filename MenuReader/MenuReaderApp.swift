//
//  MenuReaderApp.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import SwiftUI

@main
struct MenuReaderApp: App {
    var body: some Scene {
        WindowGroup {
            CameraView()
                .preferredColorScheme(.dark) // 相机界面通常使用深色主题
        }
    }
}
