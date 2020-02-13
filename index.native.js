const {
    NativeModules,
    DeviceEventEmitter,
    NativeEventEmitter,
    Platform
} = require('react-native');
const NativeModule = NativeModules.TelinkBt;
const tinycolor = require("tinycolor2");

class TelinkBt {
    static MESH_ADDRESS_MIN = 0x0001;
    static MESH_ADDRESS_MAX = 0x00FF;
    static GROUP_ADDRESS_MIN = 0x8001;
    static GROUP_ADDRESS_MAX = 0x80FF;
    static GROUP_ADDRESS_MASK = 0x00FF;
    static HUE_MIN = 0;
    static HUE_MAX = 360;
    static SATURATION_MIN = 0;
    static SATURATION_MAX = 100;
    static BRIGHTNESS_MIN = 5;
    static BRIGHTNESS_MAX = 100;
    static COLOR_TEMP_MIN = 5;
    static COLOR_TEMP_MAX = 100;
    static NODE_STATUS_OFF = 0;
    static NODE_STATUS_ON = 1;
    static NODE_STATUS_OFFLINE = 2;
    static RELAY_TIMES_MAX = 16;
    static DELAY_MS_AFTER_UPDATE_MESH_COMPLETED = 1;
    static DELAY_MS_COMMAND = 320;
    static ALARM_CREATE = 0;
    static ALARM_REMOVE = 1;
    static ALARM_UPDATE = 2;
    static ALARM_ENABLE = 3;
    static ALARM_DISABLE = 4;
    static ALARM_ACTION_TURN_OFF = 0;
    static ALARM_ACTION_TURN_ON = 1;
    static ALARM_ACTION_SCENE = 2;
    static ALARM_TYPE_DAY = 0;
    static ALARM_TYPE_WEEK = 1;

    static passthroughMode = undefined; // 通过串口或者说自定义发送数据来控制蓝牙节点

    // 由于 telink 提供了踢出为出厂状态的 0xE3 命令，因此在 hasOnlineStatusNotify 确保
    // 在线能运行 0xE3 的情况下，就不需要 needRefreshMeshNodesClaimed 来在移除前进行扫描了，
    // 带来可能的问题是 hasOnlineStatusNotify 有几秒的延迟，所以如果移除的一瞬间突然断开灯
    // 的电源的话，可能该灯会被假移除，不过这种可能性比较小，而且用户也可以按说明书强制恢复灯为
    // 出厂状态，所以好处远远大于坏处
    static hasOnlineStatusNotify = true;
    // static needRefreshMeshNodesClaimed = true;

    // 否则会因为 android/src/main/java/com/telink/bluetooth/light/LightAdapter.java
    // 的 updateMesh() 的 this.mScannedLights 没有数据而导致不进行 setNewdress() 操作
    static needRefreshMeshNodesBeforeConfig = true;

    static canConfigEvenDisconnected = true;
    static needClaimedBeforeConnect = true;

    static del4GroupStillSendOriginGroupAddress = true;

    // 开始以为 telink 没有默认群发地址，所以认领时需要同时加分组，后来发现用 0xFFFF 地址就可群发，
    // 所以下面只开启 defaultAllGroupAddress 而不开启 notDefaultAllGroupByGROUP_ADDRESS_MIN 即可
    // static notDefaultAllGroupByGROUP_ADDRESS_MIN = true;
    static defaultAllGroupAddress = 0xFFFF;

    static isSetNodeGroupAddrReturnAddresses = true;

    static doInit() {
        NativeModule.doInit();
    }

    static doDestroy() {
        NativeModule.doDestroy();
    }

    static addListener(eventName, handler) {
        if (Platform.OS === 'ios') {
            const TelinkBtEmitter = new NativeEventEmitter(NativeModule);

            TelinkBtEmitter.addListener(eventName, handler);
        } else {
            DeviceEventEmitter.addListener(eventName, handler);
        }
    }

    static removeListener(eventName, handler) {
        if (Platform.OS === 'ios') {
            const TelinkBtEmitter = new NativeEventEmitter(NativeModule);

            TelinkBtEmitter.removeListener(eventName, handler);
        } else {
            DeviceEventEmitter.removeListener(eventName, handler);
        }
    }

