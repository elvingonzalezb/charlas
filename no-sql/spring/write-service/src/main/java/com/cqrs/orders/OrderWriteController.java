package com.cqrs.orders;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/write")
public class OrderWriteController {

    @Autowired
    private OrderWriteService orderWriteService;

    @PostMapping("/orders")
    public ResponseEntity<?> createOrder(@Valid @RequestBody CreateOrderRequest request) {
        try {
            String orderId = UUID.randomUUID().toString();
            
            OrderCommand order = OrderCommand.builder()
                .orderId(orderId)
                .customerId(request.getCustomerId())
                .total(request.getTotal())
                .items(request.getItems())
                .status("CREATED")
                .build();

            orderWriteService.createOrder(order);

            return ResponseEntity.status(HttpStatus.CREATED)
                .body(Map.of(
                    "orderId", orderId,
                    "status", "CREATED",
                    "message", "Order created successfully"
                ));

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Failed to create order", "message", e.getMessage()));
        }
    }

    @GetMapping("/health")
    public ResponseEntity<?> health() {
        return ResponseEntity.ok(Map.of("status", "UP", "service", "write-service"));
    }
}