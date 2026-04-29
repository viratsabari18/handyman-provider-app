import 'package:flutter/material.dart';
import 'package:handyman_provider_flutter/Models%20new/registration_data.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/components/back_widget.dart';
import 'package:handyman_provider_flutter/components/cached_image_widget.dart';
import 'package:handyman_provider_flutter/components/empty_error_state_widget.dart';

import 'package:handyman_provider_flutter/main.dart';

import 'package:handyman_provider_flutter/utils/constant.dart';

import 'package:nb_utils/nb_utils.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../controllers/registration_data_controller.dart';


class CategoryList extends StatefulWidget {
  const CategoryList({super.key});

  @override
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  List<Category> categories = [];
  bool isLoading = true;
  bool isError = false;
  String errorMessage = '';
  bool changeListType = false; // false = grid view, true = list view

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    setState(() {
      isLoading = true;
      isError = false;
      errorMessage = '';
    });

    try {
      final response = await RegistrationDataController.getRegistrationFields();
      
      if (response != null && response.categories != null) {
        setState(() {
          categories = response.categories!;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
          errorMessage = 'No categories found';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isError = true;
        errorMessage = e.toString();
      });
      toast(errorMessage, print: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(
        'Category List',
        textColor: white,
        color: context.primaryColor,
        backWidget:  BackWidget(),
        textSize: APP_BAR_TEXT_SIZE,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                changeListType = !changeListType;
              });
            },
            icon: Icon(
              changeListType ? Icons.grid_view : Icons.list,
              size: 24,
              color: white,
            ),
          ),
          IconButton(
            onPressed: () {
              // Handle edit action
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => CategoryEditBottomSheet(
                  onRefresh: () {
                    fetchCategories();
                    Navigator.pop(context);
                  },
                ),
              );
            },
            icon: const Icon(Icons.edit, size: 24, color: white),
            tooltip: 'Edit Categories',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (isError)
            NoDataWidget(
              title: errorMessage,
              imageWidget: const ErrorStateWidget(),
              retryText: 'Reload',
              onRetry: () {
                fetchCategories();
              },
            )
          else if (categories.isEmpty)
            const NoDataWidget(
              title: 'No Categories Found',
              imageWidget: EmptyStateWidget(),
            )
          else
            AnimatedScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              onSwipeRefresh: () async {
                await fetchCategories();
                return;
              },
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: changeListType ? _buildListView() : _buildGridView(),
                ),
              ],
            ),
          Observer(
            builder: (context) => LoaderWidget().visible(appStore.isLoading),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryListItem(category);
      },
    );
  }

  Widget _buildCategoryCard(Category category) {
    return Container(
      decoration: boxDecorationWithRoundedCorners(
        borderRadius: radius(12),
        backgroundColor: appStore.isDarkMode ? cardDarkColor : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Handle category tap
          toast('Selected: ${category.name.validate()}');
        },
        borderRadius: radius(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.primaryColor.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: CachedImageWidget(
                  url: category.imageUrl.validate(),
                  fit: BoxFit.cover,
                  height: 100,
                  width: 100,
                
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              category.name.validate(),
              style: boldTextStyle(size: 14),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ).paddingSymmetric(horizontal: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryListItem(Category category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: boxDecorationWithRoundedCorners(
        borderRadius: radius(12),
        backgroundColor: appStore.isDarkMode ? cardDarkColor : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          toast('Selected: ${category.name.validate()}');
        },
        borderRadius: radius(12),
        child: Row(
          children: [
            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                border: Border.all(
                  color: context.primaryColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: CachedImageWidget(
                  url: category.imageUrl.validate(),
                  fit: BoxFit.cover,
                  height: 70,
                  width: 70,
                  
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name.validate(),
                    style: boldTextStyle(size: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${category.id.validate()}',
                    style: secondaryTextStyle(size: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                _showEditCategoryDialog(category);
              },
              icon: Icon(
                Icons.edit_outlined,
                size: 20,
                color: context.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${category.name.validate()}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: category.name.validate(),
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: category.imageUrl.validate(),
              decoration: const InputDecoration(
                labelText: 'Image URL',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle update
              Navigator.pop(context);
              toast('Update functionality to be implemented');
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

class CategoryEditBottomSheet extends StatefulWidget {
  final VoidCallback onRefresh;

  const CategoryEditBottomSheet({super.key, required this.onRefresh});

  @override
  State<CategoryEditBottomSheet> createState() => _CategoryEditBottomSheetState();
}

class _CategoryEditBottomSheetState extends State<CategoryEditBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Category Management',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Add New Category'),
            onTap: () {
              Navigator.pop(context);
              toast('Add category functionality to be implemented');
            },
          ),
          ListTile(
            leading: const Icon(Icons.reorder),
            title: const Text('Reorder Categories'),
            onTap: () {
              Navigator.pop(context);
              toast('Reorder functionality to be implemented');
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Refresh List'),
            onTap: () {
              widget.onRefresh();
            },
          ),
        ],
      ),
    );
  }
}