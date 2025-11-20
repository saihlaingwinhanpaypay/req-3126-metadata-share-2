# Salesforce DX Project: PayPay Map Picker

Interactive map component for store location selection using Leaflet.js.

## Features

- 📍 Interactive map with draggable marker
- 🔍 Address search (geocoding via Nominatim)
- 🌐 OpenStreetMap tiles
- 📱 Responsive design
- 🔒 Security-hardened implementation

## Components

- **mpMapPicker** - Lightning Web Component (Leaflet map)
- **mpMapPickerWrapper** - Aura wrapper component
- **mpFormBank** - Visualforce page integration

## Third-Party Licenses

This project uses the following open-source software:

- **Leaflet** v1.9.4+ - BSD-2-Clause License
  - Copyright (c) 2010-2023, Vladimir Agafonkin
  - https://leafletjs.com/

- **OpenStreetMap** - Open Database License (ODbL)
  - © OpenStreetMap contributors
  - https://www.openstreetmap.org/copyright

See [THIRD_PARTY_NOTICES.md](./THIRD_PARTY_NOTICES.md) for complete license information.

## Security & Compliance Documentation

- [CSP_CONFIGURATION_GUIDE.md](./CSP_CONFIGURATION_GUIDE.md) - Content Security Policy setup
- [XSS_SECURITY_GUIDE.md](./XSS_SECURITY_GUIDE.md) - XSS prevention measures
- [LEAFLET_PLUGIN_SECURITY_GUIDE.md](./LEAFLET_PLUGIN_SECURITY_GUIDE.md) - Plugin security
- [OSM_OPTIMIZATION_GUIDE.md](./OSM_OPTIMIZATION_GUIDE.md) - Tile usage optimization
- [OSM_POLICY_COMPLIANCE.md](./OSM_POLICY_COMPLIANCE.md) - OSM Terms of Use compliance
- [LICENSE_COMPLIANCE_GUIDE.md](./LICENSE_COMPLIANCE_GUIDE.md) - License compliance
- [THIRD_PARTY_NOTICES.md](./THIRD_PARTY_NOTICES.md) - Third-party licenses

## Deployment

### Prerequisites

1. Salesforce DX CLI
2. Authorized org connection
3. Leaflet static resource uploaded

### Deploy Commands

```bash
# Deploy to sandbox
sfdx force:source:deploy -p force-app/main/default -u sandbox

# Deploy to production
sfdx force:source:deploy -p force-app/main/default -u production
```

### Post-Deployment Setup

1. Configure Remote Site Settings (see CSP_CONFIGURATION_GUIDE.md)
2. Add CSP Trusted Sites (see CSP_CONFIGURATION_GUIDE.md)
3. Verify map attribution is visible
4. Test address search functionality

## Configuration

### Visualforce Page Integration

```xml
<apex:page standardController="mpOpportunity__c" extensions="mpForm">
    <!-- Map container -->
    <div id="leafletMapContainer"></div>
    
    <!-- Input fields -->
    <apex:InputText value="{!mpOpportunity__c.OgglatitudeInput__c}" id="ylatitude" />
    <apex:InputText value="{!mpOpportunity__c.OgglongitudeInput__c}" id="ylongitude" />
</apex:page>
```

## Usage

1. Map initializes with current location or stored coordinates
2. User can:
   - Click map to place marker
   - Drag marker to new position
   - Search by address
3. Latitude/longitude automatically update in input fields
4. Values saved with record

## Compliance

✅ OSM Tile Usage Policy compliant  
✅ Nominatim Usage Policy compliant  
✅ BSD-2-Clause License compliant  
✅ ODbL License compliant  
✅ CSP/XSS security hardened  

## Salesforce Documentation

- [Salesforce Extensions Documentation](https://developer.salesforce.com/tools/vscode/)
- [Salesforce CLI Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm)

## License

This project's code is proprietary. Third-party libraries are used under their respective licenses (see THIRD_PARTY_NOTICES.md).
