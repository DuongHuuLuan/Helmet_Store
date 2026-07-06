from fastapi import UploadFile, HTTPException, status

from app.core.config import settings
import cloudinary.uploader


class UploadImageUseCase:
    def execute(self, file: UploadFile, folder: str = "helmet_shop/products") -> dict:
        try:
            result = cloudinary.uploader.upload(
                file.file,
                folder=folder or "helmet_shop/products",
            )
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Không thể tải ảnh lên Cloudinary: {exc}",
            ) from exc

        url = result.get("secure_url")
        public_id = result.get("public_id")

        if not url:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Cloudinary không trả về ảnh hợp lệ",
            )

        return {"url": url, "public_id": public_id}
