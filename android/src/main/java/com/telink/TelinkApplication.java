/*
 * Copyright (C) 2015 The Telink Bluetooth Light Project
 *
 */
package com.telink;

import android.app.Application;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.os.IBinder;
import android.support.v4.content.LocalBroadcastManager;
import android.widget.Toast;

import com.telink.bluetooth.TelinkLog;
import com.telink.bluetooth.event.DeviceEvent;
import com.telink.bluetooth.event.LeScanEvent;
import com.telink.bluetooth.event.MeshEvent;
import com.telink.bluetooth.event.NotificationEvent;
import com.telink.bluetooth.event.ServiceEvent;
import com.telink.bluetooth.light.DeviceInfo;
import com.telink.bluetooth.light.GetAlarmNotificationParser;
import com.telink.bluetooth.light.GetGroupNotificationParser;
import com.telink.bluetooth.light.GetSceneNotificationParser;
import com.telink.bluetooth.light.GetTimeNotificationParser;
import com.telink.bluetooth.light.LightAdapter;
import com.telink.bluetooth.light.LightService;
import com.telink.bluetooth.light.NotificationInfo;
import com.telink.bluetooth.light.NotificationParser;
import com.telink.bluetooth.light.OnlineStatusNotificationParser;
import com.telink.util.Event;
import com.telink.util.EventBus;
import com.telink.util.EventListener;
import com.telink.util.Strings;

import java.sql.Time;
import java.text.SimpleDateFormat;
import java.util.Calendar;

public class TelinkApplication /*extends Application*/ {

    private StringBuilder logInfo;
    private static TelinkApplication mThis;

    protected final EventBus<String> mEventBus = new EventBus<>();
    protected Application mContext;
    protected boolean serviceStarted;
    protected boolean serviceConnected;
    protected final ServiceConnection mServiceConnection = new ServiceConnection() {

        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
            TelinkApplication.this.onServiceConnected(name, service);
        }

