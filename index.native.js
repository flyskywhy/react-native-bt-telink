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
    static DELAY_MS_AFTER_UPDATE_MESH_COMPLETED = 1;

    static passthroughMode = undefined; // 通过串口或者说自定义发送数据来控制蓝牙 节点

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

    static testMeshOpcode({
        opcode,
        meshAddress,
        valueArray
    }) {
        NativeModule.sendCommand(opcode, meshAddress, valueArray);
    }

    static changePower({
        meshAddress,
        value,
        type,
    }) {
        let changed = false;

        if (this.passthroughMode) {
            for (let mode in this.passthroughMode) {
                if (this.passthroughMode[mode].includes(type)) {
                    if (mode === 'silan') {
                        NativeModule.sendCommand(0xF0, meshAddress, [value]);
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
        hue = 0,
        saturation = 0,
        value,
        type,
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
                        NativeModule.sendCommand(0xF2, meshAddress, [color.r, color.g, color.b]);
                        changed = true;
                    }
                    break;
                }
            }
        }

        if (!changed) {
            NativeModule.changeBrightness(meshAddress, value);
        }
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
                        NativeModule.sendCommand(0xF2, meshAddress, [color.r, color.g, color.b]);
                        changed = true;
                    }
                    break;
                }
            }
        }

        if (!changed) {
            NativeModule.sendCommand(0xE2, meshAddress, [0x04, color.r, color.g, color.b]);
        }
    }

    static changeScene({
        meshAddress,
        scene,
        hue = 0,
        saturation = 0,
        value,
        colorIds = [1, 2, 3, 4, 5],
        type,
    }) {
        let changed = false;

        if (this.passthroughMode) {
            let color = tinycolor.fromRatio({
                h: hue / this.HUE_MAX,
                s: saturation / this.SATURATION_MAX,
                v: value / this.BRIGHTNESS_MAX,
            }).toRgb();
            for (let mode in this.passthroughMode) {
                if (this.passthroughMode[mode].includes(type)) {
                    if (mode === 'silan') {
                        switch (scene) {
                            case 0:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene]);
                                changed = true;
                                break;
                            case 1:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, color.r, color.g, color.b, 2]);
                                changed = true;
                                break;
                            case 2:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, color.r, color.g, color.b]);
                                changed = true;
                                break;
                            case 3:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, color.r, color.g, color.b]);
                                changed = true;
                                break;
                            case 4:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, color.r, color.g, color.b]);
                                changed = true;
                                break;
                            case 5:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene]);
                                changed = true;
                                break;
                            case 6:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, color.r, color.g, color.b]);
                                changed = true;
                                break;
                            case 7:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, ...colorIds]);
                                changed = true;
                                break;
                            case 8:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, ...colorIds]);
                                changed = true;
                                break;
                            case 9:
                                NativeModule.sendCommand(0xF1, meshAddress, [scene, ...colorIds]);
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
            NativeModule.sendCommand(0xEF, meshAddress, [scene]);
        }
    }

    static getTypeFromUuid = uuid => uuid;

    static out_of_mesh = 0;
    static telink_mesh1 = 1;

    static configNode({
        node,
        cfg,
        isToClaim,
    }) {
        return new Promise((resolve, reject) => {
            if (isToClaim) {
                NativeModule.configNode(node, cfg).then(payload => {
                    resolve(payload);
                }, err => {
                    reject(err);
                });
            } else {
                NativeModule.sendCommand(0xE3, node.meshAddress, [this.telink_mesh1])
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
}

module.exports = TelinkBt;
