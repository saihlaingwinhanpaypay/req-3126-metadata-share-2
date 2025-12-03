({
    doInit : function(component, event, helper) {
        // Initialize component
    },
    
    handleLocationMessage : function(component, message, helper) {
        // Lightning Message Serviceから位置情報を取得
        if (message && message.getParam) {
            var payload = message.getParam('latitude') !== undefined ? message.getParams() : null;
            
            if (payload && payload.latitude !== undefined && payload.longitude !== undefined) {
                // attributesを更新する
                component.set("v.latitude", payload.latitude);
                component.set("v.longitude", payload.longitude);
            }
        }
    }
})