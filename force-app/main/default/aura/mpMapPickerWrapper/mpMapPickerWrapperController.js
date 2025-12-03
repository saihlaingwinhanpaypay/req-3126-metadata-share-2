({
    doInit : function(component, event, helper) {
        // Initialize component
    },
    
    handleLocationChange : function(component, event, helper) {
        // LWC eventから位置情報を取得
        var detail = event.getParam('detail') || event.detail || event.sq;
        
        if (detail && detail.latitude !== undefined && detail.longitude !== undefined) {
            // attributesを更新する
            component.set("v.latitude", detail.latitude);
            component.set("v.longitude", detail.longitude);
            
            // Visualforce ページに通知する
            component.set("v.lastUpdate", new Date().getTime());
        }
    }
})