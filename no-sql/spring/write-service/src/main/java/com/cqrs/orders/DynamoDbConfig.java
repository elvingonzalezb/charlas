package com.cqrs.orders;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;

@Configuration
public class DynamoDbConfig {

    @Value("${aws.region:us-east-1}")
    private String awsRegion;

    @Value("${dynamodb.command.table.name:cqrs-orders-orders-command}")
    private String commandTableName;

    @Bean
    public DynamoDbClient dynamoDbClient() {
        return DynamoDbClient.builder()
            .region(Region.of(awsRegion))
            .build();
    }

    public String getCommandTableName() {
        return commandTableName;
    }
}