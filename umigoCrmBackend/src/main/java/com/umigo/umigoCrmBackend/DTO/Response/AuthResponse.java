package com.umigo.umigoCrmBackend.DTO.Response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
@AllArgsConstructor(staticName = "of")
public class AuthResponse {
    boolean success;
    String  accessToken;
    String  refreshToken;
    String  message;
    String  mode;            // DRIVER or STAFF
    DriverResponse driver;   // present iff mode=DRIVER
    StaffResponse  staff;    // present iff mode=STAFF

    public static AuthResponse driverOK(String at, String rt, DriverResponse d) {
        return AuthResponse.builder()
                .success(true).accessToken(at).refreshToken(rt)
                .message("OK").mode("DRIVER").driver(d).build();
    }
    public static AuthResponse staffOK(String at, String rt, StaffResponse s) {
        return AuthResponse.builder()
                .success(true).accessToken(at).refreshToken(rt)
                .message("OK").mode("STAFF").staff(s).build();
    }
    public static AuthResponse failure(String msg) {
        return AuthResponse.builder().success(false).message(msg).build();
    }
}