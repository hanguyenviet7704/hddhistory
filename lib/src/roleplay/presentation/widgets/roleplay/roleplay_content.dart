part of '../../../roleplay.dart';

class RoleplayContent extends StatelessWidget {
  const RoleplayContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.op(0.24),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h + MediaQuery.paddingOf(context).bottom),
                child: const RoleplayContentList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
