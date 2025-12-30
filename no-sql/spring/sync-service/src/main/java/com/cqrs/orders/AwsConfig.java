package com.cqrs.orders;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;

@Configuration
public class AwsConfig {

    @Value("${aws.region:us-east-1}")
    private String awsRegion;

    @Value("${dynamodb.command.table.name:cqrs-orders-orders-command}")
    private String commandTableName;

    @Value("${dynamodb.query.table.name:cqrs-orders-orders-query}")
    private String queryTableName;

    @Bean
    public DynamoDbClient dynamoDbClient() {
        return DynamoDbClient.builder()
            .region(Region.of(awsRegion))
            .build();
    }

    public String getCommandTableName() {
        return commandTableName;
    }

    public String getQueryTableName() {
        return queryTableName;
    }

    public String getAwsRegion() {
        return awsRegion;
    }
}