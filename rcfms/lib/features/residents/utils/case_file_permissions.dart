import '../../../core/constants/app_constants.dart';

class CaseFilePermissionResult {
  final bool canView;
  final bool canDownload;
  final bool canPrint;
  final bool canEdit;
  final bool canArchive;
  final bool canRestore;
  final bool canPermanentDelete;
  final bool canCreate;

  const CaseFilePermissionResult({
    this.canView = false,
    this.canDownload = false,
    this.canPrint = false,
    this.canEdit = false,
    this.canArchive = false,
    this.canRestore = false,
    this.canPermanentDelete = false,
    this.canCreate = false,
  });
}

class CaseFilePermissions {
  CaseFilePermissions._();

  static bool isCaseFolderCustodian(String userRole, String? userUnit) {
    return (userRole == AppConstants.roleHead || userRole == 'social_head') &&
        userUnit == AppConstants.unitSocial;
  }

  static bool _isAdminRole(String role) {
    return role == AppConstants.roleCenterHead ||
        role == AppConstants.roleSuperAdmin;
  }

  static bool _isUnitHead(String role) {
    return role == AppConstants.roleHead || role.endsWith('_head');
  }

  static CaseFilePermissionResult getPermissions({
    required String userRole,
    required String? userUnit,
    required String formUnit,
    required String formSubmitterId,
    required String currentUserId,
    required String formStatus,
    bool isArchived = false,
  }) {
    final isAdmin = _isAdminRole(userRole);
    final isHead = _isUnitHead(userRole);
    final isCustodian = isCaseFolderCustodian(userRole, userUnit);
    final isOwnUnit = userUnit == formUnit;
    final isOwnForm = formSubmitterId == currentUserId;
    final isEditableStatus =
        formStatus == AppConstants.statusDraft ||
        formStatus == AppConstants.statusReturned;
    final isApproved = formStatus == AppConstants.statusApproved;

    if (isAdmin) {
      return CaseFilePermissionResult(
        canView: true,
        canDownload: true,
        canPrint: true,
        canEdit: false,
        canArchive: false,
        canRestore: isArchived,
        canPermanentDelete: isArchived,
        canCreate: false,
      );
    }

    if (isCustodian) {
      return CaseFilePermissionResult(
        canView: true,
        canDownload: true,
        canPrint: true,
        canEdit: isOwnForm && isEditableStatus,
        canArchive: !isArchived,
        canRestore: isArchived,
        canPermanentDelete: isArchived,
        canCreate: isOwnUnit,
      );
    }

    if (isHead) {
      return CaseFilePermissionResult(
        canView: true,
        canDownload: isOwnUnit,
        canPrint: isOwnUnit,
        canEdit: isOwnForm && isEditableStatus,
        canArchive: !isArchived && isOwnUnit,
        canRestore: isArchived && isOwnUnit,
        canPermanentDelete: isArchived && isOwnUnit,
        canCreate: isOwnUnit,
      );
    }

    // Staff / Center Doctor
    return CaseFilePermissionResult(
      canView: isOwnUnit,
      canDownload: isOwnUnit && isApproved,
      canPrint: isOwnUnit && isApproved,
      canEdit: isOwnForm && isEditableStatus,
      canArchive: false,
      canRestore: false,
      canPermanentDelete: false,
      canCreate: isOwnUnit,
    );
  }

  static bool canCreateFormType({
    required String userRole,
    required String? userUnit,
    required String templateUnit,
  }) {
    if (_isAdminRole(userRole)) return false;
    return userUnit == templateUnit;
  }
}
