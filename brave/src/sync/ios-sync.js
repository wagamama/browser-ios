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
        window.webkit.messageHandlers.syncToIOS_on.postMessage({on_msg: message});
        if (message === 'got-init-data') {
            if (cb) {
                initCb = cb
            }
            var injected_deviceId = new Uint8Array([1,2,3,4]);
            var injected_braveSyncConfig = {apiVersion: '0', serverUrl: 'https://sync-staging.brave.com', debug:true}
            initCb(null, null, injected_deviceId, injected_braveSyncConfig)
        }
    }
    ipc.send = (message, arg1, arg2) => {
        window.webkit.messageHandlers.syncToIOS_send.postMessage({message: message, arg1: arg1, arg2: arg2});
//        if (message === 'save-init-data') {
//            seed = arg1
//            deviceId = arg2
//            ipc.on('got-init-data')
//        }
    }
    self.chrome.ipc = ipc

    chrome.ipcRenderer = chrome.ipc
}



