//
//  APIImageDetail.swift
//  Synchronoss
//
//  Created by Jian Ma on 3/31/25.
//

import Foundation

struct APIImageDetail: Codable {
    let id: String
    let author: String
    let width: Int
    let height: Int
    let url: URL
    let downloadUrl: URL
}
