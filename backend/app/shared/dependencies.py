from fastapi import Depends
from sqlalchemy.orm import Session

from app.infrastructure.database.session import get_db

from app.infrastructure.repositories.color_repository_impl import ColorRepositoryImpl
from app.infrastructure.repositories.size_repository_impl import SizeRepositoryImpl
from app.application.use_case.color.get_colors_usecase import GetColorsUseCase
from app.application.use_case.color.get_color_by_id_usecase import GetColorByIdUseCase
from app.application.use_case.color.create_color_usecase import CreateColorUseCase
from app.application.use_case.color.update_color_usecase import UpdateColorUseCase
from app.application.use_case.color.delete_color_usecase import DeleteColorUseCase
from app.application.use_case.size.get_sizes_usecase import GetSizesUseCase
from app.application.use_case.size.get_size_by_id_usecase import GetSizeByIdUseCase
from app.application.use_case.size.create_size_usecase import CreateSizeUseCase
from app.application.use_case.size.update_size_usecase import UpdateSizeUseCase
from app.application.use_case.size.delete_size_usecase import DeleteSizeUseCase
from app.domain.repositories.color_repository import ColorRepository
from app.domain.repositories.size_repository import SizeRepository


def get_color_repo(db: Session = Depends(get_db)) -> ColorRepository:
    return ColorRepositoryImpl(db)


def get_colors_use_case(
    repo: ColorRepository = Depends(get_color_repo),
) -> GetColorsUseCase:
    return GetColorsUseCase(repo)


def get_color_by_id_use_case(
    repo: ColorRepository = Depends(get_color_repo),
) -> GetColorByIdUseCase:
    return GetColorByIdUseCase(repo)


def create_color_use_case(
    repo: ColorRepository = Depends(get_color_repo),
) -> CreateColorUseCase:
    return CreateColorUseCase(repo)


def update_color_use_case(
    repo: ColorRepository = Depends(get_color_repo),
) -> UpdateColorUseCase:
    return UpdateColorUseCase(repo)


def delete_color_use_case(
    repo: ColorRepository = Depends(get_color_repo),
) -> DeleteColorUseCase:
    return DeleteColorUseCase(repo)


# ---- Size ----

def get_size_repo(db: Session = Depends(get_db)) -> SizeRepository:
    return SizeRepositoryImpl(db)


def get_sizes_use_case(
    repo: SizeRepository = Depends(get_size_repo),
) -> GetSizesUseCase:
    return GetSizesUseCase(repo)


def get_size_by_id_use_case(
    repo: SizeRepository = Depends(get_size_repo),
) -> GetSizeByIdUseCase:
    return GetSizeByIdUseCase(repo)


def create_size_use_case(
    repo: SizeRepository = Depends(get_size_repo),
) -> CreateSizeUseCase:
    return CreateSizeUseCase(repo)


def update_size_use_case(
    repo: SizeRepository = Depends(get_size_repo),
) -> UpdateSizeUseCase:
    return UpdateSizeUseCase(repo)


def delete_size_use_case(
    repo: SizeRepository = Depends(get_size_repo),
) -> DeleteSizeUseCase:
    return DeleteSizeUseCase(repo)


# ---- Category ----

from app.infrastructure.repositories.category_repository_impl import CategoryRepositoryImpl
from app.application.use_case.category.get_categories_usecase import GetCategoriesUseCase
from app.application.use_case.category.get_category_by_id_usecase import GetCategoryByIdUseCase
from app.application.use_case.category.create_category_usecase import CreateCategoryUseCase
from app.application.use_case.category.update_category_usecase import UpdateCategoryUseCase
from app.application.use_case.category.delete_category_usecase import DeleteCategoryUseCase
from app.application.use_case.category.get_category_products_usecase import GetCategoryProductsUseCase
from app.domain.repositories.category_repository import CategoryRepository


def get_category_repo(db: Session = Depends(get_db)) -> CategoryRepository:
    return CategoryRepositoryImpl(db)


def get_categories_use_case(
    repo: CategoryRepository = Depends(get_category_repo),
) -> GetCategoriesUseCase:
    return GetCategoriesUseCase(repo)


def get_category_by_id_use_case(
    repo: CategoryRepository = Depends(get_category_repo),
) -> GetCategoryByIdUseCase:
    return GetCategoryByIdUseCase(repo)


def create_category_use_case(
    repo: CategoryRepository = Depends(get_category_repo),
) -> CreateCategoryUseCase:
    return CreateCategoryUseCase(repo)


def update_category_use_case(
    repo: CategoryRepository = Depends(get_category_repo),
) -> UpdateCategoryUseCase:
    return UpdateCategoryUseCase(repo)


def delete_category_use_case(
    repo: CategoryRepository = Depends(get_category_repo),
) -> DeleteCategoryUseCase:
    return DeleteCategoryUseCase(repo)


def get_category_products_use_case(
    repo: CategoryRepository = Depends(get_category_repo),
) -> GetCategoryProductsUseCase:
    return GetCategoryProductsUseCase(repo)


# ---- User / Auth ----

from app.infrastructure.repositories.user_repository_impl import UserRepositoryImpl
from app.infrastructure.repositories.profile_repository_impl import ProfileRepositoryImpl
from app.infrastructure.repositories.user_device_repository_impl import UserDeviceRepositoryImpl
from app.application.use_case.auth.register_usecase import RegisterUseCase
from app.application.use_case.auth.login_usecase import LoginUseCase
from app.application.use_case.auth.refresh_token_usecase import RefreshTokenUseCase
from app.application.use_case.auth.change_password_usecase import ChangePasswordUseCase
from app.application.use_case.user.get_users_usecase import GetUsersUseCase
from app.application.use_case.user.get_user_by_id_usecase import GetUserByIdUseCase
from app.application.use_case.profile.get_my_profile_usecase import GetMyProfileUseCase
from app.application.use_case.profile.update_my_profile_usecase import UpdateMyProfileUseCase
from app.application.use_case.profile.upload_my_avatar_usecase import UploadMyAvatarUseCase
from app.application.use_case.push_notification.list_user_devices_usecase import ListUserDevicesUseCase
from app.application.use_case.push_notification.upsert_user_device_usecase import UpsertUserDeviceUseCase
from app.application.use_case.push_notification.deactivate_user_device_usecase import DeactivateUserDeviceUseCase
from app.domain.repositories.user_repository import UserRepository
from app.domain.repositories.profile_repository import ProfileRepository
from app.domain.repositories.user_device_repository import UserDeviceRepository


