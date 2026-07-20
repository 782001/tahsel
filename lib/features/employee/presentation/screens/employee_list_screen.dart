import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/employee/domain/entities/employee_entity.dart';
import 'package:tahsel/features/employee/presentation/cubit/employee_cubit.dart';
import 'package:tahsel/features/employee/presentation/cubit/employee_state.dart';
import 'package:tahsel/features/employee/presentation/widgets/add_edit_employee_dialog.dart';
// import 'package:tahsel/features/employee/presentation/widgets/check_in_out_dialog.dart';

import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/routes/app_routes.dart';
import 'package:tahsel/shared/widgets/no_internet_view.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'all';
  List<EmployeeEntity> _cachedEmployees = [];

  @override
  void initState() {
    super.initState();
    // Trigger initial fetch of employees
    context.read<EmployeeCubit>().fetchEmployees(AppStrings.userToken);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.scafoldBackGround,
      appBar: AppBar(scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppStrings.employeeList.tr(),
          style: TextStyles.customStyle(
            fontSize: isDesktop ? 20 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_rounded, color: Colors.white),
            tooltip: AppStrings.viewReports.tr(),
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.employeeReports);
              if (mounted) {
                // ignore: use_build_context_synchronously
                context.read<EmployeeCubit>().fetchEmployees(
                  AppStrings.userToken,
                  forceRefresh: true,
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        onPressed: _showAddEmployeeDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocListener<EmployeeCubit, EmployeeState>(
        listenWhen: (previous, current) =>
            current is EmployeeActionSuccess || current is EmployeeFailure,
        listener: (context, state) {
          if (state is EmployeeActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.actionMessage),
                backgroundColor: AppColors.success,
              ),
            );
            context.read<EmployeeCubit>().fetchEmployees(
              AppStrings.userToken,
              forceRefresh: true,
            );
          } else if (state is EmployeeFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: SafeArea(
          child: BlocBuilder<ConnectivityCubit, ConnectivityState>(
            builder: (context, connectivityState) {
              if (connectivityState is ConnectivityDisconnected) {
                return NoInternetView(
                  onRetry: () =>
                      context.read<ConnectivityCubit>().checkConnectivity(),
                );
              }
              return BlocBuilder<EmployeeCubit, EmployeeState>(
                buildWhen: (previous, current) =>
                    current is EmployeeLoading ||
                    current is EmployeeFetchSuccess ||
                    current is EmployeeFailure,
                builder: (context, state) {
                  final isDesktop = ResponsiveLayout.isDesktop(context);

                  if (state is EmployeeFetchSuccess) {
                    _cachedEmployees = state.employees;
                  }
                  final filteredList = _cachedEmployees.where((emp) {
                    final matchQuery =
                        emp.name.toLowerCase().contains(
                          _searchController.text.toLowerCase(),
                        ) ||
                        emp.role.toLowerCase().contains(
                          _searchController.text.toLowerCase(),
                        ) ||
                        emp.phone.contains(_searchController.text);
                    final matchStatus =
                        _selectedStatusFilter == 'all' ||
                        emp.status == _selectedStatusFilter;
                    return matchQuery && matchStatus;
                  }).toList();

                  return RefreshIndicator(
                    color: AppColors.primaryColor,
                    onRefresh: () async {
                      context.read<EmployeeCubit>().fetchEmployees(
                        AppStrings.userToken,
                        forceRefresh: true,
                      );
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeader(isDesktop)),
                        SliverToBoxAdapter(child: _buildFilters(isDesktop)),
                        if (state is EmployeeLoading &&
                            _cachedEmployees.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryColor,
                                strokeWidth: 3,
                              ),
                            ),
                          )
                        else if (state is EmployeeFailure &&
                            _cachedEmployees.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    state.message,
                                    style: TextStyles.customStyle(
                                      fontSize: 14,
                                      color: AppColors.error,
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  ElevatedButton(
                                    onPressed: () {
                                      context
                                          .read<EmployeeCubit>()
                                          .fetchEmployees(
                                            AppStrings.userToken,
                                            forceRefresh: true,
                                          );
                                    },
                                    child: Text(AppStrings.retry.tr()),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else ...[
                          if (filteredList.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people_outline_rounded,
                                      size: isDesktop ? 80 : 64,
                                      color: AppColors.blackLight.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                    SizedBox(height: 16.h),
                                    Text(
                                      AppStrings.noEmployeesFound.tr(),
                                      style: TextStyles.customStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.blackLight.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else ...[
                            SliverPadding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 24.w : 16.w,
                                vertical: isDesktop ? 16.h : 12.h,
                              ),
                              sliver: isDesktop
                                  ? SliverGrid(
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 16,
                                            mainAxisSpacing: 16,
                                            childAspectRatio: 1.8,
                                          ),
                                      delegate: SliverChildBuilderDelegate((
                                        context,
                                        idx,
                                      ) {
                                        return _buildEmployeeCard(
                                          filteredList[idx],
                                          isDesktop,
                                        );
                                      }, childCount: filteredList.length),
                                    )
                                  : SliverList(
                                      delegate: SliverChildBuilderDelegate((
                                        context,
                                        idx,
                                      ) {
                                        return _buildEmployeeCard(
                                          filteredList[idx],
                                          isDesktop,
                                        );
                                      }, childCount: filteredList.length),
                                    ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 16.w,
        vertical: isDesktop ? 16 : 12.h,
      ),
      color: AppColors.primaryColor,
      child: Container(
        height: isDesktop ? 48 : 42.h,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: TextField(
          cursorColor: AppColors.primaryColor,
          controller: _searchController,
          style: TextStyles.customStyle(fontSize: 14, color: Colors.white),
          decoration: InputDecoration(
            hintText: AppStrings.search.tr(),
            hintStyle: TextStyles.customStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              vertical: isDesktop ? 12 : 8.h,
            ),
          ),
          onChanged: (val) {
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildFilters(bool isDesktop) {
    final filters = ['all', 'active', 'inactive', 'suspended'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16 : 16.w,
        vertical: isDesktop ? 10 : 10.h,
      ),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedStatusFilter == f;
          return Padding(
            padding: EdgeInsets.only(right: isDesktop ? 8 : 8.w),
            child: InkWell(
              onTap: () {
                if (!isSelected) {
                  setState(() {
                    _selectedStatusFilter = f;
                  });
                }
              },
              borderRadius: BorderRadius.circular(isDesktop ? 24 : 24.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 16 : 16.w,
                  vertical: isDesktop ? 8 : 8.h,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryColor
                      : (AppColors.isDark ? Colors.grey[850] : Colors.white),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryColor
                        : (AppColors.isDark
                              ? Colors.grey[700]!
                              : AppColors.veryLightGrey),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Icon(
                        Icons.check_circle_rounded,
                        size: isDesktop ? 16 : 16.sp,
                        color: AppColors.isDark ? Colors.black87 : Colors.white,
                      ),
                      SizedBox(width: isDesktop ? 6 : 6.w),
                    ],
                    Text(
                      _getFilterTranslation(f),
                      style: TextStyles.customStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: isSelected
                            ? (AppColors.isDark ? Colors.black87 : Colors.white)
                            : (AppColors.isDark
                                  ? Colors.white70
                                  : AppColors.blackLight),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmployeeCard(EmployeeEntity employee, bool isDesktop) {
    Color statusColor = AppColors.success;
    if (employee.status == 'suspended') {
      statusColor = AppColors.error;
    } else if (employee.status == 'inactive') {
      statusColor = AppColors.blackLight;
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: isDesktop ? 0 : 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: AppColors.veryLightGrey),
      ),
      color: AppColors.whiteColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () async {
          await Navigator.pushNamed(
            context,
            AppRoutes.employeeDetails,
            arguments: employee,
          );
          if (mounted) {
            context.read<EmployeeCubit>().fetchEmployees(
              AppStrings.userToken,
              forceRefresh: true,
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 16 : 14.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primaryColor.withValues(
                      alpha: 0.1,
                    ),
                    radius: isDesktop ? 24 : 22.r,
                    child: Text(
                      employee.name.isNotEmpty
                          ? employee.name[0].toUpperCase()
                          : 'E',
                      style: TextStyles.customStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyles.customStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blackReal,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          employee.role,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyles.customStyle(
                            fontSize: 13,
                            color: AppColors.sandText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      employee.status.tr(),
                      style: TextStyles.customStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.blackLight.withValues(alpha: 0.6),
                  ),
                ],
              ),
              if (isDesktop) const Spacer() else SizedBox(height: 12.h),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.baseSalary.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 11,
                          color: AppColors.blackLight,
                        ),
                      ),
                      Text(
                        "${employee.salaryAmount.toSmartAmount()} / ${employee.salaryType.tr()}",
                        style: TextStyles.customStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blackReal,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // IconButton(
                      //   icon: Icon(
                      //     Icons.qr_code_scanner_rounded,
                      //     color: AppColors.primaryColor,
                      //     size: 20,
                      //   ),
                      //   tooltip: AppStrings.checkIn.tr(),
                      //   onPressed: () => _showCheckInOutDialog(employee),
                      // ),
                      // IconButton(
                      //   icon: Icon(
                      //     Icons.payment_rounded,
                      //     color: AppColors.primaryColor,
                      //     size: 20,
                      //   ),
                      //   tooltip: AppStrings.paySalary.tr(),
                      //   onPressed: () => _showPaySalaryDialog(employee),
                      // ),
                      IconButton(
                        icon: Icon(
                          Icons.edit_note_rounded,
                          color: AppColors.sandText,
                          size: 22,
                        ),
                        tooltip: AppStrings.edit.tr(),
                        onPressed: () => _showEditEmployeeDialog(employee),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddEmployeeDialog() {
    if (context.read<ConnectivityCubit>().state is ConnectivityDisconnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.noInternetConnection.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AddEditEmployeeDialog(
          onSave: (newEmployee) {
            context.read<EmployeeCubit>().addEmployee(newEmployee);
          },
        );
      },
    );
  }

  void _showEditEmployeeDialog(EmployeeEntity employee) {
    if (context.read<ConnectivityCubit>().state is ConnectivityDisconnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.noInternetConnection.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AddEditEmployeeDialog(
          employee: employee,
          onSave: (updatedEmployee) {
            context.read<EmployeeCubit>().editEmployee(updatedEmployee);
          },
        );
      },
    );
  }

  // void _showCheckInOutDialog(EmployeeEntity employee) {
  //     showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (ctx) {
  //         return CheckInOutDialog(
  //           employee: employee,
  //           onCheckIn: (attendance) {
  //             context.read<EmployeeCubit>().checkIn(attendance);
  //           },
  //           onCheckOut:
  //               ({
  //                 required String attendanceId,
  //                 required DateTime checkOutTime,
  //                 required double overtimeHours,
  //                 required double deductionHours,
  //                 required int lateMinutes,
  //                 required String status,
  //                 required String notes,
  //               }) {
  //                 context.read<EmployeeCubit>().checkOut(
  //                   uid: AppStrings.userToken,
  //                   attendanceId: attendanceId,
  //                   checkOutTime: checkOutTime,
  //                   overtimeHours: overtimeHours,
  //                   deductionHours: deductionHours,
  //                   lateMinutes: lateMinutes,
  //                   status: status,
  //                   notes: notes,
  //                 );
  //               },
  //         );
  //       },
  //     );
  //   }

  String _getFilterTranslation(String filter) {
    switch (filter) {
      case 'all':
        return AppStrings.all.tr();
      case 'active':
        return AppStrings.active.tr();
      case 'inactive':
        return AppStrings.inactive.tr();
      case 'suspended':
        return AppStrings.suspended.tr();
      default:
        return filter.tr();
    }
  }
}
