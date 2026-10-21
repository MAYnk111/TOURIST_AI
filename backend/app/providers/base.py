from abc import ABC, abstractmethod
from typing import List, Optional, Dict, Any
from ..models.schemas import DestinationModel, AttractionModel

class BaseDestinationProvider(ABC):
    @property
    @abstractmethod
    def provider_name(self) -> str:
        pass

    @property
    @abstractmethod
    def is_configured(self) -> bool:
        pass

    @abstractmethod
    def search_destinations(self, query: str) -> List[DestinationModel]:
        pass

    @abstractmethod
    def get_attractions(self, destination_id: str, category: Optional[str] = None) -> List[AttractionModel]:
        pass

    @abstractmethod
    def get_attraction_details(self, place_id: str) -> Optional[AttractionModel]:
        pass
