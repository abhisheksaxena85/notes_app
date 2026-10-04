package com.example.notes_app.common;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

public class PasswordHashing {

    @Autowired
    BCryptPasswordEncoder encoder;

    public String hashPassword(String rawPassword) {
        return encoder.encode(rawPassword);
    }

    public boolean verifyPassword(String rawPassword, String securedHash) {
        return encoder.matches(rawPassword, securedHash);
    }
}
