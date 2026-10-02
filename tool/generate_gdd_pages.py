#!/usr/bin/env python3
"""
Convert docs/GDD.md into a native Apple Pages document (docs/Lumen_GDD.pages and docs/GDD.pages)
using python-docx for structured document compilation and AppleScript/Pages for native packaging.
"""

import os
import re
import subprocess
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

COLOR_TEAL = RGBColor(31, 175, 138)       # #1FAF8A
COLOR_DARK_TEAL = RGBColor(14, 112, 88)   # #0E7058
COLOR_LAVENDER = RGBColor(139, 123, 200)  # #8B7BC8
COLOR_CORAL = RGBColor(255, 138, 92)      # #FF8A5C
COLOR_SLATE = RGBColor(15, 23, 42)        # #0F172A
COLOR_BODY = RGBColor(51, 65, 85)         # #334155
COLOR_MUTED = RGBColor(100, 116, 139)     # #64748B

HEX_TEAL_BG = "E6F7F3"
HEX_ROW_EVEN = "F8FAFC"
HEX_BORDER = "CBD5E1"
HEX_CODE_BG = "0F172A"

def set_cell_background(cell, hex_color):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{hex_color}"/>')
    tcPr.append(shd)

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = parse_xml(
        f'<w:tcMar {nsdecls("w")}>'
        f'<w:top w:w="{top}" w:type="dxa"/>'
        f'<w:bottom w:w="{bottom}" w:type="dxa"/>'
        f'<w:left w:w="{left}" w:type="dxa"/>'
        f'<w:right w:w="{right}" w:type="dxa"/>'
        f'</w:tcMar>'
    )
    tcPr.append(tcMar)

def set_cell_borders(cell, top="CCCCCC", bottom="CCCCCC", left=None, right=None):
    tcPr = cell._tc.get_or_add_tcPr()
    borders_elm = OxmlElement('w:tcBorders')
    
    for side, color in [('top', top), ('bottom', bottom), ('left', left), ('right', right)]:
        if color:
            b = parse_xml(f'<w:{side} {nsdecls("w")} w:val="single" w:sz="4" w:space="0" w:color="{color}"/>')
            borders_elm.append(b)
        else:
            b = parse_xml(f'<w:{side} {nsdecls("w")} w:val="none"/>')
            borders_elm.append(b)
    tcPr.append(borders_elm)

def add_styled_heading(doc, text, level):
    h = doc.add_heading(text, level=level)
    h.paragraph_format.keep_with_next = True
    h.paragraph_format.space_before = Pt(14 if level == 1 else (10 if level == 2 else 8))
    h.paragraph_format.space_after = Pt(4)
    run = h.runs[0]
    run.font.name = 'Helvetica Neue'
    
    if level == 1:
        run.font.size = Pt(17)
        run.font.bold = True
        run.font.color.rgb = COLOR_SLATE
    elif level == 2:
        run.font.size = Pt(13)
        run.font.bold = True
        run.font.color.rgb = COLOR_DARK_TEAL
    elif level == 3:
        run.font.size = Pt(11)
        run.font.bold = True
        run.font.color.rgb = COLOR_SLATE
    else:
        run.font.size = Pt(10)
        run.font.bold = True
        run.font.color.rgb = COLOR_MUTED
    return h

def format_inline_text(paragraph, text):
    """Parses basic markdown inline formatting like bold, code, and links."""
    # Pattern to match **bold**, `code`, [link text](url)
    tokens = re.split(r'(\*\*.*?\*\*|`.*?`|\[.*?\]\(.*?\))', text)
    for token in tokens:
        if not token:
            continue
        if token.startswith('**') and token.endswith('**'):
            r = paragraph.add_run(token[2:-2])
            r.font.bold = True
            r.font.color.rgb = COLOR_SLATE
        elif token.startswith('`') and token.endswith('`'):
            r = paragraph.add_run(token[1:-1])
            r.font.name = 'Menlo'
            r.font.size = Pt(8.5)
            r.font.color.rgb = COLOR_SLATE
        elif token.startswith('[') and '](' in token and token.endswith(')'):
            link_text = token[1:token.index('](')]
            r = paragraph.add_run(link_text)
            r.font.color.rgb = COLOR_DARK_TEAL
            r.font.underline = True
        else:
            r = paragraph.add_run(token)
            r.font.color.rgb = COLOR_BODY
        r.font.name = 'Helvetica Neue'

