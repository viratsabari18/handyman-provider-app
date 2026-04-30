import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:handyman_provider_flutter/Models%20new/add_provider_category_requset_and_response.dart';
import 'package:handyman_provider_flutter/Models%20new/delete_provider_category_request_response.dart';
import 'package:handyman_provider_flutter/Models%20new/registration_data.dart';
import 'package:handyman_provider_flutter/components/app_widgets.dart';
import 'package:handyman_provider_flutter/components/back_widget.dart';
import 'package:handyman_provider_flutter/components/cached_image_widget.dart';
import 'package:handyman_provider_flutter/components/empty_error_state_widget.dart';
import 'package:handyman_provider_flutter/controllers/registration_data_controller.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/utils/constant.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../Models new/provider_categories.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import '../../utils/colors.dart';
import '../../utils/configs.dart';


class CategoryList extends StatefulWidget {
  const CategoryList({super.key});

  @override
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  List<CategoryData> categories = [];

  bool isError = false;
  String errorMessage = '';
  bool changeListType = false;

  bool showCategoryDropdown = false;
  List<Category> availableCategories = [];
  List<int> selectedCategoryIds = [];
  bool isLoadingCategories = false;
  String? dropdownError;

  int page = 1;
  bool isLastPage = false;
  Future<List<CategoryData>>? future;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await fetchCategories();
    await fetchAvailableCategories();
  }

  Future<void> fetchCategories() async {
    setState(() {
 
      isError = false;
      errorMessage = '';
    });
        appStore.setLoading(true);

    try {
      final response = await getProviderCategoryList();

      if (response != null && response.data != null) {
        setState(() {
          categories = response.data!;
           appStore.setLoading(false);
        });
      } else {
        setState(() {
             appStore.setLoading(false);
          isError = true;
          errorMessage = 'No categories found';
        });
      }
    } catch (e) {
      setState(() {
           appStore.setLoading(false);
        isError = true;
        errorMessage = e.toString();
      });
      toast(errorMessage, print: true);
    }
  }

  Future<void> fetchAvailableCategories() async {
    setState(() {
      isLoadingCategories = true;
      dropdownError = null;
    });

    try {
      final response = await RegistrationDataController.getRegistrationFields();

      setState(() {
        if (response.categories != null && response.categories!.isNotEmpty) {
          final existingCategoryIds = categories.map((c) => c.id).toSet();
          availableCategories = response.categories!
              .where((cat) => !existingCategoryIds.contains(cat.id))
              .toList();
        } else {
          availableCategories = [];
          dropdownError = 'No categories available';
        }
        isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        availableCategories = [];
        isLoadingCategories = false;
        dropdownError = 'Failed to load categories: $e';
      });
      toast(dropdownError!);
    }
  }

  Future<void> addProviderCategories() async {
    if (selectedCategoryIds.isEmpty) {
      toast('Please select at least one category');
      return;
    }

    appStore.setLoading(true);

    try {
      final request = AddProviderCategoryRequest(
        categoryId: selectedCategoryIds,
      );

      final response = await addProviderCategoryList(request);

      if (response.message != null) {
        toast(response.message ?? 'Categories added successfully');

        setState(() {
          showCategoryDropdown = false;
          selectedCategoryIds.clear();
        });

        await fetchCategories();
        await fetchAvailableCategories();
      } else {
        toast(response.message ?? 'Failed to add categories');
      }
    } catch (e) {
      toast('Error: ${e.toString()}');
    } finally {
      appStore.setLoading(false);
    }
  }

  Future<void> deleteProviderCategories(int id) async {
    appStore.setLoading(true);

    try {
      final request = deleteProviderCategoryRequest(
        categoryId: id,
      );

      final response = await deleteProviderCategoryList(request);

      if (response.message != null) {
        toast(response.message ?? 'Category deleted successfully');
        await fetchCategories();
        await fetchAvailableCategories();
      } else {
        toast(response.message ?? 'Failed to delete category');
      }
    } catch (e) {
      toast('Error: ${e.toString()}');
    } finally {
      appStore.setLoading(false);
    }
  }

  void setPageToOne() {
    page = 1;
    appStore.setLoading(true);
    fetchCategories();
    setState(() {});
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: appBarWidget(
        'Category List',
        elevation: 0,
        systemUiOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.light,
        ),
        color: !isDark ? Colors.white : Colors.black,
        textColor: isDark ? Colors.white : Colors.black,
        backWidget: BackWidget(color:isDark ? Colors.white : Colors.black ,),
        textSize: APP_BAR_TEXT_SIZE,
        actions: [
          IconButton(
            onPressed: () {
              changeListType = !changeListType;
              setState(() {});
            },
            icon: Image.asset(
              changeListType
                  ? 'assets/images/list.png'
                  : 'assets/images/grid.png',
              height: 20,
              width: 20,
              errorBuilder: (context, error, stackTrace) => Icon(
                changeListType ? Icons.list : Icons.grid_view,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                showCategoryDropdown = !showCategoryDropdown;
                if (showCategoryDropdown) {
                  fetchAvailableCategories();
                }
              });
            },
            icon: Icon(Icons.add, size: 28, color: isDark ? Colors.white : Colors.black),
            tooltip: 'Add Categories',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (isError)
            NoDataWidget(
              title: errorMessage,
              imageWidget: const ErrorStateWidget(),
              retryText: 'Reload',
              onRetry: () {
                fetchCategories();
              },
            )
          else if (categories.isEmpty && !appStore.isLoading)
            const NoDataWidget(
              title: 'No Categories Found',
              imageWidget: EmptyStateWidget(),
            )
          else
            Column(
              children: [
                if (showCategoryDropdown) _buildAddCategoryDropdown(),
                Expanded(
                  child: AnimatedScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    listAnimationType: ListAnimationType.FadeIn,
                    fadeInConfiguration:
                        FadeInConfiguration(duration: 2.seconds),
                    onSwipeRefresh: () async {
                      page = 1;
                      await fetchCategories();
                      await fetchAvailableCategories();
                      return await 2.seconds.delay;
                    },
                    children: [
                      if (categories.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: changeListType
                              ? _buildListView()
                              : _buildGridView(),
                        ),
                    ],
                  ),
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

  Widget _buildAddCategoryDropdown() {
    return Container(
      margin: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add New Categories',
                  style: boldTextStyle(size: 16),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      showCategoryDropdown = false;
                      selectedCategoryIds.clear();
                      dropdownError = null;
                    });
                  },
                  icon: Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (isLoadingCategories)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (dropdownError != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dropdownError!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (availableCategories.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No categories available to add',
                  style: secondaryTextStyle(size: 14),
                ),
              ),
            )
          else
            Container(
              constraints: BoxConstraints(
                maxHeight: context.height() * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableCategories.length,
                itemBuilder: (context, index) {
                  final category = availableCategories[index];
                  final isSelected = selectedCategoryIds.contains(category.id);

                  return CheckboxListTile(
                    checkboxShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    activeColor: context.primaryColor,
                    title: Text(
                      category.name.validate(),
                      style: primaryTextStyle(size: 14),
                    ),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedCategoryIds.add(category.id!);
                        } else {
                          selectedCategoryIds.remove(category.id!);
                        }
                      });
                    },
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  );
                },
              ),
            ),
          if (!isLoadingCategories &&
              dropdownError == null &&
              availableCategories.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: context.dividerColor),
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 8,
                children: [
                  Text(
                    'Selected: ${selectedCategoryIds.length}',
                    style: secondaryTextStyle(size: 14),
                  ),
                  Wrap(
                    spacing: 12,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedCategoryIds.clear();
                          });
                        },
                        child: Text('Clear All'),
                      ),
                      ElevatedButton(
                        onPressed: selectedCategoryIds.isEmpty
                            ? null
                            : addProviderCategories,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Add Categories'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return AnimatedWrap(
      spacing: 16.0,
      runSpacing: 16.0,
      scaleConfiguration: ScaleConfiguration(
          duration: 400.milliseconds, delay: 50.milliseconds),
      listAnimationType: ListAnimationType.FadeIn,
      fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
      alignment: WrapAlignment.start,
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildListView() {
    return AnimatedWrap(
      spacing: 16.0,
      runSpacing: 16.0,
      scaleConfiguration: ScaleConfiguration(
          duration: 400.milliseconds, delay: 50.milliseconds),
      listAnimationType: ListAnimationType.FadeIn,
      fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
      alignment: WrapAlignment.start,
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryListItem(category);
      },
    );
  }

 Widget _buildCategoryCard(CategoryData category) {
  return AnimatedContainer(
    duration: 400.milliseconds,
    decoration: boxDecorationWithRoundedCorners(
      borderRadius: radius(),
      backgroundColor: appStore.isDarkMode ? cardDarkColor : cardColor,
    ),
    width: context.width() * 0.5 - 24,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 205,
          width: context.width(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CachedImageWidget(
                url: category.categoryImage.validate(),
                fit: BoxFit.cover,
                height: 180,
                width: context.width(),
              ).cornerRadiusWithClipRRectOnly(topRight: defaultRadius.toInt(), topLeft: defaultRadius.toInt()),
              Positioned(
                top: 12,
                left: 6,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  constraints: BoxConstraints(maxWidth: context.width() * 0.3),
                  decoration: boxDecorationWithShadow(
                    backgroundColor: context.cardColor.withValues(alpha: 0.9),
                    borderRadius: radius(24),
                  ),
                  child: Marquee(
                    directionMarguee: DirectionMarguee.oneDirection,
                    child: Text(
                      category.name.validate().toUpperCase(),
                      style: boldTextStyle(color: appStore.isDarkMode ? white : primaryColor, size: 12),
                    ).paddingSymmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ),
             
              Positioned(
                top: 8,
                right: 2,
                child: InkWell(
                  onTap: () {
                    showConfirmDialogCustom(
                      context,
                      dialogType: DialogType.DELETE,
                      title: 'Do you want to delete this category?',
                      positiveText: 'Delete',
                      negativeText: 'Cancel',
                      onAccept: (v) async {
                        await deleteProviderCategories(category.id ?? 0);
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.name.validate(),
                style: boldTextStyle(size: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (category.description.validate().isNotEmpty) ...[
                4.height,
                Text(
                  category.description.validate(),
                  style: secondaryTextStyle(size: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

 Widget _buildCategoryListItem(CategoryData category) {
  return AnimatedContainer(
    duration: 400.milliseconds,
    decoration: boxDecorationWithRoundedCorners(
      borderRadius: radius(),
      backgroundColor: appStore.isDarkMode ? cardDarkColor : cardColor,
    ),
    width: context.width(),
    child: Row(
      children: [
        SizedBox(
          height: 100,
          width: 100,
          child: CachedImageWidget(
            url: category.categoryImage.validate(),
            fit: BoxFit.cover,
            height: 100,
            width: 100,
          ).cornerRadiusWithClipRRectOnly(topLeft: defaultRadius.toInt(), bottomLeft: defaultRadius.toInt()),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name.validate(),
                  style: boldTextStyle(size: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (category.description.validate().isNotEmpty) ...[
                  4.height,
                  Text(
                    category.description.validate(),
                    style: secondaryTextStyle(size: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                8.height,
              
              ],
            ),
          ),
        ),
        // Delete Icon - Right Side
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: InkWell(
            onTap: () {
              showConfirmDialogCustom(
                context,
                dialogType: DialogType.DELETE,
                title: 'Do you want to delete this category?',
                positiveText: 'Delete',
                negativeText: 'Cancel',
                onAccept: (v) async {
                  await deleteProviderCategories(category.id ?? 0);
                },
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}