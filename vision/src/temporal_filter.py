from collections import deque


class TemporalVerificationFilter:
    """Sliding-window FIFO filter requiring N consecutive positive frames."""

    def __init__(self, window_size: int = 4) -> None:
        if window_size < 1:
            raise ValueError("window_size must be >= 1")
        self.window_size = window_size
        self._history: deque[bool] = deque(maxlen=window_size)

    def update(self, has_detection: bool) -> bool:
        self._history.append(has_detection)
        return len(self._history) == self.window_size and all(self._history)

    def reset(self) -> None:
        self._history.clear()
