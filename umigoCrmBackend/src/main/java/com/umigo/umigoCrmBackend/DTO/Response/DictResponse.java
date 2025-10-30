package com.umigo.umigoCrmBackend.DTO.Response;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.time.OffsetDateTime;

@Data
public class DictResponse {

    private Integer id;

    /**
     * Dictionary unique code
     */
    private String code;

    /**
     * Dictionary name
     */
    private String name;

    /**
     * @see com.umigo.umigoCrmBackend.Common.Enums.CategoryEnum
     * Dictionary category
     */
    private String category;

    // ISO-8601 in JSON (e.g., "2025-10-28T12:34:56+11:00")
    @JsonFormat(shape = JsonFormat.Shape.STRING)
    private OffsetDateTime createdAt;

    // ISO-8601 in JSON (e.g., "2025-10-28T12:34:56+11:00")
    @JsonFormat(shape = JsonFormat.Shape.STRING)
    private OffsetDateTime updatedAt;
}