def get_user_repo(db: Session = Depends(get_db)) -> UserRepository:
    return UserRepositoryImpl(db)


def get_profile_repo(db: Session = Depends(get_db)) -> ProfileRepository:
    return ProfileRepositoryImpl(db)


def get_device_repo(db: Session = Depends(get_db)) -> UserDeviceRepository:
    return UserDeviceRepositoryImpl(db)


# --- Auth ---

def get_register_use_case(
    user_repo: UserRepository = Depends(get_user_repo),
    profile_repo: ProfileRepository = Depends(get_profile_repo),
) -> RegisterUseCase:
    return RegisterUseCase(user_repo, profile_repo)


def get_login_use_case(
    user_repo: UserRepository = Depends(get_user_repo),
) -> LoginUseCase:
    return LoginUseCase(user_repo)


def get_refresh_token_use_case(
    user_repo: UserRepository = Depends(get_user_repo),
) -> RefreshTokenUseCase:
    return RefreshTokenUseCase(user_repo)


def get_change_password_use_case(
    user_repo: UserRepository = Depends(get_user_repo),
) -> ChangePasswordUseCase:
    return ChangePasswordUseCase(user_repo)


# --- User ---

def get_users_use_case(
    user_repo: UserRepository = Depends(get_user_repo),
) -> GetUsersUseCase:
    return GetUsersUseCase(user_repo)


def get_user_by_id_use_case(
    user_repo: UserRepository = Depends(get_user_repo),
    profile_repo: ProfileRepository = Depends(get_profile_repo),
) -> GetUserByIdUseCase:
    return GetUserByIdUseCase(user_repo, profile_repo)


# --- Profile ---

def get_my_profile_use_case(
    profile_repo: ProfileRepository = Depends(get_profile_repo),
) -> GetMyProfileUseCase:
    return GetMyProfileUseCase(profile_repo)


def get_update_my_profile_use_case(
    profile_repo: ProfileRepository = Depends(get_profile_repo),
    user_repo: UserRepository = Depends(get_user_repo),
) -> UpdateMyProfileUseCase:
    return UpdateMyProfileUseCase(profile_repo, user_repo)


def get_upload_avatar_use_case(
    profile_repo: ProfileRepository = Depends(get_profile_repo),
) -> UploadMyAvatarUseCase:
    return UploadMyAvatarUseCase(profile_repo)


# --- Push Notification ---

def get_list_devices_use_case(
    device_repo: UserDeviceRepository = Depends(get_device_repo),
) -> ListUserDevicesUseCase:
    return ListUserDevicesUseCase(device_repo)


def get_upsert_device_use_case(
    device_repo: UserDeviceRepository = Depends(get_device_repo),
) -> UpsertUserDeviceUseCase:
    return UpsertUserDeviceUseCase(device_repo)


def get_deactivate_device_use_case(
    device_repo: UserDeviceRepository = Depends(get_device_repo),
) -> DeactivateUserDeviceUseCase:
    return DeactivateUserDeviceUseCase(device_repo)


# ---- Product ----

from app.infrastructure.repositories.product_repository_impl import ProductRepositoryImpl
from app.infrastructure.repositories.product_detail_repository_impl import ProductDetailRepositoryImpl
from app.infrastructure.repositories.image_url_repository_impl import ImageUrlRepositoryImpl
from app.application.use_case.product.create_product_usecase import CreateProductUseCase
from app.application.use_case.product.get_product_by_id_usecase import GetProductByIdUseCase
from app.application.use_case.product.get_products_usecase import GetProductsUseCase
from app.application.use_case.product.update_product_usecase import UpdateProductUseCase
from app.application.use_case.product.delete_product_usecase import DeleteProductUseCase
from app.application.use_case.product.ensure_delete_usecase import EnsureDeleteUseCase
from app.application.use_case.product_detail.create_product_detail_usecase import CreateProductDetailUseCase
from app.application.use_case.product_detail.update_product_detail_usecase import UpdateProductDetailUseCase
from app.application.use_case.product_detail.delete_product_detail_usecase import DeleteProductDetailUseCase
from app.application.use_case.image.add_images_usecase import AddImagesUseCase
from app.application.use_case.image.delete_image_usecase import DeleteImageUseCase
from app.application.use_case.image.delete_all_images_usecase import DeleteAllImagesUseCase
from app.application.use_case.image.replace_image_usecase import ReplaceImageUseCase
from app.application.use_case.image.update_view_image_key_usecase import UpdateViewImageKeyUseCase
from app.application.use_case.image.upload_image_usecase import UploadImageUseCase
from app.domain.repositories.product_repository import ProductRepository
from app.domain.repositories.product_detail_repository import ProductDetailRepository
from app.domain.repositories.image_url_repository import ImageUrlRepository


def get_product_repo(db: Session = Depends(get_db)) -> ProductRepository:
    return ProductRepositoryImpl(db)


def get_product_detail_repo(db: Session = Depends(get_db)) -> ProductDetailRepository:
    return ProductDetailRepositoryImpl(db)


def get_image_repo(db: Session = Depends(get_db)) -> ImageUrlRepository:
    return ImageUrlRepositoryImpl(db)


# --- Product ---

def get_create_product_use_case(
    repo: ProductRepository = Depends(get_product_repo),
) -> CreateProductUseCase:
    return CreateProductUseCase(repo)


