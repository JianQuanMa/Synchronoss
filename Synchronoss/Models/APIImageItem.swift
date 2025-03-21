//
//  APIImageItem.swift
//  Synchronoss
//
//  Created by Jian Ma on 3/21/25.
//

import Foundation

struct APIImageItem: Decodable, Equatable {
    let id: String
    let author: String
    
    var url: URL {
        URL(string: "https://picsum.photos/200/300?image=\(id)")!
    }
}
