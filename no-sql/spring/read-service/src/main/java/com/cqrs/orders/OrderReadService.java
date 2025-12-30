package com.cqrs.orders;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.dynamodb.model.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
public class OrderReadService {

    @Autowired
    private DynamoDbClient dynamoDbClient;

    @Autowired
    private DynamoDbConfig dynamoDbConfig;

    public List<OrderQuery> getOrdersByCustomer(String customerId) {
        QueryRequest queryRequest = QueryRequest.builder()
            .tableName(dynamoDbConfig.getQueryTableName())
            .keyConditionExpression("PK = :pk")
            .expressionAttributeValues(Map.of(
                ":pk", AttributeValue.builder().s("CUSTOMER#" + customerId).build()
            ))
            .scanIndexForward(false) // Most recent first
            .build();

        QueryResponse response = dynamoDbClient.query(queryRequest);
        
        List<OrderQuery> orders = new ArrayList<>();
        for (Map<String, AttributeValue> item : response.items()) {
            orders.add(mapToOrderQuery(item));
        }
        
        return orders;
    }

    public OrderQuery getOrderById(String orderId) {
        // This is a simplified implementation - in practice you might need GSI
        ScanRequest scanRequest = ScanRequest.builder()
            .tableName(dynamoDbConfig.getQueryTableName())
            .filterExpression("orderId = :orderId")
            .expressionAttributeValues(Map.of(
                ":orderId", AttributeValue.builder().s(orderId).build()
            ))
            .limit(1)
            .build();

        ScanResponse response = dynamoDbClient.scan(scanRequest);
        
        if (response.items().isEmpty()) {
            return null;
        }
        
        return mapToOrderQuery(response.items().get(0));
    }

    private OrderQuery mapToOrderQuery(Map<String, AttributeValue> item) {
        OrderQuery order = new OrderQuery();
        
        if (item.containsKey("orderId")) {
            order.setOrderId(item.get("orderId").s());
        }
        if (item.containsKey("customerId")) {
            order.setCustomerId(item.get("customerId").s());
        }
        if (item.containsKey("status")) {
            order.setStatus(item.get("status").s());
        }
        if (item.containsKey("total")) {
            order.setTotal(Double.parseDouble(item.get("total").n()));
        }
        if (item.containsKey("createdAt")) {
            order.setCreatedAt(item.get("createdAt").s());
        }
        if (item.containsKey("updatedAt")) {
            order.setUpdatedAt(item.get("updatedAt").s());
        }
        
        return order;
    }
}