def get_update_product_use_case(
    repo: ProductRepository = Depends(get_product_repo),
) -> UpdateProductUseCase:
    return UpdateProductUseCase(repo)


def get_delete_product_use_case(
    repo: ProductRepository = Depends(get_product_repo),
) -> DeleteProductUseCase:
    return DeleteProductUseCase(repo)


def get_ensure_delete_use_case(
    repo: ProductRepository = Depends(get_product_repo),
) -> EnsureDeleteUseCase:
    return EnsureDeleteUseCase(repo)


# --- Product Detail ---

def get_create_product_detail_use_case(
    repo: ProductDetailRepository = Depends(get_product_detail_repo),
) -> CreateProductDetailUseCase:
    return CreateProductDetailUseCase(repo)


def get_update_product_detail_use_case(
    repo: ProductDetailRepository = Depends(get_product_detail_repo),
) -> UpdateProductDetailUseCase:
    return UpdateProductDetailUseCase(repo)


def get_delete_product_detail_use_case(
    repo: ProductDetailRepository = Depends(get_product_detail_repo),
) -> DeleteProductDetailUseCase:
    return DeleteProductDetailUseCase(repo)


# --- Image ---

def get_add_images_use_case(
    repo: ImageUrlRepository = Depends(get_image_repo),
) -> AddImagesUseCase:
    return AddImagesUseCase(repo)


def get_delete_image_use_case(
    repo: ImageUrlRepository = Depends(get_image_repo),
) -> DeleteImageUseCase:
    return DeleteImageUseCase(repo)


def get_delete_all_images_use_case(
    repo: ImageUrlRepository = Depends(get_image_repo),
) -> DeleteAllImagesUseCase:
    return DeleteAllImagesUseCase(repo)


def get_replace_image_use_case(
    repo: ImageUrlRepository = Depends(get_image_repo),
) -> ReplaceImageUseCase:
    return ReplaceImageUseCase(repo)


def get_update_view_image_key_use_case(
    repo: ImageUrlRepository = Depends(get_image_repo),
) -> UpdateViewImageKeyUseCase:
    return UpdateViewImageKeyUseCase(repo)


def get_upload_image_use_case() -> UploadImageUseCase:
    return UploadImageUseCase()


# ---- Cart ----

from app.infrastructure.repositories.cart_repository_impl import CartRepositoryImpl
from app.application.use_case.cart.add_to_cart_usecase import AddToCartUseCase
from app.application.use_case.cart.get_cart_usecase import GetCartUseCase
from app.application.use_case.cart.update_cart_detail_usecase import UpdateCartDetailUseCase
from app.application.use_case.cart.delete_cart_detail_usecase import DeleteCartDetailUseCase
from app.domain.repositories.cart_repository import CartRepository


def get_cart_repo(db: Session = Depends(get_db)) -> CartRepository:
    return CartRepositoryImpl(db)


def get_add_to_cart_use_case(
    repo: CartRepository = Depends(get_cart_repo),
) -> AddToCartUseCase:
    return AddToCartUseCase(repo)


def get_update_cart_detail_use_case(
    repo: CartRepository = Depends(get_cart_repo),
) -> UpdateCartDetailUseCase:
    return UpdateCartDetailUseCase(repo)


def get_delete_cart_detail_use_case(
    repo: CartRepository = Depends(get_cart_repo),
) -> DeleteCartDetailUseCase:
    return DeleteCartDetailUseCase(repo)


# ---- Discount ----

from app.infrastructure.repositories.discount_repository_impl import DiscountRepositoryImpl
from app.application.use_case.discount.get_discounts_usecase import GetDiscountsUseCase
from app.application.use_case.discount.create_discount_usecase import CreateDiscountUseCase
from app.application.use_case.discount.update_discount_usecase import UpdateDiscountUseCase
from app.application.use_case.discount.delete_discount_usecase import DeleteDiscountUseCase
from app.domain.repositories.discount_repository import DiscountRepository


def get_discount_repo(db: Session = Depends(get_db)) -> DiscountRepository:
    return DiscountRepositoryImpl(db)


def get_discounts_use_case(
    repo: DiscountRepository = Depends(get_discount_repo),
) -> GetDiscountsUseCase:
    return GetDiscountsUseCase(repo)


def get_create_discount_use_case(
    repo: DiscountRepository = Depends(get_discount_repo),
) -> CreateDiscountUseCase:
    return CreateDiscountUseCase(repo)


def get_update_discount_use_case(
    repo: DiscountRepository = Depends(get_discount_repo),
) -> UpdateDiscountUseCase:
    return UpdateDiscountUseCase(repo)


def get_delete_discount_use_case(
    repo: DiscountRepository = Depends(get_discount_repo),
) -> DeleteDiscountUseCase:
    return DeleteDiscountUseCase(repo)


# ---- Delivery Info ----

from app.infrastructure.repositories.delivery_info_repository_impl import DeliveryInfoRepositoryImpl
from app.application.use_case.delivery.create_delivery_usecase import CreateDeliveryUseCase
from app.application.use_case.delivery.get_my_deliveries_usecase import GetMyDeliveriesUseCase
from app.application.use_case.delivery.delete_delivery_usecase import DeleteDeliveryUseCase
from app.domain.repositories.delivery_info_repository import DeliveryInfoRepository


def get_delivery_repo(db: Session = Depends(get_db)) -> DeliveryInfoRepository:
    return DeliveryInfoRepositoryImpl(db)


def get_create_delivery_use_case(
    repo: DeliveryInfoRepository = Depends(get_delivery_repo),
) -> CreateDeliveryUseCase:
    return CreateDeliveryUseCase(repo)


def get_my_deliveries_use_case(
    repo: DeliveryInfoRepository = Depends(get_delivery_repo),
) -> GetMyDeliveriesUseCase:
    return GetMyDeliveriesUseCase(repo)


