import XCTest
@testable import Lab1Core
final class Lab1Tests: XCTestCase {
    func testRequiredOrderResults() {
        let o = OrderAnalytics.example
        XCTAssertEqual(OrderAnalytics.paidAmounts(o), [1200, 5400, 300])
        XCTAssertEqual(OrderAnalytics.unpaidTotal(o), 2900)
        XCTAssertEqual(OrderAnalytics.customers(o), ["Анна", "Иван", "Олег"])
        XCTAssertEqual(OrderAnalytics.promoCodes(o), ["SALE10", "NEW", "SALE10"])
        XCTAssertEqual(OrderAnalytics.grouped(o)["Анна"]?.map(\.id), [1, 3])
        XCTAssertEqual(OrderAnalytics.bestPaidCustomer(o), "Анна")
    }

    func testEmptyOrdersAndNoPaidOrders() {
        XCTAssertEqual(OrderAnalytics.paidAmounts([]), [])
        XCTAssertEqual(OrderAnalytics.unpaidTotal([]), 0)
        XCTAssertEqual(OrderAnalytics.customers([]), [])
        XCTAssertEqual(OrderAnalytics.promoCodes([]), [])
        XCTAssertTrue(OrderAnalytics.grouped([]).isEmpty)
        XCTAssertNil(OrderAnalytics.bestPaidCustomer([]))
        XCTAssertNil(OrderAnalytics.bestPaidCustomer(OrderAnalytics.example.filter {
            !$0.isPaid
        }))
    }

    func testPaidTieHasDeterministicWinner() {
        let o = [Order(id: 1, customer: "B", amount: 10, isPaid: true, promoCode: nil),
                 Order(id: 2, customer: "A", amount: 10, isPaid: true, promoCode: nil)]
        XCTAssertEqual(OrderAnalytics.bestPaidCustomer(o), "A")
    }

    func testPointMoveDistanceAndHash() {
        var p = Point(x: 3, y: 4)
        XCTAssertEqual(p.distanceToOrigin, 5, accuracy: 0.000001)
        p.move(byX: -3, byY: -4)
        XCTAssertEqual(p, Point(x: 0, y: 0))
        XCTAssertEqual(Set([p, p]).count, 1)
    }

    func testRectangleValidationAndMetrics() {
        let r = Rectangle(origin: Point(x: 2, y: 3), width: 4, height: 6)
        XCTAssertEqual(r.area, 24)
        XCTAssertEqual(r.perimeter, 20)
        XCTAssertEqual(r.center, Point(x: 4, y: 6))
        XCTAssertEqual(Rectangle(origin: r.origin, width: 0, height: -2).area, 1)
        XCTAssertEqual(Rectangle(origin: r.origin, width: .nan, height: .infinity).area, 1)
    }

    func testRectangleBoundaryAndScale() {
        var r = Rectangle(origin: Point(x: -2, y: -1), width: 4, height: 2)
        XCTAssertTrue(r.contains(Point(x: -2, y: -1)))
        XCTAssertTrue(r.contains(Point(x: 2, y: 1)))
        XCTAssertFalse(r.contains(Point(x: 2.1, y: 1)))
        r.scale(by: 2)
        XCTAssertEqual(r.area, 32)
        for f in [0.0, -1, .nan, .infinity] {
            r.scale(by: f)
            XCTAssertEqual(r.area, 32)
        }
    }

    func testMinAndMaxHeapsIncludingDuplicates() {
        let values = [7, -1, 0, 7, 3, 8, 2]
        var minHeap = PriorityQueue<Int>(sort: <), maxHeap = PriorityQueue<Int>(sort: >)
        values.forEach { minHeap.enqueue($0)
            maxHeap.enqueue($0)
        }
        XCTAssertEqual(minHeap.peek(), -1)
        XCTAssertEqual(maxHeap.count, values.count)
        XCTAssertEqual((0 ..< values.count).compactMap { _ in
            minHeap.dequeue()
        }, values.sorted())
        XCTAssertEqual((0 ..< values.count).compactMap { _ in
            maxHeap.dequeue()
        }, values.sorted(by: >))
        XCTAssertTrue(minHeap.isEmpty)
        XCTAssertNil(minHeap.dequeue())
        XCTAssertNil(minHeap.peek())
    }

    func testHeapInterleavingAndCustomType() {
        struct Job { let name: String
            let priority: Int
        }
        var q = PriorityQueue<Job> {
            $0.priority > $1.priority
        }
        q.enqueue(Job(name: "low", priority: 1))
        q.enqueue(Job(name: "high", priority: 10))
        XCTAssertEqual(q.dequeue()?.name, "high")
        q.enqueue(Job(name: "medium", priority: 5))
        XCTAssertEqual(q.dequeue()?.name, "medium")
        XCTAssertEqual(q.dequeue()?.name, "low")
        XCTAssertNil(q.dequeue())
    }

    func testLargeHeap() {
        var q = PriorityQueue<Int>(sort: <)
        (0 ..< 1000).reversed().forEach {
            q.enqueue($0)
        }
        XCTAssertEqual((0 ..< 1000).compactMap { _ in
            q.dequeue()
        }, Array(0 ..< 1000))
    }
}
