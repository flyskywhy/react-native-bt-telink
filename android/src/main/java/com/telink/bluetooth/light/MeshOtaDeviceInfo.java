/*
 * Copyright (C) 2015 The Telink Bluetooth Light Project
 *
 */
package com.telink.bluetooth.light;

import android.os.Parcel;

/**
 * OTA设备信息
 */
public class MeshOtaDeviceInfo extends DeviceInfo {

    public static final Creator<MeshOtaDeviceInfo> CREATOR = new Creator<MeshOtaDeviceInfo>() {
        @Override
        public MeshOtaDeviceInfo createFromParcel(Parcel in) {
            return new MeshOtaDeviceInfo(in);
        }

        @Override
        public MeshOtaDeviceInfo[] newArray(int size) {
            return new MeshOtaDeviceInfo[size];
        }
    };

    /**
     * firmware数据
     */
    public byte[] firmware;
    /**
     * ota进度
     */
    public int progress;

    public int type;

    public int mode;

    public MeshOtaDeviceInfo() {
    }

    public MeshOtaDeviceInfo(Parcel in) {
        super(in);
        this.progress = in.readInt();
        this.type = in.readInt();
        this.mode = in.readInt();
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        super.writeToParcel(dest, flags);
        dest.writeInt(this.progress);
        dest.writeInt(this.type);
        dest.writeInt(this.mode);
    }
}
