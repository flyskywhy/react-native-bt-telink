package com.telink;

import android.app.Activity;

import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.JavaScriptModule;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ViewManager;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

public class TelinkBtPackage implements ReactPackage {
    static final String TAG = "TelinkBt";

    @Override
    public List<NativeModule> createNativeModules(ReactApplicationContext reactApplicationContext) {
        TelinkBtNativeModule telinkBtModule = new TelinkBtNativeModule(reactApplicationContext);

        List<NativeModule> nativeModules = new ArrayList<>();
        nativeModules.add(telinkBtModule);
        return nativeModules;
    }

    @Override
    public List<ViewManager> createViewManagers(ReactApplicationContext reactApplicationContext) {
        return new ArrayList<>();
    }
}
