({
    doInit : function(component, event, helper) {
        // Initialize component
        console.log('MapPickerVfWrapper initialized');
    },
    
    handleLocationChange : function(component, event, helper) {
        // Get the location data from the LWC event
        var detail = event.getParam('detail');
        console.log("Aura handleLocationChange - detail:", detail);
        
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
            console.log("Checking for window.updateLocationFromAura function:", typeof window.updateLocationFromAura);
            if (typeof window.updateLocationFromAura === 'function') {
                console.log("Calling window.updateLocationFromAura with:", detail.latitude, detail.longitude);
                window.updateLocationFromAura(detail.latitude, detail.longitude);
            } else {
                console.error("window.updateLocationFromAura function not found!");
            }
        } else {
            console.error("No detail in locationchange event");
        }
    }
})