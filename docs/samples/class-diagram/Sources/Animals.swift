import Foundation

protocol Greeter {
    func greet() -> String
}

class Animal {
    let name: String

    init(name: String) {
        self.name = name
    }
}

class Dog: Animal, Greeter {
    func greet() -> String {
        "Woof! I'm \(name)."
    }
}

class Cat: Animal, Greeter {
    func greet() -> String {
        "Meow. I am \(name)."
    }
}

extension Dog {
    func fetch() {
        print("\(name) fetches the ball.")
    }
}
