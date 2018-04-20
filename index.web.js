class TelinkBt {
    static MESH_ADDRESS_MIN = 0x0001;
    static MESH_ADDRESS_MAX = 0x00FF;
    static NODE_STATUS_OFF = 0;
    static NODE_STATUS_ON = 1;
    static NODE_STATUS_OFFLINE = 2;

    static doInit() {}

    static doDestroy() {}

    static addListener(eventName, handler) {}

    static removeListener(eventName, handler) {}

    static notModeAutoConnectMesh() {
        return true;
    }

    // 自动重连
    static autoConnect({
        userMeshName,
        userMeshPwd,
        otaMac
    }) {}

    // 自动刷新 Notify
    static autoRefreshNotify({
        repeatCount,
        Interval
    }) {}

    static idleMode({
        disconnect
    }) {}

    static startScan({
        meshName,
        outOfMeshName,
        timeoutSeconds,
        isSingleNode,
    }) {}

    static changePower({
        meshAddress,
        value
    }) {}

    static changeBrightness({
        meshAddress,
        value
    }) {}

    static changeTemperatur({
        meshAddress,
        value
    }) {}

    static changeColor({
        meshAddress,
        value
    }) {}

    static configNode({
        node,
        cfg,
    }) {}
}

module.exports = TelinkBt;
