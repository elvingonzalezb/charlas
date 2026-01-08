package com.cqrs.kube.redis;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/redis")
public class RedisController {

    @Autowired
    private RedisService redisService;

    @PostMapping("/set")
    public String setValue(@RequestBody Map<String, String> request) {
        String key = request.get("key");
        String value = request.get("value");
        redisService.setValue(key, value);
        return "OK";
    }

    @GetMapping("/get/{key}")
    public String getValue(@PathVariable String key) {
        return redisService.getValue(key);
    }

    @DeleteMapping("/delete/{key}")
    public String deleteValue(@PathVariable String key) {
        redisService.deleteValue(key);
        return "DELETED";
    }

    @GetMapping("/health")
    public String health() {
        return "OK";
    }
}