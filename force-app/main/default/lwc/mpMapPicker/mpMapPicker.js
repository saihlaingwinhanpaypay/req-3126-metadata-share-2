import { LightningElement, track, api } from 'lwc';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import LEAFLET_FILES from '@salesforce/resourceUrl/leafletjs';

export default class MpMapPicker extends LightningElement {
    @api latitude;
    @api longitude;
    
    @track searchQuery = '';
    @track searchError = '';
    @track isSearching = false;
    
    map;
    marker;
    mapInitialized = false;
    leafletInitialized = false;
    useCurrentLocation = false;
    lastSearchTime = 0; // Track last search time for rate limiting

    get isSearchDisabled() {
        return !this.searchQuery.trim() || this.isSearching;
    }

    renderedCallback() {
        if (this.mapInitialized) {
            return;
        }
        this.mapInitialized = true;
        this.initializeLeaflet();
    }

    initializeLeaflet() {
        Promise.all([
            loadStyle(this, LEAFLET_FILES + '/leafletjs/leaflet.css'),
            loadScript(this, LEAFLET_FILES + '/leafletjs/leaflet.js')
        ])
        .then(() => {
            this.leafletInitialized = true;
            // Check if latitude and longitude are null or undefined
            if (!this.latitude || !this.longitude || 
                this.latitude === 0 || this.longitude === 0) {
                // Use current location
                this.useCurrentLocation = true;
                this.getCurrentLocation();
            } else {
                this.initializeMap();
            }
        })
        .catch(error => {
            console.error('Error loading Leaflet', error);
        });
    }

