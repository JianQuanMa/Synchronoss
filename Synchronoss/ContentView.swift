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
        ImageFeedView(
            state: viewModel.imageFeedViewState,
            action: {
                viewModel.onImageFeedViewAction($0)
            }
        )
    }
}

struct ImageFeedView: View {
    
    enum State: Equatable {
        case loading
        case failed(_ isRetrying: Bool)
        case list([ImageItem], _ isPaginating: Bool)
    }
    
    enum Action {
        case onAppear
        case onRetryButtonTapped
        
        case onItemAppear(ImageItem.ID)
        case onImageSuccess(Image, ImageItem)
        // privates
        case onImagesResponse(Result<[APIImageItem], Error>)
    }
    
    let state: State
    let action: (Action) -> Void
    
    var body: some View {
        
        VStack {
            switch state {
            case .loading:
                ProgressView()
            case .failed(let isLoading):
                Button {
                    action(.onRetryButtonTapped)
                } label: {
                    HStack(spacing: 8) {
                        Text(isLoading ? "Retrying..." : "Retry")
                        
                        if isLoading {
                            ProgressView()
                        }
                    }
                }
                .disabled(isLoading)
                
            case .list(let array, let isPaginating):
                ScrollView {
                    LazyVStack(alignment: .leading) {
                        ForEach(array) { item in
                            listRow(
                                item,
                                in: array,
                                isPaginating: isPaginating,
                                onImageSuccess: {
                                    action(.onImageSuccess($0, $1))
                                }
                            )
                            .onAppear {
                                action(.onItemAppear(item.id))
                            }
                            .padding(16)
                        }
                    }
                }
            }
        }
        .onAppear {
            action(.onAppear)
        }
        
    }
    private func listRow(
        _ item: ImageItem,
        in items: [ImageItem],
        isPaginating: Bool,
        onImageSuccess: @escaping (Image, ImageItem) -> Void
    ) -> some View {
        VStack(alignment: .leading) {
            HStack(spacing: 16) {
                
                switch item.urlOrImage {
                case .url(let uRL):
                    
                    AsyncImage(url: uRL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 100, height: 100)
                        case .success(let image):
                            image.resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(radius: 5)
                                .onAppear {
                                    onImageSuccess(image, item)
                                }
                            
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                case .image(let image):
                    image.resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(radius: 5)
                        .onAppear {
                            onImageSuccess(image, item)
                        }
                }
                
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.author)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("ID: \(item.id)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            
            if item.id == items.last?.id && isPaginating {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 16)
            }
        }
    }
}

#Preview {
    ImageFeedFeature()
}
