package com.example.bank;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.sql.Types;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class BankController {
    
    @Autowired
    private JdbcTemplate jdbcTemplate;
    
    @GetMapping("/test")
    public Map<String, String> test() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "OK");
        response.put("message", "API funcionando correctamente");
        return response;
    }
    
    @PostMapping("/customer")
    public Map<String, Object> createCustomer(@RequestBody Map<String, String> request) {
        try {
            SimpleJdbcCall jdbcCall = new SimpleJdbcCall(jdbcTemplate)
                .withProcedureName("sp_create_customer")
                .declareParameters(
                    new SqlParameter("p_first_name", Types.VARCHAR),
                    new SqlParameter("p_last_name", Types.VARCHAR),
                    new SqlParameter("p_email", Types.VARCHAR),
                    new SqlParameter("p_phone", Types.VARCHAR),
                    new SqlOutParameter("p_customer_id", Types.BIGINT),
                    new SqlOutParameter("p_status", Types.VARCHAR),
                    new SqlOutParameter("p_message", Types.VARCHAR)
                );
            
            Map<String, Object> inParams = new HashMap<>();
            inParams.put("p_first_name", request.get("firstName"));
            inParams.put("p_last_name", request.get("lastName"));
            inParams.put("p_email", request.get("email"));
            inParams.put("p_phone", request.get("phone"));
            
            Map<String, Object> result = jdbcCall.execute(inParams);
            
            Map<String, Object> response = new HashMap<>();
            response.put("customer_id", result.get("p_customer_id"));
            response.put("status", result.get("p_status"));
            response.put("message", result.get("p_message"));
            
            return response;
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", "FAILED");
            response.put("message", "Error: " + e.getMessage());
            return response;
        }
    }
    
    @GetMapping("/customer/{id}")
    public Map<String, Object> getCustomer(@PathVariable Long id) {
        Map<String, Object> response = new HashMap<>();
        try {
            Map<String, Object> customer = jdbcTemplate.queryForMap(
                "SELECT * FROM customers WHERE customer_id = ?", id
            );
            response.put("status", "SUCCESS");
            response.putAll(customer);
        } catch (Exception e) {
            response.put("status", "NOT_FOUND");
            response.put("message", "Cliente no encontrado");
        }
        return response;
    }
    
    @PostMapping("/account")
    public Map<String, Object> createAccount(@RequestBody Map<String, Object> request) {
        try {
            // Generar número de cuenta único
            String accountNumber = "ACC-" + System.currentTimeMillis();
            
            SimpleJdbcCall jdbcCall = new SimpleJdbcCall(jdbcTemplate)
                .withProcedureName("sp_create_account")
                .declareParameters(
                    new SqlParameter("p_customer_id", Types.BIGINT),
                    new SqlParameter("p_account_number", Types.VARCHAR),
                    new SqlParameter("p_account_type", Types.VARCHAR),
                    new SqlParameter("p_initial_balance", Types.DECIMAL),
                    new SqlOutParameter("p_account_id", Types.BIGINT),
                    new SqlOutParameter("p_status", Types.VARCHAR),
                    new SqlOutParameter("p_message", Types.VARCHAR)
                );
            
            Map<String, Object> inParams = new HashMap<>();
            inParams.put("p_customer_id", Long.valueOf(request.get("customerId").toString()));
            inParams.put("p_account_number", accountNumber);
            inParams.put("p_account_type", request.get("accountType").toString());
            inParams.put("p_initial_balance", new BigDecimal(request.get("initialBalance").toString()));
            
            Map<String, Object> result = jdbcCall.execute(inParams);
            
            Map<String, Object> response = new HashMap<>();
            response.put("account_id", result.get("p_account_id"));
            response.put("account_number", accountNumber);
            response.put("status", result.get("p_status"));
            response.put("message", result.get("p_message"));
            
            return response;
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", "FAILED");
            response.put("message", "Error: " + e.getMessage());
            return response;
        }
    }
    
    @GetMapping("/account/{id}")
    public Map<String, Object> getAccount(@PathVariable Long id) {
        Map<String, Object> response = new HashMap<>();
        try {
            Map<String, Object> account = jdbcTemplate.queryForMap(
                "SELECT a.*, c.first_name, c.last_name FROM accounts a JOIN customers c ON a.customer_id = c.customer_id WHERE a.account_id = ?", id
            );
            response.putAll(account);
        } catch (Exception e) {
            response.put("timestamp", System.currentTimeMillis());
            response.put("status", 404);
            response.put("error", "Not Found");
            response.put("path", "/api/account/" + id);
        }
        return response;
    }
    
    @PostMapping("/transfer")
    public Map<String, Object> transfer(@RequestBody Map<String, Object> request) {
        try {
            SimpleJdbcCall jdbcCall = new SimpleJdbcCall(jdbcTemplate)
                .withProcedureName("sp_transfer_funds")
                .declareParameters(
                    new SqlParameter("p_from_account_id", Types.BIGINT),
                    new SqlParameter("p_to_account_id", Types.BIGINT),
                    new SqlParameter("p_amount", Types.DECIMAL),
                    new SqlOutParameter("p_transaction_id", Types.BIGINT),
                    new SqlOutParameter("p_status", Types.VARCHAR),
                    new SqlOutParameter("p_message", Types.VARCHAR)
                );
            
            Map<String, Object> inParams = new HashMap<>();
            inParams.put("p_from_account_id", Long.valueOf(request.get("fromAccountId").toString()));
            inParams.put("p_to_account_id", Long.valueOf(request.get("toAccountId").toString()));
            inParams.put("p_amount", new BigDecimal(request.get("amount").toString()));
            
            Map<String, Object> result = jdbcCall.execute(inParams);
            
            Map<String, Object> response = new HashMap<>();
            response.put("transaction_id", result.get("p_transaction_id"));
            response.put("status", result.get("p_status"));
            response.put("message", result.get("p_message"));
            
            return response;
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("timestamp", System.currentTimeMillis());
            response.put("status", 404);
            response.put("error", "Not Found");
            response.put("path", "/api/transfer");
            return response;
        }
    }
}