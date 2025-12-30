package com.cqrs.orders;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.dynamodb.model.*;
import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class OrderWriteService {

    private static final Logger logger = LoggerFactory.getLogger(OrderWriteService.class);

    @Autowired
    private DynamoDbClient dynamoDbClient;

    @Autowired
    private DynamoDbConfig dynamoDbConfig;

    public void createOrder(OrderCommand order) {
        logger.info("Creating order: {}", order.getOrderId());
        logger.info("Using table: {}", dynamoDbConfig.getCommandTableName());
        
        String timestamp = Instant.now().toString();
        
        Map<String, AttributeValue> item = new HashMap<>();
        item.put("PK", AttributeValue.builder().s("ORDER#" + order.getOrderId()).build());
        item.put("SK", AttributeValue.builder().s("STATE").build());
        item.put("orderId", AttributeValue.builder().s(order.getOrderId()).build());
        item.put("customerId", AttributeValue.builder().s(order.getCustomerId()).build());
        item.put("status", AttributeValue.builder().s(order.getStatus()).build());
        item.put("total", AttributeValue.builder().n(order.getTotal().toString()).build());
        item.put("createdAt", AttributeValue.builder().s(timestamp).build());
        item.put("updatedAt", AttributeValue.builder().s(timestamp).build());
        item.put("version", AttributeValue.builder().n("1").build());

        // Add items if present
        if (order.getItems() != null && !order.getItems().isEmpty()) {
            item.put("items", AttributeValue.builder().s(order.getItems().toString()).build());
        }

        PutItemRequest putItemRequest = PutItemRequest.builder()
            .tableName(dynamoDbConfig.getCommandTableName())
            .item(item)
            .conditionExpression("attribute_not_exists(PK)")
            .build();

        try {
            logger.info("Attempting to put item to DynamoDB...");
            PutItemResponse response = dynamoDbClient.putItem(putItemRequest);
            logger.info("Successfully created order in DynamoDB: {}", order.getOrderId());
            logger.info("DynamoDB response: {}", response);
        } catch (ConditionalCheckFailedException e) {
            logger.error("Order already exists: {}", order.getOrderId());
            throw new RuntimeException("Order already exists: " + order.getOrderId());
        } catch (Exception e) {
            logger.error("Error creating order in DynamoDB: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to create order: " + e.getMessage());
        }
    }
}