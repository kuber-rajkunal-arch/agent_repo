import json

def normalize_sensor_data(sensor_data):
    # Simulate normalization logic
    normalized_data = {
        'id': sensor_data.get('sensor_id'),
        'type': sensor_data.get('sensor_type'),
        'location': sensor_data.get('gps_coords') or sensor_data.get('loc_data'),
        'fuel_level': sensor_data.get('fuel') or sensor_data.get('gas_level'),
        'engine_status': sensor_data.get('engine_health') or sensor_data.get('motor_status'),
        'timestamp': sensor_data.get('time')
    }
    return normalized_data

def clean_noisy_data(data):
    # Simulate cleaning noisy data
    if data.get('location') == 'noisy' or data.get('location') == 'signal_loss':
        data['location'] = 'last_known_location'
    return data
