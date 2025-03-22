//
//  ImageItem.swift
//  Synchronoss
//
//  Created by Jian Ma on 3/21/25.
//

import Foundation

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
