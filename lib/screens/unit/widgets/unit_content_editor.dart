import 'package:flutter/material.dart';
// Import the updated flutter_quill package
import 'package:flutter_quill/flutter_quill.dart';
// Remove flutter_quill_extensions import as it's not planned for use
// import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import '../../../config/app_theme.dart';

// Make UnitContentEditor StatefulWidget to manage FocusNode and ScrollController
class UnitContentEditor extends StatefulWidget {
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
  State<UnitContentEditor> createState() => _UnitContentEditorState();
}

class _UnitContentEditorState extends State<UnitContentEditor> {
  late final FocusNode _editorFocusNode;
  late final ScrollController _editorScrollController;

  @override
  void initState() {
    super.initState();
    _editorFocusNode = FocusNode();
    _editorScrollController = ScrollController();
  }

  @override
  void dispose() {
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

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
            // Updated Toolbar Widget - Using config parameter
            child: QuillSimpleToolbar(
              controller: widget.controller, // Pass controller directly
              config: QuillSimpleToolbarConfig(
                // Use config parameter
                // Toolbar Options - Using CORRECT names from the API definition
                showBoldButton: true, // Changed from showBold
                showItalicButton: true, // Changed from showItalic
                showUnderLineButton: true, // Changed from showUnderline
                showStrikeThrough: true, // This one was correct
                showColorButton: true, // This one was correct
                showBackgroundColorButton:
                    false, // Changed from showBackgroundColorButton
                showClearFormat: true, // This one was correct
                showAlignmentButtons: true, // This one was correct
                showListNumbers: true, // This one was correct
                showListBullets: true, // This one was correct
                showListCheck: false, // This one was correct
                showCodeBlock: false, // This one was correct
                showQuote: true, // This one was correct
                showIndent: true, // This one was correct
                showLink: true, // This one was correct
                showUndo: true, // Changed from showHistory
                showRedo: true, // Changed from showHistory
                showDirection: false, // This one was correct
                showHeaderStyle: true, // This one was correct
                showFontSize: false, // This one was correct
                showFontFamily: false, // This one was correct
                showSearchButton: false, // This one was correct
                multiRowsDisplay: false, // This one was correct
                showClipboardPaste: true, // Example feature
                // Button Options - Updated structure for icon theming
                buttonOptions: QuillSimpleToolbarButtonOptions(
                  base: QuillToolbarBaseButtonOptions(
                    // Apply icon theming using iconTheme
                    iconTheme: QuillIconTheme(
                      // Use WidgetStateProperty for selected state
                      iconButtonSelectedData: IconButtonData(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(
                            AppTheme.primaryBlue.withOpacity(0.2),
                          ),
                          foregroundColor: WidgetStateProperty.all<Color>(
                            AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                      // Use WidgetStateProperty for unselected state
                      iconButtonUnselectedData: IconButtonData(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(
                            Colors.transparent,
                          ),
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
              minHeight: widget.minHeight,
              maxHeight: widget.maxHeight,
            ),
            padding: const EdgeInsets.all(16),
            // Updated Editor Widget - Using config parameter
            // Requires focusNode and scrollController
            child: QuillEditor(
              controller: widget.controller, // Pass controller directly
              focusNode: _editorFocusNode, // Add required focusNode
              scrollController:
                  _editorScrollController, // Add required scrollController
              config: QuillEditorConfig(
                // Use config parameter
                // Editor Options
                placeholder: 'Start typing your unit content here...',
                padding: EdgeInsets.zero, // Padding around the editor content
                // Custom Styling - Updated structure, fixing VerticalSpacing/BoxDecoration order
                // AND fixing the type for lists (DefaultListBlockStyle) with the correct constructor args
                customStyles: DefaultStyles(
                  // Paragraph Style - Corrected structure
                  paragraph: const DefaultTextBlockStyle(
                    TextStyle(
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                      height: 1.6,
                    ),
                    HorizontalSpacing(0, 0), // horizontalSpacing
                    VerticalSpacing(
                        0, 0), // verticalSpacing (top, bottom margin for block)
                    VerticalSpacing(
                        8, 8), // lineSpacing (spacing *within* the block lines)
                    BoxDecoration(), // decoration: BoxDecoration for the block itself
                  ),

                  // Heading Styles - Corrected structure
                  h1: const DefaultTextBlockStyle(
                    TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                    HorizontalSpacing(0, 0), // horizontalSpacing
                    VerticalSpacing(
                        16, 8), // verticalSpacing (top, bottom margin)
                    VerticalSpacing(0, 0), // lineSpacing
                    BoxDecoration(),
                  ),

                  h2: const DefaultTextBlockStyle(
                    TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                    HorizontalSpacing(0, 0), // horizontalSpacing
                    VerticalSpacing(
                        14, 8), // verticalSpacing (top, bottom margin)
                    VerticalSpacing(0, 0), // lineSpacing
                    BoxDecoration(),
                  ),

                  h3: const DefaultTextBlockStyle(
                    TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                    HorizontalSpacing(0, 0), // horizontalSpacing
                    VerticalSpacing(
                        12, 8), // verticalSpacing (top, bottom margin)
                    VerticalSpacing(0, 0), // lineSpacing
                    BoxDecoration(),
                  ),

                  // Inline Styles - Remain unchanged
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

                  // Placeholder Style - Corrected structure
                  placeHolder: const DefaultTextBlockStyle(
                    TextStyle(
                      fontSize: 16,
                      color: AppTheme.textHint,
                      height: 1.6,
                    ),
                    HorizontalSpacing(0, 0), // horizontalSpacing
                    VerticalSpacing(
                        0, 0), // verticalSpacing (top, bottom margin)
                    VerticalSpacing(8, 8), // lineSpacing
                    BoxDecoration(),
                  ),

                  // List Style - CORRECTED TYPE: DefaultListBlockStyle
                  // AND CORRECTED CONSTRUCTOR ARGS: Added null for checkboxUIBuilder
                  lists: const DefaultListBlockStyle(
                    TextStyle(
                      // 1. TextStyle
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                      height: 1.6,
                    ),
                    HorizontalSpacing(0, 0), // 2. horizontalSpacing
                    VerticalSpacing(0,
                        0), // 3. verticalSpacing (top, bottom margin for list block)
                    VerticalSpacing(8,
                        8), // 4. lineSpacing (spacing within list item lines)
                    BoxDecoration(), // 5. decoration: BoxDecoration for the list block itself
                    null, // 6. QuillCheckboxBuilder? checkboxUIBuilder - Pass null as we don't use checklists
                    // Optional named parameters like indentWidthBuilder, numberPointWidthBuilder can be added here if needed
                  ),

                  // Quote Style - Corrected structure
                  quote: const DefaultTextBlockStyle(
                    TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                    ),
                    HorizontalSpacing(0, 0), // horizontalSpacing
                    VerticalSpacing(
                        8, 8), // verticalSpacing (top, bottom margin)
                    VerticalSpacing(0, 0), // lineSpacing
                    BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: AppTheme.primaryBlue,
                          width: 4,
                        ),
                      ),
                    ),
                  ),

                  // Code Style - Corrected structure
                  code: DefaultTextBlockStyle(
                    const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                      fontFamily: 'monospace',
                    ),
                    const HorizontalSpacing(0, 0), // horizontalSpacing
                    const VerticalSpacing(
                        8, 8), // verticalSpacing (top, bottom margin)
                    const VerticalSpacing(0, 0), // lineSpacing
                    BoxDecoration(
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
