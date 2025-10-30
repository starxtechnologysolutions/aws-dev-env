package com.umigo.umigoCrmBackend.Common.Enums;

import com.umigo.umigoCrmBackend.Common.Result.ResultCode;

public interface DictResultCodeEnum extends ResultCodeEnum {

    String PREFIX = "dict".toUpperCase();

    ResultCode DICT_CODE_IS_EXISTS = ResultCode.getInstance(PREFIX+"_1000", "Dictionary addition failed", "The dictionary unique code already exists");
    ResultCode DICT_DETAIL_CODE_IS_EXISTS = ResultCode.getInstance(PREFIX+"_1001", "Dictionary addition failed", "The dictionary unique detail code already exists");
    ResultCode DICT_CATEGORY_IS_EXISTS = ResultCode.getInstance(PREFIX+"_1002", "Dictionary addition failed", "The dictionary category is not exists");
}
