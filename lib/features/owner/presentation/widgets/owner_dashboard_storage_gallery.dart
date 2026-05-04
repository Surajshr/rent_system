import 'package:flutter/material.dart';
import 'package:rent_system/core/constants/app_colors.dart';
import 'package:rent_system/core/constants/app_layout.dart';
import 'package:rent_system/core/constants/app_spacing.dart';
import 'package:rent_system/core/supabase/rentflow_supabase_service.dart';

/// Horizontal gallery of Storage images on the owner dashboard.
class OwnerDashboardStorageGallery extends StatelessWidget {
  const OwnerDashboardStorageGallery({
    required this.title,
    required this.images,
    super.key,
  });

  final String title;
  final List<StorageImageRef> images;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final img = images[index];
              return SizedBox(
                width: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    AppLayout.radiusCard,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.neutral200,
                      ),
                      color: AppColors.neutral100,
                    ),
                    child: Image.network(
                      img.url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 120,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }
                        final p = loadingProgress;
                        final total = p.expectedTotalBytes;
                        return Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: total != null
                                  ? p.cumulativeBytesLoaded / total
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.neutral400,
                            ),
                          ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
