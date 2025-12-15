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
import { LightningElement, api, wire } from 'lwc';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import { publish, MessageContext } from 'lightning/messageService';
import MAP_LOCATION_CHANNEL from '@salesforce/messageChannel/MapLocationChange__c';
import LEAFLET_FILES from '@salesforce/resourceUrl/leafletjs';

export default class MpMapPicker extends LightningElement {
    @api latitude;
    @api longitude;
    @api readonly = false;
    
    searchQuery = '';
    searchError = '';
    isSearching = false;
    
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
                    this.latitude = 35.68084000000000;
                    this.longitude = 139.76700900000000;
                    this.initializeMap();
                },
                { timeout: 5000, enableHighAccuracy: true }
            );
        } else {
            // 東京駅fallback
            this.latitude = 35.68084000000000;
            this.longitude = 139.76700900000000;
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
        this.latitude = parseFloat(lat.toFixed(14));
        this.longitude = parseFloat(lng.toFixed(14));
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

    normalizeJapaneseAddress(address) {
        return address
            .replace(/[０-９]/g, (s) => String.fromCharCode(s.charCodeAt(0) - 0xFEE0))
            .replace(/[Ａ-Ｚａ-ｚ]/g, (s) => String.fromCharCode(s.charCodeAt(0) - 0xFEE0))
            .replace(/\s+/g, '')
            .replace(/[−ー‐]/g, '-')
            .replace(/[、・]/g, '');
    }

    parseJapaneseAddress(address) {
        const normalized = this.normalizeJapaneseAddress(address);
        const parts = [];
        let remaining = normalized;
        
        const patterns = [
            { regex: /^(.+?[都道府県])/, name: '都道府県' },
            { regex: /^(.+?[市区町村])/, name: '市区町村' },
            { regex: /^(.+?[町村])/, name: '町村' },
            { regex: /^(.+?[丁目丁])/, name: '丁目' },
            { regex: /^(.+?[番地番])/, name: '番地' },
            { regex: /^(.+?[号])/, name: '号' }
        ];
        
        for (const pattern of patterns) {
            const match = remaining.match(pattern.regex);
            if (match) {
                parts.push(match[1]);
                remaining = remaining.substring(match[1].length);
            }
        }
        
        if (remaining.length > 0) {
            parts.push(remaining);
        }
        
        return parts.length > 0 ? parts : [normalized];
    }

    async searchAddress(query, limit = 3) {
        try {
            const response = await fetch(
                `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(query)}&limit=${limit}&countrycodes=jp`,
                {
                    headers: {
                        'User-Agent': 'mpMapPicker/1.0',
                        'Accept-Language': 'ja'
                    }
                }
            );

            if (!response.ok) {
                return null;
            }

            const data = await response.json();
            return (data && data.length > 0) ? data[0] : null;
        } catch (error) {
            console.error('Search error:', error);
            return null;
        }
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
            
            const normalizedQuery = this.normalizeJapaneseAddress(this.searchQuery);
            let location = await this.searchAddress(normalizedQuery);
            
            if (!location) {
                const addressParts = this.parseJapaneseAddress(this.searchQuery);
                
                for (let i = addressParts.length - 1; i > 0 && !location; i--) {
                    await new Promise(resolve => setTimeout(resolve, 1000));
                    
                    const partialAddress = addressParts.slice(0, i).join('');
                    location = await this.searchAddress(partialAddress);
                    
                    if (location) {
                        console.log(`Found location using partial address: ${partialAddress}`);
                        break;
                    }
                }
            }

            if (location) {
                const lat = parseFloat(location.lat);
                const lon = parseFloat(location.lon);
                
                this.updateLocation(lat, lon);
                
                const addressParts = this.parseJapaneseAddress(this.searchQuery);
                let zoom = 15;
                if (addressParts.length >= 6) {
                    zoom = 19;
                } else if (addressParts.length >= 4) {
                    zoom = 18;
                } else if (addressParts.length >= 2) {
                    zoom = 16;
                }
                
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