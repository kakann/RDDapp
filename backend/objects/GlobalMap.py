from typing import List

from backend.objects.Road import Road


class GlobalMap:
    def __init__(self, roads: List[Road]):
        self.roads = roads
