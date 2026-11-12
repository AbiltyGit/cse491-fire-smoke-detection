"""YOLO inference wrapper placeholder for flame and smoke detection."""


class FireSmokeDetector:
    def __init__(self, weights_path: str, conf_threshold: float = 0.45) -> None:
        self.weights_path = weights_path
        self.conf_threshold = conf_threshold

    def predict(self, frame):
        raise NotImplementedError("Load Ultralytics YOLO weights and run frame inference.")
