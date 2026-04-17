package com.pia;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * Entry point for the PIA backend application.
 *
 * EnableScheduling activates Spring's scheduled task executor,
 * used for periodic listing refreshes, stale checks, and digest emails.
 *
 * ConfigurationPropertiesScan picks up all @ConfigurationProperties
 * classes automatically without manual @EnableConfigurationProperties.
 */
@SpringBootApplication
@EnableScheduling
@ConfigurationPropertiesScan
public class PiaApplication {

    public static void main(String[] args) {
        SpringApplication.run(PiaApplication.class, args);
    }
}
