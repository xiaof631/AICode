//
//  ContentView.swift
//  AICode
//
//  Created by user on 28/4/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List{
                Section{
                    NavigationLink {
                        StatusView()
                    } label: {
                        Text("打工人时间")
                    }

                }
                Section{
                    NavigationLink {
                        FloatingViewTestView()
                    } label: {
                        Text("弹窗队列")
                    }

                }
                
                Section{
                    NavigationLink {
                        SmartMattingView()
                    } label: {
                        Text("智能扣图")
                    }

                }
            }
        }
    }
}

#Preview {
    ContentView()
}
