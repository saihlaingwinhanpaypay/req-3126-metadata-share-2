# CSP (Content Security Policy) Configuration Guide

## Current Implementation Status

### ✅ Completed
- Leaflet library deployed as Salesforce Static Resource
- LWC uses Lightning Locker Service for CSP enforcement
- Static resource icons (no external image loading for UI)

### ⚠️ Required Configuration

## 1. Salesforce Remote Site Settings

Navigate to: **Setup → Security → Remote Site Settings → New Remote Site**

### Required Remote Sites:

#### OpenStreetMap Tile Server
```
Remote Site Name: OpenStreetMap_Tiles
Remote Site URL: https://tile.openstreetmap.org
Active: ✓
Description: OpenStreetMap tile server for map rendering
```

#### OpenStreetMap Subdomains (Optional but Recommended)
```
Remote Site Name: OpenStreetMap_Tiles_A
Remote Site URL: https://a.tile.openstreetmap.org
Active: ✓

Remote Site Name: OpenStreetMap_Tiles_B
Remote Site URL: https://b.tile.openstreetmap.org
Active: ✓

Remote Site Name: OpenStreetMap_Tiles_C
Remote Site URL: https://c.tile.openstreetmap.org
Active: ✓
```

#### Nominatim Geocoding Service
```
Remote Site Name: Nominatim_Geocoding
Remote Site URL: https://nominatim.openstreetmap.org
Active: ✓
Description: OpenStreetMap geocoding service for address search
```

## 2. CSP Trusted Sites (Lightning Experience)

Navigate to: **Setup → Security → CSP Trusted Sites → New Trusted Site**

### Required Trusted Sites:

#### OpenStreetMap Tiles
```
Trusted Site Name: OpenStreetMap Tiles
Trusted Site URL: https://tile.openstreetmap.org
Context: All
Active: ✓

Directives:
- ✓ img-src (for tile images)
- ✓ connect-src (for XHR/fetch requests)
```

#### OpenStreetMap Subdomains
```
Trusted Site Name: OpenStreetMap Tiles Subdomains
Trusted Site URL: https://*.tile.openstreetmap.org
Context: All
Active: ✓

Directives:
- ✓ img-src
- ✓ connect-src
```

#### Nominatim
```
Trusted Site Name: Nominatim Geocoding
Trusted Site URL: https://nominatim.openstreetmap.org
Context: All
Active: ✓

Directives:
- ✓ connect-src (for geocoding API calls)
```

## 3. Content Security Policy Directives

### Current Implementation CSP Requirements:

```
Content-Security-Policy:
  default-src 'self';
  script-src 'self' https://yourorg.lightning.force.com;
  style-src 'self' 'unsafe-inline' https://yourorg.lightning.force.com;
  img-src 'self' data: https://tile.openstreetmap.org https://*.tile.openstreetmap.org;
  connect-src 'self' https://tile.openstreetmap.org https://*.tile.openstreetmap.org https://nominatim.openstreetmap.org;
  font-src 'self' data:;
  frame-src 'self';
```

### Minimal Permissions (最小権限の原則):

1. **script-src**: 
   - ✅ Only Salesforce domains (Leaflet loaded as static resource)
   - ✅ No external JavaScript execution

2. **img-src**: 
   - ✅ Self (for marker icons from static resource)
   - ✅ data: (for inline images)
   - ⚠️ OpenStreetMap domains (for map tiles only)

3. **connect-src**: 
   - ✅ Self (for Salesforce API calls)
   - ⚠️ OpenStreetMap domains (for tiles and geocoding only)

4. **style-src**: 
   - ✅ Self (Leaflet CSS from static resource)
   - ✅ 'unsafe-inline' (required for dynamic styles in LWC)

## 4. Verification Steps

### Step 1: Check Static Resource Deployment
```bash
sfdx force:source:status
# Verify leafletjs static resource is deployed
```

### Step 2: Verify Remote Site Settings
1. Go to Setup → Security → Remote Site Settings
2. Confirm all OpenStreetMap domains are listed and active
3. Test connectivity by clicking "Test Connection"

### Step 3: Verify CSP Trusted Sites
1. Go to Setup → Security → CSP Trusted Sites
2. Confirm all domains are listed with correct directives
3. Check that both img-src and connect-src are enabled

### Step 4: Test in Browser Console
```javascript
// Open browser console on Visualforce page
// Check for CSP violations:
// Should see NO errors like:
// "Refused to load... because it violates the following Content Security Policy directive"

// Verify Leaflet loads from static resource:
console.log(L.version); // Should output Leaflet version

// Verify tiles load:
// Map should display without CSP errors
```

### Step 5: Monitor CSP Reports
Check browser console for CSP violations:
```
Setup → Security → Event Monitoring → Security Health Check
```

## 5. Alternative Solutions (Higher Security)

