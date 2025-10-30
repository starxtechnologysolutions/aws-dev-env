package com.umigo.umigoCrmBackend.Common.Exception;

import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseBody;

import com.umigo.umigoCrmBackend.Common.Enums.ResultCodeEnum;
import com.umigo.umigoCrmBackend.Common.Result.Result;

@ControllerAdvice
public class GlobalExceptionHandler {
    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    public GlobalExceptionHandler() {
    }

    @ExceptionHandler(ServiceException.class)
    @ResponseBody
    public Result bizExceptionHandler(HttpServletRequest req, ServiceException e) {
        log.error("Request URI: {} business exception, code: {}", req.getRequestURI(), e.getRetCode(), e);
        return Result.failure(e.getRetCode());
    }

    @ExceptionHandler(Exception.class)
    @ResponseBody
    public Result exceptionHandler(HttpServletRequest req, Exception e) {
        log.error("Request URI: {} unknown exception", req.getRequestURI(), e);
        return Result.failure(ResultCodeEnum.COMMON_INTERNAL_SERVER_ERROR);
    }
}
