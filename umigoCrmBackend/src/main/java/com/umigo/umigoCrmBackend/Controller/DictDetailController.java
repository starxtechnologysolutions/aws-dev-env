package com.umigo.umigoCrmBackend.Controller;

import com.umigo.umigoCrmBackend.Common.Exception.ServiceException;
import com.umigo.umigoCrmBackend.Common.Result.Result;
import com.umigo.umigoCrmBackend.DTO.Request.DictDetailRequest;
import com.umigo.umigoCrmBackend.Service.DictDetailService;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;

@RequestMapping("/dict/dictDetail")
@RestController
public class DictDetailController {
    @Resource
    private DictDetailService dictDetailService;

    @PostMapping("/save")
    public Result save(@RequestBody @Valid DictDetailRequest dictDetailRequest) throws ServiceException {
        return Result.success(dictDetailService.save(dictDetailRequest));
    }

    @GetMapping("/getPageList")
    public Result getPageList() {
        return Result.success(dictDetailService.getPageList());
    }

    @DeleteMapping("/delete/{id}")
    public Result deleteById(@PathVariable("id") Integer id) {
        dictDetailService.deleteByIds(Arrays.asList(id));
        return Result.success();
    }

    @GetMapping("/searchListByDictId/{dictId}")
    public Result searchListByDictId(@PathVariable("dictId") Integer dictId) {
        return Result.success(dictDetailService.findByDictId(dictId));
    }
}
