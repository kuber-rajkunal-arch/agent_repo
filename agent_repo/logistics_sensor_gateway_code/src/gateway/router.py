def route_alert(normalized_data):
    if normalized_data.get('engine_status') == 'alert':
        return 'Maintenance Agent'
    elif normalized_data.get('location') and 'latitude' in normalized_data['location']:
        return 'Customer Tracking Agent'
    return 'Unknown Agent'
