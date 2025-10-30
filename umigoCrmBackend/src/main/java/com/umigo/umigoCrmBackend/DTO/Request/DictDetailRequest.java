package com.umigo.umigoCrmBackend.DTO.Request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class DictDetailRequest {
    private Integer id;

    @NotNull(message = "dict id is not null")
    private Integer dictId;

    /**
     * Dictionary unique code
     */
    @NotBlank(message = "detail code is not null")
    private String detailCode;

    /**
     * Dictionary detail code name
     */
    // @NotBlank(message = "detail name is not null")
    private String detailName;

}
