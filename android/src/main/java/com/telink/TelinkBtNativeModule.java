package com.telink;

import javax.annotation.Nullable;

import java.util.Calendar;
import java.util.List;

import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.content.Context;
import android.content.BroadcastReceiver;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Toast;

import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import com.telink.bluetooth.LeBluetooth;
import com.telink.bluetooth.TelinkLog;
import com.telink.bluetooth.event.DeviceEvent;
import com.telink.bluetooth.event.LeScanEvent;
import com.telink.bluetooth.event.MeshEvent;
import com.telink.bluetooth.event.NotificationEvent;
import com.telink.bluetooth.event.ServiceEvent;
import com.telink.bluetooth.light.DeviceInfo;
import com.telink.bluetooth.light.GetAlarmNotificationParser;
import com.telink.bluetooth.light.LeAutoConnectParameters;
import com.telink.bluetooth.light.LeRefreshNotifyParameters;
import com.telink.bluetooth.light.LeScanParameters;
import com.telink.bluetooth.light.LeUpdateParameters;
import com.telink.bluetooth.light.LightAdapter;
import com.telink.bluetooth.light.OnlineStatusNotificationParser;
import com.telink.bluetooth.light.GetGroupNotificationParser;
import com.telink.bluetooth.light.Parameters;
import com.telink.util.Event;
import com.telink.util.EventListener;

import static com.telink.TelinkBtPackage.TAG;

public class TelinkBtNativeModule extends ReactContextBaseJavaModule implements ActivityEventListener, LifecycleEventListener, EventListener<String> {

    // Debugging
    private static final boolean D = true;

    // Event names
    public static final String BT_ENABLED = "bluetoothEnabled";
    public static final String BT_DISABLED = "bluetoothDisabled";
    public static final String SERVICE_CONNECTED = "serviceConnected";
    public static final String SERVICE_DISCONNECTED = "serviceDisconnected";
    public static final String NOTIFICATION_ONLINE_STATUS = "notificationOnlineStatus";
    public static final String NOTIFICATION_GET_DEVICE_STATE = "notificationGetDeviceState";
    public static final String DEVICE_STATUS_CONNECTING = "deviceStatusConnecting";
    public static final String DEVICE_STATUS_CONNECTED = "deviceStatusConnected";
    public static final String DEVICE_STATUS_LOGINING = "deviceStatusLogining";
    public static final String DEVICE_STATUS_LOGIN = "deviceStatusLogin";
    public static final String DEVICE_STATUS_LOGOUT = "deviceStatusLogout";
    public static final String DEVICE_STATUS_ERROR_N = "deviceStatusErrorAndroidN";
    public static final String DEVICE_STATUS_UPDATE_MESH_COMPLETED = "deviceStatusUpdateMeshCompleted";
    public static final String DEVICE_STATUS_UPDATING_MESH = "deviceStatusUpdatingMesh";
    public static final String DEVICE_STATUS_UPDATE_MESH_FAILURE = "deviceStatusUpdateMeshFailure";
    public static final String DEVICE_STATUS_UPDATE_ALL_MESH_COMPLETED = "deviceStatusUpdateAllMeshCompleted";
    public static final String DEVICE_STATUS_GET_LTK_COMPLETED = "deviceStatusGetLtkCompleted";
    public static final String DEVICE_STATUS_GET_LTK_FAILURE = "deviceStatusGetLtkFailure";
    public static final String DEVICE_STATUS_MESH_OFFLINE = "deviceStatusMeshOffline";
    public static final String DEVICE_STATUS_MESH_SCAN_COMPLETED = "deviceStatusMeshScanCompleted";
    public static final String DEVICE_STATUS_MESH_SCAN_TIMEOUT = "deviceStatusMeshScanTimeout";
    public static final String DEVICE_STATUS_OTA_COMPLETED = "deviceStatusOtaCompleted";
    public static final String DEVICE_STATUS_OTA_FAILURE = "deviceStatusOtaFailure";
    public static final String DEVICE_STATUS_OTA_PROGRESS = "deviceStatusOtaProgress";
    public static final String DEVICE_STATUS_GET_FIRMWARE_COMPLETED = "deviceStatusGetFirmwareCompleted";
    public static final String DEVICE_STATUS_GET_FIRMWARE_FAILURE = "deviceStatusGetFirmwareFailure";
    public static final String DEVICE_STATUS_DELETE_COMPLETED = "deviceStatusDeleteCompleted";
    public static final String DEVICE_STATUS_DELETE_FAILURE = "deviceStatusDeleteFailure";
    public static final String LE_SCAN = "leScan";
    public static final String LE_SCAN_COMPLETED = "leScanCompleted";
    public static final String LE_SCAN_TIMEOUT = "leScanTimeout";
    public static final String MESH_OFFLINE = "meshOffline";

