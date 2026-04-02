class GetCategoriesCategoryItemEntity {
  final String? id;
  final String? name;
  final String? slug;
  final List<String>? images;
  final double? price;
  final double? discountPrice;
  final int? stock;
  final String? shortDescription;
  final String? description;
  final bool? featured;
  final String? discountTag;
  final int? reviewsCount;
  final int? avgRating;
  final bool? isActive;
  final bool? isDeleted;
  final String? createdAt;
  final String? updatedAt;

  GetCategoriesCategoryItemEntity({
    this.id,
    this.name,
    this.slug,
    this.images,
    this.price,
    this.discountPrice,
    this.stock,
    this.shortDescription,
    this.description,
    this.featured,
    this.discountTag,
    this.reviewsCount,
    this.avgRating,
    this.isActive,
    this.isDeleted,
    this.createdAt,
    this.updatedAt,
  });
}

class GetCategoriesDataEntity {
  final List<GetCategoriesCategoryItemEntity>? category;

  GetCategoriesDataEntity({this.category});
}

class GetCategoriesResponseEntity {
  final bool? success;
  final String? message;
  final GetCategoriesDataEntity? data;

  GetCategoriesResponseEntity({this.success, this.message, this.data});
}

