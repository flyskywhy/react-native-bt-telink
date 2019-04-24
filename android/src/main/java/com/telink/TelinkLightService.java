/********************************************************************************************************
 * @file     TelinkLightService.java
 *
 * @brief    for TLSR chips
 *
 * @author   telink
 * @date     Sep. 30, 2010
 *
 * @par      Copyright (c) 2010, Telink Semiconductor (Shanghai) Co., Ltd.
 *           All rights reserved.
 *
 *           The information contained herein is confidential and proprietary property of Telink
 *           Semiconductor (Shanghai) Co., Ltd. and is available under the terms
 *           of Commercial License Agreement between Telink Semiconductor (Shanghai)
 *           Co., Ltd. and the licensee in separate contract or the terms described here-in.
 *           This heading MUST NOT be removed from this file.
 *
 *           Licensees are granted free, non-transferable use of the information in this
 *           file under Mutual Non-Disclosure Agreement. NO WARRENTY of ANY KIND is provided.
 *
 *******************************************************************************************************/
package com.telink;

import android.content.Intent;
import android.os.Binder;
import android.os.IBinder;

import com.telink.bluetooth.light.LightService;
import com.telink.bluetooth.light.LightAdapter;
import com.telink.bluetooth.TelinkLog;

public final class TelinkLightService extends LightService {

    private static TelinkLightService mThis;

    public static TelinkLightService Instance() {
        return mThis;
    }

    @Override
    public IBinder onBind(Intent intent) {
        if (this.mBinder == null)
            this.mBinder = new LocalBinder();

        return super.onBind(intent);
    }

    @Override
    public void onCreate() {
        super.onCreate();

        mThis = this;

        if (this.mAdapter == null)
            this.mAdapter = new LightAdapter();
        this.mAdapter.start(this);
    }

    public class LocalBinder extends Binder {
        public TelinkLightService getService() {
            return TelinkLightService.this;
        }
    }
}
