# Converting NXOP Governance Document to Microsoft Word

## Quick Start

You now have a comprehensive 1,630-line governance framework document that needs to be converted to Microsoft Word format.

## File Created

**Markdown File**: `NXOP-Data-Governance-Framework-Detailed.md`  
**Size**: 1,630 lines (approximately 80-100 pages in Word)  
**Format**: Markdown (.md)

## Conversion Methods

### Method 1: Microsoft Word Direct Open (Easiest)

1. Open Microsoft Word
2. Click **File** → **Open**
3. Navigate to the file: `NXOP-Data-Governance-Framework-Detailed.md`
4. Change file type filter to "All Files (*.*)" if you don't see the .md file
5. Select the file and click **Open**
6. Word will automatically convert the markdown formatting
7. Click **File** → **Save As**
8. Choose format: **Word Document (*.docx)**
9. Save as: `NXOP-Data-Governance-Framework-Detailed.docx`

**Pros**: No additional software needed  
**Cons**: Formatting may need manual adjustment

### Method 2: Using Pandoc (Best Formatting)

**Prerequisites**: Install Pandoc from https://pandoc.org/installing.html

**Steps**:
1. Open PowerShell in the document directory
2. Run this command:
```powershell
pandoc NXOP-Data-Governance-Framework-Detailed.md -o NXOP-Data-Governance-Framework-Detailed.docx --reference-doc=reference.docx
```

**For better formatting, create a reference document first**:
```powershell
# Basic conversion
pandoc NXOP-Data-Governance-Framework-Detailed.md -o NXOP-Data-Governance-Framework-Detailed.docx

# With table of contents
pandoc NXOP-Data-Governance-Framework-Detailed.md -o NXOP-Data-Governance-Framework-Detailed.docx --toc --toc-depth=3

# With custom styling (if you have a reference.docx template)
pandoc NXOP-Data-Governance-Framework-Detailed.md -o NXOP-Data-Governance-Framework-Detailed.docx --reference-doc=reference.docx --toc
```

**Pros**: Best formatting, professional output, automatic table of contents  
**Cons**: Requires installing Pandoc

### Method 3: Online Converter (No Installation)

1. Visit one of these websites:
   - https://www.markdowntoword.com/
   - https://cloudconvert.com/md-to-docx
   - https://products.aspose.app/words/conversion/md-to-docx

2. Upload `NXOP-Data-Governance-Framework-Detailed.md`
3. Click "Convert"
4. Download the resulting .docx file

**Pros**: No software installation needed  
**Cons**: File size limits, privacy concerns with sensitive documents

## Recommended Approach

**For American Airlines (Sensitive Document)**:
Use **Method 1** (Microsoft Word) or **Method 2** (Pandoc) to keep the document on your local machine.

**Do NOT use Method 3** (online converters) for this sensitive governance document.

## Post-Conversion Formatting

After conversion to Word, you may want to:

1. **Add Cover Page**:
   - Insert → Cover Page
   - Add American Airlines logo
   - Add document title and version

2. **Format Table of Contents**:
   - References → Table of Contents → Automatic Table
   - Update table of contents after any changes

3. **Apply Styles**:
   - Use Heading 1 for main sections
   - Use Heading 2 for subsections
   - Use Heading 3 for sub-subsections
   - Apply American Airlines corporate styles if available

4. **Format Tables**:
   - Apply table styles for consistency
   - Adjust column widths
   - Add table captions

5. **Add Headers/Footers**:
   - Insert → Header & Footer
   - Add document title, version, date
   - Add page numbers

6. **Review and Adjust**:
   - Check for formatting issues
   - Adjust page breaks
   - Ensure tables don't split awkwardly
   - Add page breaks before major sections

## What's in the Document

The document includes:

✅ **Section 1**: Governance Framework (Three-tier model, principles)  
✅ **Section 2**: Roles & Responsibilities (All roles with detailed descriptions)  
✅ **Section 3**: Governance Bodies (Meeting structures, cadences, agendas)  
✅ **Section 4**: Operational Procedures (Schema changes, vendor onboarding, data quality)  
✅ **Section 5**: Implementation Workplan (18-month detailed plan)  

📝 **Sections 6-10**: To be added (Metrics, Training, Templates, Risk Management, Appendices)

## Filling in Placeholders

The document has many `[TBD]` and `[To be assigned]` placeholders. After conversion to Word:

1. Use **Find & Replace** (Ctrl+H) to locate all `[TBD]` entries
2. Replace with actual names, emails, phone numbers
3. Update dates to match your actual timeline
4. Customize content to match American Airlines specifics

## Next Steps After Conversion

1. **Review the Document**:
   - Read through for completeness
   - Check formatting
   - Verify all sections are present

2. **Customize for American Airlines**:
   - Fill in all [TBD] placeholders
   - Add actual names and contact information
   - Adjust timelines based on resources
   - Add American Airlines branding

3. **Complete Remaining Sections**:
   - Add Section 6: Metrics & Monitoring
   - Add Section 7: Training & Communication
   - Add Section 8: Templates & Tools
   - Add Section 9: Risk Management
   - Add Section 10: Appendices

4. **Obtain Approvals**:
   - Review with Todd Waller (CDO)
   - Review with VP of Flight Operations Technology
   - Present to Joint Governance Council
   - Obtain executive sign-off

5. **Distribute**:
   - Share with all governance body members
   - Post to governance intranet site
   - Conduct training sessions
   - Begin implementation

## Support

If you need help with conversion or have questions:
- **Email**: nxop-governance@aa.com
- **Slack**: #nxop-governance

## Document Information

**Created**: January 30, 2026  
**Version**: 2.0  
**Format**: Markdown → Word  
**Size**: ~1,630 lines (~80-100 pages)  
**Status**: Ready for conversion and customization

