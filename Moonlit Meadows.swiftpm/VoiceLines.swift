import Foundation
import UIKit

// MARK: - Which recording goes with which line

/// The recorded voice lines: one `Voices/<Character>/<ID>.mp3` data set per clip, named by its
/// dialogue ID (like `JUNE-DAILY-EARLY-1`). Lines are found by who says them and their exact
/// text: `voice-lines.txt` lists each line's speaker, its clip IDs and its text. It's generated
/// from the dialogue in the catalogs with the same numbering as the voice scripts.
///
/// A line that mixes narration with speech has two clips (the character's, and the narrator's
/// `-N`), played in the order the text starts with. Your farmer's clips come in `-F` and `-M`.
enum VoiceLines {
    /// The opening story's clips, scene by scene.
    static let intro = ["INTRO-1-N", "INTRO-2-N", "INTRO-3-N", "INTRO-4-HOST", "INTRO-5-N", "INTRO-6-N"]

    private struct Row {
        let owner: String
        /// Usually one set of clips; lines that are word-for-word the same in two places (a
        /// villager's romance and best-friend lines) have one set each.
        let groups: [[String]]
        let text: String
    }

    private static let rows: [Row] = {
        guard let asset = NSDataAsset(name: "voice-lines"), let file = String(data: asset.data, encoding: .utf8) else {
            artLog.error("Missing voice-lines table: no voices will play")
            return []
        }
        return file.split(separator: "\n").compactMap { line -> Row? in
            let fields = line.split(separator: "\t", maxSplits: 2, omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 3 else { return nil }
            let groups = fields[1].split(separator: "|").map { $0.split(separator: ",").map(String.init) }
            return Row(owner: fields[0], groups: groups, text: fields[2])
        }
    }()

    private static let byText: [String: [[String]]] = {
        var table: [String: [[String]]] = [:]
        for row in rows where !isTemplate(row.text) {
            table["\(row.owner)|\(row.text)"] = row.groups
        }
        return table
    }()

    /// Lines with `{bunny}` or `{breed}` in them, matched with the names filled in.
    private static let templates: [(owner: String, pattern: NSRegularExpression, groups: [[String]])] = {
        rows.filter { isTemplate($0.text) }.compactMap { row -> (owner: String, pattern: NSRegularExpression, groups: [[String]])? in
            var pattern = NSRegularExpression.escapedPattern(for: row.text)
            for placeholder in ["{bunny}", "{breed}"] {
                pattern = pattern.replacingOccurrences(of: NSRegularExpression.escapedPattern(for: placeholder), with: ".+?")
            }
            guard let regex = try? NSRegularExpression(pattern: "^\(pattern)$") else { return nil }
            return (row.owner, regex, row.groups)
        }
    }()

    private static func isTemplate(_ text: String) -> Bool {
        text.contains("{bunny}") || text.contains("{breed}")
    }

    private static var loggedMissing: Set<String> = []

    /// The clips for a line on screen. `owner` is a person's ID, `narrator` or `farmer`.
    /// Text with blank lines between parts (a chat line, then a question) plays each part.
    /// `prefer` picks between identical lines, like `BESTIE` over `ROMANCE`.
    static func clips(owner: String, text: String, prefer: String? = nil, farmer gender: FarmerGender? = nil) -> [String] {
        let parts = text.components(separatedBy: "\n\n")
        return parts.flatMap { part -> [String] in
            let line = part.split(whereSeparator: \.isWhitespace).joined(separator: " ")
            guard !line.isEmpty else { return [] }
            guard let groups = lookup(owner: owner, line: line) else {
                let key = "\(owner)|\(line)"
                if !loggedMissing.contains(key) {
                    loggedMissing.insert(key)
                    artLog.notice("No voice line for \(owner, privacy: .public): \(line.prefix(60), privacy: .public)")
                }
                return []
            }
            let ids = groups.first { group in prefer.map { hint in group.contains { $0.contains(hint) } } ?? false }
                ?? groups[0]
            guard owner == "farmer" else { return ids }
            let suffix = gender == .male ? "-M" : "-F"
            return ids.map { $0 + suffix }
        }
    }

    private static func lookup(owner: String, line: String) -> [[String]]? {
        if let groups = byText["\(owner)|\(line)"] { return groups }
        let range = NSRange(line.startIndex..., in: line)
        return templates.first { $0.owner == owner && $0.pattern.firstMatch(in: line, range: range) != nil }?.groups
    }

    /// Every clip the game can play, for the self-check.
    static var allClipIDs: [String] {
        rows.flatMap { row in
            row.groups.flatMap { $0 }.flatMap { id in row.owner == "farmer" ? [id + "-F", id + "-M"] : [id] }
        } + intro
    }

    /// Who's speaking, as a voice owner.
    static func owner(of speaker: ChatSpeaker) -> String {
        switch speaker {
        case .person(let person): return person.id
        case .narrator: return "narrator"
        case .farmer: return "farmer"
        }
    }
}

/// A line said outside the chat screen (like a gift reaction in a toast), for the voice player.
struct VoiceCue: Equatable {
    let id = UUID()
    let owner: String
    let text: String
}
