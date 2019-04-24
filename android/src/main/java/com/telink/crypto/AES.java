/********************************************************************************************************
 * @file     AES.java
 *
 * @brief    for TLSR chips
 *
 * @author	 telink
 * @date     Sep. 30, 2010
 *
 * @par      Copyright (c) 2010, Telink Semiconductor (Shanghai) Co., Ltd.
 *           All rights reserved.
 *
 *			 The information contained herein is confidential and proprietary property of Telink
 * 		     Semiconductor (Shanghai) Co., Ltd. and is available under the terms
 *			 of Commercial License Agreement between Telink Semiconductor (Shanghai)
 *			 Co., Ltd. and the licensee in separate contract or the terms described here-in.
 *           This heading MUST NOT be removed from this file.
 *
 * 			 Licensees are granted free, non-transferable use of the information in this
 *			 file under Mutual Non-Disclosure Agreement. NO WARRENTY of ANY KIND is provided.
 *
 *******************************************************************************************************/
/*
 * Copyright (C) 2015 The Telink Bluetooth Light Project
 *
 */
package com.telink.crypto;

import com.telink.util.Arrays;

import java.io.UnsupportedEncodingException;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;

import javax.crypto.BadPaddingException;
import javax.crypto.Cipher;
import javax.crypto.IllegalBlockSizeException;
import javax.crypto.NoSuchPaddingException;
import javax.crypto.spec.SecretKeySpec;

public abstract class AES {

    public static boolean Security = true;

    static {
        System.loadLibrary("TelinkCrypto");
    }

    private AES() {
    }

    public static byte[] encrypt(byte[] key, byte[] content)
            throws NoSuchAlgorithmException, NoSuchPaddingException,
            UnsupportedEncodingException, InvalidKeyException,
            IllegalBlockSizeException, BadPaddingException,
            NoSuchProviderException {

        if (!AES.Security)
            return content;

        key = Arrays.reverse(key);
        content = Arrays.reverse(content);

        SecretKeySpec secretKeySpec = new SecretKeySpec(key, "AES");
        Cipher cipher = Cipher.getInstance("AES/ECB/NoPadding");
        cipher.init(Cipher.ENCRYPT_MODE, secretKeySpec);
        return cipher.doFinal(content);
    }

    public static byte[] decrypt(byte[] key, byte[] content)
            throws IllegalBlockSizeException, BadPaddingException,
            NoSuchAlgorithmException, NoSuchPaddingException,
            InvalidKeyException, NoSuchProviderException {

        if (!AES.Security)
            return content;

        SecretKeySpec secretKeySpec = new SecretKeySpec(key, "AES");
        Cipher cipher = Cipher.getInstance("AES/ECB/NoPadding");
        cipher.init(Cipher.DECRYPT_MODE, secretKeySpec);
        return cipher.doFinal(content);
    }

    public static byte[] encrypt(byte[] key, byte[] nonce, byte[] plaintext) {

        if (!AES.Security)
            return plaintext;

        return encryptCmd(plaintext, nonce, key);
    }

    public static byte[] decrypt(byte[] key, byte[] nonce, byte[] plaintext) {

        if (!AES.Security)
            return plaintext;

        return decryptCmd(plaintext, nonce, key);
    }

    private static native byte[] encryptCmd(byte[] packet, byte[] iv, byte[] sk);

    private static native byte[] decryptCmd(byte[] packet, byte[] iv, byte[] sk);
}