def get_delete_delivery_use_case(
    repo: DeliveryInfoRepository = Depends(get_delivery_repo),
) -> DeleteDeliveryUseCase:
    return DeleteDeliveryUseCase(repo)


# ---- Payment Method ----

from app.infrastructure.repositories.payment_method_repository_impl import PaymentMethodRepositoryImpl
from app.application.use_case.payment.get_payment_methods_usecase import GetPaymentMethodsUseCase
from app.application.use_case.payment.get_payment_methods_admin_usecase import GetPaymentMethodsAdminUseCase
from app.application.use_case.payment.get_payment_method_by_id_usecase import GetPaymentMethodByIdUseCase
from app.application.use_case.payment.create_payment_method_usecase import CreatePaymentMethodUseCase
from app.application.use_case.payment.update_payment_method_usecase import UpdatePaymentMethodUseCase
from app.application.use_case.payment.delete_payment_method_usecase import DeletePaymentMethodUseCase
from app.domain.repositories.payment_method_repository import PaymentMethodRepository


def get_payment_repo(db: Session = Depends(get_db)) -> PaymentMethodRepository:
    return PaymentMethodRepositoryImpl(db)


def get_payment_methods_use_case(
    repo: PaymentMethodRepository = Depends(get_payment_repo),
) -> GetPaymentMethodsUseCase:
    return GetPaymentMethodsUseCase(repo)


def get_payment_methods_admin_use_case(
    repo: PaymentMethodRepository = Depends(get_payment_repo),
) -> GetPaymentMethodsAdminUseCase:
    return GetPaymentMethodsAdminUseCase(repo)


def get_create_payment_method_use_case(
    repo: PaymentMethodRepository = Depends(get_payment_repo),
) -> CreatePaymentMethodUseCase:
    return CreatePaymentMethodUseCase(repo)


def get_update_payment_method_use_case(
    repo: PaymentMethodRepository = Depends(get_payment_repo),
) -> UpdatePaymentMethodUseCase:
    return UpdatePaymentMethodUseCase(repo)


def get_delete_payment_method_use_case(
    repo: PaymentMethodRepository = Depends(get_payment_repo),
) -> DeletePaymentMethodUseCase:
    return DeletePaymentMethodUseCase(repo)


def get_payment_method_by_id_use_case(
    repo: PaymentMethodRepository = Depends(get_payment_repo),
) -> GetPaymentMethodByIdUseCase:
    return GetPaymentMethodByIdUseCase(repo)


# ---- Product (fix get_by_id + get_all) ----

def get_product_by_id_use_case(
    repo: ProductRepository = Depends(get_product_repo),
) -> GetProductByIdUseCase:
    return GetProductByIdUseCase(repo)


def get_products_use_case(
    repo: ProductRepository = Depends(get_product_repo),
) -> GetProductsUseCase:
    return GetProductsUseCase(repo)


# ---- Cart (now needs warehouse_repo) ----

from app.infrastructure.repositories.warehouse_repository_impl import WarehouseRepositoryImpl
from app.domain.repositories.warehouse_repository import WarehouseRepository


def get_warehouse_repo(db: Session = Depends(get_db)) -> WarehouseRepository:
    return WarehouseRepositoryImpl(db)


def get_cart_use_case(
    repo: CartRepository = Depends(get_cart_repo),
) -> GetCartUseCase:
    return GetCartUseCase(repo)


def get_add_to_cart_use_case(
    repo: CartRepository = Depends(get_cart_repo),
    warehouse_repo: WarehouseRepository = Depends(get_warehouse_repo),
) -> AddToCartUseCase:
    return AddToCartUseCase(repo, warehouse_repo)


def get_update_cart_detail_use_case(
    repo: CartRepository = Depends(get_cart_repo),
    warehouse_repo: WarehouseRepository = Depends(get_warehouse_repo),
) -> UpdateCartDetailUseCase:
    return UpdateCartDetailUseCase(repo, warehouse_repo)


# ---- Discount (add missing use cases) ----

from app.application.use_case.discount.get_discount_by_id_usecase import GetDiscountByIdUseCase
from app.application.use_case.discount.get_valid_discount_usecase import GetValidDiscountUseCase
from app.application.use_case.discount.get_discounts_by_category_ids_usecase import GetDiscountsByCategoryIdsUseCase
from app.application.use_case.discount.get_available_discounts_for_cart_usecase import GetAvailableDiscountsForCartUseCase


def get_discount_by_id_use_case(
    repo: DiscountRepository = Depends(get_discount_repo),
) -> GetDiscountByIdUseCase:
    return GetDiscountByIdUseCase(repo)


def get_valid_discount_use_case(
    repo: DiscountRepository = Depends(get_discount_repo),
) -> GetValidDiscountUseCase:
    return GetValidDiscountUseCase(repo)


def get_discounts_by_category_ids_use_case(
    repo: DiscountRepository = Depends(get_discount_repo),
) -> GetDiscountsByCategoryIdsUseCase:
    return GetDiscountsByCategoryIdsUseCase(repo)


def get_available_discounts_for_cart_use_case(
    repo: DiscountRepository = Depends(get_discount_repo),
) -> GetAvailableDiscountsForCartUseCase:
    return GetAvailableDiscountsForCartUseCase(repo)


# ---- Distributor ----

from app.infrastructure.repositories.distributor_repository_impl import DistributorRepositoryImpl
from app.application.use_case.distributor.get_distributors_usecase import GetDistributorsUseCase
from app.application.use_case.distributor.get_distributor_usecase import GetDistributorUseCase
from app.application.use_case.distributor.create_distributor_usecase import CreateDistributorUseCase
from app.application.use_case.distributor.update_distributor_usecase import UpdateDistributorUseCase
from app.application.use_case.distributor.delete_distributor_usecase import DeleteDistributorUseCase
from app.domain.repositories.distributor_repository import DistributorRepository


def get_distributor_repo(db: Session = Depends(get_db)) -> DistributorRepository:
    return DistributorRepositoryImpl(db)


