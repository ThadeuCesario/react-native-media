/**
 * @author Haroldo Shigueaki Teruya <haroldo.s.teruya@gmail.com>
 * @version 1.0.0
 */

//==========================================================================
// IMPORTS

import {
    Platform,
    NativeModules
} from 'react-native';

//==========================================================================
/**
 * @class
 */
class AppStateNativeManager {

    //==========================================================================
    // GLOBAL VARIABLES

    //==========================================================================
    // CONSTRUCTOR

    /**
     * Creates a instance of AudioManager.
     */
    constructor() {

        this.Event = {
            ON_RESUME: 'onResume',
            ON_PAUSE: 'onPause',
            ON_DESTROY: 'onDestroy'
        };
        Object.freeze(this.Event);
    }

    //==========================================================================
    // METHODS

    addAllListener(): void {        
        (Platform.OS === 'ios') && NativeModules.AppStateNativeManagerModule.addAllListener();
    }

    removeAllListener(): void {
        (Platform.OS === 'ios') && NativeModules.AppStateNativeManagerModule.removeAllListener();
    }

}

//==========================================================================
// EXPORTS

/**
 * @module AudioManager object
 */
module.exports = new AppStateNativeManager();