    // Members
    private static TelinkBtNativeModule mThis;
    private TelinkApplication mTelinkApplication;
    private BluetoothAdapter mBluetoothAdapter;
    private ReactApplicationContext mReactContext;
    protected Context mContext;
    private Handler mHandler = new Handler(Looper.getMainLooper());

    // Patch
    private String mPatchConfigNodeOldName;

    // Promises
    private Promise mConfigNodePromise;
    private Promise mSetNodeGroupAddrPromise;
    private Promise mGetTimePromise;
    private Promise mGetAlarmPromise;

    final BroadcastReceiver mBluetoothStateReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            final String action = intent.getAction();

            if (BluetoothAdapter.ACTION_STATE_CHANGED.equals(action)) {
                final int state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR);
                switch (state) {
                    case BluetoothAdapter.STATE_OFF:
                        if (D) Log.d(TAG, "Bluetooth was disabled");
                        sendEvent(BT_DISABLED);
                        break;
                    case BluetoothAdapter.STATE_ON:
                        if (D) Log.d(TAG, "Bluetooth was enabled");
                        sendEvent(BT_ENABLED);
                        break;
                }
            }
        }
    };

    public TelinkBtNativeModule(ReactApplicationContext reactContext) {
        super(reactContext);
        mThis = this;
        mReactContext = reactContext;
        mContext = mReactContext.getApplicationContext();
    }

    @Override
    public String getName() {
        return "TelinkBt";
    }

    public static TelinkBtNativeModule getInstance() {
        return mThis;
    }

    @Override
    public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent intent) {
        if (D) Log.d(TAG, "On activity result request: " + requestCode + ", result: " + resultCode);
        // if (requestCode == REQUEST_ENABLE_BLUETOOTH) {
        //     if (resultCode == Activity.RESULT_OK) {
        //         if (D) Log.d(TAG, "User enabled Bluetooth");
        //         if (mEnabledPromise != null) {
        //             mEnabledPromise.resolve(true);
        //         }
        //     } else {
        //         if (D) Log.d(TAG, "User did *NOT* enable Bluetooth");
        //         if (mEnabledPromise != null) {
        //             mEnabledPromise.reject(new Exception("User did not enable Bluetooth"));
        //         }
        //     }
        //     mEnabledPromise = null;
        // }

        // if (requestCode == REQUEST_PAIR_DEVICE) {
        //     if (resultCode == Activity.RESULT_OK) {
        //         if (D) Log.d(TAG, "Pairing ok");
        //     } else {
        //         if (D) Log.d(TAG, "Pairing failed");
        //     }
        // }
    }

    @Override
    public void onNewIntent(Intent intent) {
        if (D) Log.d(TAG, "On new intent");
    }


    @Override
    public void onHostResume() {
        if (D) Log.d(TAG, "Host resume");
        if (mTelinkApplication != null) {
            this.doResume();
        }
    }

    @Override
    public void onHostPause() {
        if (D) Log.d(TAG, "Host pause");
    }

    @Override
    public void onHostDestroy() {
        if (D) Log.d(TAG, "Host destroy");
        // APP 切到后台时也会调用此处，导致切回前台 Resume 时无法再正常使用本组件，因此使不在此处调用 doDestroy
        // if (mTelinkApplication != null) {
        //     this.doDestroy();
        // }
    }

    @Override
    public void onCatalystInstanceDestroy() {
        if (D) Log.d(TAG, "Catalyst instance destroyed");
        super.onCatalystInstanceDestroy();
        if (mTelinkApplication != null) {
            this.doDestroy();
        }
    }

    @ReactMethod
    public void doInit() {
        if (mTelinkApplication == null) {
            mTelinkApplication = new TelinkApplication(getCurrentActivity().getApplication());
        }

        mTelinkApplication.doInit();
        //AES.Security = true;

        // 监听各种事件
        mTelinkApplication.addEventListener(DeviceEvent.STATUS_CHANGED, this);
        mTelinkApplication.addEventListener(NotificationEvent.ONLINE_STATUS, this);
        mTelinkApplication.addEventListener(NotificationEvent.GET_GROUP, this);
        mTelinkApplication.addEventListener(NotificationEvent.GET_DEVICE_STATE, this);
        mTelinkApplication.addEventListener(NotificationEvent.GET_ALARM, this);
        mTelinkApplication.addEventListener(NotificationEvent.GET_SCENE, this);
        mTelinkApplication.addEventListener(NotificationEvent.GET_TIME, this);
        mTelinkApplication.addEventListener(NotificationEvent.USER_ALL_NOTIFY, this);
        mTelinkApplication.addEventListener(NotificationEvent.GET_MESH_OTA_PROGRESS, this);
        mTelinkApplication.addEventListener(ServiceEvent.SERVICE_CONNECTED, this);
        mTelinkApplication.addEventListener(LeScanEvent.LE_SCAN, this);
        mTelinkApplication.addEventListener(LeScanEvent.LE_SCAN_TIMEOUT, this);
        mTelinkApplication.addEventListener(LeScanEvent.LE_SCAN_COMPLETED, this);
        mTelinkApplication.addEventListener(MeshEvent.OFFLINE, this);
        mTelinkApplication.addEventListener(MeshEvent.UPDATE_COMPLETED, this);
        mTelinkApplication.addEventListener(MeshEvent.ERROR, this);

        mTelinkApplication.startLightService(TelinkLightService.class);

        if (mBluetoothAdapter == null) {
            mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        }

        if (mBluetoothAdapter != null && mBluetoothAdapter.isEnabled()) {
            sendEvent(BT_ENABLED);
        } else {
            sendEvent(BT_DISABLED);
        }

        mReactContext.addActivityEventListener(this);
        mReactContext.addLifecycleEventListener(this);

        IntentFilter intentFilter = new IntentFilter();
        intentFilter.addAction(BluetoothAdapter.ACTION_STATE_CHANGED);
        mReactContext.registerReceiver(mBluetoothStateReceiver, intentFilter);

        sendEvent(DEVICE_STATUS_LOGOUT);
    }

    @ReactMethod
    public void doDestroy() {
        TelinkLog.onDestroy();
        if (mTelinkApplication != null) {
            mHandler.removeCallbacksAndMessages(null);
            mReactContext.unregisterReceiver(mBluetoothStateReceiver);
            mTelinkApplication.doDestroy();
            mTelinkApplication = null;
        }
    }

    @ReactMethod
    public void doResume() {
        Log.d(TAG, "onResume");
        //检查是否支持蓝牙设备
        if (!LeBluetooth.getInstance().isSupport(mContext)) {
            Toast.makeText(mContext, "ble not support", Toast.LENGTH_SHORT).show();
            return;
        }
    }

    @ReactMethod
    public void notModeAutoConnectMesh(Promise promise) {
        if (TelinkLightService.Instance().getMode() != LightAdapter.MODE_AUTO_CONNECT_MESH) {
            promise.resolve(true);
        } else {
            promise.reject(new Exception("Already in mode AutoConnectMesh"));
        }
    }

    @ReactMethod
    public void autoConnect(String userMeshName, String userMeshPwd, String otaMac) {
        LeAutoConnectParameters connectParams = Parameters.createAutoConnectParameters();
        connectParams.setMeshName(userMeshName);
        connectParams.setPassword(userMeshPwd);
        connectParams.autoEnableNotification(true);

        if (TextUtils.isEmpty(otaMac))  {
            mTelinkApplication.saveLog("Action: AutoConnect:NULL");
        } else {    // 之前是否有在做 MeshOTA 操作，是则继续
            connectParams.setConnectMac(otaMac);
            mTelinkApplication.saveLog("Action: AutoConnect:" + otaMac);
        }

        TelinkLightService.Instance().autoConnect(connectParams);
        // sendEvent(DEVICE_STATUS_LOGIN);
    }

    @ReactMethod
    public void autoRefreshNotify(int repeatCount, int Interval) {
        LeRefreshNotifyParameters refreshNotifyParams = Parameters.createRefreshNotifyParameters();
        refreshNotifyParams.setRefreshRepeatCount(repeatCount);
        refreshNotifyParams.setRefreshInterval(Interval);

        TelinkLightService.Instance().autoRefreshNotify(refreshNotifyParams);
    }

    @ReactMethod
    public void idleMode(boolean disconnect) {
        TelinkLightService.Instance().idleMode(disconnect);
    }

    @ReactMethod
    public void startScan(String meshName, String outOfMeshName, int timeoutSeconds, boolean isSingleNode) {
        LeScanParameters params = LeScanParameters.create();
        params.setMeshName(meshName);
        params.setOutOfMeshName(outOfMeshName);
        params.setTimeoutSeconds(timeoutSeconds);
        params.setScanMode(isSingleNode);
        TelinkLightService.Instance().startScan(params);
    }


    public static byte[] readableArray2ByteArray(ReadableArray arr) {
        int size = arr.size();
        byte[] byteArr = new byte[size];
        for(int i = 0; i < arr.size(); i++) {
            byteArr[i] = (byte)arr.getInt(i);
        }

        return byteArr;
    }

    @ReactMethod
    public void sendCommand(int opcode, int meshAddress, ReadableArray value) {
        TelinkLightService.Instance().sendCommandNoResponse((byte) opcode, meshAddress, readableArray2ByteArray(value));
    }

    @ReactMethod
    public void changePower(int meshAddress, int value) {
        byte opcode = (byte) 0xD0;
        byte[] params = new byte[]{(byte) value, 0x00, 0x00};

        TelinkLightService.Instance().sendCommandNoResponse(opcode, meshAddress, params);
    }

    @ReactMethod
    public void changeBrightness(int meshAddress, int value) {
        byte opcode = (byte) 0xD2;
        byte[] params = new byte[]{(byte) value};

        TelinkLightService.Instance().sendCommandNoResponse(opcode, meshAddress, params);
    }

    @ReactMethod
    public void changeColorTemp(int meshAddress, int value) {
        byte opcode = (byte) 0xE2;
        byte[] params = new byte[]{0x05, (byte) value};

        TelinkLightService.Instance().sendCommandNoResponse(opcode, meshAddress, params);
    }

    @ReactMethod
    public void changeColor(int meshAddress, int value) {
        byte red = (byte) (value >> 16 & 0xFF);
        byte green = (byte) (value >> 8 & 0xFF);
        byte blue = (byte) (value & 0xFF);

        byte opcode = (byte) 0xE2;
        byte[] params = new byte[]{0x04, red, green, blue};

        TelinkLightService.Instance().sendCommandNoResponse(opcode, meshAddress, params);
    }

    // @ReactMethod
    // public void configNodes(ReadableArray nodes, ReadableMap cfg, Promise promise) {
    //     int count = nodes.size();
    //     DeviceInfo[] deviceInfos = new DeviceInfo[count];
    //     for (int i = 0; i < count; i++) {
    //         ReadableMap node = nodes.getMap(i);
    //         DeviceInfo deviceInfo = new DeviceInfo();
    //         deviceInfo.macAddress = node.getString("macAddress");
    //         // deviceInfo.deviceName = node.getString("deviceName");
    //         // deviceInfo.meshName = node.getString("meshName");
    //         deviceInfo.meshAddress = node.getInt("meshAddress");
    //         // deviceInfo.meshUUID = node.getInt("meshUUID");
    //         // deviceInfo.productUUID = node.getInt("productUUID");
    //         // deviceInfo.status = node.getInt("status");
    //         deviceInfos[i] = deviceInfo;
    //     }

    //     LeUpdateParameters params = Parameters.createUpdateParameters();
    //     params.setOldMeshName(cfg.getString("oldName"));
    //     params.setOldPassword(cfg.getString("oldPwd"));
    //     params.setNewMeshName(cfg.getString("newName"));
    //     params.setNewPassword(cfg.getString("newPwd"));
    //     params.setUpdateDeviceList(deviceInfos);
    //     TelinkLightService.Instance().updateMesh(params);
    // }

    // private void onUpdateMeshCompleted(DeviceInfo deviceInfo) {
    //     if (D) Log.d(TAG, "onUpdateMeshCompleted");
    //     WritableMap params = Arguments.createMap();
    //     params.putString("macAddress", deviceInfo.macAddress);
    //     params.putString("deviceName", deviceInfo.deviceName);
    //     params.putString("meshName", deviceInfo.meshName);
    //     params.putInt("meshAddress", deviceInfo.meshAddress);
    //     params.putInt("meshUUID", deviceInfo.meshUUID);
    //     params.putInt("productUUID", deviceInfo.productUUID);
    //     params.putInt("status", deviceInfo.status);
    //     sendEvent(DEVICE_STATUS_UPDATE_MESH_COMPLETED, params);
    // }

