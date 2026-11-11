// ignore_for_file: public_member_api_docs, sort_constructors_first
part of '../utils.dart';

/// The code snippet provided defines an enum called `DTextInputType` in Dart. This enum represents
/// different types of text input fields that can be used in a user interface. The enum values include
/// `none`, `text`, `name`, `number`, `price`, `password`, `multiline`, `date`, `time`, `email`, `url`,
/// `phone`, and `address`.

enum DTextInputType {
  none,
  text,
  name,
  number,
  price,
  password,
  multiline,
  date,
  time,
  email,
  url,
  phone,
  address,
  search;

  /// The `textInputAction` getter method is used to determine the `TextInputAction` for a specific
  /// `DTextInputType` enum value. It uses a constant map to match the enum value and return the
  /// corresponding `TextInputAction`. If the enum value is not found in the map, it returns
  /// `TextInputAction.next` as the default value.
  TextInputAction get textInputAction {
    const map = {
      DTextInputType.text: TextInputAction.next,
      DTextInputType.number: TextInputAction.next,
      DTextInputType.price: TextInputAction.next,
      DTextInputType.password: TextInputAction.next,
      DTextInputType.multiline: TextInputAction.newline,
      DTextInputType.date: TextInputAction.next,
      DTextInputType.email: TextInputAction.next,
      DTextInputType.url: TextInputAction.next,
      DTextInputType.phone: TextInputAction.next,
      DTextInputType.address: TextInputAction.next,
      DTextInputType.search: TextInputAction.search,
    };

    return map[this] ?? TextInputAction.next;
  }

  /// The `textInputType` getter method is used to determine the `TextInputType` for a specific
  /// `DTextInputType` enum value. It uses a switch statement to match the enum value and return the
  /// corresponding `TextInputType`.
  TextInputType get textInputType {
    return switch (this) {
      DTextInputType.none || DTextInputType.text || DTextInputType.search => TextInputType.text,
      DTextInputType.name => TextInputType.name,
      DTextInputType.number => TextInputType.number,
      DTextInputType.price => TextInputType.number,
      DTextInputType.password => TextInputType.visiblePassword,
      DTextInputType.multiline => TextInputType.multiline,
      DTextInputType.date => TextInputType.datetime,
      DTextInputType.time => TextInputType.datetime,
      DTextInputType.email => TextInputType.emailAddress,
      DTextInputType.url => TextInputType.url,
      DTextInputType.phone => TextInputType.phone,
      DTextInputType.address => TextInputType.streetAddress,
    };
  }
}

/// Local replacement for Syncfusion's `DateRangePickerView`.
/// Keeps existing `DTextField` API stable while using Flutter built-in date picker.
enum DateRangePickerView { month, year, decade, century }

class DTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextStyle? inputStyle;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final TextStyle? errorStyle;
  final EdgeInsets? contentPadding;
  final Color? cursorColor;
  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? disabledBorder;
  final InputBorder? focusedBorder;
  final InputBorder? errorBorder;
  final InputBorder? focusedErrorBorder;
  final Color? fillColor;

  /// This is availble when type is [DTextInputType.date]
  final String customDateFormat;
  final Widget? prefix;
  final Widget? suffix;
  final bool requiredField;
  final bool readOnly;
  final int expandFlex;
  final double width;
  final Function()? onEditingComplete;
  final void Function(String)? onChanged;
  final void Function(String?)? onSaved;
  final Function()? onDateRemove;
  final Function()? onDateConfirm;
  final Function()? onTimeConfirm;
  final Function()? onTap;
  final dynamic Function(Object?)? onSubmit;
  final DTextInputType type;
  final FocusNode? focusNode;

  /// `final int maxLines` is a property of the `DTextField` class that determines the maximum number of
  /// lines that can be entered in the text field. It is used when the `type` property of the
  /// `DTextField` is set to `DTextInputType.multiline`. If `maxLines` is not specified, the default
  /// value is 5.
  final int maxLines;
  final EdgeInsets margin;
  final DateRangePickerView datePickerType;
  final String obscureCharacter;
  final TextCapitalization textCapitalization;
  final TextAlign textAlign;
  final int? maxLength;
  final String? counterText;
  final bool isDense;

  const DTextField({
    super.key,
    required this.controller,
    this.label = '',
    this.hint = '',
    this.inputStyle,
    this.labelStyle,
    this.hintStyle,
    this.errorStyle,
    this.contentPadding,
    this.cursorColor,
    this.border,
    this.enabledBorder,
    this.disabledBorder,
    this.focusedBorder,
    this.errorBorder,
    this.focusedErrorBorder,
    this.fillColor,
    this.customDateFormat = 'dd/MM/yyyy',
    this.prefix,
    this.suffix,
    this.requiredField = false,
    this.readOnly = false,
    this.expandFlex = 0,
    this.width = 0,
    this.onEditingComplete,
    this.onChanged,
    this.onSaved,
    this.onDateRemove,
    this.onDateConfirm,
    this.onTimeConfirm,
    this.onTap,
    this.onSubmit,
    this.type = DTextInputType.text,
    this.maxLines = 5,
    this.margin = EdgeInsets.zero,
    this.datePickerType = DateRangePickerView.month,
    this.obscureCharacter = '*',
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.textAlign = TextAlign.start,
    this.maxLength,
    this.counterText,
    this.isDense = false,
  }) : assert(maxLines > 0, 'maxLines must be greater than 0'),
       assert(width >= 0, 'width must be greater than or equal to 0'),
       assert(expandFlex >= 0, 'expandFlex must be greater than or equal to 0'),
       assert(width == 0 || expandFlex == 0, 'width and expandFlex cannot be used together'),
       assert(type != DTextInputType.multiline || maxLines > 1, 'maxLines must be greater than 1 for multiline type');

  @override
  State<DTextField> createState() => _DTextFieldState();
}

