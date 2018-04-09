package com.media.module.device;

import android.graphics.Bitmap;
import android.media.AudioManager;
import android.os.PowerManager;
import android.util.Base64;
import android.content.pm.PackageManager;
import android.util.Log;

import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.media.module.Util;

import java.io.ByteArrayOutputStream;

import static android.content.Context.AUDIO_SERVICE;
import static android.content.Context.POWER_SERVICE;

/**
 * Created by Teruya on 09/01/2018.
 *
 */

public class DeviceManagerModule extends ReactContextBaseJavaModule implements LifecycleEventListener
{
    // ATRIBUTES ===================================================================================

    private ReactApplicationContext reactContext = null;

    // for sleeping purpose
    private PowerManager.WakeLock wakeLock;

    // for proximity management
    private PowerManager.WakeLock proximityWakeLock;
    private Boolean proximityEmitEnable = true;
    private Boolean proximityEmitInBackgroundEnable = false;
    private Boolean isProximity = false;
    private static final int PROXIMITYNEAR = 0;
    private static final int PROXIMITYFAR = 1;
    private static final int ONBACKGROUND = 2;
    private static final int ONACTIVE = 3;

    private ProximitySensorHandler proximitySensorHandler = null;

    // CONSTRUCTOR =================================================================================

    public DeviceManagerModule(final ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;

        PowerManager powerManager = (PowerManager) reactContext.getSystemService(POWER_SERVICE);

        // for sleeping purpose
        wakeLock = powerManager.newWakeLock(PowerManager.SCREEN_DIM_WAKE_LOCK, getName());

        // for proximity management
        proximityWakeLock = powerManager.newWakeLock(PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK, getName());
    }


    // METHODS =====================================================================================

    @Override
    public String getName()
    {
        return "DeviceManagerModule";
    }

    /**
     * For default, the idle timer is on.
     *
     * @param enable
     * @param promise
     */
    @ReactMethod
    public void setIdleTimerEnable(boolean enable, final Promise promise) {

        if( enable ) {
            // enable = true
            // turn on the sleep mode
            if ( wakeLock.isHeld() ) {
                wakeLock.release();
                promise.resolve(true);
            } else {
                promise.resolve(false);
            }
        } else {
            // enable = false
            // turn off the sleep mode
            if( !wakeLock.isHeld() ) {
                wakeLock.acquire();
                promise.resolve(true);
            } else {
                promise.resolve(false);
            }
        }
    }

    /**
     * For default, the proximity sensor do nothing.
     *
     * @param enable
     * @param promise
     */
    @ReactMethod
    public void setProximityEnable(Boolean enable, final Promise promise) {
        Log.d(getName(), "setProximityEnable " + enable);

        if ( reactContext.getPackageManager() != null && reactContext.getPackageManager().hasSystemFeature(PackageManager.FEATURE_SENSOR_PROXIMITY) ) {
            Log.d(getName(), "setProximityEnable exist sensor support");
        } else {
            Log.d(getName(), "setProximityEnable not exist sensor support");
            promise.resolve(false);
            return;
        }

        if( enable ) {
            // enable = true
            // turn off screen when proximity on
            if( !proximityWakeLock.isHeld() ) {
                proximityWakeLock.acquire();

                this.enableProximitySensorHandler();

                if ( promise != null ) {
                    promise.resolve(true);
                }
            } else {
                if ( promise != null ) promise.resolve(false);
            }
        } else {
            // enable = false
            // do nothing when proximity on
            if ( proximityWakeLock.isHeld() ) {
                proximityWakeLock.release();

                this.proximitySensorHandler.unregister();
                this.proximitySensorHandler = null;

                if ( promise != null ) {
                    promise.resolve(true);
                }
            } else {
                if ( promise != null ) promise.resolve(false);
            }
        }
    }

    private void enableProximitySensorHandler() {

        this.proximitySensorHandler = null;
        this.proximitySensorHandler = new ProximitySensorHandler(reactContext, new ProximitySensorHandler.Delegate() {
            @Override
            public void onProximityChanged(Boolean isNear) {

                if ( reactContext.hasActiveCatalystInstance() && proximityEmitEnable ) {
                    if ( isNear ) {
                        reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit("onProximityChanged", DeviceManagerModule.PROXIMITYNEAR);
                    } else {
                        reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit("onProximityChanged", DeviceManagerModule.PROXIMITYFAR);
                    }

                    isProximity = isNear;
                }
            }
        });
    }

    @ReactMethod
    public void mute(boolean enable, final Promise promise) {

        //an AudioManager object, to change the volume settings
        AudioManager amanager = (AudioManager)reactContext.getSystemService(AUDIO_SERVICE);

        if (enable) {
            //turn ringer silent
            amanager.setRingerMode(AudioManager.RINGER_MODE_SILENT);
            amanager.setStreamMute(AudioManager.STREAM_SYSTEM, true);
            amanager.setStreamMute(AudioManager.STREAM_MUSIC, true);

            promise.resolve(true);
        } else {
            amanager.setRingerMode(AudioManager.RINGER_MODE_NORMAL);
            amanager.setStreamMute(AudioManager.STREAM_SYSTEM, false);
            amanager.setStreamMute(AudioManager.STREAM_MUSIC, false);

            promise.resolve(true);
        }
    }

    @ReactMethod
    public void addBlur(Promise promise) {

        Bitmap bitmap = Util.fastblur(Util.getScreenShot(getCurrentActivity()), 10);
        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream);
        String encoded = Base64.encodeToString(byteArrayOutputStream.toByteArray(), Base64.DEFAULT);
        promise.resolve(encoded);
    }

    @ReactMethod
    public void setProximityEmitInBackgroundEnable(boolean enable) {
        this.proximityEmitInBackgroundEnable = enable;
    }

    // SEND EVENT ==================================================================================

    @Override
    public void initialize() {
        getReactApplicationContext().addLifecycleEventListener(this);
    }

    @Override
    public void onHostResume() {

        this.proximityEmitEnable = true;

        if ( reactContext.hasActiveCatalystInstance() && !isProximity ) {
            reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit("onProximityChanged", DeviceManagerModule.ONACTIVE);
        }
    }

    @Override
    public void onHostPause() {

        if ( reactContext.hasActiveCatalystInstance() && !isProximity ) {
            reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit("onProximityChanged", DeviceManagerModule.ONBACKGROUND);
        }
    }

    @Override
    public void onHostDestroy() {
//         do not set state to destroyed, do not send an event. By the current implementation, the
//         catalyst instance is going to be immediately dropped, and all JS calls with it.
    }

    // CLASS =======================================================================================
}
