from app.domain.repositories.color_repository import ColorRepository


class DeleteColorUseCase:
    def __init__(self, repo: ColorRepository):
        self.repo = repo

    def execute(self, id: int) -> None:
        self.repo.delete(id)
