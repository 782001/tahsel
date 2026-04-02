import '../../domain/entities/get_categories_entity.dart';

class GetCategoriesCategoryItemModel extends GetCategoriesCategoryItemEntity {
  GetCategoriesCategoryItemModel({
    super.id,
    super.name,
    super.slug,
    super.images,
    super.price,
    super.discountPrice,
    super.stock,
    super.shortDescription,
    super.description,
    super.featured,
    super.discountTag,
    super.reviewsCount,
    super.avgRating,
    super.isActive,
    super.isDeleted,
    super.createdAt,
    super.updatedAt,
  });

  factory GetCategoriesCategoryItemModel.fromJson(Map<String, dynamic> json) {
    return GetCategoriesCategoryItemModel(
      id: json['id'] as String?,
      name: json['name'] as String?,
      slug: json['slug'] as String?,
      images:
          (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
      price: (json['price'] as num?)?.toDouble(),
      discountPrice: (json['discountPrice'] as num?)?.toDouble(),
      stock: json['stock'] as int?,
      shortDescription: json['shortDescription'] as String?,
      description: json['description'] as String?,
      featured: json['featured'] as bool?,
      discountTag: json['discountTag'] as String?,
      reviewsCount: json['reviewsCount'] as int?,
      avgRating: json['avgRating'] as int?,
      isActive: json['isActive'] as bool?,
      isDeleted: json['isDeleted'] as bool?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'images': images,
      'price': price,
      'discountPrice': discountPrice,
      'stock': stock,
      'shortDescription': shortDescription,
      'description': description,
      'featured': featured,
      'discountTag': discountTag,
      'reviewsCount': reviewsCount,
      'avgRating': avgRating,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class GetCategoriesDataModel extends GetCategoriesDataEntity {
  GetCategoriesDataModel({super.category});

  factory GetCategoriesDataModel.fromJson(Map<String, dynamic> json) {
    return GetCategoriesDataModel(
      category:
          (json['category'] as List<dynamic>?)
              ?.map(
                (e) => GetCategoriesCategoryItemModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category':
          category
              ?.map((e) => (e as GetCategoriesCategoryItemModel).toJson())
              .toList(),
    };
  }
}

class GetCategoriesResponseModel extends GetCategoriesResponseEntity {
  GetCategoriesResponseModel({super.success, super.message, super.data});

  factory GetCategoriesResponseModel.fromJson(Map<String, dynamic> json) {
    return GetCategoriesResponseModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data:
          json['data'] != null
              ? GetCategoriesDataModel.fromJson(
                json['data'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': (data as GetCategoriesDataModel?)?.toJson(),
    };
  }
}

