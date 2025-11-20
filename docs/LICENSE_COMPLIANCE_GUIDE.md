# License Compliance Guide

## Overview

This guide ensures compliance with all third-party software licenses used in the mpMapPicker component.

---

## Current Implementation Status

### ✅ Completed (2025-11-20)

1. **Source Code Attribution**
   - ✅ Header comment added to `mpMapPicker.js` with Leaflet and OpenStreetMap copyright notices
   - ✅ Inline comment above tile layer with Leaflet license reference

2. **Visible Attribution**
   - ✅ Map displays: "Leaflet | © OpenStreetMap contributors"
   - ✅ Attribution shown in bottom-right corner of map (Leaflet default)

3. **Documentation**
   - ✅ Created `THIRD_PARTY_NOTICES.md` with all license texts
   - ✅ License information documented for:
     - Leaflet (BSD-2-Clause)
     - OpenStreetMap (ODbL)
     - Nominatim (GPL v2 / Usage Policy)

### ⚠️ Pending Actions

- [ ] Include `THIRD_PARTY_NOTICES.md` in production deployment package
- [ ] Verify Leaflet static resource includes LICENSE file
- [ ] Legal team review and approval
- [ ] Update product documentation with OSS disclosure
- [ ] Add "Licenses" section to application help/about page

---

## License Requirements & Compliance

### 1. Leaflet (BSD-2-Clause License)

#### Requirements:
1. ✅ Retain copyright notice in source code
2. ✅ Include license text in distribution
3. ⚠️ Retain license text in binary distribution

#### Our Compliance:

**Source Code (mpMapPicker.js:1-15):**
```javascript
/**
 * Third-Party Libraries:
 * - Leaflet (BSD-2-Clause License)
 *   Copyright (c) 2010-2023, Vladimir Agafonkin
 *   Copyright (c) 2010-2011, CloudMade
 *   https://github.com/Leaflet/Leaflet/blob/main/LICENSE
 */
```

**Visible Attribution (mpMapPicker.js:119):**
```javascript
attribution: '<a href="https://leafletjs.com">Leaflet</a> | ...'
```

**Documentation:**
- Full license text in `THIRD_PARTY_NOTICES.md`

**Static Resource:**
- ⚠️ **ACTION REQUIRED:** Ensure Leaflet static resource includes original LICENSE file

---

### 2. OpenStreetMap (ODbL License)

#### Requirements:
1. ✅ Attribution visible to end users
2. ✅ Link to OSM copyright page
3. ✅ Credit OSM contributors
4. ⚠️ Share-alike for derivative data (if creating derivative map data)

#### Our Compliance:

**Visible Attribution (mpMapPicker.js:119):**
```javascript
attribution: '... | &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
```

**Display:**
- Attribution automatically shown in map's bottom-right corner
- Always visible to users
- Includes required copyright symbol and link

**Derivative Data:**
- ✅ N/A - We only display tiles, not creating derivative data
- If geocoding results are stored: Must attribute to OSM

---

### 3. Nominatim (GPL v2 + Usage Policy)

#### Requirements (Usage Policy):
1. ✅ Rate limiting (1 request/second)
2. ✅ User-Agent identification
3. ✅ Attribution (via OSM attribution)
4. ⚠️ Self-hosted instance for heavy use

#### Our Compliance:

**Rate Limiting (mpMapPicker.js:226-233):**
```javascript
const timeSinceLastSearch = now - this.lastSearchTime;
if (timeSinceLastSearch < 1000) {
    this.searchError = 'しばらくしてからもう一度お試しください。';
    return;
}
```

**User-Agent (mpMapPicker.js:242-244):**
```javascript
headers: {
    'User-Agent': 'PayPay-MapPicker/1.0'
}
```

**Attribution:**
- Covered by OpenStreetMap attribution (Nominatim uses OSM data)

**Heavy Use Consideration:**
- ⚠️ **ACTION REQUIRED:** Monitor usage; if exceeding free tier limits, deploy self-hosted Nominatim

---

## Deployment Checklist

### Pre-Deployment

- [ ] Verify all copyright notices in source code
- [ ] Confirm `THIRD_PARTY_NOTICES.md` is up to date
- [ ] Check Leaflet version and update copyright year if needed
- [ ] Ensure static resource includes Leaflet LICENSE file
- [ ] Test that attribution is visible on map
- [ ] Review with legal team

### Deployment Package Must Include:

1. **Source Code**
   - `mpMapPicker.js` with header copyright notices
   - All component files

2. **Documentation**
   - `THIRD_PARTY_NOTICES.md`
   - `LICENSE_COMPLIANCE_GUIDE.md` (this file)
   - Link to licenses in README.md

3. **Static Resources**
   - Leaflet library files
   - Leaflet LICENSE file (from original distribution)
   - Leaflet marker icon files

### Post-Deployment Verification:

```bash
# 1. Check source file headers
grep -A 10 "Copyright" force-app/main/default/lwc/mpMapPicker/mpMapPicker.js

# 2. Verify THIRD_PARTY_NOTICES.md exists
ls -la THIRD_PARTY_NOTICES.md

# 3. Test attribution display
# Open application → Check map bottom-right corner
# Should show: "Leaflet | © OpenStreetMap contributors"
```

---

## Attribution Display Examples

### Current Implementation (Bottom-Right Corner):

```
┌─────────────────────────────────────┐
│                                     │
│          [Map Content]              │
│                                     │
│                                     │
│          Leaflet | © OpenStreetMap │
│                         contributors │
└─────────────────────────────────────┘
```

### Acceptable Alternatives:

**Option 1: Custom Attribution Control**
```javascript
L.control.attribution({
    prefix: '<a href="https://leafletjs.com">Leaflet</a>'
}).addTo(map);
```

