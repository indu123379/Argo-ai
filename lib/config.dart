// Shared configuration for app integrations.
// Keep weather API usage limited to the weather option.

const String openWeatherApiKey = String.fromEnvironment('OPENWEATHER_API_KEY', defaultValue: 'YOUR_OPENWEATHER_API_KEY');
const String openWeatherBaseUrl = 'https://api.openweathermap.org/data/2.5/weather';
