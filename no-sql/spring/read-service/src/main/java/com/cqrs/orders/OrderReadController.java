package com.cqrs.orders;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/read")
public class OrderReadController {

    @Autowired
    private OrderReadService orderReadService;

    @GetMapping("/customers/{customerId}/orders")
    public ResponseEntity<?> getCustomerOrders(@PathVariable String customerId) {
        try {
            List<OrderQuery> orders = orderReadService.getOrdersByCustomer(customerId);
            
            return ResponseEntity.ok(Map.of(
                "customerId", customerId,
                "orders", orders,
                "count", orders.size()
            ));

        } catch (Exception e) {
            return ResponseEntity.status(500)
                .body(Map.of("error", "Failed to retrieve orders", "message", e.getMessage()));
        }
    }

    @GetMapping("/orders/{orderId}")
    public ResponseEntity<?> getOrder(@PathVariable String orderId) {
        try {
            OrderQuery order = orderReadService.getOrderById(orderId);
            
            if (order == null) {
                return ResponseEntity.notFound().build();
            }
            
            return ResponseEntity.ok(order);

        } catch (Exception e) {
            return ResponseEntity.status(500)
                .body(Map.of("error", "Failed to retrieve order", "message", e.getMessage()));
        }
    }

    @GetMapping("/health")
    public ResponseEntity<?> health() {
        return ResponseEntity.ok(Map.of("status", "UP", "service", "read-service"));
    }
}