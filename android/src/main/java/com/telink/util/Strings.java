/********************************************************************************************************
 * @file     Strings.java
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
package com.telink.util;

import java.nio.charset.Charset;

public final class Strings {

    private Strings() {
    }

    public static byte[] stringToBytes(String str, int length) {

        byte[] srcBytes;

        if (length <= 0) {
            return str.getBytes(Charset.defaultCharset());
        }

        byte[] result = new byte[length];

        srcBytes = str.getBytes(Charset.defaultCharset());

        if (srcBytes.length <= length) {
            System.arraycopy(srcBytes, 0, result, 0, srcBytes.length);
        } else {
            System.arraycopy(srcBytes, 0, result, 0, length);
        }

        return result;
    }

    public static byte[] stringToBytes(String str) {
        return stringToBytes(str, 0);
    }

    public static String bytesToString(byte[] data) {
        return data == null || data.length <= 0 ? null : new String(data, Charset.defaultCharset()).trim();
    }

    // 使 Android 获取的蓝牙设备的 mac 猥琐地从标准的 6 字节降级为 iOS 的 4 字节以便统一，
    // 只因为恶心的 iOS 在系统级的限制
    public static String telinkMacAndroidToIos(String mac6String) {
        byte[] mac6Byte = stringToBytes(mac6String.replaceAll(":", ""));
        if (mac6Byte.length < 6) {
            return mac6String;
        }

        byte[] mac4Byte = new byte[8];
        mac4Byte[0] = mac6Byte[10];
        mac4Byte[1] = mac6Byte[11];
        mac4Byte[2] = mac6Byte[8];
        mac4Byte[3] = mac6Byte[9];
        mac4Byte[4] = mac6Byte[6];
        mac4Byte[5] = mac6Byte[7];
        mac4Byte[6] = mac6Byte[4];
        mac4Byte[7] = mac6Byte[5];
        return bytesToString(mac4Byte);
    }

    public static boolean isEmpty(String str) {
        return str == null || str.trim().isEmpty();
    }
}
