const {
    NativeModules,
    DeviceEventEmitter,
} = require('react-native');
const NativeModule = NativeModules.TelinkBt;

class TelinkBt {
    static MESH_ADDRESS_MIN = 0x0001;
    static MESH_ADDRESS_MAX = 0x00FF;
    static NODE_STATUS_OFF = 0;
    static NODE_STATUS_ON = 1;
    static NODE_STATUS_OFFLINE = 2;

    static doInit() {
        NativeModule.doInit();
    }

    static doDestroy() {
        NativeModule.doDestroy();
    }

    static addListener(eventName, handler) {
        DeviceEventEmitter.addListener(eventName, handler);
    }

    static removeListener(eventName, handler) {
        DeviceEventEmitter.removeListener(eventName, handler);
    }

    static notModeAutoConnectMesh() {
        return NativeModule.notModeAutoConnectMesh();
    }

    // 自动重连
    static autoConnect({
        userMeshName,
        userMeshPwd,
        otaMac
    }) {
        return NativeModule.autoConnect(userMeshName, userMeshPwd, otaMac);
    }

    // 自动刷新 Notify
    static autoRefreshNotify({
        repeatCount,
        Interval
    }) {
        return NativeModule.autoRefreshNotify(repeatCount, Interval);
    }

    static idleMode({
        disconnect
    }) {
        return NativeModule.idleMode(disconnect);
    }

    static startScan({
        meshName,
        outOfMeshName,
        timeoutSeconds,
        isSingleNode,
    }) {
        return NativeModule.startScan(meshName, outOfMeshName, timeoutSeconds, isSingleNode);
    }

    static changePower({
        meshAddress,
        value
    }) {
        NativeModule.changePower(meshAddress, value);
    }

    static changeBrightness({
        meshAddress,
        value
    }) {
        NativeModule.changeBrightness(meshAddress, value);
    }

    static changeTemperatur({
        meshAddress,
        value
    }) {
        NativeModule.changeTemperatur(meshAddress, value);
    }

    static changeColor({
        meshAddress,
        value
    }) {
        NativeModule.changeColor(meshAddress, value);
    }

    static configNode({
        node,
        cfg,
    }) {
        return NativeModule.configNode(node, cfg);
    }
}

module.exports = TelinkBt;
