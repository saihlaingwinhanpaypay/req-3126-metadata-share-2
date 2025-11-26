({
    doInit : function(component, event, helper) {
        // Initialize component
    },
    
    handleLocationChange : function(component, event, helper) {
        // Get the location data from the LWC event
        var detail = event.getParam('detail') || event.detail || event.sq;
        
        if (detail && detail.latitude !== undefined && detail.longitude !== undefined) {
            // Update component attributes
            component.set("v.latitude", detail.latitude);
            component.set("v.longitude", detail.longitude);
            
            // Notify Visualforce page
            component.set("v.lastUpdate", new Date().getTime());
        }
    }
})