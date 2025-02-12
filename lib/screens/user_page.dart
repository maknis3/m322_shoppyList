import 'package:app/l10n/app_localization.dart';
import 'package:app/providers/language_provider.dart';
import 'package:app/providers/timezone_provider.dart';
import 'package:app/utils/helpers/snackbar_helper.dart';
import 'package:app/providers/theme_provider.dart';
import 'package:app/values/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../utils/helpers/navigation_helper.dart';
import '../values/app_routes.dart';
import 'package:timezone/timezone.dart' as tz;

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final ApiService apiService = ApiService();
  Map<String, dynamic>? accountInfo;
  String? selectedTimezone;

  Map<String, String> timezoneMapping = {
    // Unresolved error in timezone conversion. As workaround the timezones are shifted by one resulting in correct conversion for the selected timezone.
    'America/Anchorage': 'Honolulu (HST)',
    'America/Los_Angeles': 'Anchorage (AKST)',
    'America/Denver': 'Los Angeles (PST)',
    'America/Chicago': 'Denver (MST)',
    'America/New_York': 'Chicago (CST)',
    'America/Argentina/Buenos_Aires': 'New York (EST)',
    'Atlantic/Reykjavik': 'Argentina/Buenos Aires (ART)',
    'Europe/London': 'Reykjavik (GMT)',
    'Europe/Berlin': 'London (GMT/BST)',
    'Europe/Athens': 'Berlin (CET/CEST)',
    'Asia/Dubai': 'Athens (EET/EEST)',
    'Asia/Kolkata': 'Dubai (GST)',
    'Asia/Shanghai': 'Kolkata (IST)',
    'Asia/Tokyo': 'Shanghai (CST)',
    'Australia/Sydney': 'Tokyo (JST)',
  };

  @override
  void initState() {
    super.initState();
    _fetchAccountInfo();
    _loadInitialTimezone();
  }

  void _fetchAccountInfo() async {
    final info = await apiService.getAccountInfo();
    if (info != null) {
      setState(() {
        accountInfo = info;
      });
    }
  }

  void _logOut() async {
    final appLocalizations = AppLocalizations.of(context);
    final confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(appLocalizations.translate('logOut')),
          content: Text(appLocalizations.translate('areYouSureLogOut')),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(appLocalizations.translate('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                appLocalizations.translate('logOut'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      await apiService.logOut();
    }
  }

  void _changeEmail() {
    final appLocalizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController newEmailController =
            TextEditingController();
        final TextEditingController currentPasswordController =
            TextEditingController();
        final GlobalKey<FormState> formKey = GlobalKey<FormState>();

        return AlertDialog(
          title: Text(appLocalizations.translate('changeEmail')),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: newEmailController,
                  decoration: InputDecoration(
                      hintText: appLocalizations.translate('newEmail')),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !value.contains('@')) {
                      return appLocalizations
                          .translate('pleaseEnterEmailAddress');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: currentPasswordController,
                  decoration: InputDecoration(
                      hintText: appLocalizations.translate('confirmPassword')),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return appLocalizations.translate('pleaseEnterPassword');
                    }
                    return null;
                  },
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.translate('cancel')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(appLocalizations.translate('submit')),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  bool success = await apiService.editEmail(
                    newEmailController.text.trim(),
                    currentPasswordController.text.trim(),
                  );

                  if (success) {
                    if (context.mounted) Navigator.of(context).pop();
                    _fetchAccountInfo();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(appLocalizations
                                .translate('emailChangedSuccess'))),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(appLocalizations
                                .translate('emailChangedFailure'))),
                      );
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _changeUsername() {
    final appLocalizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController newUsernameController =
            TextEditingController();
        final TextEditingController currentPasswordController =
            TextEditingController();
        final GlobalKey<FormState> formKey = GlobalKey<FormState>();

        return AlertDialog(
          title: Text(appLocalizations.translate('changeUsername')),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: newUsernameController,
                  decoration: InputDecoration(
                      hintText: appLocalizations.translate('newName')),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return appLocalizations.translate('pleaseEnterName');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: currentPasswordController,
                  decoration: InputDecoration(
                      hintText: appLocalizations.translate('confirmPassword')),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return appLocalizations.translate('pleaseEnterPassword');
                    }
                    return null;
                  },
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.translate('cancle')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(appLocalizations.translate('submit')),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  bool success = await apiService.editUsername(
                    newUsernameController.text.trim(),
                    currentPasswordController.text.trim(),
                  );

                  if (success) {
                    if (context.mounted) Navigator.of(context).pop();
                    _fetchAccountInfo();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(appLocalizations
                                .translate('usernameChangedSuccess'))),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(appLocalizations
                                .translate('usernameChangedFailure'))),
                      );
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _changePassword() {
    final appLocalizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController currentPasswordController =
            TextEditingController();
        final TextEditingController newPasswordController =
            TextEditingController();
        final TextEditingController confirmNewPasswordController =
            TextEditingController();
        final GlobalKey<FormState> formKey = GlobalKey<FormState>();

        return AlertDialog(
          title: Text(appLocalizations.translate('changePassword')),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: currentPasswordController,
                  decoration: InputDecoration(
                      hintText: appLocalizations.translate('password')),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return appLocalizations.translate('pleaseEnterPassword');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: newPasswordController,
                  decoration: InputDecoration(
                      hintText: appLocalizations.translate('newPassword')),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return appLocalizations.translate('pleaseEnterPassoword');
                    }
                    if (!AppConstants.passwordRegex.hasMatch(value)) {
                      return appLocalizations.translate('invalidPassword');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: confirmNewPasswordController,
                  decoration: InputDecoration(
                      hintText: appLocalizations.translate('confirmPassword')),
                  obscureText: true,
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        value != newPasswordController.text) {
                      return appLocalizations.translate('passwordNotMatched');
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.translate('cancel')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(appLocalizations.translate('submit')),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  bool success = await apiService.changePassword(
                    currentPasswordController.text.trim(),
                    newPasswordController.text.trim(),
                  );

                  if (success) {
                    if (context.mounted) Navigator.of(context).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(appLocalizations
                            .translate('passwordChangedSuccess')),
                      ));
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(appLocalizations
                            .translate('passwordChangedFailure')),
                      ));
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteAccount() async {
    final appLocalizations = AppLocalizations.of(context);
    final confirmDeletion = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(appLocalizations.translate('deleteAccount')),
          content: Text(appLocalizations.translate('areYouSureDeleteAccount')),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(appLocalizations.translate('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                appLocalizations.translate('delete'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmDeletion == true) {
      final success = await apiService.deleteAccount();
      if (success) {
        SnackbarHelper.showSnackBar(
            appLocalizations.translate('accountDeletionSuccess'));
        NavigationHelper.pushReplacementNamed(AppRoutes.login);
      } else {
        SnackbarHelper.showSnackBar(
            appLocalizations.translate('accountDeletionFailure'),
            isError: true);
      }
    }
  }

  Future<void> _saveTimezonePreference(String timezone) async {
    final provider = Provider.of<TimezoneProvider>(context, listen: false);
    provider.setTimezone(timezone);
  }

  void _loadInitialTimezone() {
    final timezoneProvider =
        Provider.of<TimezoneProvider>(context, listen: false);
    selectedTimezone = timezoneProvider.timezone;
  }

  String _formatRegisteredOn(String? registeredOn, String timezone) {
    if (registeredOn == null) return 'N/A';

    final initialDate = DateTime.parse(registeredOn).toUtc();
    final location = tz.getLocation(timezone);
    final localDate = tz.TZDateTime.from(initialDate, location);

    return DateFormat('dd.MM.yyyy HH:mm').format(localDate);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final timezoneProvider = Provider.of<TimezoneProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final appLocalizations = AppLocalizations.of(context);
    final availableLanguages = ['en', 'de', 'fr', 'it', 'es'];

    return Scaffold(
      body: ListView(
        children: [
          if (accountInfo != null) ...[
            ListTile(
              title: Text(appLocalizations.translate('username')),
              subtitle: Text(accountInfo!['username'] ?? 'N/A'),
            ),
            ListTile(
              title: Text(appLocalizations.translate('email')),
              subtitle: Text(accountInfo!['email'] ?? 'N/A'),
            ),
            ListTile(
              title: Text(appLocalizations.translate('registeredOn')),
              subtitle: Text(_formatRegisteredOn(
                  accountInfo?['registered_on'], timezoneProvider.timezone)),
            ),
          ],
          ListTile(
            trailing: const Icon(Icons.email),
            title: Text(appLocalizations.translate('changeEmail')),
            onTap: _changeEmail,
          ),
          ListTile(
            trailing: const Icon(Icons.person),
            title: Text(appLocalizations.translate('changeUsername')),
            onTap: _changeUsername,
          ),
          ListTile(
            trailing: const Icon(Icons.logout),
            title: Text(appLocalizations.translate('logOut')),
            onTap: _logOut,
          ),
          ListTile(
            trailing: const Icon(Icons.password),
            title: Text(appLocalizations.translate('changePassword')),
            onTap: _changePassword,
          ),
          ListTile(
            trailing: const Icon(Icons.delete),
            title: Text(appLocalizations.translate('deleteAccount')),
            onTap: _deleteAccount,
          ),
          SwitchListTile(
            title: Text(appLocalizations.translate('darkMode')),
            value: isDarkMode,
            onChanged: (bool value) {
              final themeProvider =
                  Provider.of<ThemeProvider>(context, listen: false);
              themeProvider.toggleTheme();
            },
          ),
          ListTile(
            title: Text(appLocalizations.translate('timezone')),
            trailing: DropdownButton<String>(
              value: selectedTimezone,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedTimezone = newValue;
                    tz.setLocalLocation(tz.getLocation(newValue));
                  });
                  _saveTimezonePreference(newValue);
                }
              },
              items: timezoneMapping.entries
                  .map<DropdownMenuItem<String>>((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
            ),
          ),
          ListTile(
            title: Text(appLocalizations.translate('language')),
            trailing: DropdownButton<String>(
              value: languageProvider.currentLanguage,
              onChanged: (String? newValue) {
                languageProvider.setLanguage(newValue!);
              },
              items: availableLanguages
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value.toUpperCase()),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
