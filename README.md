# React Native Bluetooth Telink

[![npm version](http://img.shields.io/npm/v/react-native-bt-telink.svg?style=flat-square)](https://npmjs.org/package/react-native-bt-telink "View this project on npm")
[![npm downloads](http://img.shields.io/npm/dm/react-native-bt-telink.svg?style=flat-square)](https://npmjs.org/package/react-native-bt-telink "View this project on npm")
[![npm licence](http://img.shields.io/npm/l/react-native-bt-telink.svg?style=flat-square)](https://npmjs.org/package/react-native-bt-telink "View this project on npm")
[![Platform](https://img.shields.io/badge/platform-ios%20%7C%20android-989898.svg?style=flat-square)](https://npmjs.org/package/react-native-bt-telink "View this project on npm")

Component implementation for Bluetooth Mesh SDK of Telink.

## Install

```shell
npm i --save react-native-bt-telink
```

### Android
In `android/app/build.gradle`
```
dependencies {
    compile project(':react-native-bt-telink')
}
```

In `android/app/src/main/java/com/YourProject/MainApplication.java`
```
import com.telink.TelinkBtPackage;
...
    new TelinkBtPackage(),
```

In `android/settings.gradle`
```
include ':react-native-bt-telink'
project(':react-native-bt-telink').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-bt-telink/android')
```

### iOS
In `ios/Podfile`
```
  pod 'RNBtTelink', :path => '../node_modules/react-native-bt-telink'
```

    cd ios
    pod install

## Usage

```jsx
import React from 'react';
import { View } from 'react-native';
import meshModule from 'react-native-bt-telink';

export default class MeshModuleExample extends React.Component {
    constructor(props) {
        super(props);
        meshModule.passthroughMode = {
            silan: [
                1,
                7,
            ],
            sllc: [
                30848,
            ],
        };
    }

    componentDidMount() {
        meshModule.addListener('leScan', this.onLeScan);
        meshModule.doInit();
    }

    onLeScan = data => console.warn(data)

    render() {
        return (
            <View/>
        );
    }
}

## Sponsor

Alipay: flyskywhy@gmail.com

ETH: 0xd02fa2738dcbba988904b5a9ef123f7a957dbb3e