### Option A: Corporate Proxy (推奨)
```javascript
// Use corporate proxy for all external requests
L.tileLayer('https://map-proxy.paypay.ne.jp/osm/{z}/{x}/{y}.png', {
    // All requests go through internal proxy
    // Only need to whitelist: https://map-proxy.paypay.ne.jp
});
```

**Benefits:**
- Single domain to whitelist
- Full control over requests
- Request logging and monitoring
- Can implement additional security headers

### Option B: Self-Hosted Tiles
```javascript
// Host tiles on Salesforce or internal CDN
L.tileLayer('https://yourorg.file.force.com/tiles/{z}/{x}/{y}.png', {
    // No external domains needed
});
```

**Benefits:**
- No external dependencies
- Complete CSP compliance with 'self' only
- No rate limits
- Full data privacy

### Option C: Contracted Provider with CSP
```javascript
// Use Mapbox or MapTiler (commercial providers)
L.tileLayer('https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token={token}', {
    // Only need to whitelist: https://api.mapbox.com
});
```

**Benefits:**
- Professional support
- Better performance
- Single domain to whitelist
- Compliance-friendly

## 6. Data Minimization (データ最小化)

### Current Implementation:
```javascript
// ✅ Minimal tile loading
maxZoom: 18,              // Reduced from 19
keepBuffer: 2,            // Minimal buffer
updateWhenIdle: true,     // Load only when needed

// ✅ Minimal geocoding data
limit=1,                  // Single result only
countrycodes=jp,          // Japan only

// ✅ Rate limiting
lastSearchTime check      // 1 request per second max
```

### Recommended Additions:
1. **Request Logging**: Monitor all external API calls
2. **Cache Headers**: Implement proper caching strategies
3. **Timeout Controls**: Set reasonable fetch timeouts
4. **Error Handling**: Graceful degradation on CSP violations

## 7. Security Headers (Visualforce Page)

### Add to mpFormBank.page:
```xml
<apex:page ... applyHtmlTag="false" applyBodyTag="false">
    <html>
        <head>
            <meta http-equiv="Content-Security-Policy" 
                  content="default-src 'self'; 
                           img-src 'self' data: https://tile.openstreetmap.org https://*.tile.openstreetmap.org; 
                           connect-src 'self' https://tile.openstreetmap.org https://*.tile.openstreetmap.org https://nominatim.openstreetmap.org;
                           script-src 'self' 'unsafe-inline';
                           style-src 'self' 'unsafe-inline';" />
            
            <meta http-equiv="X-Content-Type-Options" content="nosniff" />
            <meta http-equiv="X-Frame-Options" content="SAMEORIGIN" />
            <meta http-equiv="Referrer-Policy" content="no-referrer-when-downgrade" />
        </head>
        ...
    </html>
</apex:page>
```

## 8. Configuration Checklist

- [ ] Deploy Leaflet as Salesforce Static Resource
- [ ] Add OpenStreetMap domains to Remote Site Settings
- [ ] Add OpenStreetMap domains to CSP Trusted Sites
- [ ] Configure img-src directive for tile domains
- [ ] Configure connect-src directive for API domains
- [ ] Test map rendering without CSP violations
- [ ] Test geocoding search without CSP violations
- [ ] Verify no external scripts are loaded
- [ ] Document all whitelisted domains
- [ ] Set up monitoring for CSP violations
- [ ] Review and approve with security team
- [ ] Schedule quarterly security review

## 9. Compliance Documentation

### For Security Review:
```
External Domains Required:
1. https://tile.openstreetmap.org (and subdomains a, b, c)
   - Purpose: Map tile images
   - Data: Geographic map tiles (public data)
   - Frequency: On map view/pan/zoom
   - Rate: ~10-50 tiles per map interaction
   
2. https://nominatim.openstreetmap.org
   - Purpose: Address to coordinates geocoding
   - Data: Address strings and coordinates (public data)
   - Frequency: On user search action
   - Rate: Max 1 request per second (enforced)

Security Measures:
- All scripts loaded from Salesforce static resources
- Lightning Locker Service enforced
- Rate limiting implemented
- Minimal data requested
- Proper User-Agent identification
- Referrer policy configured
- No cookies or tracking
```

## 10. Maintenance

### Quarterly Review:
1. Review all Remote Site Settings - ensure still necessary
2. Audit CSP Trusted Sites - remove unused domains
3. Check for Leaflet library updates
4. Review OSM usage policies for changes
5. Monitor usage statistics
6. Evaluate migration to internal solution

### When to Escalate:
- CSP violations detected in production
- OSM policy changes
- Rate limit errors
- Performance degradation
- Security audit findings

---

**Last Updated**: 2025-11-20
**Version**: 1.0
**Owner**: Security & Development Team
**Next Review**: 2026-02-20
