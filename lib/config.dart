// Shared configuration for app integrations.
// Keep weather API usage limited to the weather option.

const String openWeatherApiKey = String.fromEnvironment('OPENWEATHER_API_KEY', defaultValue: 'df1547a399fd534b5cef3fe241ab6479');
const String openWeatherBaseUrl = 'https://api.openweathermap.org/data/2.5/weather';