    static enableBluetooth() {
        NativeModule.enableBluetooth();
    }

    static enableSystemLocation() {
        NativeModule.enableSystemLocation();
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

    static sendCommand({
        opcode,
        meshAddress,
        valueArray,
        immediate = false,
    }) {
        NativeModule.sendCommand(opcode, meshAddress, valueArray, immediate);
    }

    static remind({
        meshAddress,
        immediate = false,
    }) {
        NativeModule.sendCommand(0xF2, meshAddress, [], immediate);
    }

    static isOnline(status) {
        return (status & 0x03) !== this.NODE_STATUS_OFFLINE;
    }

    static isOn(status) {
        return (status & 0x03) === this.NODE_STATUS_ON;
    }

    static changePower({
        meshAddress,
        value,
        type,
        delaySec = 0,
        immediate = false,
    }) {
        let changed = false;

        if (this.passthroughMode) {
            for (let mode in this.passthroughMode) {
                if (this.passthroughMode[mode].includes(type)) {
                    if (mode === 'silan') {
                        if (delaySec) {
                            NativeModule.sendCommand(0xF0, meshAddress, [value, 1, delaySec & 0xFF, delaySec >> 8 & 0xFF, delaySec >> 16 & 0xFF, delaySec >> 24 & 0xFF ], immediate);
                        } else {
                            NativeModule.sendCommand(0xF0, meshAddress, [value], immediate);
                        }
                        changed = true;
                    }
                    break;
                }
            }
        }

        if (!changed) {
            NativeModule.changePower(meshAddress, value);
        }
    }

    static changeBrightness({
        meshAddress,
        sceneSyncMeshAddress,
        hue = 0,
        saturation = 0,
        value,
        type,
        immediate = false,
    }) {
        let color = tinycolor.fromRatio({
            h: hue / this.HUE_MAX,
            s: saturation / this.SATURATION_MAX,
            v: value / this.BRIGHTNESS_MAX,
        }).toRgb();
        let changed = false;

        if (this.passthroughMode) {
            for (let mode in this.passthroughMode) {
                if (this.passthroughMode[mode].includes(type)) {
                    if (mode === 'silan') {
                        NativeModule.sendCommand(0xF2, meshAddress, [color.r, color.g, color.b], immediate);
                        changed = true;
                    }
                    break;
                }
            }
        }

        if (!changed) {
            NativeModule.changeBrightness(meshAddress, value);
        }

        this.selectNodeToResponseSceneId({
            sceneSyncMeshAddress,
        });
    }

    static changeColorTemp({
        meshAddress,
        value
    }) {
        NativeModule.changeColorTemp(meshAddress, value);
    }

    static changeColor({
        meshAddress,
        hue = 0,
        saturation = 0,
        value,
        type,
        immediate = false,
    }) {
        let color = tinycolor.fromRatio({
            h: hue / this.HUE_MAX,
            s: saturation / this.SATURATION_MAX,
            v: value / this.BRIGHTNESS_MAX,
        }).toRgb();
        let changed = false;

        if (this.passthroughMode) {
            for (let mode in this.passthroughMode) {
                if (this.passthroughMode[mode].includes(type)) {
                    if (mode === 'silan') {
                        NativeModule.sendCommand(0xF2, meshAddress, [color.r, color.g, color.b], immediate);
                        changed = true;
                    }
                    break;
                }
            }
        }

        if (!changed) {
            NativeModule.sendCommand(0xE2, meshAddress, [0x04, color.r, color.g, color.b], immediate);
        }
    }

    static changeScene({
        meshAddress,
        sceneSyncMeshAddress,
        scene,
        hue = 0,
        saturation = 0,
        value,
        color,
        colorBg,
        colorsLength = 1,
        colorSequence = 1,
        colorSequenceAndEnd = 0, // 只有（调色板更改出来的）新颜色才需要发命令（并在这里设为 1），否则物理灯串会显得卡顿
        colorIds = [1, 2, 3, 4, 5],
        colorBgId = 2,
        colorId = 1,
        speed = 3,
        type,
        immediate = false,
    }) {
        let changed = false;

        if (this.passthroughMode) {
            let color3 = color && tinycolor(color).toRgb();
            if (!color3) {
                color3 = tinycolor.fromRatio({
                    h: hue / this.HUE_MAX,
                    s: saturation / this.SATURATION_MAX,
                    v: value / this.BRIGHTNESS_MAX,
                }).toRgb();;
            }
            let color3Bg = colorBg && tinycolor(colorBg).toRgb();
            for (let mode in this.passthroughMode) {
                if (this.passthroughMode[mode].includes(type)) {
                    if (mode === 'silan') {
                        switch (scene) {
                            case 0:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, 1, color3.r, color3.g, color3.b], immediate);
                                changed = true;
                                break;
                            case 1:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, speed, color3.r, color3.g, color3.b], immediate);
                                changed = true;
                                break;
                            case 2:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, speed, color3.r, color3.g, color3.b], immediate);
                                changed = true;
                                break;
                            case 3:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, speed, color3.r, color3.g, color3.b], immediate);
                                changed = true;
                                break;
                            case 4:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, speed, color3.r, color3.g, color3.b], immediate);
                                changed = true;
                                break;
                            case 5:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, speed], immediate);
                                changed = true;
                                break;
                            case 6:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, speed, color3.r, color3.g, color3.b], immediate);
                                changed = true;
                                break;
                            case 7:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, speed, color3.r, color3.g, color3.b, colorSequence, colorsLength, colorSequenceAndEnd], immediate);
                                changed = true;
                                break;
                            case 8:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, speed, color3.r, color3.g, color3.b, colorSequence, colorsLength, colorSequenceAndEnd], immediate);
                                changed = true;
                                break;
                            case 9:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, speed, color3.r, color3.g, color3.b, colorSequence, colorsLength, colorSequenceAndEnd], immediate);
                                changed = true;
                                break;
                            case 10:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, speed], immediate);
                                changed = true;
                                break;
                            case 11:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, speed, color3.r, color3.g, color3.b, colorSequence, colorsLength, colorSequenceAndEnd], immediate);
                                changed = true;
                                break;
                            case 12:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, speed, color3.r, color3.g, color3.b, colorSequence, colorsLength, colorSequenceAndEnd], immediate);
                                changed = true;
                                break;
                            case 13:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, speed, color3.r, color3.g, color3.b, color3Bg.r, color3Bg.g, color3Bg.b], immediate);
                                changed = true;
                                break;
                            case 14:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, speed], immediate);
                                changed = true;
                                break;
                            case 15:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, speed], immediate);
                                changed = true;
                                break;
                            case 16:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, speed], immediate);
                                changed = true;
                                break;
                            case 17:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, speed], immediate);
                                changed = true;
                                break;
                            case 18:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, speed, color3.r, color3.g, color3.b], immediate);
                                changed = true;
                                break;
                            case 19:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, speed, color3.r, color3.g, color3.b, colorSequence, colorsLength, colorSequenceAndEnd], immediate);
                                changed = true;
                                break;
                            case 20:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, speed, color3.r, color3.g, color3.b, colorSequence, colorsLength, colorSequenceAndEnd], immediate);
                                changed = true;
                                break;
                            case 21:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, speed, color3.r, color3.g, color3.b, color3Bg.r, color3Bg.g, color3Bg.b], immediate);
                                changed = true;
                                break;
                            case 22:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, speed, color3.r, color3.g, color3.b, colorSequence, colorsLength, colorSequenceAndEnd], immediate);
                                changed = true;
                                break;
                            case 23:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, speed, color3.r, color3.g, color3.b, colorSequence, colorsLength, colorSequenceAndEnd], immediate);
                                changed = true;
                                break;
                            case 24:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, speed, color3.r, color3.g, color3.b], immediate);
                                changed = true;
                                break;
                            case 25:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, speed, color3.r, color3.g, color3.b, colorSequence, colorsLength, colorSequenceAndEnd], immediate);
                                changed = true;
                                break;
                            case 26:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, speed, color3.r, color3.g, color3.b, color3Bg.r, color3Bg.g, color3Bg.b], immediate);
                                changed = true;
                                break;
                            case 27:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, speed, color3.r, color3.g, color3.b, colorSequence, colorsLength, colorSequenceAndEnd], immediate);
                                changed = true;
                                break;
                            default:
                                break;
                        }
                    }
                    if (changed) {
                        break;
                    }
                }
            }
        }

        if (!changed) {
            NativeModule.sendCommand(0xEF, meshAddress, [scene], immediate);
        }

        this.selectNodeToResponseSceneId({
            sceneSyncMeshAddress,
        });
    }

    static selectNodeToResponseSceneId({
        sceneSyncMeshAddress,
        immediate = false,
    }) {
        if (sceneSyncMeshAddress !== undefined && sceneSyncMeshAddress !== null) {
            NativeModule.sendCommand(0xF7, this.defaultAllGroupAddress, [sceneSyncMeshAddress], immediate);
        }
    }

    static getTypeFromUuid = uuid => uuid;

    // 0xE3 是将一个节点踢出 mesh 功能：
    // * 恢复出厂设置
    // * 根据 Params[0] 配置 mesh_name
    // ** Params[0]: 没有这个参数或者该参数为 0  ，灯的 mesh_name 将被设置为 'out_of_mesh'；
    // ** 如果参数被设置为 1 ，灯的 mesh_name 将被设置为如下值
    //       android/src/main/java/com/telink/bluetooth/light/Manufacture.java 中的 factoryName
    //       ios/TelinkBtSDK/BTConst.h 中的 BTDevInfo_UserNameDef
    static out_of_mesh = 0;
    static telink_mesh1 = 1;

    static configNode({
        node,
        cfg,
        isToClaim,
        immediate = false,
    }) {
        return new Promise((resolve, reject) => {
            if (isToClaim) {
                NativeModule.configNode(node, cfg).then(payload => {
                    resolve(payload);
                }, err => {
                    reject(err);
                });
            } else {
                NativeModule.sendCommand(0xE3, node.meshAddress, [this.telink_mesh1], immediate)
                setTimeout(resolve, 100); // 这里延时 100 是随意定的，也许还能优化，但速度也足够快了，考虑到同时移除大量灯时要保证信号的稳定性，也许也不用优化了
            }
        });
    }

    static getTotalOfGroupIndex({
        meshAddress,
    }) {}

    static setNodeGroupAddr({
        toDel,
        meshAddress,
        groupAddress,
    }) {
        return new Promise((resolve, reject) => {
            let timer = setTimeout(() => reject({errCode: 'setNodeGroupAddr time out'}), 10000);
            NativeModule.setNodeGroupAddr(toDel, meshAddress, groupAddress).then(groupAddresses => {
                clearTimeout(timer);
                resolve(groupAddresses);
            }, reject)
        })
    }

    static setTime({
        meshAddress,
        year,
        month,
        day,
        hour,
        minute,
        second = 0,
        immediate = false,
    }) {
        NativeModule.sendCommand(0xE4, meshAddress, [year >> 8 & 0xFF, year & 0xFF, month + 1, day, hour, minute, second], immediate);
    }

    static getTime({
        meshAddress,
        relayTimes,
    }) {
        return new Promise((resolve, reject) => {
            let timer = setTimeout(() => reject({errCode: 'getTime time out'}), 10000);
            NativeModule.getTime(meshAddress, relayTimes).then(payload => {
                clearTimeout(timer);
                resolve(payload);
            }, reject)
        })
    }

    static setAlarm({
        meshAddress,
        crud,
        alarmId,
        status,
        action,
        type,
        month = 1, // telink 固件中时间月份是 1~12 而非 Java 或 JS 中标准的 0~11
        dayOrweek,
        hour,
        minute,
        second = 0,
        sceneId = 0,
        immediate = false,
    }) {
        NativeModule.sendCommand(0xE5, meshAddress, [crud, alarmId, status << 7 | type << 4 | action, month, dayOrweek, hour, minute, second, sceneId], immediate);
    }

    static getAlarm({
        meshAddress,
        relayTimes,
        alarmId,
    }) {
        return new Promise((resolve, reject) => {
            let timer = setTimeout(() => reject({errCode: 'getAlarm time out'}), 10000);
            NativeModule.getAlarm(meshAddress, relayTimes, alarmId).then(payload => {
                clearTimeout(timer);
                resolve(payload);
            }, reject)
        })
    }

    static cascadeLightStringGroup({ // 用于将一个组中的几个灯串级联模拟成一个灯串
        meshAddress,
        cascadeSeq = 1, // 向固件表明当前节点（一般为灯串）所处级联顺序，从 1 开始计数；如为 0 则代表退出级联模式
        groupNodes = 4, // 参与级联的灯串总数，也即 group.length
        groupBulbs = 96 * 4, // 参与级联总灯珠个数
        bulbOffset = 0, // 当前灯串首个灯珠地址偏移量，从 0 开始计数
        largestBulbs = 96, // 组中最多灯珠的灯串上的灯珠数
        immediate = false,
    }) {
        NativeModule.sendCommand(0xF6, meshAddress, [
            cascadeSeq,
            groupNodes,
            groupBulbs >>> 8 & 0xFF,
            groupBulbs & 0xFF,
            bulbOffset >>> 8 & 0xFF,
            bulbOffset & 0xFF,
            largestBulbs,
        ], immediate);
    }

    static flashWriteAttr({ // 设置灯串信息
        meshAddress,
        timeSequence = 1, // 灯串时序，1 为短时序，0 为长时序
        nodeBulbs = 96, // 灯串上激活灯的个数,最大值为255
        collideCenter = 40, // 碰撞特效的碰撞位置，因为灯串摆成树形时，碰撞位置如果为总灯数的 1/2 的话不好看
        flagPercent = 100, // 国旗模式下相邻两个颜色所属灯串长度百分比
        immediate = false,
    }) {
        NativeModule.sendCommand(0xF5, meshAddress, [
            timeSequence,
            nodeBulbs,
            collideCenter,
            flagPercent,
        ], immediate);
    }

    static getFirmwareVersion({
        meshAddress = 0xFFFF,
        relayTimes = 7,
        immediate = false,
    }) {
        NativeModule.sendCommand(0xC7, meshAddress, [
            relayTimes,
            0,  // 0xC7 的子命令，0 为获取版本信息
        ], immediate);
    }

    static getOtaState({
        meshAddress = 0x0000,
        relayTimes = 7,
        immediate = false,
    }) {
        NativeModule.sendCommand(0xC7, meshAddress, [
            relayTimes,
            5,  // 0xC7 的子命令，5 为获取 OTA 状态
        ], immediate);
    }

    static setOtaMode({
        meshAddress = 0x0000,
        relayTimes = 7,     // 转发次数
        otaMode = 'gatt',   // OTA 模式， gatt 为单灯升级， mesh 为单灯升级后有单灯自动通过 mesh 网络发送新固件给其它灯
        type = 0xFB00,      // 设备类型（gatt OTA 模式请忽略此字段）
        immediate = false,
    }) {
        NativeModule.sendCommand(0xC7, meshAddress, [
            relayTimes,
            6,  // 0xC7 的子命令，6 为设置 OTA 模式(OTA mode)与设备类型(Device type)
            otaMode === 'mesh' ? 1 : 0,
            type & 0xFF,
            type >>> 8 & 0xFF,
        ], immediate);
    }

    static stopMeshOta({
        meshAddress = 0xFFFF,
        immediate = false,
    }) {
        NativeModule.sendCommand(0xC6, meshAddress, [
            0xFE,
            0xFF,
        ], immediate);
    }

    static startOta({
        firmware,
    }) {
        NativeModule.startOta(firmware);
    }

    static isValidFirmware(firmware) {
        return firmware[0] === 0x0E &&
            (firmware[1] & 0xFF) === 0x80 &&
            firmware.length > 6;
    }
}

module.exports = TelinkBt;
