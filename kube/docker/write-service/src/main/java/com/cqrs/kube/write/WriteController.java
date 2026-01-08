package com.cqrs.kube.write;

import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/write")
@CrossOrigin(origins = "*")
public class WriteController {
    
    @Autowired
    private OrderRepository orderRepository;
    
    @PostMapping("/orders")
    public ResponseEntity<Map<String, Object>> createOrder(@Valid @RequestBody Order order) {
        try {
            // Generate unique order ID if not provided
            if (order.getOrderId() == null || order.getOrderId().isEmpty()) {
                order.setOrderId("ORD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase());
            }
            
            // Check if order ID already exists
            if (orderRepository.existsByOrderId(order.getOrderId())) {
                Map<String, Object> response = new HashMap<>();
                response.put("error", "Order ID already exists");
                response.put("orderId", order.getOrderId());
                return ResponseEntity.status(HttpStatus.CONFLICT).body(response);
            }
            
            // Save order
            Order savedOrder = orderRepository.save(order);
            
            Map<String, Object> response = new HashMap<>();
            response.put("message", "Order created successfully");
            response.put("orderId", savedOrder.getOrderId());
            response.put("customerId", savedOrder.getCustomerId());
            response.put("total", savedOrder.getTotal());
            response.put("status", savedOrder.getStatus());
            response.put("createdAt", savedOrder.getCreatedAt());
            
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
            
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Failed to create order");
            response.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }
    
    @PutMapping("/orders/{orderId}")
    public ResponseEntity<Map<String, Object>> updateOrder(@PathVariable String orderId, @Valid @RequestBody Order orderUpdate) {
        try {
            Order existingOrder = orderRepository.findByOrderId(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));
            
            // Update fields
            if (orderUpdate.getProductName() != null) {
                existingOrder.setProductName(orderUpdate.getProductName());
            }
            if (orderUpdate.getQuantity() != null) {
                existingOrder.setQuantity(orderUpdate.getQuantity());
            }
            if (orderUpdate.getPrice() != null) {
                existingOrder.setPrice(orderUpdate.getPrice());
            }
            if (orderUpdate.getStatus() != null) {
                existingOrder.setStatus(orderUpdate.getStatus());
            }
            
            Order savedOrder = orderRepository.save(existingOrder);
            
            Map<String, Object> response = new HashMap<>();
            response.put("message", "Order updated successfully");
            response.put("orderId", savedOrder.getOrderId());
            response.put("status", savedOrder.getStatus());
            response.put("updatedAt", savedOrder.getUpdatedAt());
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Failed to update order");
            response.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }
    
    @GetMapping("/orders/recent")
    public ResponseEntity<Map<String, Object>> getRecentOrders() {
        try {
            // Get orders from last hour
            LocalDateTime oneHourAgo = LocalDateTime.now().minusHours(1);
            List<Order> orders = orderRepository.findByCreatedAtAfter(oneHourAgo);
            
            Map<String, Object> response = new HashMap<>();
            response.put("message", "Recent orders retrieved successfully");
            response.put("count", orders.size());
            response.put("orders", orders);
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Failed to retrieve orders");
            response.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }
    
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "UP");
        response.put("service", "write-service");
        response.put("timestamp", System.currentTimeMillis());
        return ResponseEntity.ok(response);
    }
}