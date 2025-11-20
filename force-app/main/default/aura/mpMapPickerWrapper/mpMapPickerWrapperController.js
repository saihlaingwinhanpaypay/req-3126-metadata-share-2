({
    doInit : function(component, event, helper) {
        // Initialize component
    },
    
    handleLocationChange : function(component, event, helper) {
        // Get the location data from the LWC event
        // Aura wraps the event detail in different ways - try multiple approaches
        var detail = event.getParam('detail') || event.detail || event.sq;
        
        if (detail && detail.latitude !== undefined && detail.longitude !== undefined) {
            // Update component attributes
            component.set("v.latitude", detail.latitude);
            component.set("v.longitude", detail.longitude);
            
            // Notify Visualforce page via custom event attribute
            component.set("v.lastUpdate", new Date().getTime());
        }
    }
})