import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../config/app_theme.dart';

class UnitContentEditor extends StatelessWidget {
  final QuillController controller;
  final double minHeight;
  final double maxHeight;
  const UnitContentEditor({
    super.key,
    required this.controller,
    this.minHeight = 300,
    this.maxHeight = 600,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Toolbar
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: QuillToolbar.simple(
              configurations: QuillSimpleToolbarConfigurations(
                controller: controller,
                multiRowsDisplay: false,
                showFontFamily: false,
                showFontSize: false,
                showSearchButton: false,
                showSubscript: false,
                showSuperscript: false,
                showCodeBlock: false,
                showInlineCode: false,
                showBackgroundColorButton: false,
                showClearFormat: true,
                showAlignmentButtons: true,
                showDirection: false,
                showHeaderStyle: true,
                showListNumbers: true,
                showListBullets: true,
                showListCheck: false,
                showQuote: true,
                showIndent: true,
                showLink: true,
                showUndo: true,
                showRedo: true,
                decoration: const BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                buttonOptions: QuillSimpleToolbarButtonOptions(
                  base: QuillToolbarBaseButtonOptions(
                    iconTheme: QuillIconTheme(
                      // Use IconButtonData for selected state
                      iconButtonSelectedData: IconButtonData(
                        // Use 'color' for icon color in selected state
                        style: ButtonStyle(
                          // Use 'backgroundColor' for fill color in selected state
                          backgroundColor: WidgetStateProperty.all<Color>(
                            AppTheme.primaryBlue.withOpacity(0.2),
                          ),
                          // Icon color for selected state (if needed, overrides default)
                          // foregroundColor is often used for icon color
                          foregroundColor: WidgetStateProperty.all<Color>(
                            AppTheme
                                .primaryBlue, // Or use another color if needed
                          ),
                        ),
                      ),
                      // Use IconButtonData for unselected state
                      iconButtonUnselectedData: IconButtonData(
                        // Use 'color' for icon color in unselected state
                        style: ButtonStyle(
                          // Use 'backgroundColor' for fill color in unselected state
                          backgroundColor: WidgetStateProperty.all<Color>(
                            Colors.transparent,
                          ),
                          // Icon color for unselected state
                          foregroundColor: WidgetStateProperty.all<Color>(
                            AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Divider
          Container(
            height: 1,
            color: AppTheme.primaryBlue.withOpacity(0.3),
          ),
          // Editor
          Container(
            constraints: BoxConstraints(
              minHeight: minHeight,
              maxHeight: maxHeight,
            ),
            padding: const EdgeInsets.all(16),
            child: QuillEditor.basic(
              configurations: QuillEditorConfigurations(
                controller: controller,
                padding: EdgeInsets.zero, // Padding around the editor content
                placeholder: 'Start typing your unit content here...',
                customStyles: DefaultStyles(
                  // Paragraph Style
                  paragraph: const DefaultTextBlockStyle(
                    TextStyle(
                      // 1. TextStyle
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                      height: 1.6,
                    ),
                    VerticalSpacing(0,
                        0), // 2. verticalSpacing (top, bottom margin for block)
                    VerticalSpacing(8,
                        8), // 3. lineSpacing (spacing *within* the block lines)
                    null, // 4. BoxDecoration? for the block itself (usually null for paragraphs)
                    // 5. decoration: (named parameter, usually for block background/borders if needed)
                  ),

                  // Heading 1 Style
                  h1: const DefaultTextBlockStyle(
                    TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                    VerticalSpacing(16, 8), // Margin above/below
                    VerticalSpacing(0, 0), // Line spacing within
                    null, // BoxDecoration for H1 block itself
                  ),

                  // Heading 2 Style
                  h2: const DefaultTextBlockStyle(
                    TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                    VerticalSpacing(14, 8), // Margin above/below
                    VerticalSpacing(0, 0), // Line spacing within
                    null, // BoxDecoration for H2 block itself
                  ),

                  // Heading 3 Style
                  h3: const DefaultTextBlockStyle(
                    TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                    VerticalSpacing(12, 8), // Margin above/below
                    VerticalSpacing(0, 0), // Line spacing within
                    null, // BoxDecoration for H3 block itself
                  ),

                  // Inline Styles
                  bold: const TextStyle(fontWeight: FontWeight.bold),
                  italic: const TextStyle(fontStyle: FontStyle.italic),
                  underline:
                      const TextStyle(decoration: TextDecoration.underline),
                  strikeThrough:
                      const TextStyle(decoration: TextDecoration.lineThrough),
                  link: const TextStyle(
                    color: AppTheme.primaryBlue,
                    decoration: TextDecoration.underline,
                  ),

                  // Placeholder Style
                  placeHolder: const DefaultTextBlockStyle(
                    TextStyle(
                      fontSize: 16,
                      color: AppTheme.textHint,
                      height: 1.6,
                    ),
                    VerticalSpacing(0, 0), // Margin above/below
                    VerticalSpacing(8, 8), // Line spacing within
                    null, // BoxDecoration for placeholder block itself
                  ),

                  // List Style
                  lists: const DefaultListBlockStyle(
                    TextStyle(
                      // 1. TextStyle
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                      height: 1.6,
                    ),
                    VerticalSpacing(0,
                        0), // 2. verticalSpacing (top, bottom margin for list block)
                    VerticalSpacing(8,
                        8), // 3. lineSpacing (spacing within list item lines)
                    null, // 4. BoxDecoration? for the list block itself (usually null)
                    null, // 5. QuillCheckboxBuilder? (explicitly provide null)
                  ),

                  // Quote Style
                  quote: const DefaultTextBlockStyle(
                    TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                    ),
                    VerticalSpacing(8, 8), // Margin above/below
                    VerticalSpacing(0, 0), // Line spacing within
                    BoxDecoration(
                      // 4. BoxDecoration for the quote block itself
                      border: Border(
                        left: BorderSide(
                          color: AppTheme.primaryBlue,
                          width: 4,
                        ),
                      ),
                    ),
                  ),

                  // Code Style
                  code: DefaultTextBlockStyle(
                    const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                      fontFamily: 'monospace',
                      // backgroundColor is often handled by the decoration below
                    ),
                    const VerticalSpacing(8, 8), // Margin above/below
                    const VerticalSpacing(0, 0), // Line spacing within
                    BoxDecoration(
                      // 4. BoxDecoration for the code block itself
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
