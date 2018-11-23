package com.telink.bluetooth.light;

import android.os.Parcel;
import android.os.Parcelable;

/**
 * Created by kee on 2017/10/18.
 */

public class ErrorReportInfo implements Parcelable {


    /**
     * state code
     */
    public int stateCode;

    /**
     * error code
     */
    public int errorCode;

    public int deviceId;

    public ErrorReportInfo() {

    }

    public static final Creator<ErrorReportInfo> CREATOR = new Creator<ErrorReportInfo>() {
        @Override
        public ErrorReportInfo createFromParcel(Parcel in) {
            return new ErrorReportInfo(in);
        }

        @Override
        public ErrorReportInfo[] newArray(int size) {
            return new ErrorReportInfo[size];
        }
    };

    public ErrorReportInfo(Parcel in) {
        this.stateCode = in.readInt();
        this.errorCode = in.readInt();
        this.deviceId = in.readInt();
    }

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeInt(this.stateCode);
        dest.writeInt(this.errorCode);
        dest.writeInt(this.deviceId);
    }

}
