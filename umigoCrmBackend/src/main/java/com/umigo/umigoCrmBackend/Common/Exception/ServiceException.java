package com.umigo.umigoCrmBackend.Common.Exception;

import com.umigo.umigoCrmBackend.Common.Result.ResultCode;

public class ServiceException extends Exception {
    private ResultCode retCode;

    public ServiceException(ResultCode ret) {
        super("Error code：" + ret.getCode() + "，Error msg：" + ret.getErrorMsg() + "，User msg：" + ret.getUserMsg());
        this.retCode = ret;
    }

    public ServiceException(ResultCode ret, String errorMsg) {
        super("Error code：" + ret.getCode() + "，Error msg：" + errorMsg + "，User msg：" + ret.getUserMsg());
        ret.setErrorMsg(errorMsg);
        this.retCode = ret;
    }

    public ResultCode getRetCode() {
        return this.retCode;
    }}
