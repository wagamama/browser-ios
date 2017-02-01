console.log = (function (old_function) {
    return function (text) {
        old_function(text);
        document.write("<div style='font-size:25'>"+ text +"</div>");
    };
} (console.log.bind(console)));

var callbackList = {} // message name to callback function

if (!self.chrome || !self.chrome.ipc) {
    var initCb = () => {}

    self.chrome = {}
    const ipc = {}
    ipc.on = (message, cb) => {
        window.webkit.messageHandlers.syncToIOS_on.postMessage({message: message});
        if (message === 'got-init-data') {
            if (cb) {
                initCb = cb
            }
            // native has injected these varibles into the js context, or from 'save-init-data'
            initCb(null, injected_seed, injected_deviceId, injected_braveSyncConfig)
        } else {
            callbackList[message] = cb
        }
    }
    ipc.send = (message, arg1, arg2) => {
        window.webkit.messageHandlers.syncToIOS_send.postMessage({message: message, arg1: arg1, arg2: arg2});
        if (message === 'save-init-data') {
            injected_seed = arg1
            injected_deviceId = arg2
            ipc.on('got-init-data')
        }
    }
    self.chrome.ipc = ipc

    chrome.ipcRenderer = chrome.ipc
}


