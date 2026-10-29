import Lab1Core
let orders = OrderAnalytics.example
print("Оплаченные суммы:", OrderAnalytics.paidAmounts(orders))
print("Не оплачено:", OrderAnalytics.unpaidTotal(orders))
print("Клиенты:", OrderAnalytics.customers(orders))
print("Промокоды:", OrderAnalytics.promoCodes(orders))
for name in OrderAnalytics.customers(orders) {
    print(name, "заказы:", OrderAnalytics.grouped(orders)[name]!.map(\.id))
}

print("Лучший клиент:", OrderAnalytics.bestPaidCustomer(orders) ?? "нет")
var point = Point(x: 3, y: 4)
print("Расстояние:", point.distanceToOrigin)
point.move(byX: 1, byY: -1)
var rectangle = Rectangle(origin: Point(x: 0, y: 0), width: 4, height: 2)
rectangle.scale(by: 2)
print("Прямоугольник:", rectangle.area, rectangle.perimeter, rectangle.center, rectangle.contains(point))
var queue = PriorityQueue<Int>(sort: >)
[2, 8, 1, 5].forEach {
    queue.enqueue($0)
}

while let value = queue.dequeue() {
    print("Приоритет:", value)
}
