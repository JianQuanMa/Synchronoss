//
//  ContentView.swift
//  Synchronoss
//
//  Created by Jian Ma on 3/21/25.
//

import SwiftUI

@MainActor
struct ImageFeedFeature: View {
    @StateObject private var viewModel = ImageFeedViewModel()
    
    var body: some View {
        Text("hello")
    }
}

struct ImageFeedViewModel: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ImageFeedFeature()
}


// testing
