package com.media.module;

import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ViewManager;
import com.media.module.appstate.AppStateNativeManagerModule;
import com.media.module.audio.AudioManagerModule;
import com.media.module.device.DeviceManagerModule;
import com.media.module.directory.DirectoryManagerModule;
import com.media.module.permission.PermissionManagerModule;
import com.media.module.recorder.RecorderManagerModule;
import com.media.module.call.CallManagerModule;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class MediaPackage implements ReactPackage
{
    @Override
    public List<NativeModule> createNativeModules(ReactApplicationContext reactContext)
    {
        List<NativeModule> modules = new ArrayList<>();
        modules.add(new AudioManagerModule(reactContext));
        modules.add(new DeviceManagerModule(reactContext));
        modules.add(new DirectoryManagerModule(reactContext));
        modules.add(new RecorderManagerModule(reactContext));
        modules.add(new PermissionManagerModule(reactContext));
        modules.add(new AppStateNativeManagerModule(reactContext));
        modules.add(new CallManagerModule(reactContext));
        return modules;
    }

    @Override
    public List<ViewManager> createViewManagers(ReactApplicationContext reactContext)
    {
        return Collections.emptyList();
    }
}
