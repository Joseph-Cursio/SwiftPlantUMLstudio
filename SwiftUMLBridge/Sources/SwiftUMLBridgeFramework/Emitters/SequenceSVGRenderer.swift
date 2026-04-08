import Foundation

/// Lays out and renders sequence diagrams as SVG without dagre.
/// Uses a simple timeline layout: participants as columns, messages as horizontal arrows.
public struct SequenceSVGRenderer: Sendable {

    // MARK: - Layout Constants

    private static let participantWidth: Double = 120
    private static let participantHeight: Double = 36
    private static let participantSpacing: Double = 180
    private static let messageSpacing: Double = 40
    private static let topMargin: Double = 20
    private static let leftMargin: Double = 30
    private static let bottomMargin: Double = 40
    private static let lifelineExtension: Double = 20

    // MARK: - Colors

    private static let headerFill = "#4A90D9"
    private static let strokeColor = "#333333"
    private static let textColor = "#FFFFFF"
    private static let bodyTextColor = "#333333"

    // MARK: - Public API

    /// Render a sequence diagram from traversed call edges.
    public static func render(
        traversedEdges: [CallEdge],
        entryType: String,
        entryMethod: String
    ) -> String {
        // Collect participants in order of first appearance
        var participants: [String] = [entryType]
        for edge in traversedEdges {
            if !edge.isUnresolved, let calleeType = edge.calleeType,
               !participants.contains(calleeType) {
                participants.append(calleeType)
            }
        }

        // Calculate dimensions
        let totalWidth = leftMargin * 2 + Double(participants.count) * participantSpacing
        let messagesStartY = topMargin + participantHeight + 20
        let totalMessages = Double(traversedEdges.count)
        let lifelinesEndY = messagesStartY + totalMessages * messageSpacing + lifelineExtension
        let totalHeight = lifelinesEndY + participantHeight + bottomMargin

        // Map participant names to X positions (center of their column)
        var participantX: [String: Double] = [:]
        for (idx, name) in participants.enumerated() {
            participantX[name] = leftMargin + Double(idx) * participantSpacing + participantSpacing / 2
        }

        var svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="\(Int(totalWidth))" height="\(Int(totalHeight))" \
        viewBox="0 0 \(Int(totalWidth)) \(Int(totalHeight))" \
        style="font-family: -apple-system, 'SF Pro Text', 'Helvetica Neue', sans-serif;">
        <defs>
            <marker id="seq-arrow" viewBox="0 0 10 10" refX="10" refY="5" \
            markerWidth="8" markerHeight="8" orient="auto-start-reverse">
                <path d="M 0 0 L 10 5 L 0 10 Z" fill="\(strokeColor)"/>
            </marker>
            <marker id="seq-arrow-open" viewBox="0 0 10 10" refX="10" refY="5" \
            markerWidth="8" markerHeight="8" orient="auto-start-reverse">
                <path d="M 0 1 L 9 5 L 0 9" fill="none" stroke="\(strokeColor)" stroke-width="1.5"/>
            </marker>
        </defs>

        """

        // Title
        svg += "<text x=\"\(Int(totalWidth / 2))\" y=\"14\" text-anchor=\"middle\" "
        svg += "font-size=\"14\" font-weight=\"bold\" fill=\"\(bodyTextColor)\">"
        svg += "\(escapeXML(entryType)).\(escapeXML(entryMethod))</text>\n"

        // Participant boxes (top)
        let boxTopY = topMargin
        for name in participants {
            let centerX = participantX[name]!
            svg += renderParticipantBox(name: name, centerX: centerX, topY: boxTopY)
        }

        // Lifelines
        let lifelineStartY = boxTopY + participantHeight
        for name in participants {
            let centerX = participantX[name]!
            svg += "<line x1=\"\(fmt(centerX))\" y1=\"\(fmt(lifelineStartY))\" "
            svg += "x2=\"\(fmt(centerX))\" y2=\"\(fmt(lifelinesEndY))\" "
            svg += "stroke=\"\(strokeColor)\" stroke-width=\"1\" stroke-dasharray=\"4,3\"/>\n"
        }

        // Messages
        var currentY = messagesStartY
        var lastCallee = entryType
        for edge in traversedEdges {
            if edge.isUnresolved {
                // Render as a note
                let noteX = participantX[lastCallee] ?? participantX[entryType]!
                svg += renderNote(
                    text: "Unresolved: \(edge.calleeMethod)()",
                    centerX: noteX + 60,
                    posY: currentY
                )
            } else if let calleeType = edge.calleeType {
                let fromX = participantX[edge.callerType] ?? leftMargin
                let toX = participantX[calleeType] ?? leftMargin
                svg += renderMessage(
                    label: "\(edge.calleeMethod)()",
                    fromX: fromX,
                    toX: toX,
                    posY: currentY,
                    isAsync: edge.isAsync
                )
                lastCallee = calleeType
            }
            currentY += messageSpacing
        }

        // Participant boxes (bottom)
        let bottomBoxY = lifelinesEndY
        for name in participants {
            let centerX = participantX[name]!
            svg += renderParticipantBox(name: name, centerX: centerX, topY: bottomBoxY)
        }

        svg += "\n</svg>"
        return svg
    }

    // MARK: - Component Rendering

    private static func renderParticipantBox(name: String, centerX: Double, topY: Double) -> String {
        let leftX = centerX - participantWidth / 2
        var svg = "<rect x=\"\(fmt(leftX))\" y=\"\(fmt(topY))\" "
        svg += "width=\"\(fmt(participantWidth))\" height=\"\(fmt(participantHeight))\" "
        svg += "rx=\"4\" ry=\"4\" fill=\"\(headerFill)\" stroke=\"\(strokeColor)\" stroke-width=\"1.5\"/>\n"

        svg += "<text x=\"\(fmt(centerX))\" y=\"\(fmt(topY + participantHeight / 2 + 5))\" "
        svg += "text-anchor=\"middle\" fill=\"\(textColor)\" font-size=\"12\" font-weight=\"bold\">"
        svg += "\(escapeXML(name))</text>\n"

        return svg
    }

    private static func renderMessage(
        label: String,
        fromX: Double,
        toX: Double,
        posY: Double,
        isAsync: Bool
    ) -> String {
        let markerId = isAsync ? "seq-arrow-open" : "seq-arrow"
        let dashArray = isAsync ? " stroke-dasharray=\"4,3\"" : ""

        var svg = ""

        // Handle self-calls
        if abs(fromX - toX) < 1 {
            let loopWidth: Double = 30
            svg += "<path d=\"M \(fmt(fromX)) \(fmt(posY)) "
            svg += "L \(fmt(fromX + loopWidth)) \(fmt(posY)) "
            svg += "L \(fmt(fromX + loopWidth)) \(fmt(posY + 20)) "
            svg += "L \(fmt(fromX)) \(fmt(posY + 20))\" "
            svg += "fill=\"none\" stroke=\"\(strokeColor)\" stroke-width=\"1.2\"\(dashArray) "
            svg += "marker-end=\"url(#\(markerId))\"/>\n"

            svg += "<text x=\"\(fmt(fromX + loopWidth + 4))\" y=\"\(fmt(posY + 12))\" "
            svg += "fill=\"\(bodyTextColor)\" font-size=\"11\">"
            svg += "\(escapeXML(label))</text>\n"
        } else {
            // Arrow line
            svg += "<line x1=\"\(fmt(fromX))\" y1=\"\(fmt(posY))\" "
            svg += "x2=\"\(fmt(toX))\" y2=\"\(fmt(posY))\" "
            svg += "stroke=\"\(strokeColor)\" stroke-width=\"1.2\"\(dashArray) "
            svg += "marker-end=\"url(#\(markerId))\"/>\n"

            // Label above the arrow
            let labelX = (fromX + toX) / 2
            svg += "<text x=\"\(fmt(labelX))\" y=\"\(fmt(posY - 6))\" "
            svg += "text-anchor=\"middle\" fill=\"\(bodyTextColor)\" font-size=\"11\">"
            svg += "\(escapeXML(label))</text>\n"
        }

        return svg
    }

    private static func renderNote(text: String, centerX: Double, posY: Double) -> String {
        let noteWidth: Double = max(Double(text.count) * 7, 100)
        let noteHeight: Double = 24
        let leftX = centerX - noteWidth / 2

        var svg = "<rect x=\"\(fmt(leftX))\" y=\"\(fmt(posY - noteHeight / 2))\" "
        svg += "width=\"\(fmt(noteWidth))\" height=\"\(fmt(noteHeight))\" "
        svg += "rx=\"2\" ry=\"2\" fill=\"#FFFACD\" stroke=\"#CCCC88\" stroke-width=\"1\"/>\n"

        svg += "<text x=\"\(fmt(centerX))\" y=\"\(fmt(posY + 4))\" "
        svg += "text-anchor=\"middle\" fill=\"\(bodyTextColor)\" font-size=\"10\" font-style=\"italic\">"
        svg += "\(escapeXML(text))</text>\n"

        return svg
    }

    // MARK: - Helpers

    private static func escapeXML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private static func fmt(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}
