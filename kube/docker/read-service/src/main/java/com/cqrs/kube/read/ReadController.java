package com.cqrs.kube.read;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/read")
@CrossOrigin(origins = "*")
public class ReadController {
    
    @Autowired
    private OrderViewRepository orderViewRepository;
    
    @GetMapping("/orders/{orderId}")
    public ResponseEntity<Map<String, Object>> getOrderById(@PathVariable String orderId) {
        try {
            OrderView order = orderViewRepository.findByOrderId(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));
            
            Map<String, Object> response = new HashMap<>();
            response.put("message", "Order retrieved successfully");
            response.put("order", order);
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Order not found");
            response.put("orderId", orderId);
            response.put("message", e.getMessage());
            return ResponseEntity.notFound().build();
        }
    }
    
    @GetMapping("/customers/{customerId}/orders")
    public ResponseEntity<Map<String, Object>> getOrdersByCustomer(@PathVariable String customerId) {
        try {
            List<OrderView> orders = orderViewRepository.findByCustomerIdOrderByCreatedAtDesc(customerId);
            long totalOrders = orderViewRepository.countByCustomerId(customerId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("message", "Customer orders retrieved successfully");
            response.put("customerId", customerId);
            response.put("orders", orders);
            response.put("totalOrders", totalOrders);
            response.put("count", orders.size());
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Failed to retrieve customer orders");
            response.put("customerId", customerId);
            response.put("message", e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }
    
    @GetMapping("/customers/{customerId}/orders/status/{status}")
    public ResponseEntity<Map<String, Object>> getOrdersByCustomerAndStatus(
            @PathVariable String customerId, @PathVariable String status) {
        try {
            List<OrderView> orders = orderViewRepository.findByCustomerIdAndStatus(customerId, status);
            
            Map<String, Object> response = new HashMap<>();
            response.put("message", "Customer orders by status retrieved successfully");
            response.put("customerId", customerId);
            response.put("status", status);
            response.put("orders", orders);
            response.put("count", orders.size());
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Failed to retrieve customer orders by status");
            response.put("customerId", customerId);
            response.put("status", status);
            response.put("message", e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }
    
    @GetMapping("/orders/status/{status}")
    public ResponseEntity<Map<String, Object>> getOrdersByStatus(@PathVariable String status) {
        try {
            List<OrderView> orders = orderViewRepository.findByStatus(status);
            
            Map<String, Object> response = new HashMap<>();
            response.put("message", "Orders by status retrieved successfully");
            response.put("status", status);
            response.put("orders", orders);
            response.put("count", orders.size());
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Failed to retrieve orders by status");
            response.put("status", status);
            response.put("message", e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }
    
    @GetMapping("/orders/recent")
    public ResponseEntity<Map<String, Object>> getRecentOrders(@RequestParam(defaultValue = "1") int hours) {
        try {
            LocalDateTime since = LocalDateTime.now().minusHours(hours);
            List<OrderView> orders = orderViewRepository.findOrdersAfter(since);
            
            Map<String, Object> response = new HashMap<>();
            response.put("message", "Recent orders retrieved successfully");
            response.put("since", since);
            response.put("hours", hours);
            response.put("orders", orders);
            response.put("count", orders.size());
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Failed to retrieve recent orders");
            response.put("message", e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }
    
    @GetMapping("/orders/synced")
    public ResponseEntity<Map<String, Object>> getRecentlySyncedOrders(@RequestParam(defaultValue = "1") int hours) {
        try {
            LocalDateTime since = LocalDateTime.now().minusHours(hours);
            List<OrderView> orders = orderViewRepository.findRecentlySynced(since);
            
            Map<String, Object> response = new HashMap<>();
            response.put("message", "Recently synced orders retrieved successfully");
            response.put("since", since);
            response.put("hours", hours);
            response.put("orders", orders);
            response.put("count", orders.size());
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Failed to retrieve recently synced orders");
            response.put("message", e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }
    
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "UP");
        response.put("service", "read-service");
        response.put("timestamp", System.currentTimeMillis());
        return ResponseEntity.ok(response);
    }
}