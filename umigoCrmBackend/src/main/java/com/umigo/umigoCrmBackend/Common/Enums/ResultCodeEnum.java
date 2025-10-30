package com.umigo.umigoCrmBackend.Common.Enums;

import com.umigo.umigoCrmBackend.Common.Result.ResultCode;

public interface ResultCodeEnum {
    ResultCode SUCCESS = ResultCode.getInstance("0000", "操作成功", "操作成功");
    ResultCode COMMON_INTERNAL_SERVER_ERROR = ResultCode.getInstance("1000", "系统出小差了，稍后重试", "服务器内部错误");
    ResultCode COMMON_PARAM_ERROR = ResultCode.getInstance("2000", "参数校验错误", "参数校验错误");
    ResultCode COMMON_TOKEN_INVALID_ERROR = ResultCode.getInstance("3000", "登录已失效，请重新登录", "用户登录Token已失效");
}
