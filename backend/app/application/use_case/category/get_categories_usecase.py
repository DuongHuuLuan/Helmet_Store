import math

from app.domain.repositories.category_repository import CategoryRepository


class GetCategoriesUseCase:
    def __init__(self, repo: CategoryRepository):
        self.repo = repo

    def execute(
        self,
        page: int = 1,
        per_page: int | None = None,
        keyword: str | None = None,
    ) -> dict:
        items, total = self.repo.get_all_paginated(
            page=page,
            per_page=per_page,
            keyword=keyword,
        )

        effective_per_page = per_page if per_page is not None else (total if total > 0 else 1)
        last_page = max(1, math.ceil(total / effective_per_page))

        category_list = []
        for entity, count in items:
            category_list.append({
                "id": entity.id,
                "name": entity.name,
                "products_count": count,
                "created_at": entity.created_at,
            })

        return {
            "items": category_list,
            "meta": {
                "total": total,
                "current_page": max(1, page),
                "per_page": effective_per_page,
                "last_page": last_page,
            },
        }
