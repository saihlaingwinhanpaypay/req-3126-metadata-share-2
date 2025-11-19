({
    doInit : function(component, event, helper) {
        // Initialize component
        console.log('MapPickerVfWrapper initialized');
    },
    
    handleLocationChange : function(component, event, helper) {
        // Get the location data from the LWC event
        var detail = event.getParam('detail');
        if (detail) {
            component.set("v.latitude", detail.latitude);
            component.set("v.longitude", detail.longitude);
            
            // Dispatch a custom event that can be caught by Visualforce
            var vfEvent = component.getEvent("locationUpdate");
            vfEvent.setParams({
                "latitude": detail.latitude,
                "longitude": detail.longitude
            });
            vfEvent.fire();
            
            // Also update parent page via JavaScript
            if (typeof window.updateLocationFromAura === 'function') {
                window.updateLocationFromAura(detail.latitude, detail.longitude);
            }
        }
    }
})