({
    doInit : function(component, event, helper) {
        // Initialize component
        console.log('MapPickerVfWrapper initialized');
    },
    
    handleLocationChange : function(component, event, helper) {
        // Get the location data from the LWC event
        // Aura wraps the event detail in different ways - try multiple approaches
        var detail = event.getParam('detail') || event.detail || event.sq;
        console.log("Aura handleLocationChange - detail:", detail);
        
        if (detail && detail.latitude !== undefined && detail.longitude !== undefined) {
            // Update component attributes
            component.set("v.latitude", detail.latitude);
            component.set("v.longitude", detail.longitude);
            
            console.log("Updated component attributes - latitude:", detail.latitude, "longitude:", detail.longitude);
            
            // Notify Visualforce page via custom event attribute
            component.set("v.lastUpdate", new Date().getTime());
        }
    }
})