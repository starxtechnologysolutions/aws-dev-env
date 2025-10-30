package com.umigo.umigoCrmBackend.Service.Impl;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;
import com.google.firebase.auth.UserRecord;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.UserRecord.CreateRequest;
import com.umigo.umigoCrmBackend.Service.FirebaseService;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
public class FirebaseServiceImpl implements FirebaseService{

    @Override
    public FirebaseToken verifyIdToken(String idToken) throws Exception {
        FirebaseAuth auth = FirebaseAuth.getInstance();
        return auth.verifyIdToken(idToken, true);
    }

    @Override
    public UserRecord createUser(String email, String password, String phoneNumber, String displayName)
            throws FirebaseAuthException {
        CreateRequest request = new CreateRequest()
                .setEmail(email)
                .setPassword(password)
                .setDisplayName(displayName)
                .setEmailVerified(false)
                .setDisabled(false);
        if (StringUtils.hasText(phoneNumber)) {
            request.setPhoneNumber(phoneNumber);
        }
        return FirebaseAuth.getInstance().createUser(request);
    }
    
}
