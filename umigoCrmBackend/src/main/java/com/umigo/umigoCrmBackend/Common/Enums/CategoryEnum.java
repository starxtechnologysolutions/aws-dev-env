package com.umigo.umigoCrmBackend.Common.Enums;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public enum CategoryEnum {

    BRAND_MODEL("BRAND_MODEL"),
    COLOR("COLOR"),
    TYPE("TYPE"),
    INSURANCE_PROVIDER("INSURANCE_PROVIDER"),
    PICK_UP_POINT("PICK_UP_POINT"),
    RETURN_POINT("RETURN_POINT");

    private final String code;

    public static CategoryEnum getByCode(String code) {
        if (code == null) {
            return null;
        }
        for (CategoryEnum categoryEnum : CategoryEnum.values()) {
            if (categoryEnum.code.equalsIgnoreCase(code) || categoryEnum.name().equalsIgnoreCase(code)) {
                return categoryEnum;
            }
        }
        return null;
    }

}
