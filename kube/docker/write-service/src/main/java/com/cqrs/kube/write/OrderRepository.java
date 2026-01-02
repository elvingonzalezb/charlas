package com.cqrs.kube.write;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface OrderRepository extends MongoRepository<Order, String> {
    
    Optional<Order> findByOrderId(String orderId);
    
    List<Order> findByCustomerId(String customerId);
    
    List<Order> findByStatus(String status);
    
    @Query("{ 'createdAt': { $gte: ?0 } }")
    List<Order> findByCreatedAtAfter(LocalDateTime dateTime);
    
    boolean existsByOrderId(String orderId);
}