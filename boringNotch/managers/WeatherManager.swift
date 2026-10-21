import Combine
@preconcurrency import CoreLocation
import Defaults
import Foundation

struct WeatherSnapshot: Equatable {
    let location: String
    let temperature: Double
    let apparentTemperature: Double
    let weatherCode: Int
    let high: Double
    let low: Double
    let updatedAt: Date

    var symbol: String {
        switch weatherCode {
        case 0: "sun.max.fill"
        case 1, 2: "cloud.sun.fill"
        case 3: "cloud.fill"
        case 45, 48: "cloud.fog.fill"
        case 51...57: "cloud.drizzle.fill"
        case 61...67, 80...82: "cloud.rain.fill"
        case 71...77, 85, 86: "cloud.snow.fill"
        case 95...99: "cloud.bolt.rain.fill"
        default: "cloud.fill"
        }
    }

    var condition: String {
        switch weatherCode {
        case 0: "Clear"
        case 1: "Mostly clear"
        case 2: "Partly cloudy"
        case 3: "Cloudy"
        case 45, 48: "Foggy"
        case 51...57: "Drizzle"
        case 61...67, 80...82: "Rain"
        case 71...77, 85, 86: "Snow"
        case 95...99: "Thunderstorms"
        default: "Current conditions"
        }
    }

    var isAlertWorthy: Bool {
        switch weatherCode {
        case 65...67, 75...77, 82, 86, 95...99: true
        default: false
        }
    }
}

@MainActor
final class WeatherManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = WeatherManager()

    @Published private(set) var weather: WeatherSnapshot?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var locationAuthorizationStatus: CLAuthorizationStatus

    private let locationManager = CLLocationManager()
    private var refreshTask: Task<Void, Never>?
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    private var locationTimeoutTask: Task<Void, Never>?

    private override init() {
        locationAuthorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers

        if Defaults[.weatherEnabled],
           Defaults[.weatherUseCurrentLocation] || !Defaults[.weatherLocation].isEmpty {
            refresh()
        }
    }

    func refresh() {
        let location = Defaults[.weatherLocation].trimmingCharacters(in: .whitespacesAndNewlines)
        let useCurrentLocation = Defaults[.weatherUseCurrentLocation]
        guard Defaults[.weatherEnabled], useCurrentLocation || !location.isEmpty else {
            weather = nil
            errorMessage = useCurrentLocation ? nil : "Enter a city or postal code"
            return
        }

        refreshTask?.cancel()
        cancelLocationRequest()
        refreshTask = Task {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }

            do {
                if useCurrentLocation {
                    let currentLocation = try await requestCurrentLocation()
                    weather = try await fetchWeather(
                        latitude: currentLocation.coordinate.latitude,
                        longitude: currentLocation.coordinate.longitude,
                        locationName: "Current location"
                    )
                } else {
                    let place = try await geocode(location)
                    weather = try await fetchWeather(
                        latitude: place.latitude,
                        longitude: place.longitude,
                        locationName: [place.name, place.admin1].compactMap { $0 }.joined(separator: ", ")
                    )
                }
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    var locationPermissionDescription: String {
        switch locationAuthorizationStatus {
        case .notDetermined: "Location access has not been requested yet"
        case .restricted: "Location access is restricted"
        case .denied: "Location access is off for Boring Notch"
        case .authorizedAlways, .authorizedWhenInUse: "Location access is on"
        @unknown default: "Location access status is unavailable"
        }
    }

    private func requestCurrentLocation() async throws -> CLLocation {
        guard CLLocationManager.locationServicesEnabled() else {
            throw WeatherError.locationServicesDisabled
        }

        if locationContinuation != nil {
            cancelLocationRequest()
        }

        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation

            switch locationManager.authorizationStatus {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .authorizedAlways, .authorizedWhenInUse:
                locationManager.requestLocation()
            case .denied:
                finishLocationRequest(.failure(WeatherError.locationPermissionDenied))
            case .restricted:
                finishLocationRequest(.failure(WeatherError.locationPermissionRestricted))
            @unknown default:
                finishLocationRequest(.failure(WeatherError.locationPermissionDenied))
            }

            locationTimeoutTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(15))
                guard !Task.isCancelled else { return }
                self?.finishLocationRequest(.failure(WeatherError.locationTimedOut))
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationAuthorizationStatus = manager.authorizationStatus
        guard locationContinuation != nil else { return }

        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied:
            finishLocationRequest(.failure(WeatherError.locationPermissionDenied))
        case .restricted:
            finishLocationRequest(.failure(WeatherError.locationPermissionRestricted))
        case .notDetermined:
            break
        @unknown default:
            finishLocationRequest(.failure(WeatherError.locationPermissionDenied))
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            finishLocationRequest(.failure(WeatherError.locationUnavailable))
            return
        }
        finishLocationRequest(.success(location))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finishLocationRequest(.failure(error))
    }

    private func finishLocationRequest(_ result: Result<CLLocation, Error>) {
        guard let continuation = locationContinuation else { return }
        locationContinuation = nil
        locationTimeoutTask?.cancel()
        locationTimeoutTask = nil
        continuation.resume(with: result)
    }

    private func cancelLocationRequest() {
        guard locationContinuation != nil else { return }
        finishLocationRequest(.failure(CancellationError()))
    }

    private func geocode(_ query: String) async throws -> GeoResult {
        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        components.queryItems = [
            URLQueryItem(name: "name", value: query),
            URLQueryItem(name: "count", value: "1"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json")
        ]
        let (data, response) = try await URLSession.shared.data(from: components.url!)
        try validate(response)
        let payload = try JSONDecoder().decode(GeoResponse.self, from: data)
        guard let result = payload.results?.first else { throw WeatherError.locationNotFound }
        return result
    }

    private func fetchWeather(latitude: Double, longitude: Double, locationName: String) async throws -> WeatherSnapshot {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,apparent_temperature,weather_code"),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min"),
            URLQueryItem(name: "temperature_unit", value: Defaults[.weatherUseCelsius] ? "celsius" : "fahrenheit"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "1")
        ]
        let (data, response) = try await URLSession.shared.data(from: components.url!)
        try validate(response)
        let payload = try JSONDecoder().decode(ForecastResponse.self, from: data)
        guard let high = payload.daily.temperature2mMax.first, let low = payload.daily.temperature2mMin.first else {
            throw WeatherError.invalidResponse
        }
        return WeatherSnapshot(
            location: locationName,
            temperature: payload.current.temperature2m,
            apparentTemperature: payload.current.apparentTemperature,
            weatherCode: payload.current.weatherCode,
            high: high,
            low: low,
            updatedAt: .now
        )
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw WeatherError.invalidResponse
        }
    }
}

