# CSE 491 — AI-Based Real-Time Fire and Smoke Detection and Early Warning System

**Group 27** · Akdeniz University, Department of Computer Engineering  
**Supervisor:** Dr. Öğr. Üye. Joseph William LEDET

## Overview
An end-to-end real-time fire and smoke detection and early warning system operating on standard optical RGB surveillance streams (IP/RTSP or local webcams). The pipeline combines lightweight YOLO object detection with a sliding-window temporal verification filter (3–5 consecutive positive frames) to suppress optical confounders (steam, fog, headlights, solar glare), logs confirmed incidents in PostgreSQL via FastAPI, and dispatches instant push notifications with annotated snapshots to a Flutter mobile client via Firebase Cloud Messaging (FCM).

## Repository Structure
```text
cse491-fire-smoke-detection/
├── README.md
├── .gitignore
├── .env.example
├── docker-compose.yml
├── vision/                  # YOLO training, inference & temporal FIFO filter
├── backend/                 # FastAPI service, PostgreSQL schema, RTSP & FCM services
├── mobile/                  # Flutter cross-platform mobile client
└── docs/                    # Architecture & ER diagrams
```

## Quick Start (Local Development)
1. Copy environment variables:
   ```bash
   cp .env.example .env
   ```
2. Start Backend API & PostgreSQL:
   ```bash
   docker compose up --build
   ```
   The API health check will be available at `http://localhost:8000/health`.
3. Vision module (local Python environment):
   ```bash
   cd vision
   pip install -r requirements.txt
   ```
4. Mobile client (Flutter):
   ```bash
   cd mobile
   flutter pub get
   flutter run
   ```

## Git Conventions
- **Branching:** `main` (protected/stable), `feature/<module>-<short-desc>`, `fix/<short-desc>`
- **Commits:** Conventional Commits (`feat(vision): ...`, `fix(backend): ...`, `docs: ...`)

## Team Members
- **Cem Ali Görmez** — Computer Vision & Model Architecture
- **Ali Özcan Karol** — Backend & System Architecture
- **Melih Aşık** — Mobile Application & Integration
