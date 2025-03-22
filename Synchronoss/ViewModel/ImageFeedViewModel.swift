//
//  ImageFeedViewModel.swift
//  Synchronoss
//
//  Created by Jian Ma on 3/21/25.
//
import SwiftUI

@MainActor
final class ImageFeedViewModel: ObservableObject {
    enum Reason {
        case onAppear
        case onRetry
        case paginate([APIImageItem], _ page: Int)
    }
    
    enum FetchStatus {
        case loading(Reason)
        case idle
        case response(Result<[APIImageItem], Error>)
        
        var isInFlight: Bool {
            switch self {
            case .loading:
                true
            case .idle, .response:
                false
            }
        }
    }
    
    @Published var page = 1
    @Published private var imageFetchStatus: FetchStatus = .idle
    private let client: ListClient  //.succeedAfter(4)
    
    // not published, because its not a reason to re-render.
    private var imageCache: [String: Image]
    
    init(
        client: ListClient = .live,
        page: Int = 1,
        imageFetchStatus: FetchStatus = .idle,
        imageCache: [String : Image] = [:]
    ) {
        self.client = client
        self.page = page
        self.imageFetchStatus = imageFetchStatus
        self.imageCache = imageCache
    }
    
    var imageFeedViewState: ImageFeedView.State {
        switch imageFetchStatus {
        case .loading(let reason):
            switch reason {
            case .onAppear:
                return .loading
            case .onRetry:
                return .failed(true)
            case .paginate(let remoteItems, _):
                
                // use cache..
                
                
                return .list(remoteItems.map { item in
                    ImageItem.init(
                        id: item.id,
                        author: item.author,
                        urlOrImage: imageCache[item.id]
                            .map(ImageItem.URLOrImage.image) ??
                            .url(item.url)
                    )
                }, true)
            }
        case .idle:
            return .loading
        case .response(let result):
            switch result {
            case .success(let remoteItems):
                // use cache..
                return .list(remoteItems.map { item in
                    ImageItem(
                        id: item.id,
                        author: item.author,
                        urlOrImage: imageCache[item.id]
                            .map(ImageItem.URLOrImage.image) ??
                            .url(item.url)
                    )
                }, false)
            case .failure:
                return .failed(false)
            }
        }
    }
    
    private var images: [APIImageItem]? {
        switch imageFetchStatus {
        case .response(.success(let items)):
            return items
        default:
            return nil
        }
    }
    
    
    @discardableResult
    func onImageFeedViewAction(_ action: ImageFeedView.Action) -> Task<Void, Never>? {
        print("-=- action \(action)")
        switch action {
        case .onItemAppear(let imageItemID):
            if let images, imageItemID == images.last?.id, !imageFetchStatus.isInFlight {
                return fetch(for: .paginate(images, page))
            }
        case .onAppear:
            return fetch(for: .onAppear)
        case .onImagesResponse(let response):
            imageFetchStatus = .response(response)
            
            switch response {
            case .success:
                page += 1
            case .failure:
                break
            }
        case .onImageSuccess(let image, let item):
            imageCache[item.id] = image
        case .onRetryButtonTapped:
            return fetch(for: .onRetry)
            
        }

        return nil
    }
    
    private func fetch(for reason: Reason) -> Task<Void, Never> {
        Task {
            imageFetchStatus = .loading(reason)
            
            
            let raw = await client.fetch(page)
            
            let result: Result<[APIImageItem], Error>
            switch reason {
            case .onAppear:
                result = raw
            case .onRetry:
                result = raw
            case .paginate(let array, _):
                result = raw.map { items in
                    var copy = array
                    copy.append(contentsOf: items)
                    return copy
                }
            }
            
            onImageFeedViewAction(
                .onImagesResponse(result)
            )
        }
    }
}