def build_docx(md_path, docx_path):
    print(f"Reading {md_path}...")
    with open(md_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    doc = Document()

    # Page Margins: 0.75 in (approx 19mm)
    sections = doc.sections
    for section in sections:
        section.top_margin = Inches(0.8)
        section.bottom_margin = Inches(0.8)
        section.left_margin = Inches(0.8)
        section.right_margin = Inches(0.8)
        section.different_first_page_header_footer = False
        
        # Header & Footer
        header = section.header
        hp = header.paragraphs[0]
        hp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        hrun = hp.add_run("Lumen — Game Design Document (GDD v1.0)")
        hrun.font.name = 'Helvetica Neue'
        hrun.font.size = Pt(8)
        hrun.font.color.rgb = COLOR_MUTED
        
        footer = section.footer
        fp = footer.paragraphs[0]
        fp.alignment = WD_ALIGN_PARAGRAPH.LEFT
        frun = fp.add_run("Companion TDAH Offline-First · Apple Health & Health Connect")
        frun.font.name = 'Helvetica Neue'
        frun.font.size = Pt(8)
        frun.font.color.rgb = COLOR_MUTED

    # Title Card
    title_p = doc.add_paragraph()
    title_p.paragraph_format.space_before = Pt(0)
    title_p.paragraph_format.space_after = Pt(2)
    t_run = title_p.add_run("Lumen")
    t_run.font.name = 'Helvetica Neue'
    t_run.font.size = Pt(32)
    t_run.font.bold = True
    t_run.font.color.rgb = COLOR_SLATE

    sub_p = doc.add_paragraph()
    sub_p.paragraph_format.space_before = Pt(0)
    sub_p.paragraph_format.space_after = Pt(14)
    s_run = sub_p.add_run("Game Design Document (GDD) & Especificação de Produto")
    s_run.font.name = 'Helvetica Neue'
    s_run.font.size = Pt(14)
    s_run.font.bold = True
    s_run.font.color.rgb = COLOR_TEAL

    i = 0
    in_code_block = False
    code_lines = []

    while i < len(lines):
        line = lines[i].rstrip('\r\n')

        # Code block handler
        if line.startswith('```'):
            if in_code_block:
                # End code block
                in_code_block = False
                code_text = "\n".join(code_lines)
                code_lines = []
                
                table = doc.add_table(rows=1, cols=1)
                table.alignment = WD_TABLE_ALIGNMENT.CENTER
                cell = table.rows[0].cells[0]
                set_cell_background(cell, HEX_CODE_BG)
                set_cell_margins(cell, top=140, bottom=140, left=180, right=180)
                set_cell_borders(cell, top="1E293B", bottom="1E293B", left="1FAF8A", right="1E293B")
                
                cp = cell.paragraphs[0]
                cp.paragraph_format.space_before = Pt(0)
                cp.paragraph_format.space_after = Pt(0)
                c_run = cp.add_run(code_text)
                c_run.font.name = 'Menlo'
                c_run.font.size = Pt(8)
                c_run.font.color.rgb = RGBColor(226, 232, 240) # light gray
                
                doc.add_paragraph() # spacer
            else:
                in_code_block = True
                code_lines = []
            i += 1
            continue

        if in_code_block:
            code_lines.append(line)
            i += 1
            continue

        # Skip main title from md since we added title card
        if line.startswith('# Lumen — Game Design Document'):
            i += 1
            continue

        # Headings
        if line.startswith('#### '):
            add_styled_heading(doc, line[5:].strip(), level=3)
            i += 1
            continue
        elif line.startswith('### '):
            add_styled_heading(doc, line[4:].strip(), level=2)
            i += 1
            continue
        elif line.startswith('## '):
            add_styled_heading(doc, line[3:].strip(), level=1)
            i += 1
            continue
        elif line.startswith('# '):
            add_styled_heading(doc, line[2:].strip(), level=1)
            i += 1
            continue

        # Horizontal Rule
        if line.strip() in ['---', '***', '___']:
            i += 1
            continue

        # Blockquote
        if line.startswith('> '):
            bq_lines = []
            while i < len(lines) and lines[i].startswith('>'):
                bq_lines.append(lines[i].lstrip('>').strip())
                i += 1
            bq_text = " ".join(bq_lines)
            table = doc.add_table(rows=1, cols=1)
            table.alignment = WD_TABLE_ALIGNMENT.CENTER
            cell = table.rows[0].cells[0]
            set_cell_background(cell, "F8FAFC")
            set_cell_margins(cell, top=120, bottom=120, left=160, right=160)
            set_cell_borders(cell, top="E2E8F0", bottom="E2E8F0", left="1FAF8A", right="E2E8F0")
            bp = cell.paragraphs[0]
            bp.paragraph_format.space_before = Pt(0)
            bp.paragraph_format.space_after = Pt(0)
            format_inline_text(bp, bq_text)
            continue

        # Table handler
        if line.strip().startswith('|') and '|' in line[1:]:
            table_lines = []
            while i < len(lines) and lines[i].strip().startswith('|'):
                table_lines.append(lines[i].strip())
                i += 1
            
            if len(table_lines) >= 2:
                # Parse headers and rows
                headers = [c.strip() for c in table_lines[0].strip('|').split('|')]
                # line 1 is separator |---|---|
                data_rows = []
                for row_line in table_lines[2:]:
                    row_cells = [c.strip() for c in row_line.strip('|').split('|')]
                    # Align column count
                    while len(row_cells) < len(headers):
                        row_cells.append("")
                    data_rows.append(row_cells[:len(headers)])

                doc_table = doc.add_table(rows=len(data_rows) + 1, cols=len(headers))
                doc_table.alignment = WD_TABLE_ALIGNMENT.CENTER
                doc_table.style = 'Table Grid'

                # Style Header Row
                hdr_row = doc_table.rows[0]
                for idx, h_text in enumerate(headers):
                    cell = hdr_row.cells[idx]
                    set_cell_background(cell, HEX_TEAL_BG)
                    set_cell_margins(cell, top=100, bottom=100, left=120, right=120)
                    set_cell_borders(cell, top="B4E8DC", bottom="1FAF8A", left="E2E8F0", right="E2E8F0")
                    p = cell.paragraphs[0]
                    p.paragraph_format.space_before = Pt(0)
                    p.paragraph_format.space_after = Pt(0)
                    r = p.add_run(h_text.replace('<br>', ' '))
                    r.font.name = 'Helvetica Neue'
                    r.font.size = Pt(8.5)
                    r.font.bold = True
                    r.font.color.rgb = COLOR_DARK_TEAL

                # Style Data Rows
                for r_idx, row_data in enumerate(data_rows):
                    row = doc_table.rows[r_idx + 1]
                    bg = HEX_ROW_EVEN if r_idx % 2 == 1 else "FFFFFF"
                    for c_idx, cell_value in enumerate(row_data):
                        cell = row.cells[c_idx]
                        set_cell_background(cell, bg)
                        set_cell_margins(cell, top=80, bottom=80, left=110, right=110)
                        set_cell_borders(cell, top="F1F5F9", bottom="E2E8F0", left="F1F5F9", right="F1F5F9")
                        p = cell.paragraphs[0]
                        p.paragraph_format.space_before = Pt(0)
                        p.paragraph_format.space_after = Pt(0)
                        # Clean markdown linebreaks inside tables
                        cleaned_val = cell_value.replace('<br>', '\n')
                        format_inline_text(p, cleaned_val)
                        for run in p.runs:
                            run.font.size = Pt(8.5)

                doc.add_paragraph() # spacer
            continue

        # Task list items
        if line.strip().startswith('- [x] ') or line.strip().startswith('- [ ] '):
            is_checked = line.strip().startswith('- [x] ')
            task_text = line.strip()[6:].strip()
            p = doc.add_paragraph()
            p.paragraph_format.space_before = Pt(1)
            p.paragraph_format.space_after = Pt(1)
            p.paragraph_format.left_indent = Inches(0.25)
            
            box_run = p.add_run("☑ " if is_checked else "☐ ")
            box_run.font.name = 'Helvetica Neue'
            box_run.font.size = Pt(10)
            box_run.font.bold = True
            box_run.font.color.rgb = COLOR_TEAL if is_checked else COLOR_MUTED
            
            format_inline_text(p, task_text)
            i += 1
            continue

        # Bullet lists
        if line.strip().startswith('- ') or line.strip().startswith('* '):
            item_text = line.strip()[2:].strip()
            p = doc.add_paragraph(style='List Bullet')
            p.paragraph_format.space_before = Pt(1)
            p.paragraph_format.space_after = Pt(1)
            format_inline_text(p, item_text)
            i += 1
            continue

        # Numbered lists
        m_num = re.match(r'^(\d+)\.\s+(.*)$', line.strip())
        if m_num:
            num = m_num.group(1)
            item_text = m_num.group(2)
            p = doc.add_paragraph()
            p.paragraph_format.space_before = Pt(2)
            p.paragraph_format.space_after = Pt(2)
            p.paragraph_format.left_indent = Inches(0.25)
            n_run = p.add_run(f"{num}. ")
            n_run.font.name = 'Helvetica Neue'
            n_run.font.bold = True
            n_run.font.color.rgb = COLOR_DARK_TEAL
            format_inline_text(p, item_text)
            i += 1
            continue

        # Regular Paragraph
        if line.strip():
            p = doc.add_paragraph()
            p.paragraph_format.space_before = Pt(2)
            p.paragraph_format.space_after = Pt(4)
            format_inline_text(p, line.strip())

        i += 1

    print(f"Saving DOCX to {docx_path}...")
    doc.save(docx_path)
    print("DOCX successfully generated.")

def convert_docx_to_pages(docx_path, pages_path):
    print(f"Converting {docx_path} to native Apple Pages ({pages_path})...")
    # Delete destination if exists to allow clean save
    if os.path.exists(pages_path):
        subprocess.run(['rm', '-rf', pages_path])

    applescript = f'''
    tell application "Pages"
        activate
        set docxFile to POSIX file "{docx_path}"
        set theDoc to open docxFile
        delay 1
        save theDoc in POSIX file "{pages_path}"
        close theDoc saving no
    end tell
    '''
    res = subprocess.run(['osascript', '-e', applescript], capture_output=True, text=True)
    if res.returncode != 0:
        print(f"Error converting via Pages AppleScript: {res.stderr}")
        raise RuntimeError(res.stderr)
    print(f"Pages file successfully saved at: {pages_path}")

def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    md_file = os.path.join(root, "docs", "GDD.md")
    tmp_docx = "/tmp/Lumen_GDD_temp.docx"
    output_pages = os.path.join(root, "docs", "Lumen_GDD.pages")
    copy_pages = os.path.join(root, "docs", "GDD.pages")

    build_docx(md_file, tmp_docx)
    convert_docx_to_pages(tmp_docx, output_pages)
    
    # Also create copy as GDD.pages
    subprocess.run(['cp', '-R', output_pages, copy_pages])
    print(f"Mirror copied to {copy_pages}")

if __name__ == "__main__":
    main()
