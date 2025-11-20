# Third-Party Notices and Licenses

This file contains the licenses and notices for third-party software included in this project.

---

## 1. Leaflet

**Project:** Leaflet  
**Version:** 1.9.4 (or later)  
**Website:** https://leafletjs.com/  
**License:** BSD 2-Clause License  
**Used In:** mpMapPicker Lightning Web Component  

### Copyright Notice

```
Copyright (c) 2010-2023, Vladimir Agafonkin
Copyright (c) 2010-2011, CloudMade
All rights reserved.
```

### BSD 2-Clause License

```
Redistribution and use in source and binary forms, with or without modification, are
permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice, this list of
      conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright notice, this list
      of conditions and the following disclaimer in the documentation and/or other materials
      provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

**License URL:** https://github.com/Leaflet/Leaflet/blob/main/LICENSE

---

## 2. OpenStreetMap

**Project:** OpenStreetMap  
**Website:** https://www.openstreetmap.org/  
**License:** Open Database License (ODbL) v1.0  
**Used For:** Map tile data  

### Copyright Notice

```
© OpenStreetMap contributors
```

### License Summary

OpenStreetMap data is licensed under the Open Database License (ODbL).

**Key Requirements:**
- Attribution required in any public use
- Share-alike: Derivative works must use ODbL
- Keep data open

### Attribution

Our implementation includes the required attribution:
```html
© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors
```

**License URL:** https://www.openstreetmap.org/copyright  
**Full ODbL License:** https://opendatacommons.org/licenses/odbl/1-0/

---

## 3. Nominatim (OpenStreetMap Geocoding)

**Project:** Nominatim  
**Website:** https://nominatim.org/  
**License:** GPL v2  
**Used For:** Address geocoding (search functionality)  

### Usage Policy

Nominatim usage is governed by the OSMF Nominatim Usage Policy:
- https://operations.osmfoundation.org/policies/nominatim/

**Key Requirements:**
- Maximum 1 request per second
- Proper User-Agent identification
- No heavy/commercial use without own instance
- Attribution to OpenStreetMap

### Our Implementation

```javascript
// Rate limiting enforced
lastSearchTime check ensures 1 request per second

// User-Agent identification
headers: { 'User-Agent': 'PayPay-MapPicker/1.0' }

// Attribution via OpenStreetMap attribution (data source)
```

**License URL:** https://www.gnu.org/licenses/old-licenses/gpl-2.0.html

---

## 4. Lightning Web Components (LWC)

**Project:** Salesforce Lightning Web Components  
**Vendor:** Salesforce.com  
**License:** Salesforce Developer Agreement  
**Used For:** Component framework  

### Copyright Notice

```
Copyright (c) Salesforce.com, Inc.
```

**License:** Proprietary (covered under Salesforce Developer Agreement)  
**Documentation:** https://developer.salesforce.com/docs/component-library/documentation/en/lwc

---

## License Compliance Summary

| Component | License | Attribution Required | Share-Alike | Commercial Use |
|-----------|---------|---------------------|-------------|----------------|
| Leaflet | BSD-2-Clause | Yes (in code) | No | Yes |
| OpenStreetMap | ODbL | Yes (visible) | Yes (for data) | Limited* |
| Nominatim | GPL v2 / Usage Policy | Yes | N/A (API usage) | No** |
| Salesforce LWC | Proprietary | No | N/A | Yes |

\* OpenStreetMap tiles: Heavy/commercial use should use own tile server or commercial provider  
\** Nominatim: Heavy/commercial use requires self-hosted instance

---

## Attribution Display

### In Application (Map Component)

The map displays the required attribution in the bottom-right corner:
```
© OpenStreetMap contributors
```

This attribution covers:
- OpenStreetMap tile data
- Nominatim geocoding (uses OSM data)

### Leaflet Library Attribution

Leaflet library attribution is provided through:
1. This THIRD_PARTY_NOTICES.md file
2. License file included in static resource
3. Copyright notice in source code comments

---

## Compliance Actions

### ✅ Completed
- [x] OpenStreetMap attribution displayed on map
- [x] Third-party notices file created
- [x] Nominatim usage policy compliance
- [x] Rate limiting implemented
- [x] User-Agent identification

### ⚠️ Required
- [ ] Add Leaflet attribution to map control (optional but recommended)
- [ ] Include this file in production deployments
- [ ] Update README.md with license information
- [ ] Include licenses in static resource deployment
- [ ] Legal team review and approval

### 📋 Recommended
- [ ] Add "About" or "Licenses" link in application
- [ ] Display third-party licenses in settings/help section
- [ ] Document OSM tile usage in production environment
- [ ] Consider migration to commercial tile provider for heavy use
- [ ] Set up monitoring for Nominatim usage limits

---

## Usage Guidelines

### For Developers

**When modifying the map component:**
1. Do not remove attribution from tile layer
2. Do not remove copyright notices from code
3. Keep this THIRD_PARTY_NOTICES.md file updated
4. Document any new third-party libraries

**When deploying:**
1. Include this file in deployment package
2. Ensure attribution is visible on map
3. Verify compliance with usage policies
4. Document production tile server configuration

### For Legal/Compliance Team

**Review items:**
- [ ] OpenStreetMap usage aligns with ODbL requirements
- [ ] Nominatim usage within acceptable limits
- [ ] Leaflet BSD license compliance confirmed
- [ ] Commercial use scenarios reviewed
- [ ] Data privacy requirements met
- [ ] Export compliance verified

---

## Contact Information

### Questions About Licenses
- **Leaflet:** https://github.com/Leaflet/Leaflet/issues
- **OpenStreetMap:** https://www.openstreetmap.org/help
- **Nominatim:** https://nominatim.org/help/

### Internal Contacts
- **Legal Team:** [Your legal team contact]
- **Development Team:** [Your dev team contact]
- **Security Team:** [Your security team contact]

---

## Version History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-20 | 1.0 | Initial license documentation | Development Team |

---

## Additional Resources

- [Leaflet License](https://github.com/Leaflet/Leaflet/blob/main/LICENSE)
- [OpenStreetMap License](https://www.openstreetmap.org/copyright)
- [ODbL Full Text](https://opendatacommons.org/licenses/odbl/1-0/)
- [Nominatim Usage Policy](https://operations.osmfoundation.org/policies/nominatim/)
- [OSM Tile Usage Policy](https://operations.osmfoundation.org/policies/tiles/)
- [BSD 2-Clause License](https://opensource.org/licenses/BSD-2-Clause)

---

**Last Updated:** 2025-11-20  
**Next Review:** 2026-02-20  
**Maintained By:** Development & Legal Teams
