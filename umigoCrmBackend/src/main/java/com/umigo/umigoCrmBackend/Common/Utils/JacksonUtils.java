package com.umigo.umigoCrmBackend.Common.Utils;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.TimeZone;

/**
 *
 * @date 2021-04-08
 */
@Slf4j
public class JacksonUtils {

	/**
	 * 对象转json字符串
	 * @param obj
	 * @return
	 */
	public static String obj2json(Object obj) {
		ObjectMapper objectMapper = new ObjectMapper();

		if (obj == null) {
			return null;
		}
		if (obj.getClass() == String.class) {
			return (String) obj;
		}

        try {
            return objectMapper.writeValueAsString(obj);
        } catch (JsonProcessingException e) {
			e.printStackTrace();
			log.error("对象转json字符串出错：" + obj, e);
			return null;
        }
    }

	/**
	 * json转对象
	 * @param json
	 * @param toCls
	 * @param <T>
	 * @return
	 */
	public static <T> T json2obj(String json, Class<T> toCls) {
		ObjectMapper objectMapper = new ObjectMapper();
		try {
			return objectMapper.readValue(json, toCls);
		} catch (IOException e) {
			log.error("json转对象出错：" + json, e);
			return null;
		}
	}

	/**
	 * json转List
	 * <pre>
	 *     例子：
	 *     json = "[20, 15, -1, 22]";
	 *     json2list(json, Integer.class);
	 * </pre>
	 * @param json
	 * @param eClass
	 * @param <E>
	 * @return
	 */
	public static <E> List<E> json2list(String json, Class<E> eClass) {
		ObjectMapper objectMapper = new ObjectMapper();
		try {
			return objectMapper.readValue(json, objectMapper.getTypeFactory().constructCollectionType(List.class, eClass));
		} catch (IOException e) {
			log.error("json转List出错：" + json, e);
			return null;
		}
	}

	/**
	 * json转map
	 * <pre>
	 *     例子：
	 *     json = "{\"name\" : \"历史\", \"id\":123, \"age\":12.2}";
	 *     Map<Object, Object> map = json2map(json, Object.class, Object.class);
	 *
	 * </pre>
	 * @param json
	 * @param kClass
	 * @param vClass
	 * @param <K>
	 * @param <V>
	 * @return
	 */
	public static <K, V> Map<K, V> json2map(String json, Class<K> kClass, Class<V> vClass) {
		ObjectMapper objectMapper = new ObjectMapper();
		try {
			return objectMapper.readValue(json, objectMapper.getTypeFactory().constructMapType(Map.class, kClass, vClass));
		} catch (IOException e) {
			log.error("json转map出错：" + json, e);
			return null;
		}
	}

	/**
	 * Object to json string.
	 *
	 * @param obj obj
	 * @return json string
	 */
	public static String toJson(Object obj) {
		try {
			ObjectMapper objectMapper = new ObjectMapper();
			objectMapper.setTimeZone(TimeZone.getDefault());
			return objectMapper.writeValueAsString(obj);
		} catch (JsonProcessingException e) {
			log.error(obj.getClass() + e.toString());
			return "";
		}
	}

}
