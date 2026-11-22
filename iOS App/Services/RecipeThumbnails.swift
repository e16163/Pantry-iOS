import CoreGraphics
import Foundation
import ImageIO
import ImagePlayground
import UniformTypeIdentifiers

/// Draws a food illustration for each recipe with Image Playground, on device, and caches it on disk by title,
/// so suggested and favorite recipes alike get one and keep it.
/// Returns nil where Image Playground can't run (simulator, no Apple Intelligence); callers keep the emoji tile.
final class RecipeThumbnails {
    static let shared = RecipeThumbnails()

    private var memory: [String: CGImage] = [:]
    private var inFlight: [String: Task<CGImage?, Never>] = [:]
    /// Image Playground makes one image at a time, so requests wait in line behind this.
    private var queueTail: Task<Void, Never>?
    private var isUnavailable = false
    private let folder = URL.cachesDirectory.appending(path: "RecipeThumbnails", directoryHint: .isDirectory)

    func image(title: String, ingredients: [String]) async -> CGImage? {
        if let cached = memory[title] { return cached }
        if let disk = load(title) {
            memory[title] = disk
            return disk
        }
        if isUnavailable { return nil }
        if let running = inFlight[title] { return await running.value }

        let previous = queueTail
        let task = Task { () -> CGImage? in
            await previous?.value
            return await generate(title: title, ingredients: ingredients)
        }
        inFlight[title] = task
        queueTail = Task { _ = await task.value }
        let image = await task.value
        inFlight[title] = nil
        if let image {
            memory[title] = image
            save(image, title)
        }
        return image
    }

    private func generate(title: String, ingredients: [String]) async -> CGImage? {
        guard !isUnavailable else { return nil }
        let creator: ImageCreator
        do {
            creator = try await ImageCreator()
        } catch {
            isUnavailable = true
            return nil
        }
        guard let style = [.illustration, .animation].first(where: creator.availableStyles.contains) else {
            isUnavailable = true
            return nil
        }
        let prompt = "\(title), a plated home-cooked dish with \(ingredients.prefix(4).joined(separator: ", "))"
        do {
            for try await image in creator.images(for: [.text(prompt)], style: style, limit: 1) {
                return image.cgImage
            }
        } catch {
            // A refused or failed prompt keeps the emoji tile; it's retried on a later launch.
        }
        return nil
    }

    // MARK: Disk cache

    /// Stable file name for a title: lowercase letters and digits only, with a length cap.
    static func fileName(for title: String) -> String {
        let slug = title.lowercased().unicodeScalars.map { CharacterSet.alphanumerics.contains($0) ? String($0) : "-" }.joined()
        return String(slug.prefix(80)) + ".png"
    }

    private func url(_ title: String) -> URL { folder.appending(path: Self.fileName(for: title)) }

    private func load(_ title: String) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url(title) as CFURL, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    private func save(_ image: CGImage, _ title: String) {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        guard let destination = CGImageDestinationCreateWithURL(url(title) as CFURL, UTType.png.identifier as CFString, 1, nil)
        else { return }
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
    }
}