def get_distributors_use_case(
    repo: DistributorRepository = Depends(get_distributor_repo),
) -> GetDistributorsUseCase:
    return GetDistributorsUseCase(repo)


def get_distributor_use_case(
    repo: DistributorRepository = Depends(get_distributor_repo),
) -> GetDistributorUseCase:
    return GetDistributorUseCase(repo)


def get_create_distributor_use_case(
    repo: DistributorRepository = Depends(get_distributor_repo),
) -> CreateDistributorUseCase:
    return CreateDistributorUseCase(repo)


def get_update_distributor_use_case(
    repo: DistributorRepository = Depends(get_distributor_repo),
) -> UpdateDistributorUseCase:
    return UpdateDistributorUseCase(repo)


def get_delete_distributor_use_case(
    repo: DistributorRepository = Depends(get_distributor_repo),
) -> DeleteDistributorUseCase:
    return DeleteDistributorUseCase(repo)


# ---- Evaluate ----

from app.infrastructure.repositories.evaluate_repository_impl import EvaluateRepositoryImpl
from app.application.use_case.evaluate.create_evaluate_usecase import CreateEvaluateUseCase
from app.application.use_case.evaluate.get_admin_evaluations_usecase import GetAdminEvaluationsUseCase
from app.application.use_case.evaluate.get_evaluate_by_id_usecase import GetEvaluateByIdUseCase
from app.application.use_case.evaluate.get_evaluate_by_order_usecase import GetEvaluateByOrderUseCase
from app.application.use_case.evaluate.get_my_evaluations_usecase import GetMyEvaluationsUseCase
from app.application.use_case.evaluate.get_product_evaluations_usecase import GetProductEvaluationsUseCase
from app.application.use_case.evaluate.reply_evaluate_usecase import ReplyEvaluateUseCase
from app.domain.repositories.evaluate_repository import EvaluateRepository


def get_evaluate_repo(db: Session = Depends(get_db)) -> EvaluateRepository:
    return EvaluateRepositoryImpl(db)


def get_create_evaluate_use_case(
    repo: EvaluateRepository = Depends(get_evaluate_repo),
) -> CreateEvaluateUseCase:
    return CreateEvaluateUseCase(repo)


def get_admin_evaluations_use_case(
    repo: EvaluateRepository = Depends(get_evaluate_repo),
) -> GetAdminEvaluationsUseCase:
    return GetAdminEvaluationsUseCase(repo)


def get_evaluate_by_id_use_case(
    repo: EvaluateRepository = Depends(get_evaluate_repo),
) -> GetEvaluateByIdUseCase:
    return GetEvaluateByIdUseCase(repo)


def get_evaluate_by_order_use_case(
    repo: EvaluateRepository = Depends(get_evaluate_repo),
) -> GetEvaluateByOrderUseCase:
    return GetEvaluateByOrderUseCase(repo)


def get_my_evaluations_use_case(
    repo: EvaluateRepository = Depends(get_evaluate_repo),
) -> GetMyEvaluationsUseCase:
    return GetMyEvaluationsUseCase(repo)


def get_product_evaluations_use_case(
    repo: EvaluateRepository = Depends(get_evaluate_repo),
) -> GetProductEvaluationsUseCase:
    return GetProductEvaluationsUseCase(repo)


def get_reply_evaluate_use_case(
    repo: EvaluateRepository = Depends(get_evaluate_repo),
) -> ReplyEvaluateUseCase:
    return ReplyEvaluateUseCase(repo)


# ---- Receipt ----

from app.infrastructure.repositories.receipt_repository_impl import ReceiptRepositoryImpl
from app.application.use_case.receipt.get_receipts_usecase import GetReceiptsUseCase
from app.application.use_case.receipt.get_receipt_usecase import GetReceiptUseCase
from app.application.use_case.receipt.create_receipt_usecase import CreateReceiptUseCase
from app.application.use_case.receipt.confirm_receipt_usecase import ConfirmReceiptUseCase
from app.application.use_case.receipt.cancel_receipt_usecase import CancelReceiptUseCase
from app.domain.repositories.receipt_repository import ReceiptRepository


def get_receipt_repo(db: Session = Depends(get_db)) -> ReceiptRepository:
    return ReceiptRepositoryImpl(db)


def get_receipts_use_case(
    repo: ReceiptRepository = Depends(get_receipt_repo),
) -> GetReceiptsUseCase:
    return GetReceiptsUseCase(repo)


def get_receipt_use_case(
    repo: ReceiptRepository = Depends(get_receipt_repo),
) -> GetReceiptUseCase:
    return GetReceiptUseCase(repo)


def get_create_receipt_use_case(
    repo: ReceiptRepository = Depends(get_receipt_repo),
) -> CreateReceiptUseCase:
    return CreateReceiptUseCase(repo)


def get_confirm_receipt_use_case(
    repo: ReceiptRepository = Depends(get_receipt_repo),
) -> ConfirmReceiptUseCase:
    return ConfirmReceiptUseCase(repo)


def get_cancel_receipt_use_case(
    repo: ReceiptRepository = Depends(get_receipt_repo),
) -> CancelReceiptUseCase:
    return CancelReceiptUseCase(repo)


# ---- Sticker ----

from app.infrastructure.repositories.sticker_repository_impl import StickerRepositoryImpl
from app.application.use_case.sticker.create_sticker_usecase import CreateStickerUseCase
from app.application.use_case.sticker.update_sticker_usecase import UpdateStickerUseCase
from app.application.use_case.sticker.get_system_sticker_usecase import GetSystemStickerUseCase
from app.application.use_case.sticker.get_sticker_catalog_usecase import GetStickerCatalogUseCase
from app.application.use_case.sticker.get_admin_sticker_usecase import GetAdminStickerUseCase
from app.application.use_case.sticker.get_admin_stickers_usecase import GetAdminStickersUseCase
from app.application.use_case.sticker.delete_sticker_usecase import DeleteStickerUseCase
from app.application.use_case.sticker.generate_ai_sticker_usecase import GenerateAiStickerUseCase
from app.application.use_case.sticker.transcribe_ai_sticker_voice_usecase import TranscribeAiStickerVoiceUseCase
from app.domain.repositories.sticker_repository import StickerRepository


