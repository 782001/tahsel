import '../../domain/entities/get_category_by_id_entity.dart';

class GetCategoryByIdCategoryItemModel
    extends GetCategoryByIdCategoryItemEntity {
  GetCategoryByIdCategoryItemModel({
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

  factory GetCategoryByIdCategoryItemModel.fromJson(Map<String, dynamic> json) {
    return GetCategoryByIdCategoryItemModel(
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

class GetCategoryByIdDataModel extends GetCategoryByIdDataEntity {
  GetCategoryByIdDataModel({super.category});

  factory GetCategoryByIdDataModel.fromJson(Map<String, dynamic> json) {
    return GetCategoryByIdDataModel(
      category:
          (json['category'] as List<dynamic>?)
              ?.map(
                (e) => GetCategoryByIdCategoryItemModel.fromJson(
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
              ?.map((e) => (e as GetCategoryByIdCategoryItemModel).toJson())
              .toList(),
    };
  }
}

class GetCategoryByIdResponseModel extends GetCategoryByIdResponseEntity {
  GetCategoryByIdResponseModel({super.success, super.message, super.data});

  factory GetCategoryByIdResponseModel.fromJson(Map<String, dynamic> json) {
    return GetCategoryByIdResponseModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data:
          json['data'] != null
              ? GetCategoryByIdDataModel.fromJson(
                json['data'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': (data as GetCategoryByIdDataModel?)?.toJson(),
    };
  }
}