    getCurrentLocation() {
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    // Successfully got current location
                    this.latitude = position.coords.latitude;
                    this.longitude = position.coords.longitude;
                    this.initializeMap();
                },
                (error) => {
                    console.error('Error getting current location:', error);
                    // Fall back to Tokyo Station if geolocation fails
                    this.latitude = 35.680840;
                    this.longitude = 139.767009;
                    this.initializeMap();
                },
                { timeout: 5000, enableHighAccuracy: true }
            );
        } else {
            // Geolocation not supported, use Tokyo Station as fallback
            this.latitude = 35.680840;
            this.longitude = 139.767009;
            this.initializeMap();
        }
    }

    initializeMap() {
        const container = this.template.querySelector('.map-container');
        
        // Create map div
        const mapDiv = document.createElement('div');
        mapDiv.id = 'map-vf';
        mapDiv.style.height = '480px';
        mapDiv.style.width = '100%';
        mapDiv.style.maxWidth = '700px';
        container.appendChild(mapDiv);

        // Configure Leaflet to use static resource icons
        delete L.Icon.Default.prototype._getIconUrl;
        L.Icon.Default.mergeOptions({
            iconRetinaUrl: LEAFLET_FILES + '/leafletjs/marker-icon-2x.png',
            iconUrl: LEAFLET_FILES + '/leafletjs/marker-icon.png',
            shadowUrl: LEAFLET_FILES + '/leafletjs/marker-shadow.png'
        });

        // Initialize Leaflet map with optimized zoom levels
        // Reduced maxZoom to minimize tile requests (OSM recommendation)
        const maxZoom = 18;
        const minZoom = 5;
        const initialZoom = this.useCurrentLocation ? 15 : 17;
        
        this.map = L.map(mapDiv, {
            center: [this.latitude, this.longitude],
            zoom: initialZoom,
            maxZoom: maxZoom,
            minZoom: minZoom,
            // Reduce unnecessary tile reloads
            zoomSnap: 1,
            zoomDelta: 1,
            wheelPxPerZoomLevel: 120
        });

        // Add tile layer with optimization settings
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
            maxZoom: maxZoom,
            minZoom: minZoom,
            // Tile caching and loading optimization
            maxNativeZoom: 18,
            keepBuffer: 2,              // Keep 2 rows/cols of tiles loaded around viewport
            updateWhenIdle: true,       // Update tiles only when map stops moving
            updateWhenZooming: false,   // Don't update tiles during zoom animation
            // Proper referrer policy for privacy
            referrerPolicy: 'no-referrer-when-downgrade',
            // Subdomains for load distribution across OSM servers
            subdomains: ['a', 'b', 'c'],
            // Browser caching
            crossOrigin: true
        }).addTo(this.map);

        // Add marker and show it at default coordinates immediately
        this.marker = L.marker([this.latitude, this.longitude], {
            draggable: true
        }).addTo(this.map);

        // Handle map clicks
        this.map.on('click', (e) => {
            const lat = e.latlng.lat;
            const lng = e.latlng.lng;
            this.updateLocation(lat, lng);
            
            // Add marker to map if not already added
            if (!this.map.hasLayer(this.marker)) {
                this.marker.addTo(this.map);
            }
        });

        // Handle marker drag
        this.marker.on('dragend', (e) => {
            const position = this.marker.getLatLng();
            this.updateLocation(position.lat, position.lng);
        });

        // Dispatch event to notify Visualforce page that map is ready
        this.dispatchEvent(new CustomEvent('mapready'));
    }

    updateLocation(lat, lng) {
        this.latitude = parseFloat(lat.toFixed(10));
        this.longitude = parseFloat(lng.toFixed(10));
        this.marker.setLatLng([lat, lng]);
        
        // Dispatch event with new coordinates (bubbles and composed to cross shadow DOM)
        this.dispatchEvent(new CustomEvent('locationchange', {
            detail: {
                latitude: this.latitude,
                longitude: this.longitude
            },
            bubbles: true,
            composed: true
        }));
    }

    @api
    setLocation(lat, lng) {
        this.latitude = lat;
        this.longitude = lng;
        this.updateMapView();
        
        // Add marker if not already on map
        if (this.map && !this.map.hasLayer(this.marker)) {
            this.marker.addTo(this.map);
        }
    }

    @api
    getLocation() {
        return {
            latitude: this.latitude,
            longitude: this.longitude
        };
    }

    updateMapView() {
        if (this.map && this.marker) {
            this.marker.setLatLng([this.latitude, this.longitude]);
            // Keep the map at its max zoom when programmatically updating location
            const zoom = this.map.getMaxZoom ? this.map.getMaxZoom() : undefined;
            if (typeof zoom === 'number') {
                this.map.setView([this.latitude, this.longitude], zoom);
            } else {
                this.map.setView([this.latitude, this.longitude]);
            }
        }
    }

    handleSearchInput(event) {
        this.searchQuery = event.target.value;
        this.searchError = '';
    }

    async handleSearch() {
        if (!this.searchQuery.trim()) {
            this.searchError = '検索する住所を入力してください。';
            return;
        }

        // Rate limiting: Enforce 1 request per second minimum
        const now = Date.now();
        const timeSinceLastSearch = now - this.lastSearchTime;
        if (timeSinceLastSearch < 1000) {
            this.searchError = 'しばらくしてからもう一度お試しください。';
            return;
        }
        this.lastSearchTime = now;

        this.isSearching = true;
        this.searchError = '';

        try {
            // Nominatim Usage Policy: https://operations.osmfoundation.org/policies/nominatim/
            // - Limited to 1 request per second
            // - Proper User-Agent required
            // - Consider using your own Nominatim instance for production
            const response = await fetch(
                `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(this.searchQuery)}&limit=1&countrycodes=jp`,
                {
                    headers: {
                        // Required: Identify your application
                        'User-Agent': 'PayPay-MapPicker/1.0'
                    }
                }
            );

            if (!response.ok) {
                throw new Error('検索に失敗しました。');
            }

            const data = await response.json();

            if (data && data.length > 0) {
                const location = data[0];
                const lat = parseFloat(location.lat);
                const lon = parseFloat(location.lon);
                
                this.updateLocation(lat, lon);
                const zoom = this.map.getMaxZoom ? this.map.getMaxZoom() : 19;
                this.map.setView([lat, lon], zoom);
            } else {
                this.searchError = '住所が見つかりませんでした。';
            }
        } catch (error) {
            console.error('Search error:', error);
            this.searchError = '検索中にエラーが発生しました。';
        } finally {
            this.isSearching = false;
        }
    }
}