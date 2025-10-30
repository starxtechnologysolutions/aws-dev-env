package com.umigo.umigoCrmBackend.Common.Result;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class ResultCode {
    /**
     * Error code
     */
    private String code;
    /**
     * The message of show user
     */
    private String userMsg;
    /**
     * The message of backend debug
     */
    private String errorMsg;

    public static ResultCode getInstance(String code, String userMsg, String errorMsg) {
        return new ResultCode(code, userMsg, errorMsg);
    }

    public static ResultCode getInstance(ResultCode retCode, String userMsg, String errorMsg) {
        return new ResultCode(retCode.getCode(), userMsg, errorMsg);
    }
}
