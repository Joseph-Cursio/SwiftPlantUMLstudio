import Foundation

enum TrafficLightColor {
    case red
    case yellow
    case green
}

final class TrafficLight {
    var color: TrafficLightColor = .red

    func advance() {
        switch self.color {
        case .red:
            self.color = .green
        case .green:
            self.color = .yellow
        case .yellow:
            self.color = .red
        }
    }
}
