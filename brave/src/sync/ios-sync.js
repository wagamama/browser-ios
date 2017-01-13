
console.log = (function (old_function) {
    return function (text) {
        old_function(text);
        document.write("<div style='font-size:25'>"+ text +"</div>");
    };
} (console.log.bind(console)));



if (!self.chrome || !self.chrome.ipc) {
    var initCb = () => {}

    self.chrome = {}
    const ipc = {}
    ipc.on = (message, cb) => {
        window.webkit.messageHandlers.syncToIOS.postMessage({message, cb});
        if (message === 'got-init-data') {
            if (cb) {
                initCb = cb
            }
            initCb(null, injected_seed, injected_deviceId, injected_braveSyncConfig)
        }
    }
    ipc.send = (message, arg1, arg2) => {
        window.webkit.messageHandlers.syncToIOS.postMessage({message, arg1, arg2});
//        if (message === 'save-init-data') {
//            seed = arg1
//            deviceId = arg2
//            ipc.on('got-init-data')
//        }
    }
    self.chrome.ipc = ipc

    chrome.ipcRenderer = chrome.ipc
}



