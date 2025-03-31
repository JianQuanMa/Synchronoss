//
//  ListClient.swift
//  Synchronoss
//
//  Created by Jian Ma on 3/21/25.
//

import Foundation

struct ListClient {
    let fetch: (_ pageNumber: Int) async -> Result<[APIImageItem], Error>
    
    let fetchDetails: (_ id: String) async -> Result<APIImageDetail, Error>

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
    } fetchDetails: { id in
        let apiURL = URL(string: "https://picsum.photos/id/\(id)/info")!

        do {
            let (data, _) = try await URLSession.shared.data(from: apiURL)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decodedImages = try decoder.decode(APIImageDetail.self, from: data)
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
            
        } fetchDetails: { _ in
            .failure(URLError(.badServerResponse))
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
    } fetchDetails: { _ in
            .failure(URLError(.badServerResponse))
    }
}
