package com.umigo.umigoCrmBackend.DTO.Response;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.time.OffsetDateTime;

@Data
public class DictDetailResponse {
    private Integer id;

    /**
     * Dictionary ID
     */
    private Integer dictId;

    /**
     * Dictionary unique code
     */
    private String detailCode;

    /**
     * Dictionary detail code name
     */
    private String detailName;

    // ISO-8601 in JSON (e.g., "2025-10-28T12:34:56+11:00")
    @JsonFormat(shape = JsonFormat.Shape.STRING)
    private OffsetDateTime createdAt;

    // ISO-8601 in JSON (e.g., "2025-10-28T12:34:56+11:00")
    @JsonFormat(shape = JsonFormat.Shape.STRING)
    private OffsetDateTime updatedAt;
}
