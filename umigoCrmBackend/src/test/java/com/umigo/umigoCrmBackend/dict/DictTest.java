package com.umigo.umigoCrmBackend.dict;

import com.umigo.umigoCrmBackend.Common.Enums.CategoryEnum;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class DictTest {

    @Test
    void categoryEnumHasExpectedCode() {
        assertEquals("BRAND_MODEL", CategoryEnum.BRAND_MODEL.getCode());
        assertNotNull(CategoryEnum.getByCode("COLOR"));
        assertNull(CategoryEnum.getByCode("UNKNOWN"));
    }
}