// 上面注释掉的 configNodes 和 onUpdateMeshCompleted 是用于批量更新 JS 层传来的 mesh 数组的，
// 但实际调试发现只能更新第一个 mesh ， 因此还是让 JS 层间隔一段时间调用下面的 configNode 更合适

    @ReactMethod
    public void configNode(ReadableMap node, ReadableMap cfg, Promise promise) {
        mPatchConfigNodeOldName = cfg.getString("oldName");
        mConfigNodePromise = promise;

        DeviceInfo deviceInfo = new DeviceInfo();
        deviceInfo.macAddress = node.getString("macAddress");
        // deviceInfo.deviceName = node.getString("deviceName");
        // deviceInfo.meshName = node.getString("meshName");
        deviceInfo.meshAddress = node.getInt("meshAddress");
        // deviceInfo.meshUUID = node.getInt("meshUUID");
        // deviceInfo.productUUID = node.getInt("productUUID");
        // deviceInfo.status = node.getInt("status");

        LeUpdateParameters params = Parameters.createUpdateParameters();
        params.setOldMeshName(cfg.getString("oldName"));
        params.setOldPassword(cfg.getString("oldPwd"));
        params.setNewMeshName(cfg.getString("newName"));
        params.setNewPassword(cfg.getString("newPwd"));
        params.setUpdateDeviceList(deviceInfo);
        TelinkLightService.Instance().updateMesh(params);
    }

    private void onUpdateMeshCompleted() {
        if (D) Log.d(TAG, "onUpdateMeshCompleted");
        if (mConfigNodePromise != null) {
            WritableMap params = Arguments.createMap();
            mConfigNodePromise.resolve(params);
        }
        mConfigNodePromise = null;
    }

    private void onUpdateMeshFailure(DeviceInfo deviceInfo) {
        if (deviceInfo.meshName.equals(mPatchConfigNodeOldName)) {  // 开始进行一系列 updateMesh 后，第一个 Mesh 总会同时返回成功和失败的两个 Event 从而导致 JS 层代码逻辑无所适从，所以此处需要该补丁
            if (D) Log.d(TAG, "onUpdateMeshFailure");
            if (mConfigNodePromise != null) {
                mConfigNodePromise.reject(new Exception("onUpdateMeshFailure"));
            }
            mConfigNodePromise = null;
        }
    }

    private void onUpdateMeshFailure() {
        if (D) Log.d(TAG, "onUpdateMeshFailure");
        if (mConfigNodePromise != null) {
            mConfigNodePromise.reject(new Exception("onUpdateMeshFailure"));
        }
        mConfigNodePromise = null;
    }

    private void onNError(final DeviceEvent event) {
        TelinkLightService.Instance().idleMode(true);
        TelinkLog.d("DeviceScanningActivity#onNError");
        sendEvent(DEVICE_STATUS_ERROR_N);
    }

    private void onDeviceStatusChanged(DeviceEvent event) {
        DeviceInfo deviceInfo = event.getArgs();

        switch (deviceInfo.status) {
            case LightAdapter.STATUS_LOGIN:
                mHandler.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        TelinkLightService.Instance().sendCommandNoResponse((byte) 0xE4, 0xFFFF, new byte[]{});
                    }
                }, 3 * 1000);

                WritableMap params = Arguments.createMap();
                params.putInt("connectMeshAddress", mTelinkApplication.getConnectDevice().meshAddress);
                sendEvent(DEVICE_STATUS_LOGIN, params);
                break;
            case LightAdapter.STATUS_CONNECTING:
                break;
            case LightAdapter.STATUS_LOGOUT:
                sendEvent(DEVICE_STATUS_LOGOUT);
                break;
            case LightAdapter.STATUS_UPDATE_MESH_COMPLETED:
                onUpdateMeshCompleted();
                break;
            case LightAdapter.STATUS_UPDATE_MESH_FAILURE:
                onUpdateMeshFailure(deviceInfo);
                break;
            case LightAdapter.STATUS_ERROR_N:
                onNError(event);
            default:
                break;
        }
    }

    /**
     * 处理{@link NotificationEvent#ONLINE_STATUS}事件
     */
    private synchronized void onOnlineStatusNotify(NotificationEvent event) {
        TelinkLog.i("MainActivity#onOnlineStatusNotify#Thread ID : " + Thread.currentThread().getId());
        List<OnlineStatusNotificationParser.DeviceNotificationInfo> notificationInfoList;
        //noinspection unchecked
        notificationInfoList = (List<OnlineStatusNotificationParser.DeviceNotificationInfo>) event.parse();

        if (notificationInfoList == null || notificationInfoList.size() <= 0)
            return;

        WritableArray params = Arguments.createArray();
        for (OnlineStatusNotificationParser.DeviceNotificationInfo notificationInfo : notificationInfoList) {
            WritableMap map = Arguments.createMap();
            map.putInt("meshAddress", notificationInfo.meshAddress);
            map.putInt("brightness", notificationInfo.brightness);
            map.putInt("status", notificationInfo.connectionStatus.getValue());
            params.pushMap(map);
        }
        sendEvent(NOTIFICATION_ONLINE_STATUS, params);
    }

    private void onServiceConnected(ServiceEvent event) {
        sendEvent(SERVICE_CONNECTED);
    }

    private void onServiceDisconnected(ServiceEvent event) {
        sendEvent(SERVICE_DISCONNECTED);
    }

    private void onMeshOffline(MeshEvent event) {
        onUpdateMeshFailure();
        sendEvent(MESH_OFFLINE);
    }

    private void onNotificationEvent(NotificationEvent event) {
        // if (!foreground) return;
        // // 解析版本信息
        // byte[] data = event.getArgs().params;
        // if (data[0] == NotificationEvent.DATA_GET_MESH_OTA_PROGRESS) {
        //     TelinkLog.w("mesh ota progress: " + data[1]);
        //     int progress = (int) data[1];
        //     if (progress != 100) {
        //         startActivity(new Intent(this, OTAUpdateActivity.class)
        //                 .putExtra(OTAUpdateActivity.INTENT_KEY_CONTINUE_MESH_OTA, OTAUpdateActivity.CONTINUE_BY_REPORT)
        //                 .putExtra("progress", progress));
        //     }
        // }
    }

    @ReactMethod
    public void setNodeGroupAddr(boolean toDel, int meshAddress, int groupAddress, Promise promise) {
        byte opcode = (byte) 0xD7;
        byte[] params = new byte[]{(byte) (toDel ? 0x00 : 0x01), (byte) (groupAddress & 0xFF),
                (byte) (groupAddress >> 8 & 0xFF)};

        mSetNodeGroupAddrPromise = promise;
        TelinkLightService.Instance().sendCommandNoResponse(opcode, meshAddress, params);
    }

    private synchronized void onGetGroupNotify(NotificationEvent event) {
        TelinkLog.i("MainActivity#onGetGroupNotify#Thread ID : " + Thread.currentThread().getId());
        List<Integer> notificationInfoList;
        notificationInfoList = (List<Integer>) event.parse();

        if (notificationInfoList == null) {
            mSetNodeGroupAddrPromise.reject(new Exception("GetGroup return null"));
            return;
        }

        if (mSetNodeGroupAddrPromise != null) {
            WritableArray params = Arguments.createArray();
            for (Integer notificationInfo : notificationInfoList) {
                params.pushInt(notificationInfo);
            }
            mSetNodeGroupAddrPromise.resolve(params);
        }
        mSetNodeGroupAddrPromise = null;
    }

    @ReactMethod
    public void getTime(int meshAddress, int relayTimes, Promise promise) {
        byte opcode = (byte) 0xE8;
        byte[] params = new byte[]{(byte) relayTimes};

        mGetTimePromise = promise;
        TelinkLightService.Instance().sendCommandNoResponse(opcode, meshAddress, params);
    }

    private synchronized void onGetTimeNotify(NotificationEvent event) {
        Calendar notificationInfo;
        notificationInfo = (Calendar) event.parse();

        if (notificationInfo == null) {
            mGetTimePromise.reject(new Exception("GetTime return null"));
            return;
        }

        if (mGetTimePromise != null) {
            WritableMap params = Arguments.createMap();
            params.putString("time", notificationInfo.getTime().toString());
            mGetTimePromise.resolve(params);
        }
        mGetTimePromise = null;
    }

    @ReactMethod
    public void getAlarm(int meshAddress, int relayTimes, int alarmId, Promise promise) {
        byte opcode = (byte) 0xE6;
        byte[] params = new byte[]{(byte) relayTimes, (byte) alarmId};

        mGetAlarmPromise = promise;
        TelinkLightService.Instance().sendCommandNoResponse(opcode, meshAddress, params);
    }

    private synchronized void onGetAlarmNotify(NotificationEvent event) {
        GetAlarmNotificationParser.AlarmInfo notificationInfo;
        notificationInfo = (GetAlarmNotificationParser.AlarmInfo) event.parse();

        if (notificationInfo == null) {
            mGetAlarmPromise.reject(new Exception("GetAlarm return null"));
            return;
        }

        if (mGetAlarmPromise != null) {
            WritableMap params = Arguments.createMap();
            params.putInt("alarmId", notificationInfo.index);
            params.putInt("action", notificationInfo.action.getValue());
            params.putInt("type", notificationInfo.type.getValue());
            params.putInt("status", notificationInfo.status.getValue());
            params.putInt("month", notificationInfo.getMonth());
            params.putInt("dayOrWeek", notificationInfo.getDayOrWeek());
            params.putInt("hour", notificationInfo.getHour());
            params.putInt("minute", notificationInfo.getMinute());
            params.putInt("second", notificationInfo.getSecond());
            params.putInt("sceneId", notificationInfo.sceneId);
            mGetAlarmPromise.resolve(params);
        }
        mGetAlarmPromise = null;
    }

    private void onLeScan(LeScanEvent event) {
        DeviceInfo deviceInfo = event.getArgs();
        WritableMap params = Arguments.createMap();
        params.putString("macAddress", deviceInfo.macAddress);
        params.putString("deviceName", deviceInfo.deviceName);
        params.putString("meshName", deviceInfo.meshName);
        params.putInt("meshAddress", deviceInfo.meshAddress);
        params.putInt("meshUUID", deviceInfo.meshUUID);
        params.putInt("productUUID", deviceInfo.productUUID);
        params.putInt("status", deviceInfo.status);
        sendEvent(LE_SCAN, params);
    }

    private void onMeshEventUpdateCompleted(MeshEvent event) {
    }

    private void onMeshEventError(MeshEvent event) {
    }

    /**
     * 事件处理方法
     *
     * @param event
     */
    @Override
    public void performed(Event<String> event) {
        switch (event.getType()) {
            case NotificationEvent.ONLINE_STATUS:
                this.onOnlineStatusNotify((NotificationEvent) event);
                break;
            case NotificationEvent.GET_GROUP:
                this.onGetGroupNotify((NotificationEvent) event);
                break;
            case NotificationEvent.GET_TIME:
                this.onGetTimeNotify((NotificationEvent) event);
                break;
            case NotificationEvent.GET_ALARM:
                this.onGetAlarmNotify((NotificationEvent) event);
                break;
            case DeviceEvent.STATUS_CHANGED:
                this.onDeviceStatusChanged((DeviceEvent) event);
                break;
            case ServiceEvent.SERVICE_CONNECTED:
                this.onServiceConnected((ServiceEvent) event);
                break;
            case ServiceEvent.SERVICE_DISCONNECTED:
                this.onServiceDisconnected((ServiceEvent) event);
                break;
            case NotificationEvent.GET_DEVICE_STATE:
                onNotificationEvent((NotificationEvent) event);
                break;
            case LeScanEvent.LE_SCAN:
                onLeScan((LeScanEvent) event);
                break;
            case LeScanEvent.LE_SCAN_TIMEOUT:
                sendEvent(LE_SCAN_TIMEOUT);
                sendEvent(DEVICE_STATUS_LOGOUT);
                break;
            case LeScanEvent.LE_SCAN_COMPLETED:
                sendEvent(LE_SCAN_COMPLETED);
                sendEvent(DEVICE_STATUS_LOGOUT);
                break;
            case MeshEvent.OFFLINE:
                this.onMeshOffline((MeshEvent) event);
                break;
            case MeshEvent.UPDATE_COMPLETED:
                onMeshEventUpdateCompleted((MeshEvent) event);
                break;
            case MeshEvent.ERROR:
                onMeshEventError((MeshEvent) event);
                break;
        }
    }

    /*********************/
    /** Private methods **/
    /*********************/

    /**
     * Check if is api level 19 or above
     * @return is above api level 19
     */
    private boolean isKitKatOrAbove () {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT;
    }

    /**
     * Send event to javascript
     * @param eventName Name of the event
     * @param params Additional params
     */
    public void sendEvent(String eventName, @Nullable WritableMap params) {
        if (mReactContext.hasActiveCatalystInstance()) {
            if (D) Log.d(TAG, "Sending event: " + eventName);
            mReactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(eventName, params);
        }
    }

    public void sendEvent(String eventName, @Nullable WritableArray params) {
        if (mReactContext.hasActiveCatalystInstance()) {
            if (D) Log.d(TAG, "Sending event: " + eventName);
            mReactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(eventName, params);
        }
    }

    public void sendEvent(String eventName) {
        if (mReactContext.hasActiveCatalystInstance()) {
            if (D) Log.d(TAG, "Sending event: " + eventName);
            mReactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(eventName, null);
        }
    }
}
