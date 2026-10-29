/// Binary heap. `precedes(a,b)` is true when a must be removed before b.
/// Equal priorities have unspecified order. The comparator must be a strict ordering.
public struct PriorityQueue<Element> {
    private var heap: [Element] = []
    private let precedes: (Element, Element) -> Bool
    public init(sort: @escaping (Element, Element) -> Bool) {
        precedes = sort
    }

    public var count: Int {
        heap.count
    }

    public var isEmpty: Bool {
        heap.isEmpty
    }

    public func peek() -> Element? {
        heap.first
    }

    public mutating func enqueue(_ value: Element) {
        heap.append(value)
        var child = heap.count - 1
        while child > 0 {
            let parent = (child - 1) / 2
            guard precedes(heap[child], heap[parent]) else {
                break
            }
            heap.swapAt(child, parent)
            child = parent
        }
    }

    public mutating func dequeue() -> Element? {
        guard !heap.isEmpty else {
            return nil
        }
        if heap.count == 1 {
            return heap.removeLast()
        }
        heap.swapAt(0, heap.count - 1)
        let result = heap.removeLast()
        var parent = 0
        while parent * 2 + 1 < heap.count {
            let left = parent * 2 + 1, right = left + 1
            let best = right < heap.count && precedes(heap[right], heap[left]) ? right : left
            guard precedes(heap[best], heap[parent]) else {
                break
            }
            heap.swapAt(best, parent)
            parent = best
        }
        return result
    }
}
