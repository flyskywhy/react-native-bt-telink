/*
 * Copyright (C) 2015 The Telink Bluetooth Light Project
 *
 */
package com.telink.bluetooth.event;

import com.telink.bluetooth.light.ErrorReportInfo;

/**
 * Error report
 *
 */
public class ErrorReportEvent extends DataEvent<ErrorReportInfo> {

    public static final String ERROR_REPORT = "com.telink.bluetooth.light.ERROR_REPORT";

    /**
     * scan
     */
    public static final int STATE_SCAN = 1;

    /**
     * connect
     */
    public static final int STATE_CONNECT = 2;

    /**
     * login
     */
    public static final int STATE_LOGIN = 3;


    // state_scan

    /**
     * 无法收到广播包以及响应包
     */
    public static final int ERROR_SCAN_NO_ADV = 1;

    /**
     * 蓝牙未开启
     */
    public static final int ERROR_SCAN_BLE_DISABLE = 2;

    /**
     * 未扫到目标设备
     */
    public static final int ERROR_SCAN_NO_TARGET = 3;



    // state_connect

    /**
     * 未建立物理连接
     */
    public static final int ERROR_CONNECT_COMMON = 1;

    /**
     * 未读到att表
     */
    public static final int ERROR_CONNECT_ATT = 2;



    // state_login

    /**
     * write login data 没有收到response
     */
    public static final int ERROR_LOGIN_WRITE_DATA = 1;

    /**
     * read login data 没有收到response
     */
    public static final int ERROR_LOGIN_READ_DATA = 2;


    /**
     * value check失败： 密码错误
     */
    public static final int ERROR_LOGIN_VALUE_CHECK = 3;




    public ErrorReportEvent(Object sender, String type, ErrorReportInfo args) {
        super(sender, type, args);
    }

    public static ErrorReportEvent newInstance(Object sender, String type, ErrorReportInfo args) {
        return new ErrorReportEvent(sender, type, args);
    }
}