**Option 2: About Dialog**
```
Application Menu
 └─ About / Licenses
     └─ Third-Party Software
         ├─ Leaflet (BSD-2-Clause)
         ├─ OpenStreetMap (ODbL)
         └─ [View Full License Text]
```

---

## Static Resource Requirements

### Leaflet Static Resource Structure:

```
leafletjs/
├── leaflet.js              # Core library
├── leaflet.css             # Styles
├── LICENSE                 # ⚠️ REQUIRED: Original BSD-2-Clause license
├── images/
│   ├── marker-icon.png
│   ├── marker-icon-2x.png
│   └── marker-shadow.png
└── README.md               # Optional: Leaflet documentation
```

### Upload Instructions:

```bash
# 1. Download Leaflet
wget https://leafletjs-cdn.s3.amazonaws.com/leaflet-1.9.4.zip

# 2. Extract
unzip leaflet-1.9.4.zip -d leafletjs/

# 3. Verify LICENSE file exists
ls leafletjs/LICENSE

# 4. Upload to Salesforce Static Resources
sfdx force:source:deploy -p force-app/main/default/staticresources/leafletjs

# 5. Verify in Salesforce
Setup → Static Resources → leafletjs → View File
```

---

## Legal Review Requirements

### Documents for Legal Team:

1. **License Summary**
   - `THIRD_PARTY_NOTICES.md`
   - This compliance guide

2. **Usage Analysis**
   - Component: mpMapPicker (Leaflet map)
   - Purpose: Store location selection
   - Licenses: BSD-2-Clause, ODbL
   - Commercial use: Yes (Leaflet allows, OSM tiles require consideration)

3. **Risk Assessment**
   - BSD-2-Clause: ✅ Low risk (permissive)
   - ODbL: ⚠️ Medium risk (share-alike, attribution required)
   - GPL v2 (Nominatim): ✅ Low risk (API usage only, not linking)

4. **Compliance Measures**
   - Source attribution: ✅ Implemented
   - Visible attribution: ✅ Implemented
   - License distribution: ⚠️ Pending verification
   - Usage policy: ✅ Compliant

### Questions for Legal:

1. Is visible attribution sufficient for ODbL compliance?
2. Do we need additional end-user license terms?
3. Should we migrate to commercial tile provider?
4. Is self-hosted Nominatim required for our usage level?
5. Any export/import restrictions for OSM data?

---

## Monitoring & Maintenance

### Quarterly Review Checklist:

- [ ] Verify Leaflet version and update copyright year
- [ ] Check for license changes in dependencies
- [ ] Review OSM tile usage (consider commercial provider)
- [ ] Monitor Nominatim API usage (rate limits)
- [ ] Update THIRD_PARTY_NOTICES.md if versions change
- [ ] Verify attribution still visible on map
- [ ] Legal team sign-off

### Version Updates:

When updating Leaflet version:

```bash
# 1. Check new version's license
wget https://github.com/Leaflet/Leaflet/blob/v1.X.X/LICENSE

# 2. Compare with current license
diff old_LICENSE new_LICENSE

# 3. Update copyright year if needed
# 4. Update THIRD_PARTY_NOTICES.md
# 5. Update source file headers
# 6. Legal review if license changed
```

---

## FAQ

### Q: Can we remove the attribution from the map?
**A:** No. ODbL requires visible attribution. BSD-2-Clause requires notice in distribution. Both must be retained.

### Q: Can we modify Leaflet source code?
**A:** Yes. BSD-2-Clause allows modification. Must retain copyright notice in modified files.

### Q: Can we use this commercially?
**A:** 
- Leaflet: ✅ Yes (BSD-2-Clause is commercial-friendly)
- OpenStreetMap: ⚠️ Yes, but heavy use should use commercial provider or own server
- Nominatim: ⚠️ Free tier only for light use; self-host for production

### Q: Do we need to open-source our code?
**A:** No. BSD-2-Clause and ODbL do not require this. Only if modifying OSM data must share derivative data.

### Q: What if we want to hide the attribution?
**A:** 
1. Not permitted for OSM (ODbL requirement)
2. Consider alternative tile provider (Mapbox, MapTiler) with commercial license
3. Self-host tiles and negotiate custom terms

### Q: How often should we review licenses?
**A:** Quarterly or whenever:
- Updating Leaflet version
- Changing tile provider
- Adding new map features
- Legal team requests review

---

## Contact Information

### Internal:
- **Legal Team:** [Contact]
- **Development Team:** [Contact]
- **Compliance Officer:** [Contact]

### External:
- **Leaflet Issues:** https://github.com/Leaflet/Leaflet/issues
- **OSM Licensing:** https://wiki.openstreetmap.org/wiki/Legal_FAQ
- **OSMF Contact:** https://osmfoundation.org/wiki/Contact

---

## Appendix: License Comparison

| License | Permissive | Commercial OK | Attribution | Share-Alike | Source Required |
|---------|-----------|---------------|-------------|-------------|-----------------|
| BSD-2-Clause | ✅ Yes | ✅ Yes | ✅ In code | ❌ No | ❌ No |
| ODbL (Data) | ⚠️ Partial | ✅ Yes* | ✅ Visible | ✅ Yes** | ⚠️ For data |
| GPL v2 | ❌ No | ⚠️ Limited | ✅ Yes | ✅ Yes | ✅ Yes*** |

\* Heavy use may require commercial arrangement  
\** Only for derivative data (not applicable to us)  
\*** Only if distributing modified GPL software (we use API only)

---

**Last Updated:** 2025-11-20  
**Version:** 1.0  
**Next Review:** 2026-02-20  
**Approved By:** [Pending Legal Review]
