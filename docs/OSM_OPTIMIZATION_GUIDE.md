# OpenStreetMap Tile Usage Optimization Guide

## Current Optimizations Implemented

### 1. Tile Loading Optimizations
- **Reduced maxZoom**: Set to 18 (from 19) to minimize high-resolution tile requests
- **Set minZoom**: Set to 5 to prevent excessive zoom-out tile loading
- **keepBuffer: 2**: Keeps only 2 rows/columns of tiles around viewport instead of default
- **updateWhenIdle: true**: Loads tiles only when map stops moving, not during drag
- **updateWhenZooming: false**: Prevents tile loading during zoom animations
- **Subdomain distribution**: Uses ['a', 'b', 'c'] subdomains to distribute load

### 2. Privacy & Compliance
- **referrerPolicy**: Set to 'no-referrer-when-downgrade' for proper privacy handling
- **User-Agent**: Added 'PayPay-MapPicker/1.0' to Nominatim requests as required
- **Country restriction**: Geocoding limited to Japan only (countrycodes=jp)

### 3. Rate Limiting
- **Search rate limiting**: Enforces 1 request per second minimum for Nominatim
- **Single result**: Geocoding limited to 1 result per search (limit=1)
- **Browser caching**: Enabled crossOrigin for proper tile caching

### 4. Map Behavior
- **Initial zoom optimization**: Uses zoom 17 for specific coords, 15 for geolocation
- **Smooth zoom transitions**: zoomSnap and zoomDelta set to 1 for single-step zoom
- **Reduced tile reloads**: wheelPxPerZoomLevel set to 120 for controlled zoom

## Recommended Production Solutions

### Option 1: 自前タイルサーバー (Own Tile Server)
**利点:**
- Complete control over usage and costs
- No rate limits
- Data privacy compliance
- Customizable map styles

**実装方法:**
```javascript
L.tileLayer('https://your-tile-server.paypay.com/{z}/{x}/{y}.png', {
    attribution: '&copy; PayPay Map Service',
    maxZoom: 18,
    minZoom: 5
})
```

**必要なリソース:**
- OSM data download and hosting
- Tile rendering server (e.g., TileServer GL, Mapnik)
- CDN for tile distribution
- Storage for tile cache

### Option 2: 契約済みプロバイダー (Contracted Provider)
**推奨サービス:**

#### Mapbox
```javascript
L.tileLayer('https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token={accessToken}', {
    attribution: '&copy; Mapbox &copy; OpenStreetMap',
    tileSize: 512,
    maxZoom: 18,
    zoomOffset: -1,
    accessToken: 'your-mapbox-token'
})
```

#### MapTiler
```javascript
L.tileLayer('https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key={apiKey}', {
    attribution: '&copy; MapTiler &copy; OpenStreetMap contributors',
    maxZoom: 18
})
```

### Option 3: 企業プロキシ (Corporate Proxy)
**利点:**
- Centralized usage monitoring
- Request caching and deduplication
- Access control and authentication
- Usage analytics

**実装方法:**
```javascript
L.tileLayer('https://map-proxy.paypay.ne.jp/osm/{z}/{x}/{y}.png', {
    attribution: '&copy; OpenStreetMap contributors',
    maxZoom: 18,
    headers: {
        'Authorization': 'Bearer {internal-token}'
    }
})
```

**プロキシサーバー設定例 (Nginx):**
```nginx
location /osm/ {
    proxy_pass https://tile.openstreetmap.org/;
    proxy_cache tile_cache;
    proxy_cache_valid 200 30d;
    proxy_cache_valid 404 1d;
    add_header X-Cache-Status $upstream_cache_status;
}
```

## OSM Foundation Policies Compliance

### Tile Usage Policy
- ✅ Heavy use applications should use contracted services
- ✅ Technical restrictions: Max 2 concurrent connections per client
- ✅ Bulk downloading prohibited
- ✅ Clear attribution provided
- ✅ User-Agent identification implemented

### Nominatim Usage Policy
- ✅ 1 request per second limit enforced
- ✅ User-Agent header included
- ✅ Results limited to essential data only
- ⚠️ Consider self-hosting for production: https://nominatim.org/release-docs/latest/admin/Installation/

## データ最小化ルール (Data Minimization Rules)

### 現在の実装:
1. **検索結果制限**: limit=1で最小限のデータのみ取得
2. **国別フィルター**: 日本のみに制限(countrycodes=jp)
3. **タイルキャッシュ**: ブラウザキャッシュを活用
4. **座標精度**: 10桁の精度で保存(業務に必要な精度)

### 推奨される追加対策:
1. **検索履歴キャッシュ**: 同じ検索クエリの重複リクエストを防ぐ
2. **タイルローカルキャッシュ**: Service Workerでタイルをキャッシュ
3. **リクエストログ**: 使用状況をモニタリング
4. **定期的なレビュー**: 月次で使用量を確認

## Cost Considerations (契約プロバイダー使用時)

### Mapbox Pricing (参考)
- Free tier: 50,000 map views/month
- Pay as you go: $5 per 1,000 additional views
- Enterprise: Custom pricing

### MapTiler Pricing (参考)
- Free tier: 100,000 tile requests/month
- Basic: $49/month for 500,000 requests
- Professional: Custom pricing

## Implementation Checklist

- [x] Reduce maxZoom to minimize tile requests
- [x] Implement rate limiting for geocoding
- [x] Add proper User-Agent headers
- [x] Set referrerPolicy for privacy
- [x] Enable browser caching
- [x] Optimize tile loading behavior
- [ ] Implement search result caching
- [ ] Consider migration to contracted provider or corporate proxy
- [ ] Set up usage monitoring and analytics
- [ ] Document tile usage policy for stakeholders
- [ ] Establish monthly usage review process

## Contact & Resources

- OSM Tile Usage Policy: https://operations.osmfoundation.org/policies/tiles/
- Nominatim Usage Policy: https://operations.osmfoundation.org/policies/nominatim/
- Leaflet Documentation: https://leafletjs.com/reference.html
- OSM Foundation: https://osmfoundation.org/

---

**Last Updated**: 2025-11-20
**Version**: 1.0
**Maintained By**: Development Team
