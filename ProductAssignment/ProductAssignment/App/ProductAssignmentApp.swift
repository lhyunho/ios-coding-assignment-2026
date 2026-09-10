//
//  ProductAssignmentApp.swift
//  ProductAssignment
//
//  Created by 이현호 on 9/10/26.
//

import SwiftUI

@main
struct ProductAssignmentApp: App {
    private let productService = ProductService()

    var body: some Scene {
        WindowGroup {
            ProductListView(service: productService)
        }
    }
}
