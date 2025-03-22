//
//  ContentView.swift
//  Synchronoss
//
//  Created by Jian Ma on 3/21/25.
//

import SwiftUI
struct APIImageItem: Decodable, Equatable {
    let id: String
    let author: String
    
    var url: URL {
        URL(string: "https://picsum.photos/200/300?image=\(id)")!
    }
}
struct ImageItem: Identifiable, Equatable {
    enum URLOrImage: Equatable {
        case url(URL)
        case image(Image)
    }
    
    let id: String
    let author: String
    
    let urlOrImage: URLOrImage
    
    init(id: String, author: String, urlOrImage: ImageItem.URLOrImage) {
        self.id = id
        self.author = author
        self.urlOrImage = urlOrImage
    }
}
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

struct ListClient {
    let fetch: (_ pageNumber: Int) async -> Result<[APIImageItem], Error>
    
    private static let paginationIncrement = 5
    
    static let live = ListClient { page in
        let apiURL = URL(string: "https://picsum.photos/v2/list?page=\(page)&limit=\(paginationIncrement)")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: apiURL)
            let decodedImages = try JSONDecoder().decode([APIImageItem].self, from: data)
            return .success(decodedImages)
        } catch {
            return .failure(error)
        }
    }
    
    
    static func succeedAfter(_ num: Int) -> ListClient {
        var count = 0
        
        return .init { page in
            try? await Task.sleep(for: .seconds(2))
            
            count += 1
            if count < num {
                return .failure(URLError(.badServerResponse))
            }
            
            
            let numberOfMocks = 32
            
            let mocks = (0..<numberOfMocks).map { index in
                let id = String(index)
                return APIImageItem(id: id, author: "some author \(index)")
            }
            
            return .success(mocks)
            
        }
    }
    
    static let mock = ListClient { page in
        //        let apiURL = URL(string: "https://picsum.photos/v2/list?page=1&limit=100")!
        
        do {
            print("-= made ")
            
            try await Task.sleep(for: .seconds(2))
            //            let (data, _) = try await URLSession.shared.data(from: apiURL)
            //            let decodedImages = try JSONDecoder().decode([ImageItem].self, from: data)
            return .failure(URLError(.badServerResponse))
        } catch {
            return .failure(error)
        }
    }
}



#Preview {
    ImageFeedFeature()
}
