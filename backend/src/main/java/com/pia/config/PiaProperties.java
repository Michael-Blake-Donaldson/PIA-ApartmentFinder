package com.pia.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Strongly-typed binding for all pia.* properties.
 * Using records keeps this immutable and concise.
 */
@ConfigurationProperties(prefix = "pia")
public record PiaProperties(
        JwtProperties jwt,
        MailProperties mail,
        AppProperties app,
        ParserProperties parser,
        GeocodingProperties geocoding,
        AdminProperties admin,
        SchedulerProperties scheduler
) {
    public record JwtProperties(
            String secret,
            long expirationMs,
            long refreshExpirationMs
    ) {}

    public record MailProperties(String from) {}

    public record AppProperties(String baseUrl, String name) {}

    public record ParserProperties(
            int requestTimeoutSeconds,
            int maxRetries,
            int rateLimitRps
    ) {}

    public record GeocodingProperties(
            String provider,
            String nominatimBaseUrl,
            String googleApiKey
    ) {}

    public record AdminProperties(
            String initialEmail,
            String initialPassword
    ) {}

    public record SchedulerProperties(
            String listingRefreshCron,
            String staleCheckCron,
            String digestEmailCron
    ) {}
}
