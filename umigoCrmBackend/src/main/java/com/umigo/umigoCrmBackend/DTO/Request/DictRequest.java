package com.umigo.umigoCrmBackend.DTO.Request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class DictRequest {
    private Integer id;
    @NotBlank(message = "dictionary code is not null")
    private String code;
    // @NotBlank(message = "dictionary name is not null")
    private String name;
    /**
     * @see com.umigo.umigoCrmBackend.Common.Enums.CategoryEnum
     * Dictionary category
     */
    @NotBlank(message = "dictionary category is not null")
    private String category;
}
