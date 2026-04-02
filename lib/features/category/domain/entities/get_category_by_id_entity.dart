class GetCategoryByIdCategoryItemEntity {
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

  GetCategoryByIdCategoryItemEntity({
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

class GetCategoryByIdDataEntity {
  final List<GetCategoryByIdCategoryItemEntity>? category;

  GetCategoryByIdDataEntity({this.category});
}

class GetCategoryByIdResponseEntity {
  final bool? success;
  final String? message;
  final GetCategoryByIdDataEntity? data;

  GetCategoryByIdResponseEntity({this.success, this.message, this.data});
}

