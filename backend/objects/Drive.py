
from typing import List

from backend.objects.PositionImgSnap import PositionImgSnap

class Drive:
    def __init__(self, position_img_snaps: List[PositionImgSnap], total_time: float, total_images: int, total_damages: int):
        self.position_img_snaps = position_img_snaps
        self.total_time = total_time
        self.total_images = total_images
        self.total_damages = total_damages