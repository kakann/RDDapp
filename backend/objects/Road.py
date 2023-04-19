
from enum import Enum
from typing import List

class RoadStatus(Enum):
    RED = "red"
    ORANGE = "orange"
    GREEN = "green"

class Road:
    def __init__(self, id: str, status: RoadStatus):
        self.id = id
        self.status = status