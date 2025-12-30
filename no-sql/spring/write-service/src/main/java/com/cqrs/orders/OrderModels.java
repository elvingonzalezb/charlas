package com.cqrs.orders;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import java.math.BigDecimal;
import java.util.List;

class CreateOrderRequest {
    @NotBlank(message = "Customer ID is required")
    private String customerId;
    
    @NotNull(message = "Total is required")
    @Positive(message = "Total must be positive")
    private BigDecimal total;
    
    private List<OrderItem> items;

    // Getters and setters
    public String getCustomerId() { return customerId; }
    public void setCustomerId(String customerId) { this.customerId = customerId; }
    
    public BigDecimal getTotal() { return total; }
    public void setTotal(BigDecimal total) { this.total = total; }
    
    public List<OrderItem> getItems() { return items; }
    public void setItems(List<OrderItem> items) { this.items = items; }
}

class OrderItem {
    private String productId;
    private Integer quantity;
    private BigDecimal price;

    // Getters and setters
    public String getProductId() { return productId; }
    public void setProductId(String productId) { this.productId = productId; }
    
    public Integer getQuantity() { return quantity; }
    public void setQuantity(Integer quantity) { this.quantity = quantity; }
    
    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }
}

class OrderCommand {
    private String orderId;
    private String customerId;
    private BigDecimal total;
    private List<OrderItem> items;
    private String status;

    private OrderCommand(Builder builder) {
        this.orderId = builder.orderId;
        this.customerId = builder.customerId;
        this.total = builder.total;
        this.items = builder.items;
        this.status = builder.status;
    }

    public static Builder builder() {
        return new Builder();
    }

    public static class Builder {
        private String orderId;
        private String customerId;
        private BigDecimal total;
        private List<OrderItem> items;
        private String status;

        public Builder orderId(String orderId) { this.orderId = orderId; return this; }
        public Builder customerId(String customerId) { this.customerId = customerId; return this; }
        public Builder total(BigDecimal total) { this.total = total; return this; }
        public Builder items(List<OrderItem> items) { this.items = items; return this; }
        public Builder status(String status) { this.status = status; return this; }

        public OrderCommand build() {
            return new OrderCommand(this);
        }
    }

    // Getters
    public String getOrderId() { return orderId; }
    public String getCustomerId() { return customerId; }
    public BigDecimal getTotal() { return total; }
    public List<OrderItem> getItems() { return items; }
    public String getStatus() { return status; }
}