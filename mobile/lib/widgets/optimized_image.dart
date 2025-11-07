import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/image_utils.dart';

/// Оптимизированный виджет для загрузки изображений
/// Использует кэширование для экономии трафика и памяти
/// Поддерживает как HTTP URL, так и base64 изображения
class OptimizedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return errorWidget ?? _buildDefaultError();
    }

    // Проверяем, является ли это base64 изображением
    if (ImageUtils.isBase64Image(imageUrl)) {
      final imageProvider = ImageUtils.getImageProvider(imageUrl);
      if (imageProvider != null) {
        return Image(
          image: imageProvider,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ?? _buildDefaultError();
          },
        );
      }
      return errorWidget ?? _buildDefaultError();
    }

    // Используем CachedNetworkImage для HTTP URL
    if (ImageUtils.isValidUrl(imageUrl)) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        // Лимит памяти для кэша (100 MB)
        maxWidthDiskCache: 1000,
        maxHeightDiskCache: 1000,
        // Placeholder пока грузится
        placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
        // Ошибка загрузки
        errorWidget: (context, url, error) => errorWidget ?? _buildDefaultError(),
        // Fade анимация при загрузке
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 100),
      );
    }

    // Если это не валидный URL и не base64, показываем ошибку
    return errorWidget ?? _buildDefaultError();
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildDefaultError() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Icon(Icons.error_outline, color: Colors.grey),
    );
  }
}

