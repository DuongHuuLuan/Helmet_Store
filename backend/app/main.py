import mimetypes
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

import app.core.cloudinary
from app.presentation.api import auth
from app.presentation.api import cart
from app.presentation.api import category
from app.presentation.api import chat
from app.presentation.api import dashboard
from app.presentation.api import delivery
from app.presentation.api import design
from app.presentation.api import discount
from app.presentation.api import distributor
from app.presentation.api import evaluate
from app.presentation.api import ghn
from app.presentation.api import image_url
from app.presentation.api import order
from app.presentation.api import payment
from app.presentation.api import product
from app.presentation.api import product_detail
from app.presentation.api import profile
from app.presentation.api import push_notification
from app.presentation.api import receipt
from app.presentation.api import statistics
from app.presentation.api import sticker
from app.presentation.api import user
from app.presentation.api import vnpay
from app.presentation.api import warehouse

app = FastAPI(title="Helmet Shop", version="1.0.0")

mimetypes.add_type("model/gltf-binary", ".glb")
mimetypes.add_type("model/gltf+json", ".gltf")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://127.0.0.1:5173",
        "http://localhost",
        "https://localhost",
        "null",
        "https://appassets.androidplatform.net",
    ],
    allow_origin_regex=(
        r"^https?://([a-z0-9-]+\.)?ngrok-free\.app$|"
        r"^https?://localhost(:\d+)?$|"
        r"^https?://127\.0\.0\.1(:\d+)?$|"
        r"^https://appassets\.androidplatform\.net$"
    ),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

STATIC_DIR = Path(__file__).resolve().parent.parent / "static"
app.mount("/static", StaticFiles(directory=str(STATIC_DIR), check_dir=False), name="static")
app.include_router(auth.router)
app.include_router(user.router)
app.include_router(product.router)
app.include_router(category.router)
app.include_router(product_detail.router)
app.include_router(cart.router)
app.include_router(order.router)
app.include_router(delivery.router)
app.include_router(payment.router)
app.include_router(evaluate.router)
app.include_router(distributor.router)
app.include_router(warehouse.router)
app.include_router(receipt.router)
app.include_router(image_url.router)
app.include_router(discount.router)
app.include_router(vnpay.router)
app.include_router(ghn.router)
app.include_router(dashboard.router)
app.include_router(statistics.router)
app.include_router(profile.router)
app.include_router(chat.router)
app.include_router(push_notification.router)
app.include_router(sticker.router)
app.include_router(design.router)
