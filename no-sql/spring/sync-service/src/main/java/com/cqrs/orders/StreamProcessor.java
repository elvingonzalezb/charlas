package com.cqrs.orders;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.dynamodb.model.AttributeValue;
import software.amazon.awssdk.services.dynamodb.model.PutItemRequest;
import software.amazon.awssdk.services.dynamodb.model.ScanRequest;
import software.amazon.awssdk.services.dynamodb.model.ScanResponse;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

@Service
public class StreamProcessor {

    private static final Logger logger = LoggerFactory.getLogger(StreamProcessor.class);

    @Autowired
    private DynamoDbClient dynamoDbClient;

    @Autowired
    private AwsConfig awsConfig;

    private Instant lastProcessedTime = Instant.now().minusSeconds(60); // Start from 1 minute ago

    @Scheduled(fixedDelay = 10000) // Poll every 10 seconds
    public void processNewRecords() {
        try {
            logger.info("Polling for new records in command table since: {}", lastProcessedTime);
            
            // Scan command table for new records
            ScanRequest scanRequest = ScanRequest.builder()
                .tableName(awsConfig.getCommandTableName())
                .filterExpression("updatedAt > :lastProcessed")
                .expressionAttributeValues(Map.of(
                    ":lastProcessed", AttributeValue.builder().s(lastProcessedTime.toString()).build()
                ))
                .build();
            
            ScanResponse scanResponse = dynamoDbClient.scan(scanRequest);
            
            logger.info("Found {} new records to process", scanResponse.items().size());
            
            for (Map<String, AttributeValue> item : scanResponse.items()) {
                processRecord(item);
            }
            
            // Update last processed time
            lastProcessedTime = Instant.now();
            
        } catch (Exception e) {
            logger.error("Error processing new records: {}", e.getMessage(), e);
        }
    }

    private void processRecord(Map<String, AttributeValue> sourceItem) {
        try {
            // Extract data from source item
            String orderId = getStringValue(sourceItem, "orderId");
            String customerId = getStringValue(sourceItem, "customerId");
            String status = getStringValue(sourceItem, "status");
            String total = getStringValue(sourceItem, "total");
            String createdAt = getStringValue(sourceItem, "createdAt");
            String updatedAt = getStringValue(sourceItem, "updatedAt");
            String items = getStringValue(sourceItem, "items");

            if (orderId == null || customerId == null) {
                logger.warn("Skipping record - missing orderId or customerId");
                return;
            }

            logger.info("Processing order: {} for customer: {}", orderId, customerId);

            // Create optimized item for query table (customer-centric)
            Map<String, AttributeValue> queryItem = new HashMap<>();
            queryItem.put("PK", AttributeValue.builder().s("CUSTOMER#" + customerId).build());
            queryItem.put("SK", AttributeValue.builder().s("ORDER#" + orderId).build());
            queryItem.put("orderId", AttributeValue.builder().s(orderId).build());
            queryItem.put("customerId", AttributeValue.builder().s(customerId).build());
            queryItem.put("status", AttributeValue.builder().s(status != null ? status : "UNKNOWN").build());
            queryItem.put("createdAt", AttributeValue.builder().s(createdAt != null ? createdAt : Instant.now().toString()).build());
            queryItem.put("updatedAt", AttributeValue.builder().s(updatedAt != null ? updatedAt : Instant.now().toString()).build());

            if (total != null) {
                queryItem.put("total", AttributeValue.builder().n(total).build());
            }

            if (items != null) {
                queryItem.put("items", AttributeValue.builder().s(items).build());
            }

            // Write to query table
            PutItemRequest putRequest = PutItemRequest.builder()
                .tableName(awsConfig.getQueryTableName())
                .item(queryItem)
                .build();

            dynamoDbClient.putItem(putRequest);
            
            logger.info("✅ Successfully synced order {} for customer {} to query table", 
                       orderId, customerId);

        } catch (Exception e) {
            logger.error("Error syncing record to query table: {}", e.getMessage(), e);
        }
    }

    private String getStringValue(Map<String, AttributeValue> item, String key) {
        AttributeValue value = item.get(key);
        if (value != null) {
            if (value.s() != null) {
                return value.s();
            } else if (value.n() != null) {
                return value.n();
            }
        }
        return null;
    }
}