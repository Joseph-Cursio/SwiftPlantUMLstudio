import Foundation
import SwiftData

@Model
final class Author {
    var name: String = ""
    @Relationship(deleteRule: .cascade, inverse: \Book.author)
    var books: [Book] = []

    init(name: String) {
        self.name = name
    }
}

@Model
final class Book {
    var title: String = ""
    var author: Author?

    init(title: String, author: Author? = nil) {
        self.title = title
        self.author = author
    }
}
