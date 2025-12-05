/**
 * mpMapPicker - Interactive Map Component using Leaflet
 * 
 * Third-Party Libraries:
 * - Leaflet (BSD-2-Clause License)
 *   Copyright (c) 2010-2023, Vladimir Agafonkin
 *   Copyright (c) 2010-2011, CloudMade
 *   https://github.com/Leaflet/Leaflet/blob/main/LICENSE
 * 
 * - OpenStreetMap (ODbL License)
 *   © OpenStreetMap contributors
 *   https://www.openstreetmap.org/copyright
 * 
 */
import { LightningElement, track, api, wire } from 'lwc';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import { publish, MessageContext } from 'lightning/messageService';
import MAP_LOCATION_CHANNEL from '@salesforce/messageChannel/MapLocationChange__c';
import LEAFLET_FILES from '@salesforce/resourceUrl/leafletjs';

export default class MpMapPicker extends LightningElement {
    @api latitude;
    @api longitude;
    @api readonly = false;
    
    @track searchQuery = '';
    @track searchError = '';
    @track isSearching = false;
    
    map;
    marker;
    mapInitialized = false;
    leafletInitialized = false;
    useCurrentLocation = false;
    lastSearchTime = 0; // レットリミットのための最終検索時間を追跡
    
    @wire(MessageContext)
    messageContext;

    get isSearchDisabled() {
        return !this.searchQuery.trim() || this.isSearching;
    }

    get showSearch() {
        return !this.readonly;
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
            if (!this.latitude || !this.longitude || 
                this.latitude === 0 || this.longitude === 0) {
                // ユーザの現在地を利用
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
                    // ユーザの現在地取得ができる
                    this.latitude = position.coords.latitude;
                    this.longitude = position.coords.longitude;
                    this.initializeMap();
                },
                (error) => {
                    console.error('Error getting current location:', error);
                    // エラーの場合は東京駅をデフォルトにする
                    this.latitude = 35.680840;
                    this.longitude = 139.767009;
                    this.initializeMap();
                },
                { timeout: 5000, enableHighAccuracy: true }
            );
        } else {
            // 東京駅fallback
            this.latitude = 35.680840;
            this.longitude = 139.767009;
            this.initializeMap();
        }
    }

    initializeMap() {
        const container = this.template.querySelector('.map-container');
        
        const mapDiv = document.createElement('div');
        mapDiv.id = 'map-vf';
        mapDiv.style.height = '480px';
        mapDiv.style.width = '100%';
        // mapDiv.style.maxWidth = '700px';
        container.appendChild(mapDiv);

        // 静的リソースのアイコンを利用する
        delete L.Icon.Default.prototype._getIconUrl;
        L.Icon.Default.mergeOptions({
            iconRetinaUrl: LEAFLET_FILES + '/leafletjs/marker-icon-2x.png',
            iconUrl: LEAFLET_FILES + '/leafletjs/marker-icon.png',
            shadowUrl: LEAFLET_FILES + '/leafletjs/marker-shadow.png'
        });

        const maxZoom = 19;
        const minZoom = 5;
        const initialZoom = this.useCurrentLocation ? 16 : 18;
        
        this.map = L.map(mapDiv, {
            center: [this.latitude, this.longitude],
            zoom: initialZoom,
            maxZoom: maxZoom,
            minZoom: minZoom,
            zoomSnap: 1,
            zoomDelta: 1,
            wheelPxPerZoomLevel: 120
        });

        // ライセンス
        // Leaflet: Copyright (c) 2010-2023, Vladimir Agafonkin, CloudMade (BSD-2-Clause License)
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '<a href="https://leafletjs.com" title="A JavaScript library for interactive maps">Leaflet</a> | &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
            maxZoom: maxZoom,
            minZoom: minZoom,
            // タイルのパフォーマンス最適化
            maxNativeZoom: 19,
            keepBuffer: 2,
            updateWhenIdle: true,
            updateWhenZooming: false,
            // referrer policy for privacy
            referrerPolicy: 'no-referrer-when-downgrade',
            // Subdomains for load distribution across OSM servers
            subdomains: ['a', 'b', 'c'],
            // Browser caching
            crossOrigin: true
        }).addTo(this.map);

        // デフォルト位置でマーカーを追加
        this.marker = L.marker([this.latitude, this.longitude], {
            draggable: !this.readonly
        }).addTo(this.map);

        if (!this.readonly) {
            this.map.on('click', (e) => {
                const lat = e.latlng.lat;
                const lng = e.latlng.lng;
                this.updateLocation(lat, lng);

                if (!this.map.hasLayer(this.marker)) {
                    this.marker.addTo(this.map);
                }
            });
        }

        if (!this.readonly) {
            this.marker.on('dragend', (e) => {
                const position = this.marker.getLatLng();
                this.updateLocation(position.lat, position.lng);
            });
        }
    }

    updateLocation(lat, lng) {
        this.latitude = parseFloat(lat.toFixed(10));
        this.longitude = parseFloat(lng.toFixed(10));
        this.marker.setLatLng([lat, lng]);
        
        // Lightning Message Serviceで位置情報を発行する
        const payload = {
            latitude: this.latitude,
            longitude: this.longitude
        };
        publish(this.messageContext, MAP_LOCATION_CHANNEL, payload);
    }

    @api
    setLocation(lat, lng) {
        this.latitude = lat;
        this.longitude = lng;
        this.updateMapView();
        
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
        // レットリミット：1秒に1回のリクエストを強制
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
            // - Limited to 1 request per second　1秒に1回のリクエストを強制
            const response = await fetch(
                `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(this.searchQuery)}&limit=1&countrycodes=jp`,
                {
                    headers: {
                        'User-Agent': 'mpMapPicker/1.0'
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