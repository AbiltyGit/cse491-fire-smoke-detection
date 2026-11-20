CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name VARCHAR(120) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'operator',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    fcm_token TEXT UNIQUE NOT NULL,
    platform VARCHAR(20) NOT NULL CHECK (platform IN ('android', 'ios')),
    registered_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS cameras (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(120) NOT NULL,
    rtsp_url TEXT NOT NULL,
    location VARCHAR(255),
    conf_threshold DOUBLE PRECISION NOT NULL DEFAULT 0.45,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS detection_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    camera_id UUID NOT NULL REFERENCES cameras(id) ON DELETE CASCADE,
    event_type VARCHAR(20) NOT NULL CHECK (event_type IN ('flame', 'smoke', 'both')),
    max_confidence DOUBLE PRECISION NOT NULL,
    frame_streak INTEGER NOT NULL,
    snapshot_path TEXT,
    detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_events_camera_time ON detection_events (camera_id, detected_at DESC);

CREATE TABLE IF NOT EXISTS detection_boxes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES detection_events(id) ON DELETE CASCADE,
    class_name VARCHAR(20) NOT NULL CHECK (class_name IN ('flame', 'smoke')),
    confidence DOUBLE PRECISION NOT NULL,
    x_min DOUBLE PRECISION NOT NULL,
    y_min DOUBLE PRECISION NOT NULL,
    x_max DOUBLE PRECISION NOT NULL,
    y_max DOUBLE PRECISION NOT NULL
);

CREATE TABLE IF NOT EXISTS notification_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES detection_events(id) ON DELETE CASCADE,
    device_id UUID NOT NULL REFERENCES user_devices(id) ON DELETE CASCADE,
    fcm_message_id TEXT,
    status VARCHAR(30) NOT NULL DEFAULT 'sent' CHECK (status IN ('sent', 'delivered', 'failed', 'acknowledged')),
    sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    acknowledged_at TIMESTAMPTZ
);
