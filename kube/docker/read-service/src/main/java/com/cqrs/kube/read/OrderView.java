package com.cqrs.kube.read;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Document(collection = "ORDERS")
public class OrderView {
    
    @Id
    private String id;
    
    @Field("order_id")
    private String orderId;
    
    @Field("customer_id")
    private String customerId;
    
    @Field("customer_name")
    private String customerName;
    
    @Field("product_name")
    private String productName;
    
    @Field("quantity")
    private Integer quantity;
    
    @Field("price")
    private BigDecimal price;
    
    @Field("total")
    private BigDecimal total;
    
    @Field("status")
    private String status;
    
    @Field("created_at")
    private LocalDateTime createdAt;
    
    @Field("updated_at")
    private LocalDateTime updatedAt;
    
    @Field("sync_timestamp")
    private LocalDateTime syncTimestamp;
    
    // Constructors
    public OrderView() {}
    
    public OrderView(String orderId, String customerId, String customerName, String productName, 
                    Integer quantity, BigDecimal price, BigDecimal total, String status) {
        this.orderId = orderId;
        this.customerId = customerId;
        this.customerName = customerName;
        this.productName = productName;
        this.quantity = quantity;
        this.price = price;
        this.total = total;
        this.status = status;
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
        this.syncTimestamp = LocalDateTime.now();
    }
    
    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    
    public String getOrderId() { return orderId; }
    public void setOrderId(String orderId) { this.orderId = orderId; }
    
    public String getCustomerId() { return customerId; }
    public void setCustomerId(String customerId) { this.customerId = customerId; }
    
    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }
    
    public String getProductName() { return productName; }
    public void setProductName(String productName) { this.productName = productName; }
    
    public Integer getQuantity() { return quantity; }
    public void setQuantity(Integer quantity) { this.quantity = quantity; }
    
    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }
    
    public BigDecimal getTotal() { return total; }
    public void setTotal(BigDecimal total) { this.total = total; }
    
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
    
    public LocalDateTime getSyncTimestamp() { return syncTimestamp; }
    public void setSyncTimestamp(LocalDateTime syncTimestamp) { this.syncTimestamp = syncTimestamp; }
}