class _DTextFieldState extends State<DTextField> {
  bool isShowPassword = false;

  Widget? get suffix {
    Widget? result;

    if (widget.type == DTextInputType.password) {
      result = IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(
          isShowPassword ? Icons.visibility : Icons.visibility_off,
          color: Colors.grey,
        ),
        onPressed: () {
          AppHaptic.select();
          setState(() {
            isShowPassword = !isShowPassword;
          });
        },
      );
    }

    if (widget.type == DTextInputType.date) {
      result = Padding(
        padding: EdgeInsets.all(18.w),
        child: SvgPicture.asset(""),
      );
    }

    if (widget.type == DTextInputType.time) {
      result = Padding(
        padding: EdgeInsets.all(18.w),
        child: SvgPicture.asset(""),
      );
    }

    return result;
  }

  Widget? label(InputDecorationThemeData theme) {
    if (widget.label.isEmpty) return null;
    return RichText(
      textAlign: TextAlign.start,
      text: TextSpan(
        text: widget.label,
        style: widget.labelStyle ?? theme.labelStyle,
        children: [
          TextSpan(
            text: widget.requiredField ? ' *' : '',
            style: theme.errorStyle,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    InputDecorationThemeData theme = context.watch<ThemeCubit>().state.themeUtil.inputDecorationTheme;
    InputDecoration textFieldDecoration = InputDecoration(
      alignLabelWithHint: theme.alignLabelWithHint,
      floatingLabelBehavior: theme.floatingLabelBehavior,
      floatingLabelAlignment: theme.floatingLabelAlignment,
      hintFadeDuration: theme.hintFadeDuration,
      isCollapsed: theme.isCollapsed,
      isDense: widget.isDense,
      counterText: widget.counterText,
      contentPadding: widget.contentPadding ?? theme.contentPadding,
      hintStyle: widget.hintStyle ?? theme.hintStyle,
      labelStyle: widget.labelStyle ?? theme.labelStyle,
      errorStyle: widget.errorStyle ?? theme.errorStyle,
      hintText: widget.hint,
      filled: theme.filled,
      label: label(theme),
      prefixIcon: widget.prefix,
      suffixIcon: widget.suffix ?? suffix,
      fillColor: widget.fillColor ?? theme.fillColor,
      enabledBorder: widget.enabledBorder ?? theme.enabledBorder,
      focusedBorder: widget.focusedBorder ?? theme.focusedBorder,
      errorBorder: widget.border ?? theme.errorBorder,
      border: widget.border ?? theme.border,
      disabledBorder: widget.disabledBorder ?? theme.disabledBorder,
      focusedErrorBorder: widget.focusedErrorBorder ?? theme.focusedErrorBorder,
    );

    Widget tmpTextField = TextFormField(
      focusNode: widget.focusNode,
      textAlign: widget.textAlign,
      maxLength: widget.maxLength,
      controller: widget.controller,
      enableInteractiveSelection: true,
      cursorColor: widget.cursorColor,
      keyboardType: widget.type.textInputType,
      obscuringCharacter: widget.obscureCharacter,
      obscureText: widget.type == DTextInputType.password && !isShowPassword,
      enableSuggestions: widget.type != DTextInputType.password,
      autocorrect: widget.type != DTextInputType.password,
      textInputAction: widget.type.textInputAction,
      decoration: textFieldDecoration,
      onChanged: widget.onChanged ?? (value) {},
      onSaved: widget.onSaved ?? (value) {},
      textCapitalization: widget.textCapitalization,
      contextMenuBuilder: (context, editableTextState) {
        return AdaptiveTextSelectionToolbar.editableText(
          editableTextState: editableTextState,
        );
      },
      onEditingComplete: widget.onEditingComplete ?? () {},
      maxLines: (widget.type == DTextInputType.multiline) ? widget.maxLines : 1,
      style: widget.inputStyle,
      readOnly: widget.readOnly ? true : (widget.type == DTextInputType.date || widget.type == DTextInputType.time),
      onTap: widget.onTap ?? _onTapDefault,
      onFieldSubmitted: (value) {
        if (widget.onSubmit != null) {
          widget.onSubmit!(value);
        }
      },
    );

    if (widget.margin != EdgeInsets.zero) {
      tmpTextField = Container(
        margin: widget.margin.h,
        child: tmpTextField,
      );
    }

    if (widget.width > 0) {
      tmpTextField = SizedBox(
        width: widget.width.w,
        child: tmpTextField,
      );
    }

    if (widget.expandFlex > 0) {
      tmpTextField = Expanded(
        flex: widget.expandFlex,
        child: tmpTextField,
      );
    }

    return tmpTextField;
  }

  void _onTapDefault() {
    if (widget.type == DTextInputType.date) {
      _onTapDate();
    }
    if (widget.type == DTextInputType.time) {
      _onTapTime();
    }
  }

  Future<void> _onTapDate() async {
    final DateTime minDate = DateTime(1900, 1, 1);
    final DateTime maxDate = DateTime(2100, 12, 31);
    final DateTime now = DateTime.now();
    final DateTime parsedDate = _parseCurrentDate() ?? now;
    final DateTime initialDate = parsedDate.isBefore(minDate)
        ? minDate
        : parsedDate.isAfter(maxDate)
            ? maxDate
            : parsedDate;

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate,
      lastDate: maxDate,
      barrierDismissible: false,
      initialDatePickerMode: _datePickerModeFromView(widget.datePickerType),
      helpText: 'Chọn ngày',
      cancelText: 'Hủy',
      confirmText: 'Xác nhận',
      builder: (dialogContext, child) {
        return PopScope(
          canPop: false,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (!mounted) return;

    if (selectedDate == null) {
      widget.controller.text = '';
      FocusScope.of(context).requestFocus(FocusNode());
      widget.onDateRemove == null ? null : widget.onDateRemove!();
      return;
    }

    if (widget.onSubmit != null) {
      widget.onSubmit!(selectedDate);
    } else {
      widget.controller.text = df.DateFormat(widget.customDateFormat).format(selectedDate);
    }

    FocusScope.of(context).requestFocus(FocusNode());
    widget.onDateConfirm == null ? null : widget.onDateConfirm!();
  }

  DateTime? _parseCurrentDate() {
    if (widget.controller.text.trim().isEmpty) return null;

    try {
      return df.DateFormat(widget.customDateFormat).parseStrict(widget.controller.text.trim());
    } catch (_) {
      return null;
    }
  }

  DatePickerMode _datePickerModeFromView(DateRangePickerView view) {
    return switch (view) {
      DateRangePickerView.month => DatePickerMode.day,
      DateRangePickerView.year => DatePickerMode.year,
      DateRangePickerView.decade || DateRangePickerView.century => () {
        LogDev.info('Date picker view "$view" is unsupported in Material picker. Fallback to year mode.');
        return DatePickerMode.year;
      }(),
    };
  }

  Future<void> _onTapTime() async {
    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
    );

    if (time == null) return;
    if (!mounted) return;

    widget.controller.text = time.format(context);
    widget.onTimeConfirm == null ? null : widget.onTimeConfirm!();
  }
}
