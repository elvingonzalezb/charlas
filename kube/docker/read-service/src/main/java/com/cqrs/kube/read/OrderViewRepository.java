package com.cqrs.kube.read;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface OrderViewRepository extends MongoRepository<OrderView, String> {
    
    Optional<OrderView> findByOrderId(String orderId);
    
    List<OrderView> findByCustomerId(String customerId);
    
    List<OrderView> findByCustomerIdOrderByCreatedAtDesc(String customerId);
    
    List<OrderView> findByStatus(String status);
    
    @Query("{ 'createdAt' : { $gte: ?0 } }")
    List<OrderView> findOrdersAfter(LocalDateTime dateTime);
    
    @Query("{ 'customerId' : ?0, 'status' : ?1 }")
    List<OrderView> findByCustomerIdAndStatus(String customerId, String status);
    
    @Query("{ 'syncTimestamp' : { $gte: ?0 } }")
    List<OrderView> findRecentlySynced(LocalDateTime dateTime);
    
    long countByCustomerId(String customerId);
    
    @Query(value = "{ 'customerId' : ?0 }", count = true)
    long countOrdersByCustomer(String customerId);
}