        @Override
        public void onServiceDisconnected(ComponentName name) {
            TelinkApplication.this.onServiceDisconnected(name);
        }
    };

    protected DeviceInfo mCurrentConnect;
    private BroadcastReceiver mLightReceiver;

    // public static TelinkApplication getInstance() {
    //     if (mThis == null)
    //         mThis = new TelinkApplication();
    //     return mThis;
    // }

    /**
     * 当前连接的设备
     *
     * @return
     */
    public DeviceInfo getConnectDevice() {
        return mCurrentConnect;
    }

    // @Override
    // public void onCreate() {
    //     mThis = this;
    //     this.mContext = this;
    //     super.onCreate();
    //     TelinkLog.d("TelinkApplication Created.");
    // }
    /**
     * Constructor for react-native.
     * @param context Application which handles service events
     */
    TelinkApplication(Application context) {
        logInfo = new StringBuilder("log:");
        mThis = this;
        this.mContext = context;
        TelinkLog.d("TelinkApplication Created.");
        // mAdapter = BluetoothAdapter.getDefaultAdapter();
        // mState = STATE_NONE;
        // mModule = module;
    }

    public void doInit() {
        // this.doInit(this);
        this.doInit(this.mContext);
    }

    public void doInit(Application context) {
        this.doInit(context, null);
    }

    /**
     * 执行初始化,APP启动时调用
     *
     * @param context 上下文
     * @param clazz   要启动的LightService
     */
    public void doInit(Application context, Class<? extends LightService> clazz) {
        this.mContext = context;
        LocalBroadcastManager.getInstance(this.mContext).registerReceiver(makeLightReceiver(), makeLightFilter());
        if (clazz != null)
            this.startLightService(clazz);
        this.registerNotificationParser(OnlineStatusNotificationParser.create());
        this.registerNotificationParser(GetGroupNotificationParser.create());
        this.registerNotificationParser(GetAlarmNotificationParser.create());
        this.registerNotificationParser(GetSceneNotificationParser.create());
        this.registerNotificationParser(GetTimeNotificationParser.create());
    }

    /**
     * 销毁,当退出APP时调用此方法
     */
    public void doDestroy() {
        this.stopLightService();
        if (this.mLightReceiver != null)
            LocalBroadcastManager.getInstance(this.mContext).unregisterReceiver(this.mLightReceiver);
        this.removeEventListeners();
        this.mCurrentConnect = null;
        this.serviceStarted = false;
        this.serviceConnected = false;
    }

    protected BroadcastReceiver makeLightReceiver() {
        if (this.mLightReceiver == null)
            this.mLightReceiver = new BroadcastReceiver() {

                @Override
                public void onReceive(Context context, Intent intent) {

                    switch (intent.getAction()) {
                        case LightService.ACTION_NOTIFICATION:
                            onNotify(intent);
                            break;
                        case LightService.ACTION_STATUS_CHANGED:
                            onStatusChanged(intent);
                            break;
                        case LightService.ACTION_UPDATE_MESH_COMPLETED:
                            onUpdateMeshCompleted(intent);
                            break;
                        case LightService.ACTION_OFFLINE:
                            onMeshOffline(intent);
                            break;
                        case LightService.ACTION_LE_SCAN:
                            onLeScan(intent);
                            break;
                        case LightService.ACTION_LE_SCAN_TIMEOUT:
                            onLeScanTimeout(intent);
                            break;
                        case LightService.ACTION_SCAN_COMPLETED:
                            onLeScanCompleted(intent);
                            break;
                        case LightService.ACTION_ERROR:
                            onError(intent);
                            break;
                    }
                }
            };

        return this.mLightReceiver;
    }

    protected IntentFilter makeLightFilter() {
        final IntentFilter filter = new IntentFilter();
        filter.addAction(LightService.ACTION_LE_SCAN);
        filter.addAction(LightService.ACTION_SCAN_COMPLETED);
        filter.addAction(LightService.ACTION_LE_SCAN_TIMEOUT);
        filter.addAction(LightService.ACTION_NOTIFICATION);
        filter.addAction(LightService.ACTION_STATUS_CHANGED);
        filter.addAction(LightService.ACTION_UPDATE_MESH_COMPLETED);
        filter.addAction(LightService.ACTION_OFFLINE);
        filter.addAction(LightService.ACTION_ERROR);
        return filter;
    }

    /********************************************************************************
     * Event API
     *******************************************************************************/

    /**
     * 添加一个事件监听器
     *
     * @param eventType 事件类型
     * @param listener  事件监听器
     */
    public void addEventListener(String eventType, EventListener<String> listener) {
        this.mEventBus.addEventListener(eventType, listener);
    }

    /**
     * 移除事件监听器
     *
     * @param listener
     */
    public void removeEventListener(EventListener<String> listener) {
        this.mEventBus.removeEventListener(listener);
    }

    /**
     * 从事件监听器中移除指定的事件
     *
     * @param eventType
     * @param listener
     */
    public void removeEventListener(String eventType, EventListener<String> listener) {
        this.mEventBus.removeEventListener(eventType, listener);
    }

    /**
     * 移除所有的事件监听器
     */
    public void removeEventListeners() {
        this.mEventBus.removeEventListeners();
    }

    /**
     * 分发事件
     *
     * @param event
     */
    public void dispatchEvent(Event<String> event) {
        this.mEventBus.dispatchEvent(event);
    }

    /********************************************************************************
     * Service API
     *******************************************************************************/

    /**
     * 启动LightService
     *
     * @param clazz
     */
    public void startLightService(Class<? extends LightService> clazz) {

        if (this.serviceStarted || this.serviceConnected)
            return;

        this.serviceStarted = true;

        Intent service = new Intent(this.mContext, clazz);
        this.mContext.bindService(service, this.mServiceConnection,
                Context.BIND_AUTO_CREATE);
    }

    /**
     * 停止LightService
     */
    public void stopLightService() {

        if (!this.serviceStarted)
            return;

        this.serviceStarted = false;

        if (this.serviceConnected) {
            this.mContext.unbindService(this.mServiceConnection);
        }
    }

    protected void onServiceConnected(ComponentName name, IBinder service) {

        TelinkLog.d("service connected --> " + name.getShortClassName());

        this.serviceConnected = true;
        this.dispatchEvent(ServiceEvent.newInstance(this, ServiceEvent.SERVICE_CONNECTED, service));
    }

    protected void onServiceDisconnected(ComponentName name) {

        TelinkLog.d("service disconnected --> " + name.getShortClassName());

        this.serviceConnected = false;
        this.dispatchEvent(ServiceEvent.newInstance(this, ServiceEvent.SERVICE_DISCONNECTED, null));
    }

    /********************************************************************************
     * Broadcast Receiver API
     *******************************************************************************/

    protected void onLeScan(Intent intent) {
        DeviceInfo deviceInfo = intent.getParcelableExtra(LightService.EXTRA_DEVICE);
        this.dispatchEvent(LeScanEvent.newInstance(this, LeScanEvent.LE_SCAN, deviceInfo));
    }

    protected void onLeScanCompleted(Intent intent) {
        this.dispatchEvent(LeScanEvent.newInstance(this, LeScanEvent.LE_SCAN_COMPLETED, null));
    }

    protected void onLeScanTimeout(Intent intent) {
        this.dispatchEvent(LeScanEvent.newInstance(this, LeScanEvent.LE_SCAN_TIMEOUT, null));
    }

    protected void onStatusChanged(Intent intent) {

        DeviceInfo deviceInfo = intent.getParcelableExtra(LightService.EXTRA_DEVICE);

        if (deviceInfo.status == LightAdapter.STATUS_LOGIN) {
            mCurrentConnect = deviceInfo;
            this.dispatchEvent(DeviceEvent.newInstance(this, DeviceEvent.CURRENT_CONNECT_CHANGED, deviceInfo));
        }else if (deviceInfo.status == LightAdapter.STATUS_LOGOUT){
            mCurrentConnect = null;
        }

        this.dispatchEvent(DeviceEvent.newInstance(this, DeviceEvent.STATUS_CHANGED, deviceInfo));
    }

    protected void onUpdateMeshCompleted(Intent intent) {
        this.dispatchEvent(MeshEvent.newInstance(this, MeshEvent.UPDATE_COMPLETED, -1));
    }

    protected void onMeshOffline(Intent intent) {
        this.dispatchEvent(MeshEvent.newInstance(this, MeshEvent.OFFLINE, -1));
    }

    protected void onError(Intent intent) {
        int errorCode = intent.getIntExtra(LightService.EXTRA_ERROR_CODE, -1);
        this.dispatchEvent(MeshEvent.newInstance(this, MeshEvent.ERROR, errorCode));
    }

    protected void onNotify(Intent intent) {
        NotificationInfo notifyInfo = intent.getParcelableExtra(LightService.EXTRA_NOTIFY);
        this.onNotify(notifyInfo);
    }

    protected void onNotify(NotificationInfo notifyInfo) {

        int opcode = notifyInfo.opcode;
        String eventType = NotificationEvent.getEventType((byte) opcode);

        if (Strings.isEmpty(eventType))
            return;

        NotificationEvent event = NotificationEvent.newInstance(this.mContext, eventType, notifyInfo);
        event.setThreadMode(Event.ThreadMode.Background);
        this.dispatchEvent(event);
    }

    /********************************************************************************
     * Notification Parser API
     *******************************************************************************/

    /**
     * 注册通知解析器
     *
     * @param parser
     * @see NotificationParser
     */
    protected void registerNotificationParser(NotificationParser parser) {
        NotificationParser.register(parser);
    }

//    SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS");
    SimpleDateFormat format = new SimpleDateFormat("HH:mm:ss.S");

    public void saveLog(String action) {
//        SimpleDateFormat sdf = new SimpleDateFormat("dd-M-yyyy hh:mm:ss");
//        Date date = sdf.parse(dateInString);

        String time = format.format(Calendar.getInstance().getTimeInMillis());
        logInfo.append("\n\t").append(time).append(":\t").append(action);
        /*if (Looper.myLooper() == Looper.getMainLooper()) {
            showToast(action);
        }*/

        TelinkLog.w("SaveLog: " + action);
    }
}