private enum WeatherError: LocalizedError {
    case locationNotFound
    case locationServicesDisabled
    case locationPermissionDenied
    case locationPermissionRestricted
    case locationTimedOut
    case locationUnavailable
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .locationNotFound: "Location not found"
        case .locationServicesDisabled: "Location Services are turned off"
        case .locationPermissionDenied: "Allow location access in System Settings to use local weather"
        case .locationPermissionRestricted: "Location access is restricted on this Mac"
        case .locationTimedOut: "The location request timed out"
        case .locationUnavailable: "Your current location is unavailable"
        case .invalidResponse: "Weather service did not return valid data"
        }
    }
}

private struct GeoResponse: Decodable { let results: [GeoResult]? }
private struct GeoResult: Decodable {
    let name: String
    let admin1: String?
    let latitude: Double
    let longitude: Double
}

private struct ForecastResponse: Decodable {
    let current: Current
    let daily: Daily

    struct Current: Decodable {
        let temperature2m: Double
        let apparentTemperature: Double
        let weatherCode: Int

        enum CodingKeys: String, CodingKey {
            case temperature2m = "temperature_2m"
            case apparentTemperature = "apparent_temperature"
            case weatherCode = "weather_code"
        }
    }

    struct Daily: Decodable {
        let temperature2mMax: [Double]
        let temperature2mMin: [Double]

        enum CodingKeys: String, CodingKey {
            case temperature2mMax = "temperature_2m_max"
            case temperature2mMin = "temperature_2m_min"
        }
    }
}
