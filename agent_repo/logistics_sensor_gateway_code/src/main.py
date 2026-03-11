from gateway.normalizer import normalize_sensor_data, clean_noisy_data
from gateway.router import route_alert

import json

def process_gateway_data(raw_sensor_text):
    # Assume raw_sensor_text is a JSON string for simplicity
    sensor_data = json.loads(raw_sensor_text)

    normalized_data = normalize_sensor_data(sensor_data)
    cleaned_data = clean_noisy_data(normalized_data)
    
    destination_agent = route_alert(cleaned_data)
    print(f"Data processed and routed to: {destination_agent}")
    print(f"Cleaned and Normalized Data: {json.dumps(cleaned_data, indent=2)}")
    return cleaned_data, destination_agent

if __name__ == '__main__':
    # Example usage
    bosch_data = '{"sensor_id": "BOSCH001", "sensor_type": "location", "gps_coords": {"latitude": 34.0522, "longitude": -118.2437}, "fuel": 75, "engine_health": "ok", "time": "2023-10-27T10:00:00Z"}'
    garmin_data = '{"sensor_id": "GARMIN002", "sensor_type": "engine", "loc_data": "noisy", "gas_level": 50, "motor_status": "alert", "time": "2023-10-27T10:05:00Z"}'

    print("Processing Bosch Data:")
    process_gateway_data(bosch_data)

    print("\nProcessing Garmin Data:")
    process_gateway_data(garmin_data)
