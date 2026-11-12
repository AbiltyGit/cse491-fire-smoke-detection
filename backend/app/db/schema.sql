CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS cameras (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(120) NOT NULL,
    rtsp_url TEXT NOT NULL,
    location VARCHAR(255),
    conf_threshold DOUBLE PRECISION NOT NULL DEFAULT 0.45,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name VARCHAR(120) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'operator',
    fcm_token TEXT
);

CREATE TABLE IF NOT EXISTS detection_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    camera_id UUID NOT NULL REFERENCES cameras(id) ON DELETE CASCADE,
    detected_class VARCHAR(20) NOT NULL CHECK (detected_class IN ('flame', 'smoke')),
    confidence DOUBLE PRECISION NOT NULL,
    bbox_coords JSONB NOT NULL,
    frame_streak INTEGER NOT NULL,
    snapshot_path TEXT NOT NULL,
    detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES detection_events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    fcm_message_id TEXT,
    status VARCHAR(30) NOT NULL DEFAULT 'sent' CHECK (status IN ('sent', 'delivered', 'acknowledged')),
    acknowledged_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
