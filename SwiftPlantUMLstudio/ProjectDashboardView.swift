import SwiftUI

struct ProjectDashboardView: View {
    let summary: ProjectSummary?
    let insights: [Insight]
    let suggestions: [DiagramSuggestion]
    let onSuggestionTap: (DiagramSuggestion) -> Void

    var body: some View {
        if let summary {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    statsBar(summary: summary)
                    typeBreakdownGrid(summary: summary)
                    if !insights.isEmpty {
                        insightsSection
                    }
                    if !suggestions.isEmpty {
                        suggestionsSection
                    }
                }
                .padding(24)
            }
        } else {
            ContentUnavailableView(
                "No project loaded",
                systemImage: "folder",
                description: Text("Open a folder or Swift files to see project insights.")
            )
        }
    }

    // MARK: - Stats Bar

    private func statsBar(summary: ProjectSummary) -> some View {
        HStack(spacing: 16) {
            statCard(value: summary.totalFiles, label: "Files", icon: "doc.text")
            statCard(value: summary.totalTypes, label: "Types", icon: "rectangle.3.group")
            statCard(value: summary.totalRelationships, label: "Relationships", icon: "arrow.triangle.branch")
            statCard(value: summary.entryPoints.count, label: "Methods", icon: "function")
        }
    }

    private func statCard(value: Int, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.title.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Type Breakdown

    private func typeBreakdownGrid(summary: ProjectSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Type Breakdown")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                ForEach(summary.typeBreakdown.sorted(by: { $0.value > $1.value }), id: \.key) { kind, count in
                    HStack {
                        Text(kind)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(count)")
                            .font(.caption.bold())
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 4))
                }
            }
        }
    }

    // MARK: - Insights

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Insights")
                .font(.headline)
            ForEach(insights) { insight in
                insightRow(insight)
            }
        }
    }

    private func insightRow(_ insight: Insight) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.icon)
                .font(.title3)
                .foregroundStyle(insightColor(insight.severity))
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.body.bold())
                Text(insight.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
    }

    private func insightColor(_ severity: Insight.Severity) -> Color {
        switch severity {
        case .info: .blue
        case .noteworthy: .orange
        case .warning: .red
        }
    }

    // MARK: - Suggestions

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Suggested Diagrams")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 12) {
                ForEach(suggestions) { suggestion in
                    suggestionCard(suggestion)
                }
            }
        }
    }

    private func suggestionCard(_ suggestion: DiagramSuggestion) -> some View {
        Button {
            onSuggestionTap(suggestion)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: suggestion.icon)
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(suggestion.title)
                            .font(.body.bold())
                        if suggestion.requiresPro {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(suggestion.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