def get_sticker_repo(db: Session = Depends(get_db)) -> StickerRepository:
    return StickerRepositoryImpl(db)


def get_create_sticker_use_case(
    repo: StickerRepository = Depends(get_sticker_repo),
) -> CreateStickerUseCase:
    return CreateStickerUseCase(repo)


def get_update_sticker_use_case(
    repo: StickerRepository = Depends(get_sticker_repo),
) -> UpdateStickerUseCase:
    return UpdateStickerUseCase(repo)


def get_system_sticker_use_case(
    repo: StickerRepository = Depends(get_sticker_repo),
) -> GetSystemStickerUseCase:
    return GetSystemStickerUseCase(repo)


def get_sticker_catalog_use_case(
    repo: StickerRepository = Depends(get_sticker_repo),
) -> GetStickerCatalogUseCase:
    return GetStickerCatalogUseCase(repo)


def get_admin_sticker_use_case(
    repo: StickerRepository = Depends(get_sticker_repo),
) -> GetAdminStickerUseCase:
    return GetAdminStickerUseCase(repo)


def get_admin_stickers_use_case(
    repo: StickerRepository = Depends(get_sticker_repo),
) -> GetAdminStickersUseCase:
    return GetAdminStickersUseCase(repo)


def get_delete_sticker_use_case(
    repo: StickerRepository = Depends(get_sticker_repo),
) -> DeleteStickerUseCase:
    return DeleteStickerUseCase(repo)


def get_generate_ai_sticker_use_case(
    repo: StickerRepository = Depends(get_sticker_repo),
) -> GenerateAiStickerUseCase:
    return GenerateAiStickerUseCase(repo)


def get_transcribe_ai_sticker_voice_use_case() -> TranscribeAiStickerVoiceUseCase:
    return TranscribeAiStickerVoiceUseCase()


# ---- Warehouse ----

from app.application.use_case.warehouse.create_warehouse_usecase import CreateWarehouseUseCase
from app.application.use_case.warehouse.update_warehouse_usecase import UpdateWarehouseUseCase
from app.application.use_case.warehouse.get_warehouse_usecase import GetWarehouseUseCase
from app.application.use_case.warehouse.get_warehouses_usecase import GetWarehousesUseCase
from app.application.use_case.warehouse.get_warehouse_detail_usecase import GetWarehouseDetailUseCase
from app.application.use_case.warehouse.delete_warehouse_usecase import DeleteWarehouseUseCase


def get_create_warehouse_use_case(
    repo: WarehouseRepository = Depends(get_warehouse_repo),
) -> CreateWarehouseUseCase:
    return CreateWarehouseUseCase(repo)


def get_update_warehouse_use_case(
    repo: WarehouseRepository = Depends(get_warehouse_repo),
) -> UpdateWarehouseUseCase:
    return UpdateWarehouseUseCase(repo)


def get_warehouse_use_case(
    repo: WarehouseRepository = Depends(get_warehouse_repo),
) -> GetWarehouseUseCase:
    return GetWarehouseUseCase(repo)


def get_warehouses_use_case(
    repo: WarehouseRepository = Depends(get_warehouse_repo),
) -> GetWarehousesUseCase:
    return GetWarehousesUseCase(repo)


def get_warehouse_detail_use_case(
    repo: WarehouseRepository = Depends(get_warehouse_repo),
) -> GetWarehouseDetailUseCase:
    return GetWarehouseDetailUseCase(repo)


def get_delete_warehouse_use_case(
    repo: WarehouseRepository = Depends(get_warehouse_repo),
) -> DeleteWarehouseUseCase:
    return DeleteWarehouseUseCase(repo)


# ---- Chat ----

from app.infrastructure.repositories.conversation_repository_impl import ConversationRepositoryImpl
from app.infrastructure.repositories.message_repository_impl import MessageRepositoryImpl
from app.application.use_case.chat.create_conversation_usecase import CreateConversationUseCase
from app.application.use_case.chat.list_conversations_usecase import ListConversationsUseCase
from app.application.use_case.chat.list_messages_usecase import ListMessagesUseCase
from app.application.use_case.chat.mark_read_usecase import MarkReadUseCase
from app.application.use_case.chat.recall_message_usecase import RecallMessageUseCase
from app.application.use_case.chat.claim_handoff_usecase import ClaimHandoffUseCase
from app.application.use_case.chat.resume_chatbot_usecase import ResumeChatbotUseCase
from app.domain.repositories.conversation_repository import ConversationRepository
from app.domain.repositories.message_repository import MessageRepository


def get_conversation_repo(db: Session = Depends(get_db)) -> ConversationRepository:
    return ConversationRepositoryImpl(db)


def get_message_repo(db: Session = Depends(get_db)) -> MessageRepository:
    return MessageRepositoryImpl(db)


def get_create_conversation_use_case(
    conv_repo: ConversationRepository = Depends(get_conversation_repo),
    user_repo: UserRepository = Depends(get_user_repo),
) -> CreateConversationUseCase:
    return CreateConversationUseCase(conv_repo, user_repo)


def get_list_conversations_use_case(
    conv_repo: ConversationRepository = Depends(get_conversation_repo),
    msg_repo: MessageRepository = Depends(get_message_repo),
) -> ListConversationsUseCase:
    return ListConversationsUseCase(conv_repo, msg_repo)


def get_list_messages_use_case(
    conv_repo: ConversationRepository = Depends(get_conversation_repo),
    msg_repo: MessageRepository = Depends(get_message_repo),
) -> ListMessagesUseCase:
    return ListMessagesUseCase(conv_repo, msg_repo)


