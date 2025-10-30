package com.umigo.umigoCrmBackend.Common.Result;

import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

import com.umigo.umigoCrmBackend.Common.Enums.ResultCodeEnum;

@Data
@NoArgsConstructor
public class Result implements Serializable {
    private String code;
    private String userMsg;
    private String errorMsg;
    private Object data;

    public static Result success() {
        Result result = new Result();
        result.setCode(ResultCodeEnum.SUCCESS.getCode());
        return result;
    }

    public static Result success(Object data) {
        Result result = new Result();
        result.setCode(ResultCodeEnum.SUCCESS.getCode());
        result.setData(data);
        return result;
    }

    public static Result failure(ResultCode resultCode) {
        Result result = new Result();
        result.setResultCode(resultCode);
        return result;
    }

    public static Result failure(ResultCode resultCode, Object data) {
        Result result = new Result();
        result.setResultCode(resultCode);
        result.setData(data);
        return result;
    }

    public void setResultCode(ResultCode resultCode) {
        this.code = resultCode.getCode();
        this.userMsg = resultCode.getUserMsg();
        this.errorMsg = resultCode.getErrorMsg();
    }
}
