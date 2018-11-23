/*
 * Copyright (C) 2015 The Telink Bluetooth Light Project
 *
 */
package com.telink.bluetooth.light;

/**
 * 获取mesh设备列表 notify数据解析
 */
public final class GetMeshDeviceNotificationParser extends NotificationParser<GetMeshDeviceNotificationParser.MeshDeviceInfo> {

    private GetMeshDeviceNotificationParser() {
    }

    public static GetMeshDeviceNotificationParser create() {
        return new GetMeshDeviceNotificationParser();
    }

    @Override
    public byte opcode() {
        return Opcode.BLE_GATT_OP_CTRL_E1.getValue();
    }

    @Override
    public MeshDeviceInfo parse(NotificationInfo notifyInfo) {

        byte[] params = notifyInfo.params;

        // 63,71,FB,6C,00,C3,02,E1,11,02,6C,00,6C,88,1D,63,FF,FF,00,00
        // params : 6C,00,6C,88,1D,63,FF,FF,00,00

//        int offset = 0;
        MeshDeviceInfo meshDeviceInfo = new MeshDeviceInfo();
        meshDeviceInfo.deviceId = (params[0] & 0xFF) | (params[1] & 0xFF << 8);
        meshDeviceInfo.macBytes = new byte[6];
        System.arraycopy(params, 2, meshDeviceInfo.macBytes, 0, 6);
        // 反转高低位
//        Arrays.reverse(meshDeviceInfo.macBytes);
        return meshDeviceInfo;
    }


    public final class MeshDeviceInfo {

        public int deviceId;

        public byte[] macBytes;
    }
}