def get_mark_read_use_case(
    conv_repo: ConversationRepository = Depends(get_conversation_repo),
    msg_repo: MessageRepository = Depends(get_message_repo),
) -> MarkReadUseCase:
    return MarkReadUseCase(conv_repo, msg_repo)


def get_recall_message_use_case(
    conv_repo: ConversationRepository = Depends(get_conversation_repo),
    msg_repo: MessageRepository = Depends(get_message_repo),
) -> RecallMessageUseCase:
    return RecallMessageUseCase(conv_repo, msg_repo)


def get_claim_handoff_use_case(
    conv_repo: ConversationRepository = Depends(get_conversation_repo),
    msg_repo: MessageRepository = Depends(get_message_repo),
) -> ClaimHandoffUseCase:
    return ClaimHandoffUseCase(conv_repo, msg_repo)


def get_resume_chatbot_use_case(
    conv_repo: ConversationRepository = Depends(get_conversation_repo),
    msg_repo: MessageRepository = Depends(get_message_repo),
) -> ResumeChatbotUseCase:
    return ResumeChatbotUseCase(conv_repo, msg_repo)


# ---- Design ----

from app.infrastructure.repositories.design_repository_impl import DesignRepositoryImpl
from app.application.use_case.design.create_design_usecase import CreateDesignUseCase
from app.application.use_case.design.get_designs_usecase import GetDesignsUseCase
from app.application.use_case.design.get_design_detail_usecase import GetDesignDetailUseCase
from app.application.use_case.design.update_design_usecase import UpdateDesignUseCase
from app.application.use_case.design.order_design_usecase import OrderDesignUseCase
from app.application.use_case.design.create_share_link_usecase import CreateShareLinkUseCase
from app.domain.repositories.design_repository import DesignRepository


def get_design_repo(db: Session = Depends(get_db)) -> DesignRepository:
    return DesignRepositoryImpl(db)


def get_create_design_use_case(
    repo: DesignRepository = Depends(get_design_repo),
) -> CreateDesignUseCase:
    return CreateDesignUseCase(repo)


def get_designs_use_case(
    repo: DesignRepository = Depends(get_design_repo),
) -> GetDesignsUseCase:
    return GetDesignsUseCase(repo)


def get_design_detail_use_case(
    repo: DesignRepository = Depends(get_design_repo),
) -> GetDesignDetailUseCase:
    return GetDesignDetailUseCase(repo)


def get_update_design_use_case(
    repo: DesignRepository = Depends(get_design_repo),
) -> UpdateDesignUseCase:
    return UpdateDesignUseCase(repo)


def get_order_design_use_case(
    design_repo: DesignRepository = Depends(get_design_repo),
    cart_repo: CartRepository = Depends(get_cart_repo),
    warehouse_repo: WarehouseRepository = Depends(get_warehouse_repo),
) -> OrderDesignUseCase:
    return OrderDesignUseCase(design_repo, cart_repo, warehouse_repo)


def get_create_share_link_use_case(
    repo: DesignRepository = Depends(get_design_repo),
) -> CreateShareLinkUseCase:
    return CreateShareLinkUseCase(repo)


# ---- Order ----

from app.infrastructure.repositories.order_repository_impl import OrderRepositoryImpl
from app.application.use_case.order.create_order_usecase import CreateOrderUseCase
from app.application.use_case.order.get_user_orders_usecase import GetUserOrdersUseCase
from app.application.use_case.order.get_admin_orders_usecase import GetAdminOrdersUseCase
from app.application.use_case.order.get_user_order_by_id_usecase import GetUserOrderByIdUseCase
from app.application.use_case.order.get_admin_order_by_id_usecase import GetAdminOrderByIdUseCase
from app.application.use_case.order.update_order_status_usecase import UpdateOrderStatusUseCase
from app.application.use_case.order.cancel_order_usecase import CancelOrderUseCase
from app.application.use_case.order.approve_order_usecase import ApproveOrderUseCase
from app.application.use_case.order.reject_order_usecase import RejectOrderUseCase
from app.application.use_case.order.confirm_delivery_usecase import ConfirmDeliveryUseCase
from app.application.use_case.order.get_order_production_usecase import GetOrderProductionUseCase
from app.application.use_case.order.export_order_production_usecase import ExportOrderProductionUseCase
from app.domain.repositories.order_repository import OrderRepository


def get_order_repo(db: Session = Depends(get_db)) -> OrderRepository:
    return OrderRepositoryImpl(db)


def get_create_order_use_case(
    repo: OrderRepository = Depends(get_order_repo),
) -> CreateOrderUseCase:
    return CreateOrderUseCase(repo)


def get_user_orders_use_case(
    repo: OrderRepository = Depends(get_order_repo),
) -> GetUserOrdersUseCase:
    return GetUserOrdersUseCase(repo)


def get_admin_orders_use_case(
    repo: OrderRepository = Depends(get_order_repo),
) -> GetAdminOrdersUseCase:
    return GetAdminOrdersUseCase(repo)


def get_user_order_by_id_use_case(
    repo: OrderRepository = Depends(get_order_repo),
) -> GetUserOrderByIdUseCase:
    return GetUserOrderByIdUseCase(repo)


def get_admin_order_by_id_use_case(
    repo: OrderRepository = Depends(get_order_repo),
) -> GetAdminOrderByIdUseCase:
    return GetAdminOrderByIdUseCase(repo)


def get_update_order_status_use_case(
    repo: OrderRepository = Depends(get_order_repo),
) -> UpdateOrderStatusUseCase:
    return UpdateOrderStatusUseCase(repo)


def get_cancel_order_use_case(
    repo: OrderRepository = Depends(get_order_repo),
) -> CancelOrderUseCase:
    return CancelOrderUseCase(repo)


def get_approve_order_use_case(
    repo: OrderRepository = Depends(get_order_repo),
) -> ApproveOrderUseCase:
    return ApproveOrderUseCase(repo)


def get_reject_order_use_case(
    repo: OrderRepository = Depends(get_order_repo),
) -> RejectOrderUseCase:
    return RejectOrderUseCase(repo)


