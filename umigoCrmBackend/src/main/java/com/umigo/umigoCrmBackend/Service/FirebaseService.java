package com.umigo.umigoCrmBackend.Service;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import com.google.firebase.auth.UserRecord;

public interface FirebaseService {

    FirebaseToken verifyIdToken(String idToken) throws Exception;

    UserRecord createUser(String email, String password, String phoneNumber, String displayName)
            throws FirebaseAuthException;
}
