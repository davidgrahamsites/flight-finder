import Foundation

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        var index = 0
        var chunks: [[Element]] = []
        chunks.reserveCapacity((count / size) + 1)

        while index < count {
            let end = Swift.min(index + size, count)
            chunks.append(Array(self[index..<end]))
            index = end
        }

        return chunks
    }
}