def get_confirm_delivery_use_case(
    repo: OrderRepository = Depends(get_order_repo),
) -> ConfirmDeliveryUseCase:
    return ConfirmDeliveryUseCase(repo)


def get_order_production_use_case(
    repo: OrderRepository = Depends(get_order_repo),
) -> GetOrderProductionUseCase:
    return GetOrderProductionUseCase(repo)


def get_export_order_production_use_case(
    repo: OrderRepository = Depends(get_order_repo),
) -> ExportOrderProductionUseCase:
    return ExportOrderProductionUseCase(repo)


# ---- GHN Shipment ----

from app.infrastructure.repositories.ghn_shipment_repository_impl import GhnShipmentRepositoryImpl
from app.domain.repositories.ghn_shipment_repository import GhnShipmentRepository


def get_ghn_shipment_repo(db: Session = Depends(get_db)) -> GhnShipmentRepository:
    return GhnShipmentRepositoryImpl(db)


# ---- VNPay Transaction ----

from app.infrastructure.repositories.vnpay_transaction_repository_impl import VnPayTransactionRepositoryImpl
from app.domain.repositories.vnpay_transaction_repository import VnPayTransactionRepository


def get_vnpay_txn_repo(db: Session = Depends(get_db)) -> VnPayTransactionRepository:
    return VnPayTransactionRepositoryImpl(db)


# ---- GHN Service ----

from app.infrastructure.external.ghn.service import GhnService


def get_ghn_service(
    order_repo: OrderRepository = Depends(get_order_repo),
    ghn_shipment_repo: GhnShipmentRepository = Depends(get_ghn_shipment_repo),
) -> GhnService:
    return GhnService(order_repo, ghn_shipment_repo)


# ---- VNPay Service ----

from app.infrastructure.external.vnpay.service import VnpayService


def get_vnpay_service(
    order_repo: OrderRepository = Depends(get_order_repo),
    vnpay_txn_repo: VnPayTransactionRepository = Depends(get_vnpay_txn_repo),
) -> VnpayService:
    return VnpayService(order_repo, vnpay_txn_repo)


# ---- Dashboard ----

from app.application.use_case.dashboard.get_dashboard_summary_usecase import GetDashboardSummaryUseCase
from app.application.use_case.dashboard.get_dashboard_activity_usecase import GetDashboardActivityUseCase


def get_dashboard_summary_use_case(
    order_repo: OrderRepository = Depends(get_order_repo),
    user_repo: UserRepository = Depends(get_user_repo),
    product_repo: ProductRepository = Depends(get_product_repo),
) -> GetDashboardSummaryUseCase:
    return GetDashboardSummaryUseCase(order_repo, user_repo, product_repo)


def get_dashboard_activity_use_case(
    db: Session = Depends(get_db),
) -> GetDashboardActivityUseCase:
    return GetDashboardActivityUseCase(db)


# ---- Statistics ----

from app.domain.repositories.statistics_repository import StatisticsRepository
from app.infrastructure.repositories.statistics_repository_impl import StatisticsRepositoryImpl
from app.application.use_case.statistics.get_statistics_overview_usecase import GetStatisticsOverviewUseCase
from app.application.use_case.statistics.get_statistics_revenue_series_usecase import GetStatisticsRevenueSeriesUseCase
from app.application.use_case.statistics.get_statistics_order_mix_usecase import GetStatisticsOrderMixUseCase
from app.application.use_case.statistics.get_statistics_top_products_usecase import GetStatisticsTopProductsUseCase
from app.application.use_case.statistics.get_statistics_payment_mix_usecase import GetStatisticsPaymentMixUseCase
from app.application.use_case.statistics.get_statistics_reviews_summary_usecase import GetStatisticsReviewsSummaryUseCase
from app.application.use_case.statistics.get_statistics_alerts_usecase import GetStatisticsAlertsUseCase
from app.application.use_case.statistics.export_statistics_pdf_usecase import ExportStatisticsPdfUseCase


def get_statistics_repo(db: Session = Depends(get_db)) -> StatisticsRepository:
    return StatisticsRepositoryImpl(db)


def get_statistics_overview_use_case(
    repo: StatisticsRepository = Depends(get_statistics_repo),
) -> GetStatisticsOverviewUseCase:
    return GetStatisticsOverviewUseCase(repo)


def get_statistics_revenue_series_use_case(
    repo: StatisticsRepository = Depends(get_statistics_repo),
) -> GetStatisticsRevenueSeriesUseCase:
    return GetStatisticsRevenueSeriesUseCase(repo)


def get_statistics_order_mix_use_case(
    repo: StatisticsRepository = Depends(get_statistics_repo),
) -> GetStatisticsOrderMixUseCase:
    return GetStatisticsOrderMixUseCase(repo)


def get_statistics_top_products_use_case(
    repo: StatisticsRepository = Depends(get_statistics_repo),
) -> GetStatisticsTopProductsUseCase:
    return GetStatisticsTopProductsUseCase(repo)


def get_statistics_payment_mix_use_case(
    repo: StatisticsRepository = Depends(get_statistics_repo),
) -> GetStatisticsPaymentMixUseCase:
    return GetStatisticsPaymentMixUseCase(repo)


def get_statistics_reviews_summary_use_case(
    repo: StatisticsRepository = Depends(get_statistics_repo),
) -> GetStatisticsReviewsSummaryUseCase:
    return GetStatisticsReviewsSummaryUseCase(repo)


def get_statistics_alerts_use_case(
    repo: StatisticsRepository = Depends(get_statistics_repo),
) -> GetStatisticsAlertsUseCase:
    return GetStatisticsAlertsUseCase(repo)


def export_statistics_pdf_use_case(
    repo: StatisticsRepository = Depends(get_statistics_repo),
) -> ExportStatisticsPdfUseCase:
    return ExportStatisticsPdfUseCase(repo)
