//
//  SynchronossTests.swift
//  SynchronossTests
//
//  Created by Jian Ma on 3/21/25.
//



import XCTest
import SwiftUI
@testable import Synchronoss

@MainActor
final class ImageFeedViewModelTests: XCTestCase {
    func testOnAppear() {
        let (_, viewModel) = makeSUT()
        viewModel.onImageFeedViewAction(.onAppear)
        
        XCTAssertEqual(viewModel.imageFeedViewState, .loading)
    }
    
    func testFetchImagesSuccess() async {
        let apiItemStub = APIImageItem(id: "1", author: "Test Author")
        let (_, viewModel) = makeSUT(apiItemStub: .success([apiItemStub]))

        viewModel.onImageFeedViewAction(.onAppear)

        XCTAssertEqual(viewModel.imageFeedViewState, .loading)
        
        await Task.yield()
        
        XCTAssertEqual(viewModel.imageFeedViewState, .list([
            .init(
                id: apiItemStub.id,
                author: apiItemStub.author,
                urlOrImage: .url(apiItemStub.url))
        ], false))
    }
    
    func testFetchImagesFailure() async {
        let (_, viewModel) = makeSUT(
            apiItemStub: .failure(URLError(.badServerResponse))
        )

        viewModel.onImageFeedViewAction(.onAppear)

        await Task.yield()
        
        switch viewModel.imageFeedViewState {
        case .failed(false):
            XCTAssertTrue(true)
        default:
            XCTFail("Expected failed state")
        }
    }
    
    private func makeSUT(
        apiItemStub: Result<[APIImageItem], Error> = .success([APIImageItem(id: "1", author: "Test Author")])
    ) -> (ListClient, ImageFeedViewModel) {
        let mockClient = ListClient { _ in apiItemStub }
        let viewModel = ImageFeedViewModel(client: mockClient)
        return (mockClient, viewModel)
    }
}
