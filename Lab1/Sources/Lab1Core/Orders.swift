public struct Order: Equatable, Sendable {
    public let id: Int
    public let customer: String
    public let amount: Double
    public let isPaid: Bool
    public let promoCode: String?
    public init(id: Int, customer: String, amount: Double, isPaid: Bool, promoCode: String?) {
        self.id = id; self.customer = customer; self.amount = amount
        self.isPaid = isPaid; self.promoCode = promoCode
    }
}
public enum OrderAnalytics {
    public static func paidAmounts(_ orders: [Order]) -> [Double] {
        orders.filter(\.isPaid).map(\.amount)
    }
    public static func unpaidTotal(_ orders: [Order]) -> Double {
        orders.filter { !$0.isPaid }.reduce(0) { $0 + $1.amount }
    }
    public static func customers(_ orders: [Order]) -> [String] {
        Set(orders.map(\.customer)).sorted()
    }
    public static func promoCodes(_ orders: [Order]) -> [String] {
        orders.compactMap(\.promoCode)
    }
    public static func grouped(_ orders: [Order]) -> [String: [Order]] {
        Dictionary(grouping: orders, by: \.customer)
    }
    // Equal totals are resolved alphabetically, independently of Dictionary iteration order.
    public static func bestPaidCustomer(_ orders: [Order]) -> String? {
        grouped(orders.filter(\.isPaid))
            .map { (name: $0.key, total: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.total == $1.total ? $0.name < $1.name : $0.total > $1.total }
            .first?.name
    }
    public static let example = [
        Order(id: 1, customer: "Анна", amount: 1200, isPaid: true, promoCode: "SALE10"),
        Order(id: 2, customer: "Иван", amount: 800, isPaid: false, promoCode: nil),
        Order(id: 3, customer: "Анна", amount: 5400, isPaid: true, promoCode: nil),
        Order(id: 4, customer: "Олег", amount: 300, isPaid: true, promoCode: "NEW"),
        Order(id: 5, customer: "Иван", amount: 2100, isPaid: false, promoCode: "SALE10")
    ]
}
